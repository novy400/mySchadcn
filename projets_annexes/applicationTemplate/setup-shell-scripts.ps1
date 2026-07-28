# Script PowerShell pour configurer les scripts shell sur Windows
# Usage: .\setup-shell-scripts.ps1

Write-Host "Configuration des scripts shell sur Windows" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$scriptsFound = @()

# Chercher tous les scripts .sh
Write-Host ""
Write-Host "Recherche des scripts shell..." -ForegroundColor Cyan

# Scripts dans le répertoire racine
Get-ChildItem "*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
    $scriptsFound += $_.FullName
    Write-Host "   OK $($_.Name)" -ForegroundColor Green
}

# Scripts dans le répertoire scripts/
if (Test-Path "scripts") {
    Get-ChildItem "scripts\*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
        $scriptsFound += $_.FullName
        Write-Host "   OK $($_.Name)" -ForegroundColor Green
    }
}

if ($scriptsFound.Count -eq 0) {
    Write-Host "ERREUR: Aucun script shell trouve" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Scripts disponibles:" -ForegroundColor Blue
Write-Host ""

Write-Host "Generation/Creation:" -ForegroundColor Yellow
Write-Host "   bash scripts/create-new-entity.sh -e ENTITY -t TABLE"
Write-Host "   bash scripts/generate-api-skeleton.sh RESOURCE TABLE"
Write-Host ""

Write-Host "Tests:" -ForegroundColor Yellow
Write-Host "   bash test-employee-api-conformity.sh"
Write-Host "   bash test-modular-architecture.sh"
Write-Host "   bash test-phase2-filtres-avances.sh"
Write-Host ""

Write-Host "Comment utiliser sur Windows:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1 - Git Bash (recommande):" -ForegroundColor White
Write-Host "   1. Ouvrir Git Bash dans ce repertoire"
Write-Host "   2. ./scripts/create-new-entity.sh -e product -t PRODUCT"
Write-Host ""

Write-Host "Option 2 - WSL:" -ForegroundColor White
Write-Host "   1. wsl"
Write-Host "   2. ./scripts/create-new-entity.sh -e product -t PRODUCT"
Write-Host ""

Write-Host "Option 3 - PowerShell avec bash:" -ForegroundColor White
Write-Host "   1. bash"
Write-Host "   2. ./scripts/create-new-entity.sh -e product -t PRODUCT"
Write-Host ""

Write-Host "Configuration terminee!" -ForegroundColor Green
Write-Host ""
Write-Host "Avantages des scripts shell:" -ForegroundColor Cyan
Write-Host "   - Plus de problemes d'encodage UTF-8"
Write-Host "   - Compatible Linux, macOS, WSL, Git Bash"
Write-Host "   - Syntaxe plus simple et lisible"
Write-Host "   - Execution plus rapide"
Write-Host ""

Write-Host "References:" -ForegroundColor Blue
Write-Host "   - README: scripts/README_SHELL.md"
Write-Host "   - Documentation: ressources/docs/copilotInstructions/"
Write-Host "   - Pattern: src/employee/ (reference)"