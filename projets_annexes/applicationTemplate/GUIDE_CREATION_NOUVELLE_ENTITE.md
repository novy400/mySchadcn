# 📋 Guide Complet - Création d'une Nouvelle Entité API REST

> Guide étape par étape pour créer une nouvelle entité (ex: Product) dans le projet ArchiAPI

---

## 🎯 Vue d'Ensemble

Ce guide détaille le processus complet de création d'une nouvelle entité API REST en suivant les conventions validées du projet ArchiAPI. L'exemple utilisé sera l'entité **Product**.

### Prérequis

- ✅ Git configuré et accès au repository
- ✅ Environnement IBM i avec BOB installé
- ✅ ILEastic configuré et fonctionnel
- ✅ Connaissance de base des patterns du projet (voir `src/employee/`)

---

## 🚀 PROCESSUS COMPLET

### **ÉTAPE 1 : Création de la Feature Branch**

#### 1.1 Utiliser le Script Automatisé

```powershell
# Depuis le répertoire racine du projet
.\scripts\Create-FeatureBranch.ps1 -ResourceName "product" -TableName "PRODUCT"
```

**Ce script fait automatiquement :**
- Checkout et pull de la branche `employee_rest`
- Création de la branche `feature/api-product`
- Génération de la structure de base
- Commit initial

#### 1.2 Création Manuelle (alternative)

```powershell
# 1. Mise à jour de la branche de base
git checkout employee_rest
git pull origin employee_rest

# 2. Création de la nouvelle branche
git checkout -b feature/api-product

# 3. Push de la branche
git push -u origin feature/api-product
```

### **ÉTAPE 2 : Génération de la Structure API**

#### 2.1 Utiliser le Générateur Principal

```powershell
# Commande complète avec tous les paramètres
.\scripts\generate_resource.ps1 `
  -Name "product" `
  -Table "PRODUCT" `
  -PluralName "products" `
  -IdField "productno" `
  -IdType "char(10)"
```

**Paramètres du générateur :**
- `Name` : Nom de l'entité (singulier)
- `Table` : Nom de la table DB2
- `PluralName` : Nom pluriel pour les routes (optionnel)
- `IdField` : Champ ID de la table (optionnel, auto-généré)
- `IdType` : Type du champ ID (défaut: char(6))

#### 2.2 Fichiers Générés

```
src/product/
├── product.sqlrpgle          # Module métier (CRUD + SQL)
├── product.rest.sqlrpgle     # Module REST (handlers HTTP/JSON)
├── product.route.sqlrpgle    # Configuration routes ILEastic
├── product.bnd               # Binding source
├── Rules.mk                  # Configuration build
└── README.md                 # Documentation

includes/
└── product.rpgleinc          # Structures et prototypes
```

### **ÉTAPE 3 : Personnalisation selon les Besoins**

#### 3.1 Adapter les Structures de Données

Éditer `includes/product.rpgleinc` :

```rpg
// Structures pour l'entité Product
dcl-ds product_detail_t template qualified;
  productno char(10);
  productName varchar(50);
  description varchar(200);
  category varchar(30);
  price packed(9:2);
  stock int(10);
  active char(1);
end-ds;

dcl-ds product_item_t template qualified;
  productno char(10);
  productName varchar(50);
  category varchar(30);
  price packed(9:2);
  stock int(10);
  active char(1);
end-ds;

dcl-ds product_input_t template qualified;
  productName varchar(50);
  description varchar(200);
  category varchar(30);
  price packed(9:2);
  stock int(10);
  active char(1);
end-ds;
```

#### 3.2 Adapter les Requêtes SQL

Éditer `src/product/product.sqlrpgle` pour ajuster les requêtes selon votre table :

```rpg
// Exemple de requête search adaptée
dcl-s lSQL varchar(2000);

lSQL = 'SELECT productno, productName, category, price, stock, active ' +
       'FROM PRODUCT ' +
       'WHERE 1=1 ';

// Ajouter les filtres dynamiques selon CMAGIC_context
```

#### 3.3 Adapter les Routes

Éditer `src/product/product.route.sqlrpgle` :

```rpg
// Configuration des routes pour Product
il_addRoute(router : %addr(product_getProducts) : IL_GET : '/api/products');
il_addRoute(router : %addr(product_getProduct) : IL_GET : '/api/products/:id');
il_addRoute(router : %addr(product_createProduct) : IL_POST : '/api/products');
il_addRoute(router : %addr(product_updateProduct) : IL_PUT : '/api/products/:id');
il_addRoute(router : %addr(product_deleteProduct) : IL_DELETE : '/api/products/:id');
```

### **ÉTAPE 4 : Intégration dans le Serveur Principal**

#### 4.1 Modifier le Module Principal

Éditer `src/main/main.sqlrpgle` pour ajouter les routes Product :

```rpg
// Ajouter l'include
/include 'includes/product.rpgleinc'

// Dans la procédure de configuration
product_setupRoutes(router);
```

#### 4.2 Mise à jour du Build

Éditer `src/Rules.mk` si nécessaire pour inclure le nouveau module dans le build.

### **ÉTAPE 5 : Tests et Validation**

#### 5.1 Build sur IBM i

```bash
# Se connecter à IBM i
ssh user@your-ibmi

# Aller dans le répertoire
cd /path/to/applicationTemplate

# Pull des modifications
git pull origin feature/api-product

# Build avec BOB
bob --build src/product

# Vérifier le succès
echo $?  # Doit retourner 0
```

#### 5.2 Tests Fonctionnels

```bash
# Test 1: Vérifier que l'API répond
curl -I "http://your-ibmi:44000/api/products"

# Test 2: Collection avec pagination
curl "http://your-ibmi:44000/api/products?_page=1&_limit=10"

# Test 3: Récupération d'un élément
curl "http://your-ibmi:44000/api/products/PROD001"

# Test 4: Création d'un nouveau produit
curl -X POST "http://your-ibmi:44000/api/products" \
  -H "Content-Type: application/json" \
  -d '{"productName":"Test Product","category":"TEST","price":99.99}'
```

#### 5.3 Script de Test Automatisé

Créer `test_product_api.ps1` :

```powershell
# Tests automatisés pour l'API Product
param(
    [string]$BaseUrl = "http://your-ibmi:44000"
)

Write-Host "🧪 Testing Product API..." -ForegroundColor Yellow

# Test collection
$response = Invoke-RestMethod -Uri "$BaseUrl/api/products" -Method Get
Write-Host "✅ Collection: $($response.Count) products found"

# Test avec header X-Total-Count
$headers = Invoke-WebRequest -Uri "$BaseUrl/api/products" -Method Head
$totalCount = $headers.Headers["X-Total-Count"]
Write-Host "✅ Total-Count header: $totalCount"

# Test pagination
$paged = Invoke-RestMethod -Uri "$BaseUrl/api/products?_page=1&_limit=5" -Method Get
Write-Host "✅ Pagination: $($paged.Count) products in page 1"

Write-Host "🎉 All tests passed!" -ForegroundColor Green
```

### **ÉTAPE 6 : Documentation et Finalisation**

#### 6.1 Mettre à Jour la Documentation

Créer `src/product/README.md` :

```markdown
# API Product

Routes disponibles :
- GET /api/products - Liste des produits
- GET /api/products/{id} - Détail d'un produit
- POST /api/products - Création d'un produit
- PUT /api/products/{id} - Modification d'un produit  
- DELETE /api/products/{id} - Suppression d'un produit

## Filtres supportés
- category=valeur
- category_like=pattern
- price_gte=montant
- price_lte=montant
- active=Y/N
```

#### 6.2 Commit et Push

```powershell
# Ajouter tous les fichiers
git add -A

# Commit avec message descriptif
git commit -m "feat(api): implement Product REST API

- Add complete Product resource structure
- Support standard REST operations (CRUD)
- Compatible with React-Admin data provider
- Includes advanced filtering capabilities
- Tests validate all endpoints

Closes #123"

# Push vers GitHub
git push origin feature/api-product
```

#### 6.3 Créer une Pull Request

1. Aller sur GitHub
2. Créer une Pull Request depuis `feature/api-product` vers `employee_rest`
3. Remplir le template avec :
   - Description des changements
   - Résultats des tests
   - Checklist de validation

---

## 🔧 SCRIPTS ET OUTILS DISPONIBLES

### Scripts Principaux

| Script | Usage | Description |
|--------|-------|-------------|
| `Create-FeatureBranch.ps1` | Création branche + structure | Script tout-en-un |
| `generate_resource.ps1` | Génération code | Génère tous les fichiers RPG |
| `validate_api_pattern.sh` | Validation | Vérifie conformité aux patterns |

### Scripts de Test

| Script | Usage | Description |
|--------|-------|-------------|
| `test_employee_api_conformity.ps1` | Référence | Tests pour Employee (modèle) |
| `GUIDE_BUILD_TEST_PHASE2.md` | Build/Test | Procédures de validation |

### Templates et Exemples

- **Modèle de référence** : `src/employee/` (structure validée)
- **Documentation patterns** : `ressources/docs/copilotInstructions/`
- **Tests Bruno** : `tests/bruno/` (tests API automatisés)

---

## 📚 RESSOURCES ET RÉFÉRENCES

### Documentation Obligatoire

1. **`ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`**
   - Patterns REST complets
   - Structures CMAGIC
   - Format JSON standard

2. **`CHECKLIST_EMPLOYEE_API_CONFORMITY.md`**
   - Critères de validation
   - Points de contrôle

3. **`src/employee/README.md`**
   - Exemple d'implémentation validée

### Guides Spécialisés

- **Filtres avancés** : `CHECKLIST_PHASE2_FILTRES_AVANCES.md`
- **Build et déploiement** : `GUIDE_BUILD_TEST_PHASE2.md`
- **CORS** : `GUIDE_PLUGIN_CORS_ILEASTIC.md`

---

## ⚡ CHECKLIST RAPIDE

### Avant de Commencer
- [ ] Branche `employee_rest` à jour
- [ ] Table DB2 créée et accessible
- [ ] Spécifications des champs définies

### Pendant le Développement
- [ ] Script `Create-FeatureBranch.ps1` exécuté
- [ ] Générateur `generate_resource.ps1` utilisé
- [ ] Structures adaptées aux besoins
- [ ] Routes ajoutées au serveur principal

### Tests de Validation
- [ ] Build BOB réussi sur IBM i
- [ ] Service ILEastic démarré
- [ ] Collection GET retourne un tableau JSON
- [ ] Header X-Total-Count présent
- [ ] Pagination fonctionnelle
- [ ] CRUD operations testées

### Finalisation
- [ ] Documentation à jour
- [ ] Tests automatisés créés
- [ ] Commit avec message descriptif
- [ ] Pull Request créée

---

## 🚨 POINTS CRITIQUES

1. **Header X-Total-Count** : Obligatoire pour la pagination
2. **Format JSON** : Collection = tableau, Item = objet
3. **Build BOB** : Doit réussir avant tout test
4. **Convention nommage** : Suivre exactement les patterns Employee
5. **Tests exhaustifs** : Valider chaque endpoint avant merge

---

**🎯 OBJECTIF : Suivre ce guide garantit une API conforme aux standards du projet et compatible avec tous les outils low-code modernes.**