#!/bin/bash
# =================================================================
# SCRIPT MAINTENANCE ÉCOSYSTÈME AGENTS IA v4.0
# =================================================================

# Configuration
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="./logs/maintenance_$(date +%Y%m%d).log"

# Créer répertoires si nécessaire
mkdir -p "$BACKUP_DIR" "./logs"

echo "🔧 Maintenance Écosystème Agents IA v4.0" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Début: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 1. Sauvegarde workflows
echo "📦 Sauvegarde workflows..." | tee -a "$LOG_FILE"
if [ -d "workflows" ]; then
    cp -r workflows "$BACKUP_DIR/"
    echo "✅ Workflows sauvegardés" | tee -a "$LOG_FILE"
else
    echo "❌ Dossier workflows introuvable" | tee -a "$LOG_FILE"
fi

# 2. Sauvegarde base de données
echo "🗄️  Sauvegarde Supabase..." | tee -a "$LOG_FILE"
if command -v pg_dump > /dev/null 2>&1; then
    # Remplacez par votre connection string
    pg_dump "your-supabase-connection-string" > "$BACKUP_DIR/supabase_backup.sql" 2>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo "✅ Base de données sauvegardée" | tee -a "$LOG_FILE"
    else
        echo "❌ Échec sauvegarde base" | tee -a "$LOG_FILE"
    fi
else
    echo "⚠️  pg_dump non disponible, skip" | tee -a "$LOG_FILE"
fi

# 3. Nettoyage logs anciens
echo "🧹 Nettoyage logs..." | tee -a "$LOG_FILE"
find ./logs -name "*.log" -mtime +30 -delete 2>>"$LOG_FILE"
echo "✅ Logs anciens supprimés" | tee -a "$LOG_FILE"

# 4. Vérification santé système
echo "🏥 Vérification santé..." | tee -a "$LOG_FILE"
./scripts/test_ecosystem.sh > "$BACKUP_DIR/health_check.txt" 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Système en bonne santé" | tee -a "$LOG_FILE"
else
    echo "⚠️  Problèmes détectés, voir health_check.txt" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Fin: $(date)" | tee -a "$LOG_FILE"
echo "🎉 Maintenance terminée !" | tee -a "$LOG_FILE"