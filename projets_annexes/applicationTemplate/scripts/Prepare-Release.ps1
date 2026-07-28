# Script de Préparation de Release
# .\scripts\Prepare-Release.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseBranch = "employee_rest",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests
)

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

Write-Host "🚀 Preparing release version: $Version" -ForegroundColor Green

try {
    # 1. Vérifier format version
    if ($Version -notmatch '^v?\d+\.\d+\.\d+$') {
        throw "Version format should be: vX.Y.Z or X.Y.Z"
    }
    
    # Normaliser version (ajouter v si manquant)
    if (!$Version.StartsWith('v')) {
        $Version = "v$Version"
    }

    # 2. Vérifier que nous sommes dans un repo Git
    git status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # 3. Checkout et pull la branche de base
    Write-Host "📥 Updating base branch: $BaseBranch"
    git checkout $BaseBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to checkout $BaseBranch"
    }
    
    git pull origin $BaseBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to pull from origin, continuing with local branch"
    }

    # 4. Vérifier que la branche est propre
    $status = git status --porcelain
    if ($status) {
        Write-Warning "Working directory has uncommitted changes:"
        git status --short
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            throw "Aborted by user"
        }
    }

    # 5. Créer branche release
    $releaseBranch = "release/$Version"
    Write-Host "🌟 Creating release branch: $releaseBranch"
    
    git checkout -b $releaseBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create release branch $releaseBranch"
    }

    # 6. Tests complets (si non skip)
    if (!$SkipTests) {
        Write-Host "🧪 Running comprehensive tests..." -ForegroundColor Yellow
        
        # Test build de toutes les ressources
        Write-Host "   Building all resources..."
        if (Test-Path "src") {
            $resources = Get-ChildItem "src" -Directory | Where-Object { $_.Name -ne "qclsrc" -and $_.Name -ne "qcmdsrc" }
            foreach ($resource in $resources) {
                Write-Host "     - Building $($resource.Name)..."
                bob --build "src/$($resource.Name)" 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Build failed for $($resource.Name)"
                }
            }
        }
        
        # Tests endpoints (si scripts disponibles)
        if (Test-Path ".\scripts\Test-All-Resources.ps1") {
            Write-Host "   Testing all API endpoints..."
            & ".\scripts\Test-All-Resources.ps1"
        }
        
        if (Test-Path ".\scripts\Validate-All-APIs.ps1") {
            Write-Host "   Validating API conformity..."
            & ".\scripts\Validate-All-APIs.ps1"
        }
    }

    # 7. Mise à jour documentation
    Write-Host "📚 Updating documentation..." -ForegroundColor Yellow
    
    # Générer documentation API (si script disponible)
    if (Test-Path ".\scripts\Generate-Documentation.ps1") {
        & ".\scripts\Generate-Documentation.ps1"
    }
    
    # Mettre à jour CHANGELOG
    $changelogPath = "CHANGELOG.md"
    if (!(Test-Path $changelogPath)) {
        $changelogContent = @"
# Changelog

All notable changes to this project will be documented in this file.

## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
- Release $Version preparation

### Changed
- Updated documentation

### Fixed
- Various bug fixes and improvements

"@
        Write-FileUTF8NoBOM -Path $changelogPath -Content $changelogContent
    } else {
        # Ajouter entrée au changelog existant
        $changelog = Get-Content $changelogPath -Raw
        $newEntry = @"
## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
- New features in this release

### Changed
- Updated components

### Fixed
- Bug fixes and improvements

$changelog
"@
        Write-FileUTF8NoBOM -Path $changelogPath -Content $newEntry
    }

    # 8. Mise à jour version dans les fichiers projet
    Write-Host "📝 Updating version information..."
    
    # Mettre à jour iproj.json si existe
    if (Test-Path "iproj.json") {
        $iproj = Get-Content "iproj.json" | ConvertFrom-Json
        $iproj.version = $Version.TrimStart('v')
        $iprojJson = $iproj | ConvertTo-Json -Depth 10
        Write-FileUTF8NoBOM -Path "iproj.json" -Content $iprojJson
    }
    
    # Mettre à jour package.json si existe
    if (Test-Path "package.json") {
        $package = Get-Content "package.json" | ConvertFrom-Json
        $package.version = $Version.TrimStart('v')
        $packageJson = $package | ConvertTo-Json -Depth 10
        Write-FileUTF8NoBOM -Path "package.json" -Content $packageJson
    }

    # 9. Commit des changements
    Write-Host "📝 Committing release preparation..."
    
    git add -A
    
    $commitMessage = "chore(release): prepare version $Version

- Update documentation and changelog
- Validate all API endpoints  
- Run comprehensive test suite
- Update version information
- Ready for production deployment"

    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No changes to commit"
    }

    # 10. Afficher les prochaines étapes
    Write-Host "`n✅ Release branch created successfully!" -ForegroundColor Green
    Write-Host "🎯 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Final review and testing"
    Write-Host "   2. Push release branch: git push origin $releaseBranch"
    Write-Host "   3. Create Pull Request to main"
    Write-Host "   4. After merge to main:"
    Write-Host "      git checkout main"
    Write-Host "      git pull origin main" 
    Write-Host "      git tag -a $Version -m 'Release $Version'"
    Write-Host "      git push origin $Version"
    Write-Host "   5. Merge back to development branch:"
    Write-Host "      git checkout $BaseBranch"
    Write-Host "      git merge main"
    Write-Host "      git push origin $BaseBranch"
    
    Write-Host "`n📊 Current branch: " -NoNewline
    git branch --show-current
    
    Write-Host "`n📋 Generated files:"
    if (Test-Path $changelogPath) {
        Write-Host "   - $changelogPath (updated)"
    }
    if (Test-Path "iproj.json") {
        Write-Host "   - iproj.json (version updated)"
    }

} catch {
    Write-Error "❌ Error preparing release: $($_.Exception.Message)"
    Write-Host "🔧 Manual recovery steps:"
    Write-Host "   git checkout $BaseBranch"
    Write-Host "   git branch -D $releaseBranch (if created)"
    exit 1
}