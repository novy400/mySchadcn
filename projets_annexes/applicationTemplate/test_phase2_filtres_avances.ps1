# Test Phase 2 - Filtres Avancés
# Script de test pour vérifier tous les opérateurs de filtrage

param(
    [string]$ServerUrl = "http://your-ibmi:44000",
    [switch]$Verbose
)

$apiBase = "$ServerUrl/api/employees"
$testResults = @()

function Test-ApiEndpoint {
    param(
        [string]$Url,
        [string]$Description,
        [string]$ExpectedPattern = ""
    )
    
    Write-Host "Test: $Description" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method GET -Headers @{
            'Accept' = 'application/json'
        } -ErrorAction Stop
        
        if ($ExpectedPattern -and $response) {
            $jsonString = $response | ConvertTo-Json -Depth 10
            if ($jsonString -match $ExpectedPattern) {
                Write-Host "✅ SUCCÈS: $Description" -ForegroundColor Green
                return @{ Test = $Description; Status = "PASS"; Response = $response }
            } else {
                Write-Host "❌ ÉCHEC: Pattern non trouvé dans la réponse" -ForegroundColor Red
                return @{ Test = $Description; Status = "FAIL"; Error = "Pattern non trouvé" }
            }
        } else {
            Write-Host "✅ SUCCÈS: $Description" -ForegroundColor Green
            return @{ Test = $Description; Status = "PASS"; Response = $response }
        }
    }
    catch {
        Write-Host "❌ ÉCHEC: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Test = $Description; Status = "FAIL"; Error = $_.Exception.Message }
    }
}

function Test-ApiHeader {
    param(
        [string]$Url,
        [string]$Description,
        [string]$HeaderName
    )
    
    Write-Host "Test: $Description" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -Headers @{
            'Accept' = 'application/json'
        } -ErrorAction Stop
        
        if ($response.Headers[$HeaderName]) {
            Write-Host "✅ SUCCÈS: Header $HeaderName présent = $($response.Headers[$HeaderName])" -ForegroundColor Green
            return @{ Test = $Description; Status = "PASS"; Header = $response.Headers[$HeaderName] }
        } else {
            Write-Host "❌ ÉCHEC: Header $HeaderName manquant" -ForegroundColor Red
            return @{ Test = $Description; Status = "FAIL"; Error = "Header manquant" }
        }
    }
    catch {
        Write-Host "❌ ÉCHEC: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Test = $Description; Status = "FAIL"; Error = $_.Exception.Message }
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "TEST PHASE 2 - FILTRES AVANCÉS" -ForegroundColor Cyan
Write-Host "Serveur: $ServerUrl" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Test 1: Collection de base avec header X-Total-Count
Write-Host "`n--- Test 1: Collection de base ---" -ForegroundColor Magenta
$testResults += Test-ApiHeader -Url $apiBase -Description "Collection avec X-Total-Count" -HeaderName "X-Total-Count"

# Test 2: Filtres EQUAL (=)
Write-Host "`n--- Test 2: Filtres EQUAL (=) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?nom=HAAS" -Description "Filtre nom égal HAAS"
$testResults += Test-ApiEndpoint -Url "$apiBase?service=A00" -Description "Filtre service égal A00"

# Test 3: Filtres LIKE
Write-Host "`n--- Test 3: Filtres LIKE ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?nom_like=HAA" -Description "Filtre nom contient HAA"
$testResults += Test-ApiEndpoint -Url "$apiBase?prenom_like=CHR" -Description "Filtre prenom contient CHR"

# Test 4: Filtres GREATER_EQUAL (>=)
Write-Host "`n--- Test 4: Filtres GREATER_EQUAL (>=) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?salaire_gte=50000" -Description "Filtre salaire >= 50000"

# Test 5: Filtres LESS_EQUAL (<=)
Write-Host "`n--- Test 5: Filtres LESS_EQUAL (<=) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?salaire_lte=100000" -Description "Filtre salaire <= 100000"

# Test 6: Filtres GREATER (>)
Write-Host "`n--- Test 6: Filtres GREATER (>) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?salaire_gt=50000" -Description "Filtre salaire > 50000"

# Test 7: Filtres LESS (<)
Write-Host "`n--- Test 7: Filtres LESS (<) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?salaire_lt=100000" -Description "Filtre salaire < 100000"

# Test 8: Filtres NOT_EQUAL (<>)
Write-Host "`n--- Test 8: Filtres NOT_EQUAL (<>) ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?service_ne=A00" -Description "Filtre service différent de A00"

# Test 9: Recherche générale 'q'
Write-Host "`n--- Test 9: Recherche générale 'q' ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?q=HAAS" -Description "Recherche générale HAAS"

# Test 10: Filtres combinés
Write-Host "`n--- Test 10: Filtres combinés ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?nom_like=HAA&salaire_gte=50000&service_ne=A00" -Description "Filtres combinés: nom LIKE + salaire >= + service <>"

# Test 11: Pagination avec filtres
Write-Host "`n--- Test 11: Pagination avec filtres ---" -ForegroundColor Magenta
$testResults += Test-ApiEndpoint -Url "$apiBase?nom_like=A&_page=1&_limit=5" -Description "Pagination + filtre nom LIKE A"

# Résumé des résultats
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "RÉSUMÉ DES TESTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host "Total: $totalCount tests" -ForegroundColor White
Write-Host "Réussis: $passCount tests" -ForegroundColor Green
Write-Host "Échoués: $failCount tests" -ForegroundColor Red

if ($failCount -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "COMMANDES POUR TESTS MANUELS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

@"
# Tests de base
curl "$apiBase"
curl -I "$apiBase"

# Tests filtres EQUAL
curl "$apiBase?nom=HAAS"
curl "$apiBase?service=A00"

# Tests filtres LIKE
curl "$apiBase?nom_like=HAA"
curl "$apiBase?prenom_like=CHR"

# Tests filtres numériques
curl "$apiBase?salaire_gte=50000"
curl "$apiBase?salaire_lte=100000"
curl "$apiBase?salaire_gt=50000"
curl "$apiBase?salaire_lt=100000"

# Tests filtres NOT_EQUAL
curl "$apiBase?service_ne=A00"

# Tests recherche générale
curl "$apiBase?q=HAAS"

# Tests filtres combinés
curl "$apiBase?nom_like=HAA&salaire_gte=50000&service_ne=A00"
"@ | Write-Host -ForegroundColor Gray

# Rapport de conformité Phase 2
$conformityScore = [math]::Round(($passCount / $totalCount) * 100, 2)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CONFORMITÉ PHASE 2" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Score de conformité: $conformityScore%" -ForegroundColor $(if ($conformityScore -ge 90) { "Green" } elseif ($conformityScore -ge 70) { "Yellow" } else { "Red" })

if ($conformityScore -eq 100) {
    Write-Host "🎉 PHASE 2 COMPLÈTE - Tous les filtres avancés fonctionnent!" -ForegroundColor Green
} elseif ($conformityScore -ge 90) {
    Write-Host "✅ PHASE 2 PRESQUE COMPLÈTE - Quelques ajustements mineurs" -ForegroundColor Yellow
} elseif ($conformityScore -ge 70) {
    Write-Host "⚠️  PHASE 2 EN COURS - Corrections nécessaires" -ForegroundColor Yellow
} else {
    Write-Host "❌ PHASE 2 ÉCHOUÉE - Révision majeure requise" -ForegroundColor Red
}

Write-Host "`nProchaine étape: Implémenter Phase 3 (Optimisation) après correction des erreurs Phase 2" -ForegroundColor Cyan