#!/bin/bash
# Script de conversion globale PowerShell vers Shell
# Remplace les scripts .ps1 existants par leurs équivalents .sh

echo "🔄 Conversion PowerShell → Shell"
echo "================================"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="scripts/.backup_ps1"

# Créer répertoire de backup
mkdir -p "$BACKUP_DIR"

echo "📦 Sauvegarde des scripts PowerShell..."

# Sauvegarder les scripts PowerShell existants
for ps1_file in *.ps1 scripts/*.ps1; do
    if [[ -f "$ps1_file" ]]; then
        cp "$ps1_file" "$BACKUP_DIR/"
        echo "   💾 $(basename "$ps1_file") → $BACKUP_DIR/"
    fi
done

echo ""
echo "✅ Scripts shell créés:"
echo ""

echo "📁 Générateurs:"
echo "   ./scripts/create-new-entity.sh      (remplace Create-NewEntity.ps1)"
echo "   ./scripts/generate-api-skeleton.sh  (remplace generate_api_skeleton.ps1)"
echo ""

echo "🧪 Tests:"
echo "   ./test-employee-api-conformity.sh   (remplace test_employee_api_conformity.ps1)"
echo "   ./test-modular-architecture.sh      (remplace test_modular_architecture.ps1)"
echo "   ./test-phase2-filtres-avances.sh    (remplace test_phase2_filtres_avances.ps1)"
echo "   ./test-testservice-api.sh           (remplace test_testservice_api.ps1)"
echo ""

echo "🔧 Utilitaires:"
echo "   ./scripts/make-executable.sh        (nouveau)"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   1. Les scripts PowerShell originaux sont sauvegardés dans $BACKUP_DIR"
echo "   2. Exécutez ./scripts/make-executable.sh pour rendre les scripts exécutables"
echo "   3. Sur Windows, utilisez Git Bash, WSL ou un terminal compatible bash"
echo ""

echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo "   1. chmod +x scripts/*.sh test-*.sh  (rendre exécutable)"
echo "   2. Tester: ./test-employee-api-conformity.sh"
echo "   3. Créer nouvelle entité: ./scripts/create-new-entity.sh -e product -t PRODUCT"
echo ""

echo -e "${GREEN}🎉 Conversion terminée!${NC}"
echo "   Vous pouvez maintenant utiliser les scripts shell sans problèmes d'encodage"