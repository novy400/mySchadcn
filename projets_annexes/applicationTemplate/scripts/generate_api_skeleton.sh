#!/bin/bash

# Générateur de squelette API REST
# Basé sur le pattern employee validé

RESOURCE_NAME=$1
TABLE_NAME=$2

if [ -z "$RESOURCE_NAME" ] || [ -z "$TABLE_NAME" ]; then
    echo "Usage: $0 <resource_name> <table_name>"
    echo "Exemple: $0 customer CUSTOMER"
    exit 1
fi

echo "🏗️ Génération API $RESOURCE_NAME basée sur table $TABLE_NAME"
echo "============================================================"

# Vérifier que le template employee existe
if [ ! -d "src/employee" ]; then
    echo "❌ Template employee non trouvé dans src/employee"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Créer le répertoire destination
TARGET_DIR="src/$RESOURCE_NAME"
if [ -d "$TARGET_DIR" ]; then
    echo "⚠️ Le répertoire $TARGET_DIR existe déjà"
    read -p "Voulez-vous le remplacer ? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Opération annulée"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

echo "📁 Création structure $TARGET_DIR..."
cp -r src/employee "$TARGET_DIR"

# Renommer les fichiers
echo "📝 Renommage fichiers..."
cd "$TARGET_DIR" || exit 1

for file in employee.*; do
    if [ -f "$file" ]; then
        new_name="${file/employee/$RESOURCE_NAME}"
        mv "$file" "$new_name"
        echo "   $file → $new_name"
    fi
done

# Copier et adapter l'include
echo "📝 Création include..."
cp "../../includes/employee.rpgleinc" "../../includes/$RESOURCE_NAME.rpgleinc"

# Remplacements dans les fichiers
echo "🔄 Adaptation du code..."

# Liste des fichiers à modifier
FILES_TO_MODIFY=(
    "$RESOURCE_NAME.main.rpgle"
    "$RESOURCE_NAME.route.sqlrpgle" 
    "$RESOURCE_NAME.rest.sqlrpgle"
    "$RESOURCE_NAME.sqlrpgle"
    "$RESOURCE_NAME.bnd"
    "Rules.mk"
    "../../includes/$RESOURCE_NAME.rpgleinc"
)

for file in "${FILES_TO_MODIFY[@]}"; do
    if [ -f "$file" ]; then
        echo "   Modification $file..."
        
        # Remplacements de base
        sed -i "s/employee/$RESOURCE_NAME/g" "$file"
        sed -i "s/EMPLOYEE/${RESOURCE_NAME^^}/g" "$file"
        sed -i "s/Employee/${RESOURCE_NAME^}/g" "$file"
        
        # Remplacements spécifiques selon le type de fichier
        case "$file" in
            *".sqlrpgle")
                # Remplacer le nom de table (exemple)
                sed -i "s/from employee/from $TABLE_NAME/g" "$file"
                sed -i "s/FROM employee/FROM $TABLE_NAME/g" "$file"
                ;;
            *".rpgleinc")
                # Adapter la garde d'include
                sed -i "s/EMPLOYEE_INCLUDE/${RESOURCE_NAME^^}_INCLUDE/g" "$file"
                ;;
        esac
    fi
done

# Retour au répertoire racine
cd - > /dev/null

# Créer le README spécifique
echo "📚 Création README..."
cat > "$TARGET_DIR/README_${RESOURCE_NAME^^}_API.md" << EOF
# ${RESOURCE_NAME^} API REST

Cette API respecte le pattern défini dans \`ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md\`.

## Configuration

**Table DB2:** $TABLE_NAME

## Endpoints

- \`GET /api/${RESOURCE_NAME}s\` - Liste avec pagination, filtres, tri
- \`GET /api/${RESOURCE_NAME}s/{id}\` - Détail item
- \`POST /api/${RESOURCE_NAME}s\` - Création
- \`PUT /api/${RESOURCE_NAME}s/{id}\` - Modification
- \`DELETE /api/${RESOURCE_NAME}s/{id}\` - Suppression

## Tests de Validation

\`\`\`bash
# Collection avec pagination
curl "http://server:44000/api/${RESOURCE_NAME}s?_page=1&_limit=10"

# Filtres (à adapter selon vos champs)
curl "http://server:44000/api/${RESOURCE_NAME}s?[champ]=valeur"
curl "http://server:44000/api/${RESOURCE_NAME}s?[champ]_gte=valeur"

# Recherche
curl "http://server:44000/api/${RESOURCE_NAME}s?q=terme"

# Tri
curl "http://server:44000/api/${RESOURCE_NAME}s?_sort=[champ]&_order=ASC"
\`\`\`

## Prochaines Étapes

1. **Adapter les structures** dans \`includes/${RESOURCE_NAME}.rpgleinc\` selon la table $TABLE_NAME
2. **Modifier les requêtes SQL** dans \`${RESOURCE_NAME}.sqlrpgle\`
3. **Configurer les champs filtrables** dans la fonction \`setupFilters\`
4. **Tester** avec \`scripts/validate_api_pattern.sh ${RESOURCE_NAME}s\`
5. **Compiler** avec \`make -C src/${RESOURCE_NAME}\`

## Conformité Pattern

- [ ] Retourne tableau JSON pour collection
- [ ] Header X-Total-Count présent
- [ ] Pagination (_page, _limit)
- [ ] Tri (_sort, _order)
- [ ] Filtres avec opérateurs (_gte, _like, etc.)
- [ ] CRUD complet (GET, POST, PUT, DELETE)
- [ ] Compatible React-Admin
EOF

# Créer un fichier TODO spécifique
cat > "$TARGET_DIR/TODO_${RESOURCE_NAME^^}.md" << EOF
# TODO ${RESOURCE_NAME^} API

## ✅ Génération Automatique Terminée

- [x] Structure de fichiers créée
- [x] Renommage des fichiers effectué
- [x] Adaptations de base appliquées

## 🔄 Adaptations Manuelles Requises

### 1. Structures de Données (30 min)
- [ ] Modifier \`includes/${RESOURCE_NAME}.rpgleinc\`
- [ ] Adapter \`${RESOURCE_NAME}_detail_t\` selon table $TABLE_NAME
- [ ] Adapter \`${RESOURCE_NAME}_item_t\` (version optimisée)
- [ ] Adapter \`${RESOURCE_NAME}_input_t\` (création/modification)

### 2. Requêtes SQL (45 min)
- [ ] Modifier SELECT dans \`${RESOURCE_NAME}_search\`
- [ ] Adapter requête complète dans \`${RESOURCE_NAME}_getById\`
- [ ] Configurer \`supportedFields\` pour filtres
- [ ] Configurer \`sortableFields\` pour tri
- [ ] Configurer \`searchableFields\` pour recherche

### 3. Validation (15 min)
- [ ] Compiler: \`make -C src/${RESOURCE_NAME}\`
- [ ] Tester: \`scripts/validate_api_pattern.sh ${RESOURCE_NAME}s\`
- [ ] Vérifier tous les endpoints
- [ ] Tester avec React-Admin si disponible

### 4. Documentation (10 min)
- [ ] Compléter README avec exemples réels
- [ ] Documenter champs spécifiques
- [ ] Ajouter exemples cURL avec vraies données

## 📋 Checklist Conformité

- [ ] GET /api/${RESOURCE_NAME}s retourne tableau JSON
- [ ] Header X-Total-Count présent
- [ ] Pagination fonctionne
- [ ] Filtres simples fonctionnent
- [ ] Opérateurs avancés fonctionnent
- [ ] Recherche textuelle fonctionne
- [ ] Tri fonctionne
- [ ] CRUD complet fonctionne

## 🚀 Actions Métier Futures

- [ ] Identifier actions spécifiques à ${RESOURCE_NAME}
- [ ] Implémenter endpoints d'actions
- [ ] Documenter logique métier
EOF

echo ""
echo "✅ Génération terminée avec succès!"
echo ""
echo "📁 Fichiers créés dans $TARGET_DIR:"
ls -la "$TARGET_DIR"
echo ""
echo "📚 Documentation créée:"
echo "   - $TARGET_DIR/README_${RESOURCE_NAME^^}_API.md"
echo "   - $TARGET_DIR/TODO_${RESOURCE_NAME^^}.md"
echo ""
echo "🎯 Prochaines étapes:"
echo "   1. Adapter les structures: includes/${RESOURCE_NAME}.rpgleinc"
echo "   2. Modifier les requêtes SQL: $TARGET_DIR/${RESOURCE_NAME}.sqlrpgle"
echo "   3. Compiler: make -C $TARGET_DIR"
echo "   4. Tester: scripts/validate_api_pattern.sh ${RESOURCE_NAME}s"
echo ""
echo "⏱️ Temps estimé pour adaptation complète: 2 heures"
echo ""
echo "Pour plus de détails, voir: ressources/docs/guides/guide_nouvelle_api_rest.md"