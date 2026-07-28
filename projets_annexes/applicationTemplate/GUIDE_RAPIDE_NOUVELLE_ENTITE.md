# 🚀 Guide Rapide - Création Nouvelle Entité API

> **Guide express pour créer une nouvelle entité Product en 5 minutes**

---

## ⚡ MÉTHODE RAPIDE - Script Tout-en-Un

### Une Seule Commande
```powershell
# Création complète de l'entité Product
.\scripts\Create-NewEntity.ps1 -EntityName "product" -TableName "PRODUCT" -IdType "char(10)"
```

**Cette commande fait automatiquement :**
- ✅ Création branche `feature/api-product`
- ✅ Génération structure RPG complète
- ✅ Création documentation et tests
- ✅ Commit initial

### Résultat Obtenu
```
src/product/
├── product.sqlrpgle          # Logique métier + SQL
├── product.rest.sqlrpgle     # Handlers HTTP/JSON
├── product.route.sqlrpgle    # Configuration routes
├── product.bnd               # Binding
└── README.md                 # Doc complète

includes/
└── product.rpgleinc          # Structures + prototypes

test_product_api.ps1          # Tests automatisés
```

---

## 🛠️ PERSONNALISATION AVANCÉE

### Paramètres Disponibles
```powershell
.\scripts\Create-NewEntity.ps1 `
  -EntityName "customer" `          # Nom entité (singulier)
  -TableName "CUSTOMER" `           # Table DB2
  -PluralName "customers" `         # Pluriel pour routes (optionnel)
  -IdField "custno" `               # Champ ID (optionnel)
  -IdType "int(10)" `               # Type ID (défaut: char(6))
  -BaseBranch "main" `              # Branche de base (défaut: employee_rest)
  -SkipTests                        # Sauter les tests de validation
```

### Exemples Concrets
```powershell
# Entité simple
.\scripts\Create-NewEntity.ps1 -EntityName "department" -TableName "DEPT"

# Entité avec ID numérique
.\scripts\Create-NewEntity.ps1 -EntityName "order" -TableName "ORDERS" -IdType "int(10)"

# Entité avec pluriel personnalisé
.\scripts\Create-NewEntity.ps1 -EntityName "category" -TableName "CATEGORY" -PluralName "categories"
```

---

## 🔧 ÉTAPES MANUELLES REQUISES APRÈS

### 1. Adaptation des Structures (2 min)
```rpg
// Éditer includes/product.rpgleinc
dcl-ds product_detail_t template qualified;
  productno char(10);            // Adapter selon votre table
  productName varchar(50);       // Ajouter vos champs
  description varchar(200);
  price packed(9:2);
  // ... autres champs
end-ds;
```

### 2. Intégration Routes (1 min)
```rpg
// Ajouter dans src/main/main.sqlrpgle
/include 'includes/product.rpgleinc'

// Dans la procédure de setup
product_setupRoutes(router);
```

### 3. Build et Test (2 min)
```bash
# Sur IBM i
bob --build src/product

# Test local
.\test_product_api.ps1 -BaseUrl "http://your-server:44000"
```

---

## 📋 CHECKLIST VALIDATION EXPRESS

```powershell
# Validation rapide - Une seule commande
.\scripts\validate_entity.ps1 -EntityName "product"
```

**Vérifie automatiquement :**
- [x] Fichiers générés présents
- [x] Build BOB réussi
- [x] Routes accessibles
- [x] Format JSON correct
- [x] Headers X-Total-Count

---

## 🎯 ROUTES GÉNÉRÉES AUTOMATIQUEMENT

| Méthode | URL | Fonction |
|---------|-----|----------|
| `GET` | `/api/products` | Liste avec pagination |
| `GET` | `/api/products/{id}` | Détail d'un produit |
| `POST` | `/api/products` | Création |
| `PUT` | `/api/products/{id}` | Modification |
| `DELETE` | `/api/products/{id}` | Suppression |

**Paramètres supportés :**
- `_page`, `_limit` - Pagination
- `_sort`, `_order` - Tri
- `fieldname=value` - Filtres exacts
- `fieldname_like=pattern` - Filtres LIKE
- `q=terme` - Recherche globale

---

## 🚀 WORKFLOW COMPLET (5 minutes)

```powershell
# 1. Créer l'entité (2 min)
.\scripts\Create-NewEntity.ps1 -EntityName "product" -TableName "PRODUCT"

# 2. Adapter les structures (1 min)
# Éditer includes/product.rpgleinc selon vos besoins

# 3. Intégrer au serveur (30 sec)
# Ajouter product_setupRoutes(router) dans main.sqlrpgle

# 4. Build et test (1.5 min)
# Sur IBM i : bob --build src/product
# Test : .\test_product_api.ps1

# 5. Push et PR (30 sec)
git push -u origin feature/api-product
# Créer Pull Request sur GitHub
```

---

## 💡 TIPS ET BONNES PRATIQUES

### Conventions de Nommage
- **Entité** : singulier, lowercase (`product`)
- **Table** : uppercase (`PRODUCT`)
- **Routes** : pluriel (`/api/products`)
- **Champ ID** : `[entity]no` (`productno`)

### Structure Recommandée
```rpg
// Toujours 3 structures par entité
[entity]_detail_t    // Détail complet (GET /api/entity/{id})
[entity]_item_t      // Liste résumée (GET /api/entity)
[entity]_input_t     // Saisie (POST/PUT)
```

### Tests Indispensables
```bash
# Les 4 tests critiques
curl "http://server:44000/api/products"                    # Collection
curl -I "http://server:44000/api/products"                 # Header X-Total-Count
curl "http://server:44000/api/products?_page=1&_limit=5"   # Pagination
curl "http://server:44000/api/products/PROD001"            # Item
```

---

## 📚 RESSOURCES ET SCRIPTS

### Scripts Principaux
- `Create-NewEntity.ps1` - **Script tout-en-un** (recommandé)
- `generate_resource.ps1` - Génération structure seulement
- `Create-FeatureBranch.ps1` - Gestion Git + génération

### Documentation de Référence
- `GUIDE_CREATION_NOUVELLE_ENTITE.md` - Guide complet détaillé
- `CHECKLIST_NOUVELLE_ENTITE.md` - Checklist de validation
- `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md` - Patterns techniques

### Modèles et Exemples
- `src/employee/` - **Modèle de référence validé**
- `test_employee_api_conformity.ps1` - Tests de référence

---

## 🏆 RÉSULTAT FINAL

Après 5 minutes, vous avez :
- ✅ API REST complète et fonctionnelle
- ✅ Compatible React-Admin, Appsmith, Retool
- ✅ Pagination, tri, filtres avancés
- ✅ Documentation complète
- ✅ Tests automatisés
- ✅ Build validé sur IBM i

**🎯 L'entité est prête pour l'intégration dans vos applications low-code !**

---

**💡 Astuce Copilot :**
```
@workspace Utilise Create-NewEntity.ps1 pour créer l'entité "invoice" avec table "INVOICES" et ID numérique int(10)
```