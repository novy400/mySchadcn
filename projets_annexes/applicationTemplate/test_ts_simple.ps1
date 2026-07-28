# Script PowerShell simple pour tester la conversion TypeScript

Write-Host "Test de la conversion TypeScript Employee API" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$frontDir = "src\employee\front"

# Verification des fichiers TypeScript
Write-Host "`nVerification des fichiers TypeScript..." -ForegroundColor Yellow

$tsFiles = @(
    "types.ts",
    "dataProvider.ts", 
    "employeeDataProvider.ts",
    "employeeApiClient.ts",
    "examples.ts",
    "reactAdminConfig.tsx",
    "index.ts",
    "test.ts"
)

$filesFound = 0
foreach ($file in $tsFiles) {
    $fullPath = "$frontDir\$file"
    if (Test-Path $fullPath) {
        Write-Host "  OK $file" -ForegroundColor Green
        $filesFound++
    } else {
        Write-Host "  MANQUANT $file" -ForegroundColor Red
    }
}

Write-Host "`nResultat: $filesFound/$($tsFiles.Count) fichiers TypeScript trouves" -ForegroundColor Cyan

# Verification de tsconfig.json
if (Test-Path "$frontDir\tsconfig.json") {
    Write-Host "OK tsconfig.json present" -ForegroundColor Green
} else {
    Write-Host "MANQUANT tsconfig.json" -ForegroundColor Red
}

# Verification de package.json
if (Test-Path "$frontDir\package.json") {
    Write-Host "OK package.json present" -ForegroundColor Green
} else {
    Write-Host "MANQUANT package.json" -ForegroundColor Red
}

# Verification documentation
$docFiles = @(
    "README_TypeScript.md",
    "RAPPORT_CONVERSION_TYPESCRIPT.md"
)

$docsFound = 0
foreach ($file in $docFiles) {
    $fullPath = "$frontDir\$file"
    if (Test-Path $fullPath) {
        Write-Host "OK $file" -ForegroundColor Green
        $docsFound++
    } else {
        Write-Host "MANQUANT $file" -ForegroundColor Yellow
    }
}

# Rapport final
Write-Host "`n=== RAPPORT FINAL ===" -ForegroundColor Green

if ($filesFound -eq $tsFiles.Count) {
    Write-Host "SUCCES: Conversion TypeScript complete!" -ForegroundColor Green
    Write-Host "Tous les fichiers TypeScript sont presents" -ForegroundColor Green
    Write-Host "`nProchaines etapes:" -ForegroundColor Yellow
    Write-Host "1. npm install typescript @types/react @types/react-dom"
    Write-Host "2. npm run type-check"
    Write-Host "3. npm run build"
} else {
    Write-Host "ATTENTION: Conversion incomplete" -ForegroundColor Yellow
    Write-Host "$($tsFiles.Count - $filesFound) fichier(s) manquant(s)" -ForegroundColor Red
}

Write-Host "`nTest termine." -ForegroundColor Green