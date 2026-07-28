# Scripts Shell - Remplacement PowerShell

Ce répertoire contient les scripts shell (bash) qui remplacent les scripts PowerShell pour éviter les problèmes d'encodage.

## 🚀 Démarrage Rapide

### 1. Rendre les scripts exécutables
```bash
# Méthode 1: Script automatique
./scripts/make-executable.sh

# Méthode 2: Manuel
chmod +x scripts/*.sh test-*.sh
```

### 2. Tester une API existante
```bash
./test-employee-api-conformity.sh
```

### 3. Créer une nouvelle entité
```bash
./scripts/create-new-entity.sh -e product -t PRODUCT
```

## 📁 Scripts Disponibles

### 🏗️ Génération/Création

| Script | PowerShell Original | Description |
|--------|-------------------|-------------|
| `scripts/create-new-entity.sh` | `Create-NewEntity.ps1` | Création complète d'une nouvelle entité API |
| `scripts/generate-api-skeleton.sh` | `generate_api_skeleton.ps1` | Génération rapide structure API |

#### Exemple d'utilisation:
```bash
# Création entité complète avec branche Git
./scripts/create-new-entity.sh -e customer -t CUSTOMER -p clients

# Génération simple
./scripts/generate-api-skeleton.sh product PRODUCT
```

### 🧪 Tests et Validation

| Script | PowerShell Original | Description |
|--------|-------------------|-------------|
| `test-employee-api-conformity.sh` | `test_employee_api_conformity.ps1` | Test conformité API Employee |
| `test-modular-architecture.sh` | `test_modular_architecture.ps1` | Validation architecture modulaire |
| `test-phase2-filtres-avances.sh` | `test_phase2_filtres_avances.ps1` | Test filtres avancés Phase 2 |
| `test-testservice-api.sh` | `test_testservice_api.ps1` | Test API TestService |

#### Exemple d'utilisation:
```bash
# Test complet API Employee
./test-employee-api-conformity.sh

# Validation structure projet
./test-modular-architecture.sh

# Test filtres avancés
./test-phase2-filtres-avances.sh
```

### 🔧 Utilitaires

| Script | Description |
|--------|-------------|
| `scripts/make-executable.sh` | Rend tous les scripts .sh exécutables |
| `scripts/convert-to-shell.sh` | Script de conversion globale |

## 🌟 Avantages des Scripts Shell

### ✅ Problèmes Résolus
- **Encodage UTF-8**: Plus de problèmes d'accents ou caractères spéciaux
- **Portabilité**: Fonctionne sur Linux, macOS, WSL, Git Bash
- **Performance**: Exécution plus rapide
- **Lisibilité**: Syntaxe plus simple pour les opérations de fichiers

### 🔄 Équivalences PowerShell → Shell

| PowerShell | Shell (bash) |
|------------|--------------|
| `Test-Path "file"` | `[[ -f "file" ]]` |
| `Copy-Item -Recurse` | `cp -r` |
| `Remove-Item -Recurse -Force` | `rm -rf` |
| `Write-Host "text" -ForegroundColor Green` | `echo -e "${GREEN}text${NC}"` |
| `$variable.ToLower()` | `$(echo "$variable" \| tr '[:upper:]' '[:lower:]')` |

## 🎯 Utilisation par Environnement

### Windows
```bash
# Option 1: Git Bash (recommandé)
git-bash.exe
./scripts/create-new-entity.sh -e product -t PRODUCT

# Option 2: WSL
wsl
./scripts/create-new-entity.sh -e product -t PRODUCT

# Option 3: PowerShell avec bash
powershell> bash
bash$ ./scripts/create-new-entity.sh -e product -t PRODUCT
```

### Linux/macOS
```bash
# Direct
./scripts/create-new-entity.sh -e product -t PRODUCT
```

## 📋 Migration depuis PowerShell

### Scripts de Migration Automatique
```bash
# 1. Convertir tous les scripts (sauvegarde auto des .ps1)
./scripts/convert-to-shell.sh

# 2. Rendre exécutables
./scripts/make-executable.sh

# 3. Tester
./test-employee-api-conformity.sh
```

### Migration Manuelle
Si vous préférez migrer progressivement:

1. **Sauvegarder les scripts PowerShell**:
```bash
mkdir scripts/.backup_ps1
cp *.ps1 scripts/*.ps1 scripts/.backup_ps1/
```

2. **Utiliser les nouveaux scripts shell**:
```bash
# Au lieu de
# .\scripts\Create-NewEntity.ps1 -EntityName "product" -TableName "PRODUCT"

# Utiliser
./scripts/create-new-entity.sh -e product -t PRODUCT
```

## 🔍 Dépannage

### Script non exécutable
```bash
chmod +x scripts/nom-du-script.sh
```

### Erreur "command not found"
```bash
# Vérifier que vous êtes dans le bon répertoire
pwd
ls scripts/

# Utiliser le chemin complet
./scripts/create-new-entity.sh -e test -t TEST
```

### Problème de fin de ligne (Windows)
```bash
# Convertir les fins de ligne
dos2unix scripts/*.sh test-*.sh
```

## 📖 Références

- **Pattern de référence**: Module Employee (`src/employee/`)
- **Documentation**: `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- **Checklist**: `CHECKLIST_NOUVELLE_ENTITE.md`

## 🤝 Contribution

Pour ajouter un nouveau script shell:

1. Créer le fichier `.sh`
2. Ajouter le shebang: `#!/bin/bash`
3. Rendre exécutable: `chmod +x script.sh`
4. Tester et documenter
5. Mettre à jour ce README

---

**🎯 L'objectif est de remplacer complètement les scripts PowerShell pour éliminer les problèmes d'encodage tout en conservant toutes les fonctionnalités.**