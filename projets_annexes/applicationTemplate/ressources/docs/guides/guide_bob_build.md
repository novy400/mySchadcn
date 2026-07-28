# Guide BOB - Build APIs REST sur IBM i

*Guide spécifique pour l'environnement IBM i avec BOB (Better Object Builder)*

## 🎯 **Prérequis BOB**

### **Installation BOB**
BOB doit être installé sur votre IBM i via `yum`:
```bash
yum install ibmi-bob
```

**Prérequis système** :
- Accès SSH à IBM i
- Git installé sur IBM i (`yum install git`)
- Repository cloné dans `/home/[user]/projects/applicationTemplate`

### **Structure Projet Compatible BOB**
```
applicationTemplate/
├── .env                        # Configuration bibliothèques (CURLIB, LIBL)
├── iproj.json                  # Configuration BOB (includePath, libl)
├── Rules.mk                    # Règles globales (SUBDIRS)
├── src/
│   ├── Rules.mk               # Règles src (SUBDIRS = hello employee)
│   ├── employee/
│   │   ├── Rules.mk           # Dépendances employee (MODULE, SRVPGM, PGM)
│   │   ├── *.sqlrpgle         # Sources RPG
│   │   ├── *.bnd              # Binding sources
│   │   └── *.dspf             # Display files
│   └── customer/              # Future API
└── includes/                  # Headers partagés (.rpgleinc)
```

**Note** : Les fichiers `makefile`, `makefile_config`, `makefile_components` sont **legacy** et non utilisés par BOB.

## 🚀 **Commandes BOB Standard**

### **Build API Employee**
```bash
# Depuis racine du projet sur IBM i
makei build -l src/employee

# Build incrémental (seulement fichiers modifiés)
makei build -l src/employee

# Build spécifique d'un objet
makei build -t EMPLOYEE.SRVPGM
```

### **Build Complet du Projet**
```bash
# Build tout (employee + autres composants)
makei build

# Clean puis build
makei clean
makei build
```

### **Options Avancées**
```bash
# Build avec log détaillé
makei build -v

# Build d'un fichier source spécifique
makei compile -f src/employee/employee.sqlrpgle

# Vérifier status sans compiler
makei list
```

## 📋 **Workflow Développement avec BOB**

### **1. Modification Code (Local)**
```bash
# Sur machine de développement Windows
git pull origin employee_rest
# Modifier sources RPG localement
git add .
git commit -m "Update employee API"
git push origin employee_rest
```

### **2. Build sur IBM i**
```bash
# SSH vers IBM i
ssh user@your-ibmi

# Aller au projet
cd /home/[user]/projects/applicationTemplate

# Pull dernières modifications
git pull origin employee_rest

# Build avec BOB
makei build -l src/employee
```

### **3. Test API**
```bash
# Test depuis machine cliente Windows
curl "http://your-ibmi:44000/api/employees?_limit=5"

# Vérifier header X-Total-Count
curl -I "http://your-ibmi:44000/api/employees"

# Test filtres
curl "http://your-ibmi:44000/api/employees?lastname_like=SM"
```

## 🛠️ **Commandes de Validation**

### **Status Build**
```bash
# Lister objets du projet
makei list

# Voir dépendances
cat src/employee/Rules.mk
```

### **Tests Rapides Post-Build**
```bash
#!/bin/bash
# validate_build_ibmi.sh

echo "🔍 Validation Build Employee API"
echo "================================"

# Test 1: API accessible
echo "Test 1: API accessible..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:44000/api/employees")
if [ "$STATUS" = "200" ]; then
    echo "✅ API accessible (Status: $STATUS)"
else
    echo "❌ API inaccessible (Status: $STATUS)"
fi

# Test 2: Format JSON tableau
echo "Test 2: Format JSON..."
RESPONSE=$(curl -s "http://localhost:44000/api/employees?_limit=1")
if echo "$RESPONSE" | grep -q '\[.*\]'; then
    echo "✅ Format JSON tableau correct"
else
    echo "❌ Format JSON incorrect"
fi

# Test 3: Header X-Total-Count
echo "Test 3: Header X-Total-Count..."
HEADERS=$(curl -s -I "http://localhost:44000/api/employees")
if echo "$HEADERS" | grep -qi "x-total-count"; then
    echo "✅ X-Total-Count présent"
else
    echo "❌ X-Total-Count manquant"
fi

echo ""
echo "🎯 Validation build terminée!"
```

## 📊 **Métriques Build BOB**

### **Temps de Build Typiques**
| Composant | Temps Build | Remarques |
|-----------|-------------|-----------|
| **employee.sqlrpgle MODULE** | 5-10s | Module principal logique métier |
| **EMPLOYEE.SRVPGM** | 3-5s | Création service program |
| **wrkemp.dspf FILE** | 2-3s | Display file |
| **WRKEMP.PGM** | 8-12s | Programme interactif |
| **TOTAL Employee** | **20-30s** | **Build incrémental** |
| **Build complet from scratch** | **45-60s** | **Tous objets** |

### **Optimisations Build**
- **Build incrémental** : BOB compile seulement modules modifiés
- **Parallélisme** : Non supporté actuellement par makei
- **Cache** : Réutilisation objets non modifiés

## 🚨 **Troubleshooting BOB**

### **Erreurs Communes**

#### **1. Rules.mk non trouvé**
```bash
# Erreur
makei: error: No Rules.mk found

# Solution
# Vérifier présence Rules.mk dans répertoire courant
ls -la Rules.mk
```

#### **2. Variable &CURLIB non définie**
```bash
# Erreur
error: Variable &CURLIB not defined

# Solution
# Vérifier .env à la racine
cat .env
# Doit contenir: CURLIB=CKOOLBIN
```

#### **3. Include non trouvé**
```bash
# Erreur
/copy includes/employee.rpgleinc not found

# Solution
# Vérifier iproj.json includePath
cat iproj.json
# Doit contenir: "includePath": ["includes", "/usr/local/include"]
```

#### **4. Objet dépendant manquant**
```bash
# Erreur
WRKEMP.PGM requires EMPLOYEE.SRVPGM

# Solution
# Build dépendances d'abord
makei build -t EMPLOYEE.SRVPGM
makei build -t WRKEMP.PGM
# Ou laisser BOB gérer automatiquement
makei build -l src/employee
```

### **Debug Build**
```bash
# Build avec traces détaillées
makei build -v -l src/employee

# Examiner erreurs de compilation
cat .logs/employee.splf

# Vérifier objets créés dans bibliothèque
system "DSPLIB LIB(CKOOLBIN)"
system "DSPOBJD OBJ(CKOOLBIN/EMPLOYEE) OBJTYPE(*SRVPGM)"
```

## 🔄 **Workflow Customer API**

### **Génération Squelette**
```bash
# Sur machine de développement Windows
scripts/generate_api_skeleton.sh customer CUSTOMER

# Commit changements
git add src/customer
git commit -m "Generate customer API skeleton"
git push origin employee_rest
```

### **Adaptation & Build**
```bash
# Sur IBM i
cd /home/[user]/projects/applicationTemplate
git pull origin employee_rest

# Adapter structures dans includes/customer.rpgleinc
# Adapter SQL dans src/customer/customer.sqlrpgle
# Créer Rules.mk avec dépendances

# Build
makei build -l src/customer

# Test
curl "http://localhost:44000/api/customers?_limit=5"
```

## 📈 **Métriques Projet**

### **Status Build Global**
```bash
# Script de monitoring build
#!/bin/bash
# check_build_status.sh

echo "📊 Status Build Projet ArchiAPI"
echo "================================"

APIS=("employee" "customer")

for api in "${APIS[@]}"; do
    echo ""
    echo "Checking $api API..."
    
    if [ -d "src/$api" ]; then
        # Build status (via makei list)
        if makei list | grep -qi "${api}.srvpgm"; then
            echo "✅ $api objets trouvés"
        else
            echo "⚠️ $api objets manquants - build requis"
        fi
        
        # API status
        API_NAME="${api}s"  # employees, customers
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:44000/api/${API_NAME}")
        if [ "$STATUS" = "200" ]; then
            echo "✅ $api API OK (HTTP $STATUS)"
        else
            echo "❌ $api API FAIL (HTTP $STATUS)"
        fi
    else
        echo "⚠️ $api pas encore créé"
    fi
done

echo ""
echo "🎯 Monitoring terminé!"
```

## 🎯 **Checklist Build Sprint 0**

### **Employee API - Build & Validation**
- [ ] `.env` configuré avec `CURLIB=CKOOLBIN` et `LIBL`
- [ ] `iproj.json` avec `includePath` et bibliothèques
- [ ] `src/employee/Rules.mk` avec toutes dépendances
- [ ] `makei build -l src/employee` - Build réussi sans erreurs
- [ ] `curl http://ibmi:44000/api/employees` - API accessible
- [ ] Header `X-Total-Count` présent dans réponse
- [ ] Pagination fonctionnelle (`_page`, `_limit`)
- [ ] Filtres avancés (`lastname_like`, `empno_gte`)
- [ ] Performance < 200ms pour requêtes simples

### **Customer API - Génération & Build**
- [ ] Squelette généré avec script
- [ ] Structures adaptées selon table CUSTOMER
- [ ] `src/customer/Rules.mk` créé avec dépendances
- [ ] `makei build -l src/customer` - Build réussi
- [ ] Tests cURL passants (collection, item, pagination)
- [ ] Conformité pattern Employee validée

## 🏆 **Avantages BOB pour APIs REST**

### **Système de Build Moderne**
- ✅ **Syntaxe déclarative** : Rules.mk simples vs Makefiles complexes
- ✅ **Dépendances automatiques** : BOB résout le graphe de dépendances
- ✅ **Build incrémental** : Compile seulement fichiers modifiés
- ✅ **Configuration centralisée** : `.env` + `iproj.json`
- ✅ **Pas de Source Orbit requis** : Rules.mk manuels suffisants

### **Intégration IBM i Native**
- ✅ **Build natif** sur plateforme cible
- ✅ **Logs compilation** intégrés (`.evfevent`, `.splf`)
- ✅ **Support IFS** : Sources en stream files
- ✅ **Gestion bibliothèques** : CURLIB, LIBL via `.env`

### **Workflow Développement**
- ✅ **VS Code Actions** : Build depuis éditeur avec `deployFirst`
- ✅ **Git integration** : Clone repo, build, test
- ✅ **Feedback immédiat** : Erreurs compilation visibles rapidement
- ✅ **Tests directs** : APIs testables immédiatement après build

## 📚 **Ressources**

### **Documentation BOB**
- [GitHub IBM BOB](https://github.com/IBM/ibmi-bob)
- [Documentation officielle](https://ibm.github.io/ibmi-bob/#/)

### **Configuration Projet**
- `.env` : Variables environnement (CURLIB, LIBL)
- `iproj.json` : Configuration BOB (includePath, bibliothèques)
- `Rules.mk` : Dépendances objets (MODULE, SRVPGM, PGM, FILE, CMD)

### **Fichiers Legacy (Non utilisés)**
- `makefile` : Ancien système gmake (ignorer)
- `makefile_config` : Configuration gmake (ignorer)
- `makefile_components` : Composants gmake (ignorer)

**Note** : Ces fichiers sont conservés pour historique mais **ne sont pas utilisés** par BOB.

---

**✨ Ce guide vous permet de développer efficacement vos APIs REST avec BOB directement sur IBM i, en suivant le pattern `ibmi_rest_api_instructions.md` !** 🚀