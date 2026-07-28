#!/bin/bash

# Script pour lancer les tests Bruno Employee API
# Usage: ./run-bruno-tests.sh [environment] [output-format]
# Exemple: ./run-bruno-tests.sh local html

# Configuration par défaut
ENVIRONMENT=${1:-local}
OUTPUT_FORMAT=${2:-html}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Déterminer la racine du projet et créer le chemin absolu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/reports/bruno"
OUTPUT_FILE="employee-api-tests-${TIMESTAMP}.${OUTPUT_FORMAT}"

# Créer le répertoire de sortie si nécessaire
mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo "🧪 Tests Bruno - Employee API"
echo "================================================"
echo "Environnement: $ENVIRONMENT"
echo "Format: $OUTPUT_FORMAT"
echo "Rapport: $OUTPUT_DIR/$OUTPUT_FILE"
echo "================================================"

# Se placer dans le répertoire Bruno
cd "$PROJECT_ROOT/tests/bruno"

# Lancer les tests
echo "⚡ Lancement des tests..."
if [ "$OUTPUT_FORMAT" = "html" ]; then
    bru run employee-api --env "$ENVIRONMENT" -o "$OUTPUT_DIR/$OUTPUT_FILE" -f html
elif [ "$OUTPUT_FORMAT" = "json" ]; then
    bru run employee-api --env "$ENVIRONMENT" -o "$OUTPUT_DIR/$OUTPUT_FILE" -f json
else
    # Format console par défaut
    bru run employee-api --env "$ENVIRONMENT"
fi

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo "✅ Tests terminés avec succès!"
    if [ "$OUTPUT_FORMAT" != "console" ]; then
        echo "📊 Rapport disponible: $OUTPUT_DIR/$OUTPUT_FILE"
    fi
else
    echo "❌ Des tests ont échoué!"
    exit 1
fi

echo "================================================"