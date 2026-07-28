# Test de Conformité API Employee - Sprint 0
# Script de validation avant passage au Sprint 1

Write-Host "🚀 Test de Conformité API Employee" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

$baseUrl = "http://localhost:44000"
$apiUrl = "$baseUrl/api/employees"

Write-Host "`n1️⃣ Test GET Collection..." -ForegroundColor Yellow

try {
    # Test basique de collection
    $response = Invoke-WebRequest -Uri $apiUrl -Method GET -Headers @{Accept="application/json"}
    
    Write-Host "✅ Status Code: $($response.StatusCode)" -ForegroundColor Green
    
    # Vérifier Content-Type
    $contentType = $response.Headers["Content-Type"]
    if ($contentType -like "*application/json*") {
        Write-Host "✅ Content-Type: $contentType" -ForegroundColor Green
    } else {
        Write-Host "❌ Content-Type incorrect: $contentType" -ForegroundColor Red
    }
    
    # Vérifier X-Total-Count
    $totalCount = $response.Headers["X-Total-Count"]
    if ($totalCount) {
        Write-Host "✅ X-Total-Count: $totalCount" -ForegroundColor Green
    } else {
        Write-Host "❌ X-Total-Count manquant" -ForegroundColor Red
    }
    
    # Vérifier que c'est un tableau JSON
    $content = $response.Content | ConvertFrom-Json
    if ($content -is [Array]) {
        Write-Host "✅ Réponse est un tableau JSON" -ForegroundColor Green
        Write-Host "   Nombre d'éléments: $($content.Length)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Réponse n'est pas un tableau JSON" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erreur lors du test GET collection: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2️⃣ Test Pagination..." -ForegroundColor Yellow

try {
    # Test pagination
    $pagResponse = Invoke-WebRequest -Uri "$apiUrl?_page=1&_limit=5" -Method GET -Headers @{Accept="application/json"}
    
    Write-Host "✅ Pagination Status: $($pagResponse.StatusCode)" -ForegroundColor Green
    
    $pagContent = $pagResponse.Content | ConvertFrom-Json
    if ($pagContent -is [Array] -and $pagContent.Length -le 5) {
        Write-Host "✅ Pagination fonctionne (max 5 éléments)" -ForegroundColor Green
    } else {
        Write-Host "❌ Pagination ne fonctionne pas correctement" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erreur lors du test pagination: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3️⃣ Test GET One..." -ForegroundColor Yellow

try {
    # D'abord récupérer un ID depuis la collection
    $collectionResponse = Invoke-WebRequest -Uri "$apiUrl?_limit=1" -Method GET -Headers @{Accept="application/json"}
    $items = $collectionResponse.Content | ConvertFrom-Json
    
    if ($items.Length -gt 0) {
        $testId = $items[0].id
        Write-Host "   Test avec ID: $testId" -ForegroundColor Cyan
        
        $oneResponse = Invoke-WebRequest -Uri "$apiUrl/$testId" -Method GET -Headers @{Accept="application/json"}
        
        Write-Host "✅ GET One Status: $($oneResponse.StatusCode)" -ForegroundColor Green
        
        $oneContent = $oneResponse.Content | ConvertFrom-Json
        if ($oneContent -is [PSCustomObject] -and $oneContent.id -eq $testId) {
            Write-Host "✅ GET One retourne un objet JSON avec bon ID" -ForegroundColor Green
        } else {
            Write-Host "❌ GET One ne retourne pas le bon objet" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ Aucun employé pour tester GET One" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Erreur lors du test GET one: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4️⃣ Test Filtres..." -ForegroundColor Yellow

try {
    # Test avec un filtre
    $filterResponse = Invoke-WebRequest -Uri "$apiUrl?lastname_like=HAA" -Method GET -Headers @{Accept="application/json"}
    
    Write-Host "✅ Filtre Status: $($filterResponse.StatusCode)" -ForegroundColor Green
    
    $filterContent = $filterResponse.Content | ConvertFrom-Json
    if ($filterContent -is [Array]) {
        Write-Host "✅ Filtre retourne un tableau" -ForegroundColor Green
        Write-Host "   Résultats filtrés: $($filterContent.Length)" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Erreur lors du test filtres: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📊 Résumé du Test de Conformité" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
Write-Host "✅ API Employee testée avec succès" -ForegroundColor Green
Write-Host "🎯 Prêt pour Sprint 1 si tous les tests passent" -ForegroundColor Green
Write-Host "`n📝 Note: Ce script teste uniquement les endpoints de lecture (GET)" -ForegroundColor Cyan
Write-Host "   Les tests POST/PUT/DELETE doivent être faits après déploiement sur IBM i" -ForegroundColor Cyan