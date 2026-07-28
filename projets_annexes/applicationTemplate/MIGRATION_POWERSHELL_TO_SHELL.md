# Guide de Migration PowerShell → Shell

## 🎯 Problème Résolu

Les scripts PowerShell causaient des **problèmes d'encodage UTF-8** récurrents, particulièrement avec les caractères accentués et les symboles. Les scripts shell (bash) éliminent complètement ces problèmes.

## ✅ Migration Réussie

### Scripts Convertis

| PowerShell Original | Script Shell | Status |
|-------------------|-------------|---------|
| `Create-NewEntity.ps1` | `scripts/create-new-entity.sh` | ✅ Converti |
| `generate_api_skeleton.ps1` | `scripts/generate-api-skeleton.sh` | ✅ Converti |
| `test_employee_api_conformity.ps1` | `test-employee-api-conformity.sh` | ✅ Converti |
| `test_modular_architecture.ps1` | `test-modular-architecture.sh` | ✅ Converti |
| `test_phase2_filtres_avances.ps1` | `test-phase2-filtres-avances.sh` | ✅ Converti |
| `test_testservice_api.ps1` | `test-testservice-api.sh` | ✅ Converti |

### Nouveaux Utilitaires

| Script | Description |
|--------|-------------|
| `scripts/make-executable.sh` | Rend tous les scripts .sh exécutables |
| `scripts/convert-to-shell.sh` | Script de migration globale |
| `setup-shell-scripts.ps1` | Configuration Windows (PowerShell) |

## 🚀 Utilisation

### Sur Windows

#### Option 1: Git Bash (Recommandé)
```bash
# Ouvrir Git Bash dans le répertoire du projet
./scripts/create-new-entity.sh -e product -t PRODUCT
./test-employee-api-conformity.sh
```

#### Option 2: WSL
```bash
wsl
./scripts/create-new-entity.sh -e product -t PRODUCT
```

#### Option 3: PowerShell avec bash
```powershell
bash
./scripts/create-new-entity.sh -e product -t PRODUCT
```

#### Option 4: Directement depuis PowerShell
```powershell
bash scripts/create-new-entity.sh -e product -t PRODUCT
```

### Sur Linux/macOS
```bash
# Utilisation directe
./scripts/create-new-entity.sh -e product -t PRODUCT
./test-employee-api-conformity.sh
```

## 📋 Commandes Essentielles

### Créer une Nouvelle Entité
```bash
# Syntaxe complète
./scripts/create-new-entity.sh -e ENTITY -t TABLE [-p PLURAL] [-i ID_FIELD]

# Exemples
./scripts/create-new-entity.sh -e product -t PRODUCT
./scripts/create-new-entity.sh -e customer -t CUSTOMER -p clients -i custno
```

### Tests et Validation
```bash
# Test API Employee
./test-employee-api-conformity.sh

# Validation architecture
./test-modular-architecture.sh

# Test filtres avancés
./test-phase2-filtres-avances.sh
```

### Génération Rapide
```bash
# Structure de base seulement
./scripts/generate-api-skeleton.sh product PRODUCT
```

## 🔧 Configuration Initiale

### 1. Rendre les Scripts Exécutables
```bash
# Automatique
bash scripts/make-executable.sh

# Manuel si nécessaire
chmod +x scripts/*.sh test-*.sh
```

### 2. Vérification
```bash
# Lister les scripts disponibles
ls -la scripts/*.sh test-*.sh

# Tester un script
./scripts/make-executable.sh
```

## ⚡ Avantages Obtenus

### ✅ Problèmes Résolus
- **Encodage UTF-8**: Plus de problèmes d'accents
- **Compatibilité**: Fonctionne sur tous les OS
- **Lisibilité**: Syntaxe shell plus claire
- **Performance**: Exécution plus rapide
- **Maintenance**: Moins de dépendances

### 📊 Comparaison

| Aspect | PowerShell | Shell (bash) |
|--------|------------|-------------|
| Encodage UTF-8 | ❌ Problématique | ✅ Natif |
| Portabilité | ❌ Windows uniquement | ✅ Multi-plateforme |
| Syntaxe fichiers | Complexe | ✅ Simple |
| Performance | Lent | ✅ Rapide |
| Dépendances | .NET Framework | ✅ Minimal |

## 🎯 Migration des Anciens Scripts

### Si Vous Aviez des Scripts Personnalisés

1. **Sauvegarder**:
```bash
mkdir scripts/.backup_ps1
cp *.ps1 scripts/*.ps1 scripts/.backup_ps1/
```

2. **Convertir la Syntaxe**:
```bash
# PowerShell → Shell
Test-Path "file"              → [[ -f "file" ]]
Copy-Item -Recurse source dst → cp -r source dst
Remove-Item -Recurse -Force   → rm -rf
$var.ToLower()               → $(echo "$var" | tr '[:upper:]' '[:lower:]')
```

3. **Adapter les Couleurs**:
```bash
# PowerShell
Write-Host "text" -ForegroundColor Green

# Shell
echo -e "${GREEN}text${NC}"
```

## 🔍 Dépannage

### Script Non Trouvé
```bash
# Vérifier l'emplacement
ls scripts/create-new-entity.sh

# Utiliser chemin absolu si nécessaire
bash ./scripts/create-new-entity.sh -e test -t TEST
```

### Problème Permissions
```bash
# Rendre exécutable
chmod +x scripts/create-new-entity.sh

# Ou utiliser bash directement
bash scripts/create-new-entity.sh -e test -t TEST
```

### Fin de Ligne Windows
```bash
# Si disponible
dos2unix scripts/*.sh

# Ou recréer les fichiers sur Unix
```

## 📚 Références

- **Documentation**: `scripts/README_SHELL.md`
- **Pattern de référence**: `src/employee/`
- **Instructions API**: `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- **Checklist**: `CHECKLIST_NOUVELLE_ENTITE.md`

## ✨ Prochaines Étapes

1. **Utiliser uniquement les scripts shell**
2. **Supprimer progressivement les scripts PowerShell** (après validation)
3. **Contribuer**: Signaler tout problème ou amélioration
4. **Documenter**: Ajouter de nouveaux scripts selon le même pattern

---

**🎉 Migration réussie ! Plus jamais de problèmes d'encodage avec les scripts.**