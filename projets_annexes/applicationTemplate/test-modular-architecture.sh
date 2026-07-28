#!/bin/bash
# Test de l'architecture modulaire
# Validation de la structure des modules API

echo "🏗️  Test Architecture Modulaire"
echo "================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0

# Fonction de test
test_condition() {
    local condition="$1"
    local description="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ $description${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

echo ""
echo "📁 1. Vérification Structure Générale"
echo "======================================="

test_condition "[ -d 'src' ]" "Répertoire src/ existe"
test_condition "[ -d 'includes' ]" "Répertoire includes/ existe"
test_condition "[ -f 'src/Rules.mk' ]" "Fichier src/Rules.mk existe"

echo ""
echo "📦 2. Vérification Module Employee (Référence)"
echo "==============================================="

test_condition "[ -d 'src/employee' ]" "Module employee existe"
test_condition "[ -f 'src/employee/employee.main.rpgle' ]" "Fichier main.rpgle existe"
test_condition "[ -f 'src/employee/employee.route.sqlrpgle' ]" "Fichier route.sqlrpgle existe"
test_condition "[ -f 'src/employee/employee.rest.sqlrpgle' ]" "Fichier rest.sqlrpgle existe"
test_condition "[ -f 'src/employee/employee.sqlrpgle' ]" "Fichier sqlrpgle existe"
test_condition "[ -f 'src/employee/employee.bnd' ]" "Fichier bnd existe"
test_condition "[ -f 'includes/employee.rpgleinc' ]" "Include employee.rpgleinc existe"

echo ""
echo "🔍 3. Vérification Contenu des Fichiers Employee"
echo "================================================="

if [ -f "includes/employee.rpgleinc" ]; then
    test_condition "grep -q 'employee_detail_t' includes/employee.rpgleinc" "Structure employee_detail_t définie"
    test_condition "grep -q 'employee_item_t' includes/employee.rpgleinc" "Structure employee_item_t définie"
    test_condition "grep -q 'employee_input_t' includes/employee.rpgleinc" "Structure employee_input_t définie"
fi

if [ -f "src/employee/employee.rest.sqlrpgle" ]; then
    test_condition "grep -q 'X-Total-Count' src/employee/employee.rest.sqlrpgle" "Header X-Total-Count présent"
    test_condition "grep -q 'application/json' src/employee/employee.rest.sqlrpgle" "Content-Type JSON configuré"
fi

if [ -f "src/employee/employee.route.sqlrpgle" ]; then
    test_condition "grep -q 'il_addRoute' src/employee/employee.route.sqlrpgle" "Routes ILEastic configurées"
fi

echo ""
echo "📊 4. Vérification Modules Additionnels"
echo "========================================"

# Vérifier les autres modules s'ils existent
for module_dir in src/*/; do
    if [ -d "$module_dir" ]; then
        module_name=$(basename "$module_dir")
        
        # Ignorer les répertoires spéciaux
        if [[ "$module_name" =~ ^(qclsrc|qcmdsrc|qrpgleref|qrpglesrc|qsrvsrc|qtstsrc|main|tests)$ ]]; then
            continue
        fi
        
        echo ""
        echo -e "${BLUE}Module: $module_name${NC}"
        
        # Structure de base
        test_condition "[ -f '$module_dir${module_name}.main.rpgle' ]" "  Fichier main.rpgle"
        test_condition "[ -f '$module_dir${module_name}.route.sqlrpgle' ]" "  Fichier route.sqlrpgle"
        test_condition "[ -f '$module_dir${module_name}.rest.sqlrpgle' ]" "  Fichier rest.sqlrpgle"
        test_condition "[ -f '$module_dir${module_name}.sqlrpgle' ]" "  Fichier sqlrpgle"
        test_condition "[ -f '$module_dir${module_name}.bnd' ]" "  Fichier bnd"
        
        # Include correspondant
        test_condition "[ -f 'includes/${module_name}.rpgleinc' ]" "  Include ${module_name}.rpgleinc"
        
        # Vérification dans Rules.mk
        test_condition "grep -q '$module_name' src/Rules.mk" "  Module dans src/Rules.mk"
    fi
done

echo ""
echo "🔧 5. Vérification Configuration Build"
echo "======================================"

if [ -f "src/Rules.mk" ]; then
    test_condition "grep -q 'SUBDIRS' src/Rules.mk" "Variable SUBDIRS définie"
    test_condition "grep -q 'employee' src/Rules.mk" "Module employee dans SUBDIRS"
fi

echo ""
echo "📁 6. Vérification Données de Test"
echo "=================================="

test_condition "[ -d 'ressources/data' ]" "Répertoire ressources/data existe"

# Vérifier les données pour chaque module
for module_dir in src/*/; do
    if [ -d "$module_dir" ]; then
        module_name=$(basename "$module_dir")
        
        # Ignorer les répertoires spéciaux
        if [[ "$module_name" =~ ^(qclsrc|qcmdsrc|qrpgleref|qrpglesrc|qsrvsrc|qtstsrc|main|tests)$ ]]; then
            continue
        fi
        
        test_condition "[ -f 'ressources/data/${module_name}.sql' ]" "Données SQL pour $module_name"
        test_condition "[ -f 'ressources/data/${module_name}.json' ]" "Données JSON pour $module_name"
    fi
done

echo ""
echo "🚀 7. Test Compilation (si BOB disponible)"
echo "=========================================="

if command -v bob > /dev/null; then
    echo "BOB détecté, test de compilation..."
    
    for module_dir in src/*/; do
        if [ -d "$module_dir" ]; then
            module_name=$(basename "$module_dir")
            
            # Ignorer les répertoires spéciaux
            if [[ "$module_name" =~ ^(qclsrc|qcmdsrc|qrpgleref|qrpglesrc|qsrvsrc|qtstsrc|main|tests)$ ]]; then
                continue
            fi
            
            echo -n "   Test compilation $module_name... "
            if bob --build "src/$module_name" > /dev/null 2>&1; then
                echo -e "${GREEN}✅${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "${RED}❌${NC}"
            fi
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
        fi
    done
else
    echo "⚠️  BOB non disponible, tests de compilation ignorés"
fi

echo ""
echo "📋 8. Résumé Architecture"
echo "========================="

# Lister les modules détectés
echo ""
echo "🗂️  Modules détectés:"
for module_dir in src/*/; do
    if [ -d "$module_dir" ]; then
        module_name=$(basename "$module_dir")
        
        # Ignorer les répertoires spéciaux
        if [[ "$module_name" =~ ^(qclsrc|qcmdsrc|qrpgleref|qrpglesrc|qsrvsrc|qtstsrc|main|tests)$ ]]; then
            continue
        fi
        
        echo "   📦 $module_name"
        
        # Vérifier les routes potentielles
        if [ -f "src/$module_name/${module_name}.route.sqlrpgle" ]; then
            routes=$(grep -o '/api/[^"]*' "src/$module_name/${module_name}.route.sqlrpgle" 2>/dev/null | sort | uniq)
            if [ -n "$routes" ]; then
                echo "      Routes: $routes"
            fi
        fi
    fi
done

echo ""
echo "📊 RÉSULTAT FINAL"
echo "================="
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 SUCCÈS: Tous les tests passent ($PASSED_TESTS/$TOTAL_TESTS)${NC}"
    echo -e "${GREEN}   Architecture modulaire conforme${NC}"
    exit_code=0
else
    echo -e "${RED}❌ ÉCHEC: $((TOTAL_TESTS - PASSED_TESTS)) tests en échec${NC}"
    echo -e "${YELLOW}   Tests réussis: $PASSED_TESTS/$TOTAL_TESTS${NC}"
    exit_code=1
fi

echo ""
echo "📖 Recommandations:"
echo "   - Chaque module doit avoir sa structure complète (main, route, rest, sql, bnd)"
echo "   - Include correspondant dans includes/"
echo "   - Données de test dans ressources/data/"
echo "   - Déclaration dans src/Rules.mk"
echo ""
echo "🔗 Références:"
echo "   - Pattern Employee comme modèle"
echo "   - ibmi_rest_api_instructions.md pour les détails"
echo "   - GUIDE_CREATION_NOUVELLE_ENTITE.md pour la procédure"

exit $exit_code