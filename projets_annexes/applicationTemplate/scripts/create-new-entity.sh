#!/bin/bash
# Script Complet - Creation Nouvelle Entite API
# Usage: ./scripts/create-new-entity.sh -e "product" -t "PRODUCT"

# Configuration par défaut
ENTITY_NAME=""
TABLE_NAME=""
PLURAL_NAME=""
ID_FIELD=""
ID_TYPE="char(6)"
BASE_BRANCH="employee_rest"
SKIP_TESTS=false

# Fonction d'aide
show_help() {
    echo "Usage: $0 -e ENTITY_NAME -t TABLE_NAME [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --entity     Nom de l'entité (obligatoire)"
    echo "  -t, --table      Nom de la table (obligatoire)"
    echo "  -p, --plural     Nom pluriel (optionnel)"
    echo "  -i, --id-field   Champ ID (optionnel, défaut: {entity}no)"
    echo "  -y, --id-type    Type du champ ID (optionnel, défaut: char(6))"
    echo "  -b, --base       Branche de base (optionnel, défaut: employee_rest)"
    echo "  -s, --skip-tests Ignorer les tests"
    echo "  -h, --help       Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -e product -t PRODUCT"
    echo "  $0 -e customer -t CUSTOMER -p clients -i custno"
}

# Parse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--entity)
            ENTITY_NAME="$2"
            shift 2
            ;;
        -t|--table)
            TABLE_NAME="$2"
            shift 2
            ;;
        -p|--plural)
            PLURAL_NAME="$2"
            shift 2
            ;;
        -i|--id-field)
            ID_FIELD="$2"
            shift 2
            ;;
        -y|--id-type)
            ID_TYPE="$2"
            shift 2
            ;;
        -b|--base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérification des paramètres obligatoires
if [[ -z "$ENTITY_NAME" ]] || [[ -z "$TABLE_NAME" ]]; then
    echo "❌ ERREUR: EntityName et TableName sont obligatoires"
    show_help
    exit 1
fi

# Configuration des variables
ENTITY_LOWER=$(echo "$ENTITY_NAME" | tr '[:upper:]' '[:lower:]')
ENTITY_CAPITAL=$(echo "${ENTITY_LOWER^}")

# Génération du nom pluriel si pas fourni
if [[ -z "$PLURAL_NAME" ]]; then
    if [[ "$ENTITY_LOWER" =~ y$ ]]; then
        PLURAL_NAME="${ENTITY_LOWER%y}ies"
    elif [[ "$ENTITY_LOWER" =~ (s|x|ch|sh)$ ]]; then
        PLURAL_NAME="${ENTITY_LOWER}es"
    else
        PLURAL_NAME="${ENTITY_LOWER}s"
    fi
fi

# Génération du champ ID si pas fourni
if [[ -z "$ID_FIELD" ]]; then
    ID_FIELD="${ENTITY_LOWER}no"
fi

echo "🚀 Creation complete de l'entite API: $ENTITY_CAPITAL"
echo "  - Table: $TABLE_NAME"
echo "  - Routes: /api/$PLURAL_NAME"
echo "  - Champ ID: $ID_FIELD ($ID_TYPE)"

# Vérifier que nous sommes dans le bon répertoire
if [[ ! -d "src/employee" ]]; then
    echo "❌ ERREUR: Template employee non trouvé dans src/employee"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# 1. Créer nouvelle branche
echo ""
echo "📋 Étape 1: Création de la branche feature/api-$ENTITY_LOWER"
git checkout "$BASE_BRANCH" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "⚠️  Branche $BASE_BRANCH non trouvée, utilisation de la branche courante"
fi
git checkout -b "feature/api-$ENTITY_LOWER"

# 2. Copier et adapter la structure
echo ""
echo "📋 Étape 2: Génération des fichiers sources"

# Créer le répertoire destination
TARGET_DIR="src/$ENTITY_LOWER"
if [[ -d "$TARGET_DIR" ]]; then
    echo "⚠️  ATTENTION: Le répertoire $TARGET_DIR existe déjà"
    read -p "Voulez-vous le remplacer ? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Opération annulée"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

echo "Création structure $TARGET_DIR..."
cp -r "src/employee" "$TARGET_DIR"

# Renommer les fichiers
echo "Renommage fichiers..."
cd "$TARGET_DIR"
for file in employee.*; do
    if [[ -f "$file" ]]; then
        new_name="${file/employee/$ENTITY_LOWER}"
        mv "$file" "$new_name"
        echo "   $file → $new_name"
    fi
done
cd - > /dev/null

# Copier et adapter l'include
echo "Création include..."
cp "includes/employee.rpgleinc" "includes/$ENTITY_LOWER.rpgleinc"

# 3. Remplacements dans les fichiers
echo ""
echo "📋 Étape 3: Adaptation du contenu des fichiers"

# Fonction pour remplacer dans un fichier
replace_in_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # Remplacements de base
        sed -i "s/employee/$ENTITY_LOWER/g" "$file"
        sed -i "s/Employee/$ENTITY_CAPITAL/g" "$file"
        sed -i "s/EMPLOYEE/${TABLE_NAME}/g" "$file"
        sed -i "s/empno/$ID_FIELD/g" "$file"
        sed -i "s/employees/$PLURAL_NAME/g" "$file"
        
        echo "   ✅ $file"
    fi
}

# Appliquer les remplacements
echo "Adaptation des fichiers sources..."
for file in src/$ENTITY_LOWER/*; do
    replace_in_file "$file"
done

echo "Adaptation de l'include..."
replace_in_file "includes/$ENTITY_LOWER.rpgleinc"

# 4. Mettre à jour Rules.mk
echo ""
echo "📋 Étape 4: Mise à jour des fichiers de build"

if [[ -f "src/Rules.mk" ]]; then
    if ! grep -q "$ENTITY_LOWER" "src/Rules.mk"; then
        echo "" >> "src/Rules.mk"
        echo "# Module $ENTITY_CAPITAL" >> "src/Rules.mk"
        echo "SUBDIRS += $ENTITY_LOWER" >> "src/Rules.mk"
        echo "   ✅ src/Rules.mk mis à jour"
    else
        echo "   ⚠️  $ENTITY_LOWER déjà présent dans src/Rules.mk"
    fi
fi

# 5. Créer les données de test
echo ""
echo "📋 Étape 5: Génération des données de test"

mkdir -p "ressources/data"

# Créer fichier SQL de test
cat > "ressources/data/${ENTITY_LOWER}.sql" << EOF
-- Données de test pour $ENTITY_CAPITAL
-- Table: $TABLE_NAME

-- Exemple de données (à adapter selon votre structure)
INSERT INTO $TABLE_NAME ($ID_FIELD, NAME, DESCRIPTION) VALUES 
('TEST01', 'Test ${ENTITY_CAPITAL} 1', 'Description test 1'),
('TEST02', 'Test ${ENTITY_CAPITAL} 2', 'Description test 2'),
('TEST03', 'Test ${ENTITY_CAPITAL} 3', 'Description test 3');

COMMIT;
EOF

# Créer fichier JSON de test
cat > "ressources/data/${ENTITY_LOWER}.json" << EOF
[
  {
    "$ID_FIELD": "TEST01",
    "name": "Test ${ENTITY_CAPITAL} 1",
    "description": "Description test 1"
  },
  {
    "$ID_FIELD": "TEST02", 
    "name": "Test ${ENTITY_CAPITAL} 2",
    "description": "Description test 2"
  },
  {
    "$ID_FIELD": "TEST03",
    "name": "Test ${ENTITY_CAPITAL} 3", 
    "description": "Description test 3"
  }
]
EOF

echo "   ✅ ressources/data/${ENTITY_LOWER}.sql"
echo "   ✅ ressources/data/${ENTITY_LOWER}.json"

# 6. Tests de validation
if [[ "$SKIP_TESTS" == false ]]; then
    echo ""
    echo "📋 Étape 6: Tests de validation"
    
    # Test de compilation
    echo "Test de compilation..."
    if command -v bob > /dev/null; then
        if bob --build "src/$ENTITY_LOWER"; then
            echo "   ✅ Compilation réussie"
        else
            echo "   ❌ Erreur de compilation"
        fi
    else
        echo "   ⚠️  BOB non disponible, test de compilation ignoré"
    fi
fi

# 7. Commit des changements
echo ""
echo "📋 Étape 7: Commit des changements"

git add .
git commit -m "feat: Ajout nouvelle entité API $ENTITY_CAPITAL

- Structure complète basée sur pattern Employee
- Routes REST /api/$PLURAL_NAME
- Table source: $TABLE_NAME
- Champ ID: $ID_FIELD ($ID_TYPE)
- Données de test incluses"

echo ""
echo "🎉 SUCCÈS: Entité $ENTITY_CAPITAL créée avec succès!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Adapter la structure de données dans includes/$ENTITY_LOWER.rpgleinc"
echo "   2. Modifier les requêtes SQL dans src/$ENTITY_LOWER/$ENTITY_LOWER.sqlrpgle"
echo "   3. Tester l'API: curl http://localhost:44000/api/$PLURAL_NAME"
echo "   4. Exécuter les tests: ./test-${ENTITY_LOWER}-api.sh"
echo ""
echo "📁 Fichiers créés:"
echo "   - src/$ENTITY_LOWER/ (tous les fichiers sources)"
echo "   - includes/$ENTITY_LOWER.rpgleinc"
echo "   - ressources/data/${ENTITY_LOWER}.sql"
echo "   - ressources/data/${ENTITY_LOWER}.json"
echo ""
echo "🌿 Branche créée: feature/api-$ENTITY_LOWER"