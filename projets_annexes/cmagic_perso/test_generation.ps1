# Script de test de génération CMagic
# Test la génération du customer avec la nouvelle implémentation

Write-Host "=== Test de génération CMagic ===" -ForegroundColor Green

# 1. Supprimer les fichiers générés
Write-Host "1. Nettoyage des fichiers générés..." -ForegroundColor Yellow
Remove-Item -Path ".\generated\customer" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ✓ Dossier customer supprimé" -ForegroundColor Green

# 2. Vérifier que les templates sont à jour
Write-Host "2. Vérification des templates..." -ForegroundColor Yellow
$templateDate = (Get-Item ".\out\templates\service.sqlrpgle.tpl").LastWriteTime
Write-Host "   Template modifié le: $templateDate" -ForegroundColor Cyan

# 3. Générer le code
Write-Host "3. Génération du code customer..." -ForegroundColor Yellow
& node .\out\cli\main.js .\prd_customer_test.cmagic

# 4. Vérifier le résultat
Write-Host "4. Vérification du résultat..." -ForegroundColor Yellow
if (Test-Path ".\generated\customer\customer.sqlrpgle") {
    Write-Host "   ✓ Fichier customer.sqlrpgle généré" -ForegroundColor Green
    
    # Rechercher la nouvelle implémentation
    $content = Get-Content ".\generated\customer\customer.sqlrpgle" -Raw
    if ($content -match "lLimit int\(10\)") {
        Write-Host "   ✓ Nouvelle implémentation de search_local détectée!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Ancienne implémentation (TODO) détectée" -ForegroundColor Yellow
        Write-Host "   → Le template n'a pas été appliqué correctement" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Fichier non généré" -ForegroundColor Red
}

Write-Host "=== Fin du test ===" -ForegroundColor Green