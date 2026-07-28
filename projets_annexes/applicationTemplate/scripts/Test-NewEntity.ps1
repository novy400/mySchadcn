# Script de test pour la création d'entité
param(
    [Parameter(Mandatory=$true)]
    [string]$EntityName,
    
    [Parameter(Mandatory=$true)]
    [string]$TableName,
    
    [Parameter(Mandatory=$false)]
    [string]$IdType = "char(6)"
)

$ErrorActionPreference = "Stop"

Write-Host "Test de creation d'entite : $EntityName" -ForegroundColor Green
Write-Host "  - Table: $TableName" -ForegroundColor Gray
Write-Host "  - ID Type: $IdType" -ForegroundColor Gray

$EntityLower = $EntityName.ToLower()
$EntityCapital = (Get-Culture).TextInfo.ToTitleCase($EntityLower)

Write-Host "  - Entity Lower: $EntityLower" -ForegroundColor Gray
Write-Host "  - Entity Capital: $EntityCapital" -ForegroundColor Gray

# Test du generateur de ressources
Write-Host "Test du generateur de ressources..." -ForegroundColor Yellow

if (Test-Path "scripts\generate_resource.ps1") {
    Write-Host "generate_resource.ps1 trouve" -ForegroundColor Green
    
    # Test d'appel du générateur
    try {
        & ".\scripts\generate_resource.ps1" -Name $EntityLower -Table $TableName -IdType $IdType
        Write-Host "Generateur execute avec succes" -ForegroundColor Green
    } catch {
        Write-Host "Erreur du generateur: $_" -ForegroundColor Red
    }
} else {
    Write-Host "generate_resource.ps1 non trouve" -ForegroundColor Red
}

Write-Host "Test termine" -ForegroundColor Green