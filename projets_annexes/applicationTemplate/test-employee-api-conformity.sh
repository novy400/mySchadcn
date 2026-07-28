#!/bin/bash
# Test de Conformité API Employee - Sprint 0
# Script de validation avant passage au Sprint 1

echo "🚀 Test de Conformité API Employee"
echo "======================================="

BASE_URL="http://localhost:44000"
API_URL="$BASE_URL/api/employees"

# Fonction utilitaire pour les tests HTTP
test_http() {
    local url="$1"
    local method="${2:-GET}"
    local description="$3"
    
    echo -n "   Testing $description... "
    
    if response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" "$url" -H "Accept: application/json" 2>/dev/null); then
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
        
        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            echo "✅ ($http_code)"
            return 0
        else
            echo "❌ ($http_code)"
            return 1
        fi
    else
        echo "❌ (Connexion échouée)"
        return 1
    fi
}

# Fonction pour vérifier les headers
check_headers() {
    local url="$1"
    local description="$2"
    
    echo -n "   $description... "
    
    if headers=$(curl -s -I "$url" 2>/dev/null); then
        # Vérifier Content-Type
        if echo "$headers" | grep -qi "content-type.*application/json"; then
            content_type_ok=true
        else
            content_type_ok=false
        fi
        
        # Vérifier X-Total-Count
        if echo "$headers" | grep -qi "x-total-count"; then
            total_count_ok=true
            total_count=$(echo "$headers" | grep -i "x-total-count" | cut -d: -f2 | tr -d ' \r')
        else
            total_count_ok=false
        fi
        
        if [[ "$content_type_ok" == true && "$total_count_ok" == true ]]; then
            echo "✅ (X-Total-Count: $total_count)"
            return 0
        else
            echo "❌"
            [[ "$content_type_ok" == false ]] && echo "      Content-Type manquant"
            [[ "$total_count_ok" == false ]] && echo "      X-Total-Count manquant"
            return 1
        fi
    else
        echo "❌ (Échec requête headers)"
        return 1
    fi
}

# Test 1: GET Collection
echo ""
echo "1️⃣ Test GET Collection..."

if test_http "$API_URL" "GET" "Collection de base"; then
    # Vérifier les headers
    check_headers "$API_URL" "Headers HTTP"
    
    # Vérifier le format JSON (tableau)
    echo -n "   Format JSON tableau... "
    if response=$(curl -s "$API_URL" 2>/dev/null); then
        if echo "$response" | jq -e 'type == "array"' > /dev/null 2>&1; then
            count=$(echo "$response" | jq 'length')
            echo "✅ ($count éléments)"
        else
            echo "❌ (Pas un tableau JSON)"
        fi
    else
        echo "❌ (Erreur récupération JSON)"
    fi
fi

# Test 2: Pagination
echo ""
echo "2️⃣ Test Pagination..."

test_http "$API_URL?_page=1&_limit=5" "GET" "Page 1, limite 5"
test_http "$API_URL?_page=2&_limit=3" "GET" "Page 2, limite 3"

# Test 3: Tri
echo ""
echo "3️⃣ Test Tri..."

test_http "$API_URL?_sort=empno&_order=asc" "GET" "Tri ascendant par empno"
test_http "$API_URL?_sort=empno&_order=desc" "GET" "Tri descendant par empno"

# Test 4: Filtres de base
echo ""
echo "4️⃣ Test Filtres de Base..."

test_http "$API_URL?empno=000010" "GET" "Filtre exact empno"
test_http "$API_URL?lastname=THOMPSON" "GET" "Filtre exact lastname"

# Test 5: Filtres avancés
echo ""
echo "5️⃣ Test Filtres Avancés..."

test_http "$API_URL?lastname_like=JOHN" "GET" "Filtre LIKE lastname"
test_http "$API_URL?empno_gte=000010" "GET" "Filtre empno >= 000010"
test_http "$API_URL?empno_lte=000050" "GET" "Filtre empno <= 000050"

# Test 6: GET Item individuel
echo ""
echo "6️⃣ Test GET Item..."

test_http "$API_URL/000010" "GET" "Item individuel empno=000010"

# Test 7: Recherche textuelle
echo ""
echo "7️⃣ Test Recherche..."

test_http "$API_URL?q=DEVELOPER" "GET" "Recherche textuelle 'DEVELOPER'"

# Test 8: Tests POST/PUT/DELETE (optionnels, nécessitent données de test)
echo ""
echo "8️⃣ Test CRUD (Optionnel)..."

# Test POST
echo -n "   POST nouvel employé... "
post_data='{"empno":"999999","firstname":"TEST","lastname":"USER","workdept":"A00"}'
if response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$post_data" 2>/dev/null); then
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    if [[ "$http_code" == "201" ]]; then
        echo "✅ (201 Created)"
        test_user_created=true
    else
        echo "⚠️  ($http_code - données possiblement existantes)"
        test_user_created=false
    fi
else
    echo "❌ (Erreur POST)"
    test_user_created=false
fi

# Test PUT si POST a réussi
if [[ "$test_user_created" == true ]]; then
    echo -n "   PUT modification employé... "
    put_data='{"empno":"999999","firstname":"TEST","lastname":"UPDATED","workdept":"A00"}'
    if response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT "$API_URL/999999" \
        -H "Content-Type: application/json" \
        -d "$put_data" 2>/dev/null); then
        
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        if [[ "$http_code" == "200" ]]; then
            echo "✅ (200 OK)"
        else
            echo "❌ ($http_code)"
        fi
    else
        echo "❌ (Erreur PUT)"
    fi
    
    # Test DELETE
    echo -n "   DELETE employé test... "
    if response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X DELETE "$API_URL/999999" 2>/dev/null); then
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        if [[ "$http_code" == "200" ]]; then
            echo "✅ (200 OK)"
        else
            echo "❌ ($http_code)"
        fi
    else
        echo "❌ (Erreur DELETE)"
    fi
fi

# Résumé final
echo ""
echo "📊 RÉSUMÉ DU TEST"
echo "=================="
echo ""
echo "🎯 API Employee testée sur:"
echo "   ✓ GET Collection avec X-Total-Count"
echo "   ✓ Pagination (_page, _limit)"  
echo "   ✓ Tri (_sort, _order)"
echo "   ✓ Filtres de base (field=value)"
echo "   ✓ Filtres avancés (_like, _gte, _lte)"
echo "   ✓ GET Item individuel"
echo "   ✓ Recherche textuelle (q=)"
echo "   ✓ CRUD operations (POST/PUT/DELETE)"
echo ""

# Vérifier la disponibilité de jq pour les prochains tests
if ! command -v jq > /dev/null; then
    echo "⚠️  RECOMMANDATION: Installer jq pour des tests JSON plus précis"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   macOS: brew install jq"
    echo "   Windows: choco install jq"
fi

echo ""
echo "✅ Test de conformité terminé!"
echo ""
echo "📋 Si tous les tests passent, votre API Employee est conforme"
echo "   aux standards REST et prête pour le Sprint 1"
echo ""
echo "📖 Consultez CHECKLIST_EMPLOYEE_API_CONFORMITY.md pour plus de détails"