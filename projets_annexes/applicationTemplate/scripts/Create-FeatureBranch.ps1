# Script de Création de Feature Branch avec Génération API
# .\scripts\Create-FeatureBranch.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceName,
    
    [Parameter(Mandatory=$false)]
    [string]$IssueNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$TableName,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseBranch = "employee_rest"
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

Write-Host "🌿 Creating feature branch for API resource: $ResourceName" -ForegroundColor Green

try {
    # 1. Vérifier que nous sommes dans un repo Git
    $gitStatus = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # 2. Checkout et pull la branche de base
    Write-Host "📥 Updating base branch: $BaseBranch"
    git checkout $BaseBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to checkout $BaseBranch"
    }
    
    git pull origin $BaseBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to pull from origin, continuing with local branch"
    }

    # 3. Créer nouvelle branche feature
    $featureBranch = "feature/api-$($ResourceName.ToLower())"
    Write-Host "🌟 Creating feature branch: $featureBranch"
    
    git checkout -b $featureBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create feature branch $featureBranch"
    }

    # 4. Générer la ressource API
    Write-Host "🔧 Generating API resource structure..."
    
    $generateParams = @{
        ResourceName = $ResourceName
    }
    
    if ($TableName) {
        $generateParams.TableName = $TableName
    }
    
    # Appeler le script de génération (à adapter selon votre script existant)
    if (Test-Path ".\scripts\Generate-ApiResource.ps1") {
        & ".\scripts\Generate-ApiResource.ps1" @generateParams
    } else {
        Write-Warning "Generate-ApiResource.ps1 not found, creating basic structure..."
        
        # Créer structure de base si le script n'existe pas
        $srcPath = "src\$($ResourceName.ToLower())"
        $includePath = "includes"
        
        if (!(Test-Path $srcPath)) {
            New-Item -ItemType Directory -Path $srcPath -Force
        }
        
        # Copier template depuis employee si disponible
        if (Test-Path "src\employee") {
            Write-Host "📋 Copying from employee template..."
            Copy-Item "src\employee\*" -Destination $srcPath -Recurse -Force
            
            # Remplacer employee par le nouveau nom dans les fichiers
            Get-ChildItem $srcPath -File | ForEach-Object {
                $content = Get-Content $_.FullName -Raw
                $content = $content -replace "employee", $ResourceName.ToLower()
                $content = $content -replace "Employee", $ResourceName
                $content = $content -replace "EMPLOYEE", $ResourceName.ToUpper()
                Write-FileUTF8NoBOM -Path $_.FullName -Content $content
            }
            
            # Renommer les fichiers
            Get-ChildItem $srcPath -File | Where-Object { $_.Name -match "employee" } | ForEach-Object {
                $newName = $_.Name -replace "employee", $ResourceName.ToLower()
                Rename-Item $_.FullName -NewName $newName
            }
        }
    }

    # 5. Commit initial
    Write-Host "📝 Creating initial commit..."
    
    git add -A
    
    $commitMessage = "feat(api): initialize $ResourceName resource structure

- Generate base files from employee pattern
- Configure routing and REST handlers  
- Add CMAGIC integration
- Prepare for API implementation"

    if ($IssueNumber) {
        $commitMessage += "`n`nRefs: #$IssueNumber"
    }
    
    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No changes to commit, continuing..."
    }

    # 6. Afficher les prochaines étapes
    Write-Host "`n✅ Feature branch created successfully!" -ForegroundColor Green
    Write-Host "🎯 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Implement business logic in src/$($ResourceName.ToLower())/$($ResourceName.ToLower()).sqlrpgle"
    Write-Host "   2. Test with: .\scripts\Test-ApiEndpoints.ps1 -Resource $ResourceName"
    Write-Host "   3. Build with: bob --build src/$($ResourceName.ToLower())"
    Write-Host "   4. Commit changes: git commit -m 'feat(api): implement $ResourceName business logic'"
    Write-Host "   5. Push: git push origin $featureBranch"
    Write-Host "   6. Create Pull Request to $BaseBranch"
    
    if ($IssueNumber) {
        Write-Host "`n🔗 Related Issue: #$IssueNumber"
    }
    
    Write-Host "`n📊 Current branch: " -NoNewline
    git branch --show-current

} catch {
    Write-Error "❌ Error creating feature branch: $($_.Exception.Message)"
    Write-Host "🔧 Manual recovery steps:"
    Write-Host "   git checkout $BaseBranch"
    Write-Host "   git branch -D $featureBranch (if created)"
    exit 1
}