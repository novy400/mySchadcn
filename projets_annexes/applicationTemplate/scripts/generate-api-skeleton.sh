#!/bin/bash
# Générateur API Skeleton - Conversion du script PowerShell
# Usage: ./scripts/generate-api-skeleton.sh RESOURCE_NAME TABLE_NAME

# Vérification des paramètres
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 RESOURCE_NAME TABLE_NAME"
    echo "Exemple: $0 product PRODUCT"
    exit 1
fi

RESOURCE_NAME="$1"
TABLE_NAME="$2"

echo "🚀 Génération API $RESOURCE_NAME basée sur table $TABLE_NAME"
echo "============================================================"

# Vérifier que le template employee existe
if [[ ! -d "src/employee" ]]; then
    echo "❌ ERREUR: Template employee non trouvé dans src/employee"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Créer le répertoire destination
TARGET_DIR="src/$RESOURCE_NAME"
if [[ -d "$TARGET_DIR" ]]; then
    echo "⚠️  ATTENTION: Le répertoire $TARGET_DIR existe déjà"
    read -p "Voulez-vous le remplacer ? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Opération annulée"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

echo "📁 Création structure $TARGET_DIR..."
cp -r "src/employee" "$TARGET_DIR"

# Renommer les fichiers
echo "📝 Renommage fichiers..."
cd "$TARGET_DIR"

for file in employee.*; do
    if [[ -f "$file" ]]; then
        new_name="${file/employee/$RESOURCE_NAME}"
        mv "$file" "$new_name"
        echo "   $file → $new_name"
    fi
done

cd - > /dev/null

# Copier et adapter l'include
echo "📄 Création include..."
cp "includes/employee.rpgleinc" "includes/$RESOURCE_NAME.rpgleinc"

# Remplacements dans les fichiers
echo "🔄 Remplacements dans les fichiers..."

# Fonction pour effectuer les remplacements
replace_content() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        # Remplacements de base
        sed -i "s/employee/$RESOURCE_NAME/g" "$file"
        sed -i "s/Employee/$(echo "${RESOURCE_NAME^}")/g" "$file"
        sed -i "s/EMPLOYEE/$TABLE_NAME/g" "$file"
        
        # Remplacements spécifiques
        sed -i "s/empno/${RESOURCE_NAME}no/g" "$file"
        sed -i "s/employees/${RESOURCE_NAME}s/g" "$file"
        
        echo "   ✅ $file"
    fi
}

# Appliquer les remplacements aux fichiers sources
echo "   Fichiers sources:"
for file in src/$RESOURCE_NAME/*; do
    replace_content "$file"
done

echo "   Include:"
replace_content "includes/$RESOURCE_NAME.rpgleinc"

# Mettre à jour Rules.mk
echo "🔧 Mise à jour Rules.mk..."
if [[ -f "src/Rules.mk" ]]; then
    if ! grep -q "$RESOURCE_NAME" "src/Rules.mk"; then
        echo "" >> "src/Rules.mk"
        echo "# Module $(echo "${RESOURCE_NAME^}")" >> "src/Rules.mk" 
        echo "SUBDIRS += $RESOURCE_NAME" >> "src/Rules.mk"
        echo "   ✅ $RESOURCE_NAME ajouté à src/Rules.mk"
    else
        echo "   ⚠️  $RESOURCE_NAME déjà présent dans src/Rules.mk"
    fi
fi

# Créer les données de test
echo "📊 Création données de test..."
mkdir -p "ressources/data"

# Fichier SQL
cat > "ressources/data/$RESOURCE_NAME.sql" << EOF
-- Données de test pour $(echo "${RESOURCE_NAME^}")
-- Table: $TABLE_NAME

-- Exemple de structure (à adapter selon vos besoins)
INSERT INTO $TABLE_NAME (${RESOURCE_NAME}no, name, description) VALUES 
('001', 'Test $(echo "${RESOURCE_NAME^}") 1', 'Description 1'),
('002', 'Test $(echo "${RESOURCE_NAME^}") 2', 'Description 2');

COMMIT;
EOF

# Fichier JSON  
cat > "ressources/data/$RESOURCE_NAME.json" << EOF
[
  {
    "${RESOURCE_NAME}no": "001",
    "name": "Test $(echo "${RESOURCE_NAME^}") 1", 
    "description": "Description 1"
  },
  {
    "${RESOURCE_NAME}no": "002",
    "name": "Test $(echo "${RESOURCE_NAME^}") 2",
    "description": "Description 2" 
  }
]
EOF

echo "   ✅ ressources/data/$RESOURCE_NAME.sql"
echo "   ✅ ressources/data/$RESOURCE_NAME.json"

# Test de compilation si BOB est disponible
echo "🔨 Test compilation..."
if command -v bob > /dev/null; then
    if bob --build "src/$RESOURCE_NAME"; then
        echo "   ✅ Compilation réussie"
    else
        echo "   ❌ Erreur de compilation - vérifiez les fichiers générés"
    fi
else
    echo "   ⚠️  BOB non disponible, compilation ignorée"
fi

echo ""
echo "🎉 Génération terminée avec succès!"
echo ""
echo "📋 Fichiers créés:"
echo "   - src/$RESOURCE_NAME/ (structure complète)"
echo "   - includes/$RESOURCE_NAME.rpgleinc"
echo "   - ressources/data/$RESOURCE_NAME.sql" 
echo "   - ressources/data/$RESOURCE_NAME.json"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Adapter la structure dans includes/$RESOURCE_NAME.rpgleinc"
echo "   2. Modifier les requêtes SQL dans src/$RESOURCE_NAME/$RESOURCE_NAME.sqlrpgle"
echo "   3. Tester: curl http://localhost:44000/api/${RESOURCE_NAME}s"
echo ""
echo "🔗 Routes API générées:"
echo "   GET    /api/${RESOURCE_NAME}s"
echo "   GET    /api/${RESOURCE_NAME}s/{id}"
echo "   POST   /api/${RESOURCE_NAME}s"
echo "   PUT    /api/${RESOURCE_NAME}s/{id}"
echo "   DELETE /api/${RESOURCE_NAME}s/{id}"