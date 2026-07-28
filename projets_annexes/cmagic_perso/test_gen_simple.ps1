# Script de test de génération CMagic
Write-Host "=== Test de génération CMagic ===" -ForegroundColor Green

# 1. Supprimer les fichiers générés
Write-Host "1. Nettoyage..." -ForegroundColor Yellow
Remove-Item -Path ".\generated\customer" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Générer le code
Write-Host "2. Génération..." -ForegroundColor Yellow
node .\out\cli\main.js .\prd_customer_test.cmagic

# 3. Vérifier le résultat
Write-Host "3. Vérification..." -ForegroundColor Yellow
if (Test-Path ".\generated\customer\customer.sqlrpgle") {
    Write-Host "Fichier généré avec succès" -ForegroundColor Green
    
    $content = Get-Content ".\generated\customer\customer.sqlrpgle" -Raw
    if ($content -like "*lLimit int(10)*") {
        Write-Host "Nouvelle implémentation détectée!" -ForegroundColor Green
    } else {
        Write-Host "Ancienne implémentation (TODO)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Échec de génération" -ForegroundColor Red
}