param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceName,
    
    [Parameter(Mandatory=$true)]
    [string]$TableName
)

Write-Host "Génération API $ResourceName basée sur table $TableName" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

# Vérifier que le template employee existe
if (-not (Test-Path "src\employee")) {
    Write-Host "ERREUR: Template employee non trouvé dans src\employee" -ForegroundColor Red
    Write-Host "Assurez-vous d'être dans le répertoire racine du projet" -ForegroundColor Yellow
    exit 1
}

# Créer le répertoire destination
$TargetDir = "src\$ResourceName"
if (Test-Path $TargetDir) {
    Write-Host "ATTENTION: Le répertoire $TargetDir existe déjà" -ForegroundColor Yellow
    $confirm = Read-Host "Voulez-vous le remplacer ? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Opération annulée" -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Recurse -Force $TargetDir
}

Write-Host "Création structure $TargetDir..." -ForegroundColor Cyan
Copy-Item -Recurse "src\employee" $TargetDir

# Renommer les fichiers
Write-Host "Renommage fichiers..." -ForegroundColor Cyan
Push-Location $TargetDir

Get-ChildItem "employee.*" | ForEach-Object {
    $newName = $_.Name -replace "employee", $ResourceName
    Rename-Item $_.Name $newName
    Write-Host "   $($_.Name) → $newName" -ForegroundColor Gray
}

Pop-Location

# Copier et adapter l'include
Write-Host "Création include..." -ForegroundColor Cyan
Copy-Item "includes\employee.rpgleinc" "includes\$ResourceName.rpgleinc"

# Remplacements dans les fichiers
Write-Host "Adaptation du code..." -ForegroundColor Cyan

# Liste des fichiers à modifier
$FilesToModify = @(
    "$TargetDir\$ResourceName.main.sqlrpgle",
    "$TargetDir\$ResourceName.route.sqlrpgle",
    "$TargetDir\$ResourceName.rest.sqlrpgle", 
    "$TargetDir\$ResourceName.sqlrpgle",
    "$TargetDir\$ResourceName.bnd",
    "$TargetDir\Rules.mk",
    "includes\$ResourceName.rpgleinc"
)

foreach ($file in $FilesToModify) {
    if (Test-Path $file) {
        Write-Host "   Modification $file..." -ForegroundColor Gray
        
        # Lire le contenu du fichier
        $content = Get-Content $file -Raw
        
        # Remplacements de base
        $content = $content -replace "employee", $ResourceName
        $content = $content -replace "EMPLOYEE", $ResourceName.ToUpper()
        $content = $content -replace "Employee", (Get-Culture).TextInfo.ToTitleCase($ResourceName.ToLower())
        
        # Remplacements spécifiques selon le type de fichier
        if ($file -like "*.sqlrpgle") {
            # Remplacer le nom de table
            $content = $content -replace "from employee", "from $TableName"
            $content = $content -replace "FROM employee", "FROM $TableName"
        }
        elseif ($file -like "*.rpgleinc") {
            # Adapter la garde d'include
            $content = $content -replace "EMPLOYEE_INCLUDE", "$($ResourceName.ToUpper())_INCLUDE"
        }
        
        # Écrire le fichier modifié avec encodage UTF-8 sans BOM
        [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

# Créer le README spécifique
Write-Host "Création README..." -ForegroundColor Cyan
$ResourceNameCapitalized = (Get-Culture).TextInfo.ToTitleCase($ResourceName.ToLower())
$readmeContent = @"
# $ResourceNameCapitalized API REST

Cette API respecte le pattern défini dans ``ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md``.

## Configuration

**Table DB2:** $TableName

## Endpoints

- ``GET /api/${ResourceName}s`` - Liste avec pagination, filtres, tri
- ``GET /api/${ResourceName}s/{id}`` - Détail item
- ``POST /api/${ResourceName}s`` - Création
- ``PUT /api/${ResourceName}s/{id}`` - Modification
- ``DELETE /api/${ResourceName}s/{id}`` - Suppression

## Tests de Validation

````bash
# Collection avec pagination
curl "http://server:44000/api/${ResourceName}s?_page=1&_limit=10"

# Filtres (à adapter selon vos champs)
curl "http://server:44000/api/${ResourceName}s?[champ]=valeur"
curl "http://server:44000/api/${ResourceName}s?[champ]_gte=valeur"

# Recherche
curl "http://server:44000/api/${ResourceName}s?q=terme"

# Tri
curl "http://server:44000/api/${ResourceName}s?_sort=[champ]&_order=ASC"
````

## Prochaines Étapes

1. **Adapter les structures** dans ``includes/$ResourceName.rpgleinc`` selon la table $TableName
2. **Modifier les requêtes SQL** dans ``$ResourceName.sqlrpgle``
3. **Configurer les champs filtrables** dans la fonction ``setupFilters``
4. **Tester** avec ``scripts/validate_api_pattern.sh ${ResourceName}s``
5. **Compiler** avec ``make -C src/$ResourceName``

## Conformité Pattern

- [ ] Retourne tableau JSON pour collection
- [ ] Header X-Total-Count présent
- [ ] Pagination (_page, _limit)
- [ ] Tri (_sort, _order)
- [ ] Filtres avec opérateurs (_gte, _like, etc.)
- [ ] CRUD complet (GET, POST, PUT, DELETE)
- [ ] Compatible React-Admin
"@

[System.IO.File]::WriteAllText("$TargetDir\README_$($ResourceName.ToUpper())_API.md", $readmeContent, [System.Text.UTF8Encoding]::new($false))

# Créer un fichier TODO spécifique
$todoContent = @"
# TODO $ResourceNameCapitalized API

## ✅ Génération Automatique Terminée

- [x] Structure de fichiers créée
- [x] Renommage des fichiers effectué
- [x] Adaptations de base appliquées

## 🔄 Adaptations Manuelles Requises

### 1. Structures de Données (30 min)
- [ ] Modifier ``includes/$ResourceName.rpgleinc``
- [ ] Adapter ``${ResourceName}_detail_t`` selon table $TableName
- [ ] Adapter ``${ResourceName}_item_t`` (version optimisée)
- [ ] Adapter ``${ResourceName}_input_t`` (création/modification)

### 2. Requêtes SQL (45 min)
- [ ] Modifier SELECT dans ``${ResourceName}_search``
- [ ] Adapter requête complète dans ``${ResourceName}_getById``
- [ ] Configurer ``supportedFields`` pour filtres
- [ ] Configurer ``sortableFields`` pour tri
- [ ] Configurer ``searchableFields`` pour recherche

### 3. Validation (15 min)
- [ ] Compiler: ``make -C src/$ResourceName``
- [ ] Tester: ``scripts/validate_api_pattern.sh ${ResourceName}s``
- [ ] Vérifier tous les endpoints
- [ ] Tester avec React-Admin si disponible

### 4. Documentation (10 min)
- [ ] Compléter README avec exemples réels
- [ ] Documenter champs spécifiques
- [ ] Ajouter exemples cURL avec vraies données

## 📋 Checklist Conformité

- [ ] GET /api/${ResourceName}s retourne tableau JSON
- [ ] Header X-Total-Count présent
- [ ] Pagination fonctionne
- [ ] Filtres simples fonctionnent
- [ ] Opérateurs avancés fonctionnent
- [ ] Recherche textuelle fonctionne
- [ ] Tri fonctionne
- [ ] CRUD complet fonctionne

## 🚀 Actions Métier Futures

- [ ] Identifier actions spécifiques à $ResourceName
- [ ] Implémenter endpoints d'actions
- [ ] Documenter logique métier
"@

[System.IO.File]::WriteAllText("$TargetDir\TODO_$($ResourceName.ToUpper()).md", $todoContent, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Génération terminée avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers créés dans $TargetDir" -ForegroundColor Cyan
Get-ChildItem $TargetDir | Format-Table Name, Length, LastWriteTime
Write-Host ""
Write-Host "Documentation créée:" -ForegroundColor Cyan
Write-Host "   - $TargetDir\README_$($ResourceName.ToUpper())_API.md" -ForegroundColor Gray
Write-Host "   - $TargetDir\TODO_$($ResourceName.ToUpper()).md" -ForegroundColor Gray
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Yellow
Write-Host "   1. Adapter les structures: includes\$ResourceName.rpgleinc" -ForegroundColor Gray
Write-Host "   2. Modifier les requêtes SQL: $TargetDir\$ResourceName.sqlrpgle" -ForegroundColor Gray
Write-Host "   3. Compiler: make -C $TargetDir" -ForegroundColor Gray
Write-Host "   4. Tester: scripts\validate_api_pattern.sh ${ResourceName}s" -ForegroundColor Gray
Write-Host ""
Write-Host "Temps estimé pour adaptation complète: 2 heures" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour plus de détails, voir: ressources/docs/guides/guide_nouvelle_api_rest.md" -ForegroundColor Cyan