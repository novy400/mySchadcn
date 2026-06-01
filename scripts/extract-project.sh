#!/bin/bash

# Script pour extraire le projet actuel (mySchadcn) vers un nouveau dossier "template".
# Ce script copie les fichiers, nettoie l'historique Git et les dépendances, 
# et prépare le package.json pour le nouveau projet.

if [ "$#" -ne 1 ]; then
    echo "Usage: ./scripts/extract-project.sh <chemin_nouveau_projet>"
    echo "Exemple: ./scripts/extract-project.sh ../mon-nouveau-crm"
    exit 1
fi

# Résoudre le répertoire cible (pour gérer les chemins relatifs)
mkdir -p "$1"
TARGET_DIR="$(cd "$1" && pwd)"
PROJECT_NAME=$(basename "$TARGET_DIR")

# Résoudre le répertoire source du projet mySchadcn (là où se trouve le script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

echo "📂 Création du nouveau projet dans : $TARGET_DIR"
echo "📥 Source copiée : $SRC_DIR"

# Copie ultra-rapide en EXCLUANT node_modules, dist et .git *pendant* la copie
echo "⏳ Copie des fichiers en cours (sans node_modules ni .git)..."
tar -cf - --exclude=node_modules --exclude=.git --exclude=dist -C "$SRC_DIR" . | tar -xf - -C "$TARGET_DIR"

# Se déplacer dans le nouveau dossier
cd "$TARGET_DIR"

# Initialisation d'un historique Git tout neuf
echo "🌱 Initialisation de Git..."
git init

# Remplacement du nom du projet dans package.json
# Le .bak assure la compatibilité avec toutes les versions de sed (MacOS/Linux)
sed -i.bak -e "s/\"name\": \".*\"/\"name\": \"$PROJECT_NAME\"/" package.json
rm -f package.json.bak

echo "=========================================="
echo "✅ Nouveau projet '$PROJECT_NAME' prêt ! "
echo "=========================================="
echo "👉 Prochaines étapes :"
echo "   cd $1"
echo "   npm install"
echo "   npm run dev"
