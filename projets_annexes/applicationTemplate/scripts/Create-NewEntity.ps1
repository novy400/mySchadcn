# Script Complet - Creation Nouvelle Entite API
# Usage: .\scripts\Create-NewEntity.ps1 -EntityName "product" -TableName "PRODUCT"

param(
    [Parameter(Mandatory=$true)]
    [string]$EntityName,
    
    [Parameter(Mandatory=$true)]
    [string]$TableName,
    
    [Parameter(Mandatory=$false)]
    [string]$PluralName,
    
    [Parameter(Mandatory=$false)]
    [string]$IdField,
    
    [Parameter(Mandatory=$false)]
    [string]$IdType = "char(6)",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseBranch = "employee_rest",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests
)

# Configuration de l'encodage UTF-8 sans BOM
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)  # false = no BOM

$EntityLower = $EntityName.ToLower()
$EntityCapital = (Get-Culture).TextInfo.ToTitleCase($EntityLower)

if (-not $PluralName) {
    $PluralName = if ($EntityLower.EndsWith("y")) {
        $EntityLower.Substring(0, $EntityLower.Length - 1) + "ies"
    } elseif ($EntityLower.EndsWith("s") -or $EntityLower.EndsWith("x") -or $EntityLower.EndsWith("ch") -or $EntityLower.EndsWith("sh")) {
        $EntityLower + "es"
    } else {
        $EntityLower + "s"
    }
}

if (-not $IdField) {
    $IdField = $EntityLower + "no"
}

Write-Host "Creation complete de l'entite API: $EntityCapital" -ForegroundColor Green
Write-Host "  - Table: $TableName" -ForegroundColor Gray
Write-Host "  - Routes: /api/$PluralName" -ForegroundColor Gray
Write-Host "  - ID Field: $IdField ($IdType)" -ForegroundColor Gray

# Etape 1: Verifications preliminaires
Write-Host "`nEtape 1: Verifications preliminaires..." -ForegroundColor Yellow

try {
    # Verifier Git
    git status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Pas dans un repository Git"
    }

    # Verifier que nous avons les scripts necessaires
    $scriptsToCheck = @(
        "scripts\generate_resource.ps1",
        "src\employee"
    )
    
    foreach ($script in $scriptsToCheck) {
        if (-not (Test-Path $script)) {
            throw "Fichier/dossier requis manquant: $script"
        }
    }
    
    Write-Host "Verifications OK" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des verifications: $_" -ForegroundColor Red
    exit 1
}

# Etape 2: Creation de la feature branch
Write-Host "`nEtape 2: Creation de la feature branch..." -ForegroundColor Yellow

try {
    # Checkout et pull de la branche de base
    Write-Host "Mise a jour de $BaseBranch..."
    git checkout $BaseBranch
    
    $featureBranch = "feature/api-$EntityLower"
    
    # Verifier si la branche existe deja
    $branchExists = git branch --list $featureBranch
    if ($branchExists) {
        Write-Host "Branche $featureBranch existe deja, checkout..."
        git checkout $featureBranch
    } else {
        Write-Host "Creation de la branche $featureBranch..."
        git checkout -b $featureBranch
        if ($LASTEXITCODE -ne 0) {
            throw "Impossible de creer la branche $featureBranch"
        }
    }
    
    Write-Host "Branche creee/activee: $featureBranch" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la creation de branche: $_" -ForegroundColor Red
    exit 1
}

# Etape 3: Generation de la structure API
Write-Host "`nEtape 3: Generation de la structure API..." -ForegroundColor Yellow

try {
    # Appel du generateur avec les bons parametres
    & ".\scripts\generate_resource.ps1" -Name $EntityLower -Table $TableName -IdType $IdType -IdField $IdField -PluralName $PluralName
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de la generation de la ressource"
    }
    
    Write-Host "Structure generee avec succes" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la generation: $_" -ForegroundColor Red
    exit 1
}

# Etape 4: Verification des fichiers generes
Write-Host "`nEtape 4: Verification des fichiers generes..." -ForegroundColor Yellow

$expectedFiles = @(
    "src\$EntityLower\$EntityLower.sqlrpgle",
    "src\$EntityLower\$EntityLower.rest.sqlrpgle", 
    "src\$EntityLower\$EntityLower.route.sqlrpgle",
    "includes\$EntityLower.rpgleinc",
    "src\$EntityLower\$EntityLower.bnd",
    "src\$EntityLower\Rules.mk",
    "src\$EntityLower\README.md"
)

$missingFiles = @()
foreach ($file in $expectedFiles) {
    if (Test-Path $file) {
        Write-Host "OK: $file" -ForegroundColor Green
    } else {
        Write-Host "MANQUANT: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "Fichiers manquants detectes:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw "Generation incomplete"
}

Write-Host "Tous les fichiers ont ete generes" -ForegroundColor Green

# Etape 5: Creation du script de test
Write-Host "`nEtape 5: Creation du script de test..." -ForegroundColor Yellow

$testScriptPath = "test_${EntityLower}_api.ps1"
$testScriptContent = @"
# Test automatique de l'API $EntityCapital
# Generated by Create-NewEntity.ps1

`$baseUrl = "http://localhost:44000/api/$PluralName"

Write-Host "Test de l'API $EntityCapital" -ForegroundColor Green
Write-Host "URL de base: `$baseUrl" -ForegroundColor Gray

# Test 1: GET collection
Write-Host "`nTest 1: GET collection" -ForegroundColor Yellow
try {
    `$response = Invoke-RestMethod -Uri `$baseUrl -Method GET
    Write-Host "OK: GET collection reussie (`$(`$response.Count) elements)" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: GET collection - `$_" -ForegroundColor Red
}

# Test 2: GET avec pagination
Write-Host "`nTest 2: GET avec pagination" -ForegroundColor Yellow
try {
    `$response = Invoke-RestMethod -Uri "`$baseUrl?_page=1&_limit=5" -Method GET
    Write-Host "OK: GET pagine reussie" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: GET pagine - `$_" -ForegroundColor Red
}

# Test 3: GET avec filtre
Write-Host "`nTest 3: GET avec filtre" -ForegroundColor Yellow
try {
    `$response = Invoke-RestMethod -Uri "`$baseUrl?$IdField=1" -Method GET
    Write-Host "OK: GET avec filtre reussie" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: GET avec filtre - `$_" -ForegroundColor Red
}

Write-Host "`nTests termines" -ForegroundColor Green
"@

[System.IO.File]::WriteAllText($testScriptPath, $testScriptContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "Script de test cree: $testScriptPath" -ForegroundColor Green

# Etape 6: Ajout au git et commit initial
Write-Host "`nEtape 6: Commit des fichiers generes..." -ForegroundColor Yellow

try {
    # Ajouter tous les fichiers generes
    git add "src\$EntityLower\*"
    git add "includes\$EntityLower.rpgleinc"
    git add $testScriptPath
    
    # Message de commit detaille
    $commitMessage = @"
feat(api): implement $EntityCapital REST API

- Add complete $EntityCapital resource structure
- Support standard REST operations (CRUD)
- Routes: /api/$PluralName
- Table: $TableName (ID: $IdField)
- Compatible with React-Admin data provider
- Includes test script and documentation

Generated with ArchiAPI entity generator
"@

    git commit -m $commitMessage
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Commit cree avec succes" -ForegroundColor Green
    } else {
        Write-Host "Aucun changement a commiter ou erreur" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Erreur lors du commit: $_" -ForegroundColor Red
}

# Etape 7: Tests rapides (optionnel)
if (-not $SkipTests) {
    Write-Host "`nEtape 7: Tests de validation des fichiers..." -ForegroundColor Yellow
    
    # Verifier la syntaxe des fichiers generes
    $rpgleFiles = Get-ChildItem "src\$EntityLower\*.sqlrpgle", "src\$EntityLower\*.rpgle" -ErrorAction SilentlyContinue
    
    foreach ($file in $rpgleFiles) {
        if (Select-String -Path $file.FullName -Pattern "TODO|FIXME|PLACEHOLDER" -Quiet) {
            Write-Host "Le fichier $($file.Name) contient des TODO/FIXME a completer" -ForegroundColor Yellow
        } else {
            Write-Host "$($file.Name) semble complet" -ForegroundColor Green
        }
    }
}

# Etape 8: Resume et prochaines etapes
Write-Host "`nCREATION TERMINEE AVEC SUCCES!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

Write-Host "`nResume:" -ForegroundColor White
Write-Host "  Branche creee: feature/api-$EntityLower" -ForegroundColor Gray
Write-Host "  Structure API generee dans: src\$EntityLower\" -ForegroundColor Gray
Write-Host "  Prototypes crees dans: includes\$EntityLower.rpgleinc" -ForegroundColor Gray
Write-Host "  Documentation: src\$EntityLower\README.md" -ForegroundColor Gray
Write-Host "  Script de test: $testScriptPath" -ForegroundColor Gray
Write-Host "  Commit initial effectue" -ForegroundColor Gray

Write-Host "`nProchaines etapes:" -ForegroundColor White
Write-Host "  1. Adapter les structures dans includes\$EntityLower.rpgleinc selon votre table" -ForegroundColor Yellow
Write-Host "  2. Modifier les requetes SQL dans src\$EntityLower\$EntityLower.sqlrpgle" -ForegroundColor Yellow
Write-Host "  3. Integrer les routes dans src\main\main.sqlrpgle" -ForegroundColor Yellow
Write-Host "  4. Build sur IBM i: bob --build src/$EntityLower" -ForegroundColor Yellow
Write-Host "  5. Tester avec: .\$testScriptPath" -ForegroundColor Yellow
Write-Host "  6. Push et creer une Pull Request" -ForegroundColor Yellow

Write-Host "`nDocumentation de reference:" -ForegroundColor White
Write-Host "  - GUIDE_CREATION_NOUVELLE_ENTITE.md (ce guide)" -ForegroundColor Gray
Write-Host "  - ressources\docs\copilotInstructions\ibmi_rest_api_instructions.md" -ForegroundColor Gray
Write-Host "  - src\employee\ (modele de reference)" -ForegroundColor Gray

Write-Host "`nCommandes utiles:" -ForegroundColor White
Write-Host "  git push -u origin feature/api-$EntityLower  # Push de la branche" -ForegroundColor Gray
Write-Host "  .\$testScriptPath                            # Test de l'API" -ForegroundColor Gray
Write-Host "  bob --build src/$EntityLower                  # Build sur IBM i" -ForegroundColor Gray

Write-Host "`nBonne continuation!" -ForegroundColor Green