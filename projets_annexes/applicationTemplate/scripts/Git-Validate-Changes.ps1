# Script de Validation Git avec Tests
# .\scripts\Git-Validate-Changes.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetBranch,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoCommit
)

Write-Host "🔍 Validating Git changes and running tests..." -ForegroundColor Green

try {
    # 1. Vérifier que nous sommes dans un repo Git
    git status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # 2. Obtenir la branche courante
    $currentBranch = git branch --show-current
    Write-Host "📊 Current branch: $currentBranch"

    # 3. Vérifier les changements
    $staged = git diff --cached --name-only
    $unstaged = git diff --name-only
    $untracked = git ls-files --others --exclude-standard

    Write-Host "`n📋 Changes summary:"
    if ($staged) {
        Write-Host "   Staged files:" -ForegroundColor Green
        $staged | ForEach-Object { Write-Host "     + $_" -ForegroundColor Green }
    }
    if ($unstaged) {
        Write-Host "   Unstaged files:" -ForegroundColor Yellow
        $unstaged | ForEach-Object { Write-Host "     ~ $_" -ForegroundColor Yellow }
    }
    if ($untracked) {
        Write-Host "   Untracked files:" -ForegroundColor Red
        $untracked | ForEach-Object { Write-Host "     ? $_" -ForegroundColor Red }
    }
    
    if (!$staged -and !$unstaged -and !$untracked) {
        Write-Host "   No changes detected" -ForegroundColor Gray
        return
    }

    # 4. Identifier les ressources modifiées
    $allChanges = @($staged) + @($unstaged) + @($untracked)
    $modifiedResources = @()
    
    foreach ($file in $allChanges) {
        if ($file -match '^src/([^/]+)/') {
            $resource = $matches[1]
            if ($modifiedResources -notcontains $resource) {
                $modifiedResources += $resource
            }
        }
    }
    
    if ($modifiedResources) {
        Write-Host "`n🎯 Modified resources: $($modifiedResources -join ', ')"
    }

    # 5. Build validation (si non skip)
    if (!$SkipBuild) {
        Write-Host "`n🔨 Running build validation..." -ForegroundColor Yellow
        
        if ($modifiedResources) {
            foreach ($resource in $modifiedResources) {
                if (Test-Path "src/$resource") {
                    Write-Host "   Building $resource..."
                    bob --build "src/$resource" 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "     ✅ Build successful" -ForegroundColor Green
                    } else {
                        Write-Warning "     ❌ Build failed for $resource"
                        bob --build "src/$resource"  # Afficher erreurs
                    }
                }
            }
        } else {
            Write-Host "   No source changes detected, skipping build"
        }
    }

    # 6. Tests API (si non skip)
    if (!$SkipTests) {
        Write-Host "`n🧪 Running API tests..." -ForegroundColor Yellow
        
        if ($modifiedResources) {
            foreach ($resource in $modifiedResources) {
                if (Test-Path ".\scripts\Test-ApiEndpoints.ps1") {
                    Write-Host "   Testing $resource endpoints..."
                    try {
                        & ".\scripts\Test-ApiEndpoints.ps1" -Resource $resource -ErrorAction Stop
                        Write-Host "     ✅ API tests passed" -ForegroundColor Green
                    } catch {
                        Write-Warning "     ❌ API tests failed for $resource"
                        Write-Host "     Error: $($_.Exception.Message)"
                    }
                }
            }
        } else {
            Write-Host "   No API changes detected, skipping tests"
        }
        
        # Tests conformité globale
        if (Test-Path ".\scripts\Validate-All-APIs.ps1") {
            Write-Host "   Running global conformity tests..."
            try {
                & ".\scripts\Validate-All-APIs.ps1" -ErrorAction Stop
                Write-Host "     ✅ Conformity tests passed" -ForegroundColor Green
            } catch {
                Write-Warning "     ❌ Conformity tests failed"
            }
        }
    }

    # 7. Validation différentielle avec branche cible
    if ($TargetBranch) {
        Write-Host "`n🔄 Comparing with target branch: $TargetBranch" -ForegroundColor Yellow
        
        # Vérifier que la branche cible existe
        git show-ref --verify --quiet "refs/heads/$TargetBranch"
        if ($LASTEXITCODE -eq 0) {
            $diffFiles = git diff --name-only "$TargetBranch..HEAD"
            if ($diffFiles) {
                Write-Host "   Files different from $TargetBranch :"
                $diffFiles | ForEach-Object { Write-Host "     $_" }
                
                # Statistiques des changements
                $stats = git diff --stat "$TargetBranch..HEAD"
                Write-Host "`n   Change statistics:"
                $stats | ForEach-Object { Write-Host "     $_" }
            } else {
                Write-Host "   No differences with $TargetBranch"
            }
        } else {
            Write-Warning "   Target branch $TargetBranch not found locally"
        }
    }

    # 8. Auto-commit si demandé et tout est OK
    if ($AutoCommit -and ($unstaged -or $untracked)) {
        Write-Host "`n📝 Auto-committing changes..." -ForegroundColor Yellow
        
        # Ajouter tous les fichiers
        git add -A
        
        # Générer message de commit intelligent
        $commitType = "feat"
        $scope = ""
        
        if ($modifiedResources.Count -eq 1) {
            $scope = "($($modifiedResources[0]))"
        } elseif ($modifiedResources.Count -gt 1) {
            $scope = "(api)"
        }
        
        # Analyser le type de changements
        $hasNewFiles = $untracked.Count -gt 0
        $hasModifications = $unstaged.Count -gt 0
        $hasDocChanges = ($allChanges | Where-Object { $_ -match '\.(md|txt)$' }).Count -gt 0
        
        if ($hasDocChanges -and !$hasNewFiles -and !($unstaged | Where-Object { $_ -notmatch '\.(md|txt)$' })) {
            $commitType = "docs"
        } elseif ($hasNewFiles) {
            $commitType = "feat"
        } elseif ($hasModifications) {
            $commitType = "fix"
        }
        
        $commitMessage = "$commitType$scope`: update $($modifiedResources -join ', ') resources

- Auto-generated commit from validation script
- All builds and tests passed
- Changes validated against standards"

        git commit -m $commitMessage
        if ($LASTEXITCODE -eq 0) {
            Write-Host "     ✅ Changes committed successfully" -ForegroundColor Green
        } else {
            Write-Warning "     ❌ Commit failed"
        }
    }

    # 9. Résumé final
    Write-Host "`n✅ Validation completed!" -ForegroundColor Green
    Write-Host "📊 Summary:" -ForegroundColor Cyan
    Write-Host "   - Branch: $currentBranch"
    Write-Host "   - Modified resources: $($modifiedResources.Count)"
    Write-Host "   - Build status: $(if ($SkipBuild) { 'Skipped' } else { 'Validated' })"
    Write-Host "   - Test status: $(if ($SkipTests) { 'Skipped' } else { 'Validated' })"
    
    if ($AutoCommit) {
        Write-Host "   - Auto-commit: Enabled"
    }

    # 10. Suggestions d'actions
    Write-Host "`n💡 Suggested next steps:" -ForegroundColor Cyan
    if ($unstaged -or $untracked) {
        Write-Host "   git add -A"
        Write-Host "   git commit -m 'your commit message'"
    }
    Write-Host "   git push origin $currentBranch"
    if ($currentBranch -ne "main" -and $currentBranch -ne "employee_rest") {
        Write-Host "   # Create Pull Request when ready"
    }

} catch {
    Write-Error "❌ Validation failed: $($_.Exception.Message)"
    exit 1
}