#!/bin/bash
# Script pour rendre tous les scripts shell exécutables
# Usage: ./scripts/make-executable.sh

echo "🔧 Configuration des permissions pour scripts shell"
echo "=================================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Trouver tous les fichiers .sh
echo "📁 Recherche des scripts shell..."

# Scripts dans le répertoire racine
for script in *.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo -e "${GREEN}✅ $script${NC}"
    fi
done

# Scripts dans le répertoire scripts/
if [[ -d "scripts" ]]; then
    for script in scripts/*.sh; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            echo -e "${GREEN}✅ $script${NC}"
        fi
    done
fi

# Scripts de test
for script in test-*.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo -e "${GREEN}✅ $script${NC}"
    fi
done

echo ""
echo -e "${BLUE}📋 Scripts disponibles:${NC}"
echo ""

echo "🏗️  Génération/Création:"
echo "   ./scripts/create-new-entity.sh -e ENTITY -t TABLE"
echo "   ./scripts/generate-api-skeleton.sh RESOURCE TABLE"
echo ""

echo "🧪 Tests:"
echo "   ./test-employee-api-conformity.sh"
echo "   ./test-modular-architecture.sh"
echo "   ./test-phase2-filtres-avances.sh"
echo ""

echo "🔨 Build/Utilitaires:"
echo "   ./scripts/make-executable.sh (ce script)"
echo ""

echo "✅ Tous les scripts shell sont maintenant exécutables!"