#!/bin/bash
# Script de test simple pour l'API TestService
# Équivalent shell du test PowerShell

echo "🧪 Test API TestService"
echo "======================="

BASE_URL="http://localhost:44000"
API_URL="$BASE_URL/api/testservices"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_endpoint() {
    local url="$1"
    local description="$2"
    
    echo -n "   $description... "
    
    if response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url" -H "Accept: application/json" 2>/dev/null); then
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        
        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            echo -e "${GREEN}✅ ($http_code)${NC}"
            return 0
        else
            echo -e "${RED}❌ ($http_code)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ (Connexion échouée)${NC}"
        return 1
    fi
}

echo ""
echo "🎯 Tests de base"
echo "================"

test_endpoint "$API_URL" "GET Collection"
test_endpoint "$API_URL?_page=1&_limit=5" "Pagination"
test_endpoint "$API_URL?_sort=id&_order=asc" "Tri"

echo ""
echo "✅ Test TestService terminé"