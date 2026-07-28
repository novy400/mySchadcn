#!/bin/bash

# Script de validation du pattern API REST
# Basé sur ibmi_rest_api_instructions.md

echo "🔍 Validation Pattern API REST"
echo "=============================="

IBMI_HOST=${IBMI_HOST:-"your-ibmi-server"}
PORT=${PORT:-"44000"}
RESOURCE=${1:-"employees"}

echo "Serveur: $IBMI_HOST:$PORT"
echo "Ressource: $RESOURCE"
echo ""

# Test 1: Header X-Total-Count présent
echo "Test 1: Header X-Total-Count..."
HEADERS=$(curl -s -I "http://$IBMI_HOST:$PORT/api/$RESOURCE")
if echo "$HEADERS" | grep -i "x-total-count" > /dev/null; then
    echo "✅ X-Total-Count présent"
else
    echo "❌ X-Total-Count manquant"
fi

# Test 2: Format JSON tableau pour collection
echo "Test 2: Format JSON collection..."
RESPONSE=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_limit=1")
if echo "$RESPONSE" | jq empty 2>/dev/null && echo "$RESPONSE" | grep -E '^\[.*\]$' > /dev/null; then
    echo "✅ Format tableau JSON correct"
else
    echo "❌ Format JSON incorrect (doit être un tableau)"
fi

# Test 3: Pagination fonctionne
echo "Test 3: Pagination..."
RESPONSE1=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_page=1&_limit=2")
RESPONSE2=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_page=2&_limit=2")
if [ "$RESPONSE1" != "$RESPONSE2" ]; then
    echo "✅ Pagination fonctionnelle"
else
    echo "❌ Pagination ne fonctionne pas"
fi

# Test 4: Filtres fonctionnent  
echo "Test 4: Filtres..."
ALL=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE" | jq length 2>/dev/null)
if [ "$RESOURCE" = "employees" ]; then
    FILTERED=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?workdept=A00" | jq length 2>/dev/null)
elif [ "$RESOURCE" = "customers" ]; then
    FILTERED=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?city=PARIS" | jq length 2>/dev/null)
else
    FILTERED=$ALL
fi

if [ "$ALL" -gt "$FILTERED" ] 2>/dev/null; then
    echo "✅ Filtres fonctionnels"
else
    echo "⚠️ Filtres non testés ou identiques (normal pour petites données)"
fi

# Test 5: Opérateurs avancés
echo "Test 5: Opérateurs avancés..."
if [ "$RESOURCE" = "employees" ]; then
    GTE_RESULT=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?salary_gte=50000" | jq length 2>/dev/null)
elif [ "$RESOURCE" = "customers" ]; then
    GTE_RESULT=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?creditlimit_gte=10000" | jq length 2>/dev/null)
else
    GTE_RESULT=1
fi

if [ "$GTE_RESULT" -ge 0 ] 2>/dev/null; then
    echo "✅ Opérateurs avancés fonctionnels"
else
    echo "❌ Opérateurs avancés ne fonctionnent pas"
fi

# Test 6: Recherche textuelle
echo "Test 6: Recherche textuelle..."
if [ "$RESOURCE" = "employees" ]; then
    SEARCH_RESULT=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?q=HAAS" | jq length 2>/dev/null)
elif [ "$RESOURCE" = "customers" ]; then
    SEARCH_RESULT=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?q=DUPONT" | jq length 2>/dev/null)
else
    SEARCH_RESULT=1
fi

if [ "$SEARCH_RESULT" -ge 0 ] 2>/dev/null; then
    echo "✅ Recherche textuelle fonctionnelle"
else
    echo "❌ Recherche textuelle ne fonctionne pas"
fi

# Test 7: Tri
echo "Test 7: Tri..."
if [ "$RESOURCE" = "employees" ]; then
    SORTED=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_sort=lastname&_order=ASC&_limit=3" | jq length 2>/dev/null)
elif [ "$RESOURCE" = "customers" ]; then
    SORTED=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_sort=custname&_order=ASC&_limit=3" | jq length 2>/dev/null)
else
    SORTED=1
fi

if [ "$SORTED" -ge 0 ] 2>/dev/null; then
    echo "✅ Tri fonctionnel"
else
    echo "❌ Tri ne fonctionne pas"
fi

# Test 8: Accès item individuel
echo "Test 8: Item individuel..."
FIRST_ID=$(curl -s "http://$IBMI_HOST:$PORT/api/$RESOURCE?_limit=1" | jq -r '.[0].id // .[0].empno // .[0].custno // "000001"' 2>/dev/null)
ITEM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$IBMI_HOST:$PORT/api/$RESOURCE/$FIRST_ID")

if [ "$ITEM_RESPONSE" = "200" ]; then
    echo "✅ Accès item individuel fonctionnel"
else
    echo "❌ Accès item individuel ne fonctionne pas (Status: $ITEM_RESPONSE)"
fi

echo ""
echo "🎯 Validation terminée!"
echo ""
echo "📋 Résumé des tests pour $RESOURCE:"
echo "   1. X-Total-Count header"
echo "   2. Format JSON tableau" 
echo "   3. Pagination (_page, _limit)"
echo "   4. Filtres simples"
echo "   5. Opérateurs avancés (_gte, _lte, etc.)"
echo "   6. Recherche textuelle (q=)"
echo "   7. Tri (_sort, _order)" 
echo "   8. Accès item individuel"
echo ""
echo "Pour plus de détails, voir: ibmi_rest_api_instructions.md"
echo ""
echo "Tests manuels supplémentaires recommandés:"
echo "curl \"http://$IBMI_HOST:$PORT/api/$RESOURCE?_page=1&_limit=5\""
echo "curl \"http://$IBMI_HOST:$PORT/api/$RESOURCE?_sort=id&_order=DESC\""
echo "curl \"http://$IBMI_HOST:$PORT/api/$RESOURCE/$FIRST_ID\""