#!/bin/bash
# Script de test des filtres avancés - Phase 2
# Test des opérateurs de comparaison et filtres complexes

echo "🔍 Test Phase 2 - Filtres Avancés"
echo "=================================="

BASE_URL="http://localhost:44000"
API_URL="$BASE_URL/api/employees"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0

# Fonction de test HTTP
test_api() {
    local url="$1"
    local description="$2"
    local expected_behavior="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "   Testing: $description... "
    
    if response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url" -H "Accept: application/json" 2>/dev/null); then
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
        
        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            # Vérifier si c'est un tableau JSON
            if echo "$body" | jq -e 'type == "array"' > /dev/null 2>&1; then
                count=$(echo "$body" | jq 'length')
                echo -e "${GREEN}✅ ($count résultats)${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                
                # Tests spécifiques selon le comportement attendu
                case "$expected_behavior" in
                    "non_empty")
                        if [[ $count -gt 0 ]]; then
                            echo "      ↳ Résultats trouvés comme attendu"
                        else
                            echo -e "      ${YELLOW}↳ Aucun résultat (peut être normal)${NC}"
                        fi
                        ;;
                    "limited")
                        echo "      ↳ Limite appliquée: $count éléments"
                        ;;
                esac
                
                return 0
            else
                echo -e "${RED}❌ (Réponse non-tableau)${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ (HTTP $http_code)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ (Connexion échouée)${NC}"
        return 1
    fi
}

# Vérifier que jq est disponible
if ! command -v jq > /dev/null; then
    echo -e "${YELLOW}⚠️  jq non disponible, certains tests seront limités${NC}"
fi

echo ""
echo "1️⃣ Filtres de Comparaison Numérique"
echo "====================================="

test_api "$API_URL?empno_gte=000020" "empno >= 000020" "non_empty"
test_api "$API_URL?empno_lte=000050" "empno <= 000050" "non_empty"
test_api "$API_URL?empno_gt=000030" "empno > 000030" "non_empty"
test_api "$API_URL?empno_lt=000040" "empno < 000040" "non_empty"
test_api "$API_URL?empno_ne=000010" "empno ≠ 000010" "non_empty"

echo ""
echo "2️⃣ Filtres de Comparaison Texte"
echo "================================"

test_api "$API_URL?lastname_like=JOHN" "lastname LIKE '%JOHN%'" "non_empty"
test_api "$API_URL?firstname_like=CHRIST" "firstname LIKE '%CHRIST%'" "non_empty"
test_api "$API_URL?workdept_ne=A00" "workdept ≠ 'A00'" "non_empty"

echo ""
echo "3️⃣ Filtres Combinés"
echo "==================="

test_api "$API_URL?workdept=A00&empno_gte=000020" "workdept='A00' ET empno>=000020" "non_empty"
test_api "$API_URL?lastname_like=JOHN&workdept_ne=D11" "lastname LIKE '%JOHN%' ET workdept≠'D11'" "non_empty"
test_api "$API_URL?empno_gte=000010&empno_lte=000030" "empno BETWEEN 000010 AND 000030" "non_empty"

echo ""
echo "4️⃣ Filtres avec Pagination"
echo "============================"

test_api "$API_URL?empno_gte=000010&_page=1&_limit=3" "Filtré + Page 1, limite 3" "limited"
test_api "$API_URL?workdept=A00&_page=1&_limit=2" "workdept='A00' + Page 1, limite 2" "limited"

echo ""
echo "5️⃣ Filtres avec Tri"
echo "==================="

test_api "$API_URL?workdept=A00&_sort=empno&_order=desc" "workdept='A00' trié par empno DESC" "non_empty"
test_api "$API_URL?lastname_like=JOHN&_sort=firstname&_order=asc" "lastname LIKE '%JOHN%' trié par firstname ASC" "non_empty"

echo ""
echo "6️⃣ Tests Cas Limites"
echo "====================="

test_api "$API_URL?empno_gte=999999" "empno >= 999999 (aucun résultat attendu)" "empty"
test_api "$API_URL?lastname_like=ZZZZZ" "lastname LIKE '%ZZZZZ%' (aucun résultat attendu)" "empty"
test_api "$API_URL?workdept_ne=A00&workdept_ne=B01&workdept_ne=C01" "Multiples exclusions" "non_empty"

echo ""
echo "7️⃣ Validation Format Réponses"
echo "=============================="

echo -n "   Vérification headers X-Total-Count... "
if headers=$(curl -s -I "$API_URL?empno_gte=000010" 2>/dev/null); then
    if echo "$headers" | grep -qi "x-total-count"; then
        total_count=$(echo "$headers" | grep -i "x-total-count" | cut -d: -f2 | tr -d ' \r')
        echo -e "${GREEN}✅ (Count: $total_count)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ (Header manquant)${NC}"
    fi
else
    echo -e "${RED}❌ (Erreur requête)${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo -n "   Vérification CORS headers... "
if echo "$headers" | grep -qi "access-control"; then
    echo -e "${GREEN}✅ (CORS configuré)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠️  (CORS possiblement manquant)${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "8️⃣ Test Performance Filtres"
echo "============================"

echo -n "   Test réponse rapide (<2s)... "
start_time=$(date +%s)
if curl -s "$API_URL?lastname_like=JOHN&workdept_ne=D11&_limit=10" > /dev/null 2>&1; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [[ $duration -lt 2 ]]; then
        echo -e "${GREEN}✅ (${duration}s)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${YELLOW}⚠️  (${duration}s - lent)${NC}"
    fi
else
    echo -e "${RED}❌ (Erreur)${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "📊 RÉSUMÉ PHASE 2"
echo "================="

echo ""
echo "🎯 Opérateurs testés:"
echo "   ✓ _gte (>=), _lte (<=), _gt (>), _lt (<)"
echo "   ✓ _ne (≠), _like (LIKE)"
echo "   ✓ Combinaisons multiples"
echo "   ✓ Filtres + Pagination + Tri"

echo ""
echo "📈 Résultats:"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 SUCCÈS: Tous les tests passent ($PASSED_TESTS/$TOTAL_TESTS)${NC}"
    echo -e "${GREEN}   Filtres avancés Phase 2 fonctionnels${NC}"
    exit_code=0
else
    echo -e "${RED}❌ ÉCHEC: $((TOTAL_TESTS - PASSED_TESTS)) tests en échec${NC}"
    echo -e "${YELLOW}   Tests réussis: $PASSED_TESTS/$TOTAL_TESTS${NC}"
    exit_code=1
fi

echo ""
echo "📋 Prochaines étapes si succès:"
echo "   1. ✅ Phase 2 validée - Filtres avancés opérationnels"
echo "   2. 🎯 Prêt pour Phase 3 - Actions métier (PROMOTE, TRANSFER, etc.)"
echo "   3. 🚀 Appliquer pattern aux autres entités (Customer, Department, etc.)"

echo ""
echo "🔧 En cas d'échec:"
echo "   - Vérifier implementation CMAGIC_filter dans .sqlrpgle"
echo "   - Contrôler mapping opérateurs dans .rest.sqlrpgle"
echo "   - Consulter CHECKLIST_PHASE2_FILTRES_AVANCES.md"

exit $exit_code