#!/usr/bin/env bash

# Extrait le projet actuel (mySchadcn) vers un nouveau dossier réutilisable.
# Le script copie les fichiers utiles, exclut les artefacts locaux, initialise
# un nouvel historique Git et renomme le package npm.

set -euo pipefail

usage() {
    echo "Usage: ./scripts/extract-project.sh <chemin_nouveau_projet>"
    echo "Exemple: ./scripts/extract-project.sh ../mon-nouveau-crm"
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

TARGET_PATH="$1"

# Résoudre le répertoire source du projet (racine = parent du dossier scripts).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

# Résoudre le répertoire cible sans imposer qu'il existe déjà.
TARGET_PARENT="$(dirname "$TARGET_PATH")"
TARGET_BASENAME="$(basename "$TARGET_PATH")"
mkdir -p "$TARGET_PARENT"
TARGET_PARENT_ABS="$(cd "$TARGET_PARENT" && pwd)"
TARGET_DIR="$TARGET_PARENT_ABS/$TARGET_BASENAME"
PROJECT_NAME="$TARGET_BASENAME"

if [ "$TARGET_DIR" = "$SRC_DIR" ]; then
    echo "❌ Le dossier cible ne peut pas être le projet source."
    exit 1
fi

if [ -e "$TARGET_DIR" ] && [ -n "$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    echo "❌ Le dossier cible existe déjà et n'est pas vide : $TARGET_DIR"
    echo "   Choisissez un nouveau dossier ou videz-le avant de relancer le script."
    exit 1
fi

mkdir -p "$TARGET_DIR"

echo "📂 Création du nouveau projet dans : $TARGET_DIR"
echo "📥 Source copiée : $SRC_DIR"

# Copie en excluant l'historique, les dépendances, les builds et les fichiers locaux.
echo "⏳ Copie des fichiers en cours..."
tar -cf - \
    --exclude=.git \
    --exclude=node_modules \
    --exclude=dist \
    --exclude=coverage \
    --exclude=.vite \
    --exclude=.turbo \
    --exclude=.cache \
    --exclude='*.log' \
    --exclude=.DS_Store \
    --exclude=.env \
    --exclude=.env.local \
    --exclude=.env.*.local \
    -C "$SRC_DIR" . | tar -xf - -C "$TARGET_DIR"

cd "$TARGET_DIR"

# Renommer package.json et package-lock.json avec un nom npm valide.
echo "📝 Renommage du package npm..."
PROJECT_NAME="$PROJECT_NAME" node <<'NODE'
const fs = require('node:fs');
const path = require('node:path');

const rawName = process.env.PROJECT_NAME || 'nouveau-projet';
const packageName = rawName
  .toLowerCase()
  .replace(/[^a-z0-9._-]+/g, '-')
  .replace(/^[._-]+|[._-]+$/g, '') || 'nouveau-projet';

function updateJson(file, updater) {
  const filePath = path.resolve(file);
  if (!fs.existsSync(filePath)) return;
  const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  updater(json);
  fs.writeFileSync(filePath, `${JSON.stringify(json, null, 2)}\n`);
}

updateJson('package.json', json => {
  json.name = packageName;
});

updateJson('package-lock.json', json => {
  json.name = packageName;
  if (json.packages?.['']) {
    json.packages[''].name = packageName;
  }
});

console.log(`   package name: ${packageName}`);
NODE

# Initialisation d'un historique Git tout neuf.
if command -v git >/dev/null 2>&1; then
    echo "🌱 Initialisation de Git..."
    git init
else
    echo "⚠️ Git introuvable : initialisation ignorée."
fi

cat <<EOF
==========================================
✅ Nouveau projet '$PROJECT_NAME' prêt !
==========================================
👉 Prochaines étapes :
   cd "$TARGET_PATH"
   npm install
   npm run dev

🔎 Vérifications recommandées :
   npm run lint
   npm run test
   npm run build
EOF
