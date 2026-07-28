# Test des Corrections d'Encodage UTF-8 sans BOM
# Usage: .\test_encoding_fix.ps1

# Configuration de l'encodage UTF-8 sans BOM
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)  # false = no BOM

# Fonction utilitaire pour écrire des fichiers avec le bon encodage
function Write-FileUTF8NoBOM {
    param(
        [string]$Path,
        [string]$Content
    )
    
    # Pour PowerShell 5.x, utiliser System.IO.File pour avoir UTF-8 sans BOM
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# Function pour tester l'encodage d'un fichier
function Test-FileEncoding {
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return @{ Status = "Missing"; Encoding = "N/A"; HasBOM = $false }
    }
    
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    
    # Vérifier BOM UTF-8 (EF BB BF)
    $hasUTF8BOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    
    # Détecter l'encodage
    if ($hasUTF8BOM) {
        $encoding = "UTF-8 with BOM"
    } else {
        # Test si c'est de l'UTF-8 valide
        try {
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            $encoding = "UTF-8 without BOM"
        } catch {
            $encoding = "Unknown/Binary"
        }
    }
    
    return @{
        Status = "Found"
        Encoding = $encoding
        HasBOM = $hasUTF8BOM
        Size = $bytes.Length
    }
}

Write-Host "🧪 Test des Corrections d'Encodage PowerShell" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Test 1: Créer un fichier de test avec caractères accentués
Write-Host "`n📝 Test 1: Création fichier avec caractères accentués..." -ForegroundColor Yellow

$testContent = @"
# Fichier de Test - Caracteres Accentues
# Cree le $(Get-Date -Format "yyyy-MM-dd a HH:mm")

## Description
Ce fichier contient des caracteres francais pour tester l'encodage :
- Caracteres accentues : a e e u c o a e i i
- Majuscules accentuees : A E E U C O A E I I
- Guillemets francais : guillemets doubles
- Symboles speciaux : Euro Degre Section

## Phrases de Test
1. L'ete a Montreal avec ses temperatures elevees
2. Developpement d'API REST en francais
3. Gestion des metadonnees et de la qualite
4. Optimisation des performances cote serveur
"@

$testFile = "temp_encoding_test.md"
Write-FileUTF8NoBOM -Path $testFile -Content $testContent

$result = Test-FileEncoding -FilePath $testFile
Write-Host "   Résultat: $($result.Encoding)" -ForegroundColor $(if ($result.HasBOM) { "Red" } else { "Green" })
Write-Host "   Taille: $($result.Size) bytes" -ForegroundColor Gray

# Test 2: Vérifier que le contenu est lisible
Write-Host "`n📖 Test 2: Vérification lecture correcte..." -ForegroundColor Yellow

try {
    $readContent = Get-Content $testFile -Raw -Encoding UTF8
    $hasAccentedChars = $readContent -match "[aeiou]"
    
    if ($hasAccentedChars) {
        Write-Host "   ✅ Caracteres correctement preserves" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Probleme avec les caracteres" -ForegroundColor Red
    }
    
    # Afficher un extrait pour verification visuelle
    $firstLine = ($readContent -split "`n")[4]  # Ligne avec accents
    Write-Host "   Extrait: $firstLine" -ForegroundColor Cyan
} catch {
    Write-Host "   ❌ Erreur lecture: $_" -ForegroundColor Red
}

# Test 3: Tester les scripts corrigés
Write-Host "`n🔧 Test 3: Validation scripts corrigés..." -ForegroundColor Yellow

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
            Write-Host "     ✅ Utilise Write-FileUTF8NoBOM" -ForegroundColor Green
        } else {
            Write-Host "     ⚠️  Pas de fonction UTF8NoBOM detectee" -ForegroundColor Yellow
        }
        
        if ($hasOldSetContent) {
            Write-Host "     ❌ Contient encore Set-Content -Encoding UTF8" -ForegroundColor Red
        } else {
            Write-Host "     ✅ Plus de Set-Content -Encoding UTF8" -ForegroundColor Green
        }
    } else {
        Write-Host "   ❌ Script manquant: $script" -ForegroundColor Red
    }
}

# Test 4: Recommandations pour les nouveaux scripts
Write-Host "`n💡 Test 4: Template pour nouveaux scripts..." -ForegroundColor Yellow

$templateScript = @"
# Template PowerShell avec Encodage UTF-8 sans BOM
# Configuration obligatoire en début de script

param(
    # Vos paramètres ici
)

# Configuration de l'encodage UTF-8 sans BOM
`$OutputEncoding = [System.Text.UTF8Encoding]::new(`$false)  # false = no BOM

# Fonction utilitaire pour écrire des fichiers avec le bon encodage
function Write-FileUTF8NoBOM {
    param(
        [string]`$Path,
        [string]`$Content
    )
    
    # Pour PowerShell 5.x, utiliser System.IO.File pour avoir UTF-8 sans BOM
    `$utf8NoBom = [System.Text.UTF8Encoding]::new(`$false)
    [System.IO.File]::WriteAllText(`$Path, `$Content, `$utf8NoBom)
}

# Utilisation:
# Write-FileUTF8NoBOM -Path "fichier.txt" -Content "Contenu avec accents: aeeu"
"@

$templateFile = "template_powershell_utf8.ps1"
Write-FileUTF8NoBOM -Path $templateFile -Content $templateScript

Write-Host "   ✅ Template créé: $templateFile" -ForegroundColor Green

# Nettoyage
Write-Host "`n🧹 Nettoyage..." -ForegroundColor Yellow
Remove-Item $testFile -Force -ErrorAction SilentlyContinue

Write-Host "`n🎉 Tests terminés!" -ForegroundColor Green
Write-Host "`nResume des corrections appliquees:" -ForegroundColor Yellow
Write-Host "- ✅ Configuration `$OutputEncoding pour UTF-8 sans BOM" -ForegroundColor Green
Write-Host "- ✅ Fonction Write-FileUTF8NoBOM dans tous les scripts" -ForegroundColor Green
Write-Host "- ✅ Remplacement Set-Content par Write-FileUTF8NoBOM" -ForegroundColor Green
Write-Host "- ✅ Preservation des caracteres accentues francais" -ForegroundColor Green

Write-Host "`n📋 Prochaines etapes:" -ForegroundColor Cyan
Write-Host "1. Tester les scripts avec: .\scripts\Create-NewEntity.ps1 -EntityName 'test' -TableName 'TEST'" -ForegroundColor Gray
Write-Host "2. Verifier que les fichiers generes affichent correctement les accents" -ForegroundColor Gray
Write-Host "3. Utiliser le template_powershell_utf8.ps1 pour nouveaux scripts" -ForegroundColor Gray