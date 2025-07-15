#!/bin/bash
# =================================================================
# SUITE DE TESTS ÉCOSYSTÈME AGENTS IA v4.0 - GUILLAUME TAI
# =================================================================

# Configuration
N8N_BASE_URL="https://srv743925.hstgr.cloud:5678"
SUPABASE_URL="your-supabase-url"
API_TIMEOUT=30

# Couleurs pour affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 SUITE DE TESTS ÉCOSYSTÈME AGENTS IA v4.0${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# =================================================================
# TESTS PRÉLIMINAIRES
# =================================================================

echo -e "${YELLOW}📋 Phase 1: Tests Préliminaires${NC}"
echo ""

# Test 1: Connexion n8n
echo -n "🔌 Test connexion n8n... "
if curl -s --max-time $API_TIMEOUT "$N8N_BASE_URL/rest/health" > /dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
    N8N_STATUS="OK"
else
    echo -e "${RED}❌ ÉCHEC${NC}"
    N8N_STATUS="FAIL"
fi

# Test 2: Validation Supabase
echo -n "🗄️  Test Supabase schema... "
if command -v psql > /dev/null 2>&1; then
    # Remplacez par votre connection string
    SUPABASE_TEST=$(psql "$SUPABASE_URL" -c "SELECT chatbot_health_check_v41();" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ OK${NC}"
        SUPABASE_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        SUPABASE_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (psql non disponible)${NC}"
    SUPABASE_STATUS="SKIP"
fi

# Test 3: Workflows présents
echo -n "📦 Test workflows présents... "
WORKFLOWS_DIR="workflows"
if [ -d "$WORKFLOWS_DIR" ] && [ $(ls -1 $WORKFLOWS_DIR/*.json 2>/dev/null | wc -l) -eq 5 ]; then
    echo -e "${GREEN}✅ OK (5 workflows)${NC}"
    WORKFLOWS_STATUS="OK"
else
    echo -e "${RED}❌ ÉCHEC${NC}"
    WORKFLOWS_STATUS="FAIL"
fi

echo ""

# =================================================================
# TESTS FONCTIONNELS AGENTS
# =================================================================

echo -e "${YELLOW}🤖 Phase 2: Tests Fonctionnels Agents${NC}"
echo ""

# Test Master Coordinator
echo -n "🧠 Test Master Coordinator... "
if [ "$N8N_STATUS" = "OK" ]; then
    # Test webhook Master Coordinator
    MASTER_RESPONSE=$(curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/master-coordinator-v40" \
        -H "Content-Type: application/json" \
        -d '{"message": "Status check", "test": true}')
    
    if [ ! -z "$MASTER_RESPONSE" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        MASTER_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        MASTER_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (n8n indisponible)${NC}"
    MASTER_STATUS="SKIP"
fi

# Test Productivity Agent
echo -n "📈 Test Productivity Agent... "
if [ "$N8N_STATUS" = "OK" ]; then
    PRODUCTIVITY_RESPONSE=$(curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/productivity-agent-v40" \
        -H "Content-Type: application/json" \
        -d '{"query": "health check", "test": true}')
    
    if [ ! -z "$PRODUCTIVITY_RESPONSE" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        PRODUCTIVITY_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        PRODUCTIVITY_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (n8n indisponible)${NC}"
    PRODUCTIVITY_STATUS="SKIP"
fi

# Test Learning Agent
echo -n "🎓 Test Learning Agent... "
if [ "$N8N_STATUS" = "OK" ]; then
    LEARNING_RESPONSE=$(curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/learning-agent-v40" \
        -H "Content-Type: application/json" \
        -d '{"query": "test rag", "test": true}')
    
    if [ ! -z "$LEARNING_RESPONSE" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        LEARNING_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        LEARNING_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (n8n indisponible)${NC}"
    LEARNING_STATUS="SKIP"
fi

# Test Content Agent
echo -n "✍️  Test Content Agent... "
if [ "$N8N_STATUS" = "OK" ]; then
    CONTENT_RESPONSE=$(curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/content-agent-v40" \
        -H "Content-Type: application/json" \
        -d '{"task": "health check", "test": true}')
    
    if [ ! -z "$CONTENT_RESPONSE" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        CONTENT_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        CONTENT_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (n8n indisponible)${NC}"
    CONTENT_STATUS="SKIP"
fi

# Test Security Agent
echo -n "🔒 Test Security Agent... "
if [ "$N8N_STATUS" = "OK" ]; then
    SECURITY_RESPONSE=$(curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/security-agent-v40" \
        -H "Content-Type: application/json" \
        -d '{"action": "status", "test": true}')
    
    if [ ! -z "$SECURITY_RESPONSE" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        SECURITY_STATUS="OK"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        SECURITY_STATUS="FAIL"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (n8n indisponible)${NC}"
    SECURITY_STATUS="SKIP"
fi

echo ""

# =================================================================
# TESTS PERFORMANCE
# =================================================================

echo -e "${YELLOW}⚡ Phase 3: Tests Performance${NC}"
echo ""

# Test temps de réponse Master Coordinator
if [ "$MASTER_STATUS" = "OK" ]; then
    echo -n "⏱️  Test performance Master Coordinator... "
    
    START_TIME=$(date +%s%N)
    curl -s --max-time $API_TIMEOUT \
        -X POST "$N8N_BASE_URL/webhook/master-coordinator-v40" \
        -H "Content-Type: application/json" \
        -d '{"message": "performance test"}' > /dev/null
    END_TIME=$(date +%s%N)
    
    RESPONSE_TIME_MS=$(((END_TIME - START_TIME) / 1000000))
    
    if [ $RESPONSE_TIME_MS -lt 5000 ]; then
        echo -e "${GREEN}✅ OK (${RESPONSE_TIME_MS}ms)${NC}"
        PERFORMANCE_STATUS="OK"
    else
        echo -e "${YELLOW}⚠️  LENT (${RESPONSE_TIME_MS}ms)${NC}"
        PERFORMANCE_STATUS="SLOW"
    fi
else
    echo -e "${YELLOW}⚠️  SKIP (Master Coordinator indisponible)${NC}"
    PERFORMANCE_STATUS="SKIP"
fi

echo ""

# =================================================================
# RAPPORT FINAL
# =================================================================

echo -e "${BLUE}📊 RAPPORT FINAL${NC}"
echo -e "${BLUE}===============${NC}"
echo ""

# Calcul score global
TOTAL_TESTS=8
SUCCESS_COUNT=0

# Comptage des succès
[ "$N8N_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$SUPABASE_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$WORKFLOWS_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$MASTER_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$PRODUCTIVITY_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$LEARNING_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$CONTENT_STATUS" = "OK" ] && ((SUCCESS_COUNT++))
[ "$SECURITY_STATUS" = "OK" ] && ((SUCCESS_COUNT++))

SUCCESS_RATE=$(( (SUCCESS_COUNT * 100) / TOTAL_TESTS ))

echo "🔌 n8n Connection: $N8N_STATUS"
echo "🗄️  Supabase Schema: $SUPABASE_STATUS"
echo "📦 Workflows: $WORKFLOWS_STATUS"
echo "🧠 Master Coordinator: $MASTER_STATUS"
echo "📈 Productivity Agent: $PRODUCTIVITY_STATUS"
echo "🎓 Learning Agent: $LEARNING_STATUS"
echo "✍️  Content Agent: $CONTENT_STATUS"
echo "🔒 Security Agent: $SECURITY_STATUS"
echo ""
echo "📊 Score Global: $SUCCESS_COUNT/$TOTAL_TESTS ($SUCCESS_RATE%)"
echo ""

if [ $SUCCESS_RATE -ge 80 ]; then
    echo -e "${GREEN}🎉 ÉCOSYSTÈME OPÉRATIONNEL !${NC}"
    echo -e "${GREEN}Vous pouvez utiliser vos agents IA.${NC}"
    exit 0
elif [ $SUCCESS_RATE -ge 60 ]; then
    echo -e "${YELLOW}⚠️  ÉCOSYSTÈME PARTIELLEMENT OPÉRATIONNEL${NC}"
    echo -e "${YELLOW}Certains agents nécessitent des ajustements.${NC}"
    exit 1
else
    echo -e "${RED}❌ ÉCOSYSTÈME NON OPÉRATIONNEL${NC}"
    echo -e "${RED}Vérifiez la configuration et relancez les tests.${NC}"
    exit 2
fi