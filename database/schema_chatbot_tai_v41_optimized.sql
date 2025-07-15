-- ================================================
-- SCHEMA CHATBOT TAI v4.1 - OPTIMISÉ MÉMOIRE
-- Solution pour erreur maintenance_work_mem
-- ================================================

-- 1. CONFIGURATION TEMPORAIRE MÉMOIRE
-- Exécuter dans psql (obligatoire pour éviter timeout dashboard)
SET maintenance_work_mem = '256MB';
SET max_parallel_maintenance_workers = 2;
SET random_page_cost = 1.1;

-- 2. ACTIVATION EXTENSIONS REQUISES
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- 3. SCHÉMA TABLES OPTIMISÉES

-- Table documents avec optimisations
CREATE TABLE IF NOT EXISTS documents_tai_v41 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_url TEXT,
    metadata JSONB DEFAULT '{}',
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table conversations avec tracking performance
CREATE TABLE IF NOT EXISTS conversations_tai_v41 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL,
    agent_type VARCHAR(50) NOT NULL,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    response_time_ms INTEGER,
    confidence_score FLOAT,
    relevant_docs UUID[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table analytics pour monitoring
CREATE TABLE IF NOT EXISTS agent_analytics_v41 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_type VARCHAR(50) NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value FLOAT NOT NULL,
    date_recorded DATE DEFAULT CURRENT_DATE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. INDEX OPTIMISÉS POUR PERFORMANCE

-- Index texte pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_documents_content_gin 
ON documents_tai_v41 USING gin(to_tsvector('french', content));

-- Index HNSW pour embeddings (plus efficace que IVFFlat)
CREATE INDEX IF NOT EXISTS idx_documents_embedding_hnsw 
ON documents_tai_v41 USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Index pour conversations
CREATE INDEX IF NOT EXISTS idx_conversations_session_agent 
ON conversations_tai_v41(session_id, agent_type, created_at DESC);

-- Index pour analytics
CREATE INDEX IF NOT EXISTS idx_analytics_agent_date 
ON agent_analytics_v41(agent_type, date_recorded DESC);

-- 5. FONCTIONS UTILITAIRES

-- Fonction recherche hybride (texte + vectorielle)
CREATE OR REPLACE FUNCTION search_documents_hybrid_v41(
    query_text TEXT,
    query_embedding VECTOR(1536),
    similarity_threshold FLOAT DEFAULT 0.7,
    max_results INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    similarity_score FLOAT,
    text_rank FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        (1 - (d.embedding <=> query_embedding)) as similarity_score,
        ts_rank(to_tsvector('french', d.content), plainto_tsquery('french', query_text)) as text_rank
    FROM documents_tai_v41 d
    WHERE 
        (1 - (d.embedding <=> query_embedding)) > similarity_threshold
        OR to_tsvector('french', d.content) @@ plainto_tsquery('french', query_text)
    ORDER BY 
        GREATEST(
            (1 - (d.embedding <=> query_embedding)),
            ts_rank(to_tsvector('french', d.content), plainto_tsquery('french', query_text))
        ) DESC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Fonction health check
CREATE OR REPLACE FUNCTION chatbot_health_check_v41()
RETURNS TABLE (
    component TEXT,
    status TEXT,
    details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'documents_table'::TEXT as component,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'WARNING' END as status,
        jsonb_build_object('total_documents', COUNT(*)) as details
    FROM documents_tai_v41
    
    UNION ALL
    
    SELECT 
        'vector_index'::TEXT as component,
        CASE 
            WHEN (SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_documents_embedding_hnsw') > 0 
            THEN 'OK' 
            ELSE 'ERROR' 
        END as status,
        jsonb_build_object('index_exists', 
            (SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_documents_embedding_hnsw') > 0
        ) as details
    
    UNION ALL
    
    SELECT 
        'recent_activity'::TEXT as component,
        CASE 
            WHEN COUNT(*) > 0 THEN 'OK' 
            ELSE 'INFO' 
        END as status,
        jsonb_build_object(
            'conversations_last_24h', COUNT(*),
            'avg_response_time_ms', COALESCE(AVG(response_time_ms), 0)
        ) as details
    FROM conversations_tai_v41
    WHERE created_at > NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Fonction d'insertion avec embedding automatique
CREATE OR REPLACE FUNCTION insert_document_with_embedding_v41(
    p_title TEXT,
    p_content TEXT,
    p_source_type TEXT,
    p_source_url TEXT DEFAULT NULL,
    p_embedding VECTOR(1536) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO documents_tai_v41 (
        title, content, source_type, source_url, embedding
    ) VALUES (
        p_title, p_content, p_source_type, p_source_url, p_embedding
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- 6. TRIGGERS POUR MAINTENANCE AUTO

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_documents_updated_at 
    BEFORE UPDATE ON documents_tai_v41 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. DONNÉES D'EXEMPLE POUR TESTS

INSERT INTO documents_tai_v41 (title, content, source_type) VALUES 
('Introduction TAI', 'Le Technicien d\'Assistance Informatique (TAI) intervient sur les équipements informatiques...', 'formation'),
('Protocole TCP/IP', 'TCP/IP est la suite de protocoles de communication utilisée sur Internet...', 'cours'),
('Sécurité Windows', 'La sécurisation d\'un environnement Windows implique plusieurs couches de protection...', 'securite')
ON CONFLICT DO NOTHING;

-- 8. VUES POUR ANALYTICS

CREATE OR REPLACE VIEW agent_performance_v41 AS
SELECT 
    agent_type,
    DATE(created_at) as date,
    COUNT(*) as total_requests,
    AVG(response_time_ms) as avg_response_time,
    AVG(confidence_score) as avg_confidence,
    COUNT(CASE WHEN confidence_score > 0.8 THEN 1 END) as high_confidence_responses
FROM conversations_tai_v41
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY agent_type, DATE(created_at)
ORDER BY date DESC, agent_type;

-- 9. PERMISSIONS ET SÉCURITÉ

-- RLS policies (à adapter selon votre setup Supabase)
ALTER TABLE documents_tai_v41 ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations_tai_v41 ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_analytics_v41 ENABLE ROW LEVEL SECURITY;

-- 10. MAINTENANCE ET OPTIMISATION

-- Fonction de maintenance régulière
CREATE OR REPLACE FUNCTION maintenance_tai_v41()
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Vacuum analyze pour optimiser performance
    PERFORM pg_stat_reset();
    
    -- Réindexation si nécessaire
    REINDEX INDEX CONCURRENTLY idx_documents_embedding_hnsw;
    
    -- Nettoyage des anciennes conversations (optionnel)
    DELETE FROM conversations_tai_v41 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    result := 'Maintenance completed at ' || NOW();
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FIN SCHEMA CHATBOT TAI v4.1 - OPTIMISÉ MÉMOIRE
-- ================================================

-- Validation finale
SELECT 'Schema TAI v4.1 installé avec succès !' as status;
SELECT * FROM chatbot_health_check_v41();