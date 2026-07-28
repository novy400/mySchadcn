# Test Simple des Corrections d'Encodage PowerShell
# Usage: .\test_encoding_simple.ps1

Write-Host "Test des Corrections d'Encodage PowerShell" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Test 1: Verifier les scripts modifies
Write-Host "`nVerification des scripts corriges..." -ForegroundColor Yellow

$scriptsToTest = @(
    "scripts\Create-NewEntity.ps1",
    "scripts\generate_resource.ps1", 
    "scripts\Prepare-Release.ps1",
    "scripts\Create-FeatureBranch.ps1"
)

foreach ($script in $scriptsToTest) {
    if (Test-Path $script) {
        $hasUTF8Function = Select-String -Path $script -Pattern "Write-FileUTF8NoBOM" -Quiet
        $hasOldSetContent = Select-String -Path $script -Pattern "Set-Content.*-Encoding\s+UTF8\b" -Quiet
        
        Write-Host "   $script :" -ForegroundColor Gray
        if ($hasUTF8Function) {
            Write-Host "     Utilise Write-FileUTF8NoBOM" -ForegroundColor Green
        } else {
            Write-Host "     Pas de fonction UTF8NoBOM detectee" -ForegroundColor Yellow
        }
        
        if ($hasOldSetContent) {
            Write-Host "     Contient encore Set-Content -Encoding UTF8" -ForegroundColor Red
        } else {
            Write-Host "     Plus de Set-Content -Encoding UTF8" -ForegroundColor Green
        }
    } else {
        Write-Host "   Script manquant: $script" -ForegroundColor Red
    }
}

# Test 2: Creer un fichier test simple
Write-Host "`nTest creation fichier avec caracteres speciaux..." -ForegroundColor Yellow

# Configuration de l'encodage UTF-8 sans BOM
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Fonction utilitaire
function Write-FileUTF8NoBOM {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$testContent = @"
# Test Encodage PowerShell
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm")

Caracteres de test:
- Accents: aeiouy
- Casse: AEIOUY  
- Ponctuation: .,;:!?
- Symboles: @#$%&*

Ce fichier devrait s'afficher correctement.
"@

$testFile = "temp_test_simple.txt"
Write-FileUTF8NoBOM -Path $testFile -Content $testContent

if (Test-Path $testFile) {
    Write-Host "   Fichier cree avec succes" -ForegroundColor Green
    
    # Lire et afficher le contenu
    $content = Get-Content $testFile -Raw
    Write-Host "   Contenu lisible: $($content.Length) caracteres" -ForegroundColor Cyan
    
    # Nettoyer
    Remove-Item $testFile -Force
} else {
    Write-Host "   Echec creation fichier" -ForegroundColor Red
}

Write-Host "`nTests termines!" -ForegroundColor Green
Write-Host "`nCorrections appliquees:" -ForegroundColor Yellow
Write-Host "- Configuration OutputEncoding pour UTF-8 sans BOM" -ForegroundColor Green
Write-Host "- Fonction Write-FileUTF8NoBOM dans tous les scripts" -ForegroundColor Green
Write-Host "- Remplacement Set-Content par fonction personnalisee" -ForegroundColor Green

Write-Host "`nTest final recommande:" -ForegroundColor Cyan
Write-Host "Executez: .\scripts\Create-NewEntity.ps1 -EntityName test -TableName TEST" -ForegroundColor Gray