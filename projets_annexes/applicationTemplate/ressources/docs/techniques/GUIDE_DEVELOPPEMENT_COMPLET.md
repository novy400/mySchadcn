# 🚀 Guide de Développement Complet - ArchiAPI

*Guide complet pour le développement d'APIs REST sur IBM i avec ArchiAPI*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Vue d'Ensemble

Ce guide couvre l'ensemble du processus de développement d'APIs REST modernes sur IBM i, depuis la conception jusqu'au déploiement en production.

### **🏆 Objectifs**
- Créer des APIs REST conformes aux standards modernes
- Intégrer avec React-Admin, Appsmith, Retool
- Utiliser les patterns CMAGIC pour la cohérence
- Automatiser build et déploiement avec BOB

---

## 📋 Prérequis & Environnement

### **🖥️ Environnement de Développement**

#### **Poste de Travail**
- **Windows 10/11** ou **Linux** 
- **Visual Studio Code** avec extensions IBM i
- **Git** pour contrôle de version
- **PowerShell** 7.0+ (recommandé)
- **Node.js** 18+ (pour outils frontend)

#### **IBM i Target**
- **IBM i 7.3+** (recommandé 7.5)
- **ILE RPG** compilateur moderne
- **ILEastic** framework REST
- **BOB** système de build
- **Access IFS** pour développement

#### **Extensions VS Code Essentielles**
```
IBM i Development Pack
├── code-for-ibmi              # Connexion IBM i
├── vscode-rpgle               # Support RPG
├── vscode-db2i                # Base de données
└── gitpod-io.leeway           # Git workflow
```

### **📦 Installation Dépendances**

#### **ILEastic Framework**
```bash
# Sur IBM i
/QOpenSys/pkgs/bin/yum install git
git clone https://github.com/sitemule/ILEastic.git
cd ILEastic
make
```

#### **BOB Build System**
```bash
# Sur poste développeur
npm install -g @bobjs/bob-cli

# Configuration projet
bob init --template ibmi-rest-api
```

---

## 🏗️ Architecture Projet

### **📁 Structure Standard ArchiAPI**

```
applicationTemplate/
├── src/                        # Code source
│   ├── [resource]/            # Ressources API
│   │   ├── [resource].main.rpgle        # Point d'entrée
│   │   ├── [resource].route.sqlrpgle    # Configuration routes
│   │   ├── [resource].rest.sqlrpgle     # Handlers REST
│   │   ├── [resource].sqlrpgle          # Logique métier
│   │   └── [resource].bnd               # Binding
│   ├── cmagic/                # Framework CMAGIC
│   ├── crest/                 # Utilitaires REST
│   └── main/                  # Point d'entrée global
├── includes/                   # Headers & prototypes
├── tests/                     # Tests automatisés
├── scripts/                   # Scripts PowerShell
└── ressources/               # Documentation & données
```

### **🎯 Principes Architecturaux**

#### **1. Séparation des Responsabilités**
| Couche | Responsabilité | Technologies |
|--------|----------------|-------------|
| **Presentation** | HTTP/JSON, Routes | ILEastic |
| **Business** | Logique métier, Validation | RPG ILE |
| **Data** | Accès données, SQL | DB2 for i |
| **Infrastructure** | Configuration, Logging | CMAGIC |

#### **2. Patterns CMAGIC**
```rpg
// Structure contexte standardisée
dcl-ds CMAGIC_context template qualified;
  dcl-ds pagination likeDS(CMAGIC_pagination);
  dcl-ds sort likeDS(CMAGIC_sort) dim(CMAGIC_MAX_SORTS);
  dcl-ds filter likeDS(CMAGIC_filter) dim(CMAGIC_MAX_FILTERS);
  dcl-ds metadata likeDS(CMAGIC_metadata);
end-ds;
```

#### **3. Standards REST**
- **GET collection** → Tableau `[]` + `X-Total-Count`
- **GET item** → Objet `{}`
- **POST** → `201 Created` + objet créé
- **PUT** → `200 OK` + objet mis à jour
- **DELETE** → `200 OK` + objet supprimé

---

## 🔄 Processus de Développement

### **🌟 Workflow Nouvelle Ressource**

#### **Étape 1 : Planification**
```markdown
1. Analyser le besoin métier
2. Définir le modèle de données
3. Identifier les endpoints nécessaires
4. Planifier les filtres et actions
```

#### **Étape 2 : Génération Structure**
```powershell
# Créer feature branch + structure
.\scripts\Create-FeatureBranch.ps1 -ResourceName "products" -IssueNumber "156"
```

#### **Étape 3 : Implémentation**

##### **A. Définir le Modèle (includes/product.rpgleinc)**
```rpg
// Structure détail complet
dcl-ds product_detail_t template qualified;
  id int(10);
  name varchar(100);
  description varchar(500);
  price packed(9:2);
  category_id int(10);
  active ind;
  created_at timestamp;
  updated_at timestamp;
end-ds;

// Structure liste (optimisée)
dcl-ds product_item_t template qualified;
  id int(10);
  name varchar(100);
  price packed(9:2);
  category varchar(50);
  active ind;
end-ds;

// Structure input (création/modification)
dcl-ds product_input_t template qualified;
  name varchar(100);
  description varchar(500);
  price packed(9:2);
  category_id int(10);
  active ind;
end-ds;
```

##### **B. Configurer les Routes (product.route.sqlrpgle)**
```rpg
// Configuration routes REST
dcl-proc product_setupRoutes export;
  dcl-pi *n ind end-pi;
  
  // Collection endpoints
  il_addRoute(%trimr(router) : %trimr(config.uri) + '/products' 
    : IL_GET : %paddr(product_getCollection));
  il_addRoute(%trimr(router) : %trimr(config.uri) + '/products' 
    : IL_POST : %paddr(product_create));
    
  // Item endpoints  
  il_addRoute(%trimr(router) : %trimr(config.uri) + '/products/{id}' 
    : IL_GET : %paddr(product_getItem));
  il_addRoute(%trimr(router) : %trimr(config.uri) + '/products/{id}' 
    : IL_PUT : %paddr(product_update));
  il_addRoute(%trimr(router) : %trimr(config.uri) + '/products/{id}' 
    : IL_DELETE : %paddr(product_delete));
    
  return *ON;
end-proc;
```

##### **C. Implémenter REST Handlers (product.rest.sqlrpgle)**
```rpg
// Handler collection GET
dcl-proc product_getCollection export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-ds context likeDS(CMAGIC_context);
  dcl-s json varchar(32000);
  dcl-s totalCount int(10);
  
  monitor;
    // Parser paramètres REST
    CMAGIC_parseRestParams(request : context);
    
    // Appel logique métier
    product_getCollectionData(context : json : totalCount);
    
    // Headers REST standards
    il_addHttpHeader(response : 'Content-Type' : 'application/json');
    il_addHttpHeader(response : 'X-Total-Count' : %char(totalCount));
    il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
    
    // Réponse
    il_responseWrite(response : %addr(json) : %len(%trimr(json)));
    
    return *ON;
    
  on-error;
    CREST_handleError(response : 'Error fetching products');
    return *OFF;
  endmon;
  
end-proc;
```

##### **D. Logique Métier (product.sqlrpgle)**
```rpg
// Logique collection avec SQL
dcl-proc product_getCollectionData export;
  dcl-pi *n ind;
    context likeDS(CMAGIC_context) const;
    json varchar(32000);
    totalCount int(10);
  end-pi;
  
  dcl-s sql varchar(4000);
  dcl-s whereClause varchar(1000) inz('');
  dcl-s orderClause varchar(200) inz('ORDER BY id');
  
  monitor;
    // 1. Construire WHERE depuis filtres
    CMAGIC_buildWhereClause(context.filter : whereClause);
    
    // 2. Construire ORDER BY depuis tri
    CMAGIC_buildOrderClause(context.sort : orderClause);
    
    // 3. Count total (AVANT pagination)
    sql = 'SELECT COUNT(*) FROM products p ' +
          'LEFT JOIN categories c ON p.category_id = c.id ' +
          whereClause;
    exec sql PREPARE stmt1 FROM :sql;
    exec sql EXECUTE stmt1 INTO :totalCount;
    
    // 4. Données avec pagination
    sql = 'SELECT p.id, p.name, p.price, c.name as category, p.active ' +
          'FROM products p ' +
          'LEFT JOIN categories c ON p.category_id = c.id ' +
          whereClause + ' ' + orderClause + ' ' +
          'LIMIT ' + %char(context.pagination.limit) + ' ' +
          'OFFSET ' + %char(context.pagination.offset);
          
    // 5. Générer JSON depuis résultat
    json = CMAGIC_buildJsonFromQuery(sql : 'product_item_t');
    
    return *ON;
    
  on-error;
    CKOOL_logError('Error in product_getCollectionData: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

#### **Étape 4 : Tests & Validation**
```powershell
# Build
bob --build src/product

# Tests API
.\scripts\Test-ApiEndpoints.ps1 -Resource "product"

# Validation conformité
.\scripts\Validate-RestApi.ps1 -Resource "product"
```

#### **Étape 5 : Documentation**
```powershell
# Génération documentation
.\scripts\Generate-Documentation.ps1 -Resource "product"
```

---

## 🧪 Tests & Qualité

### **🔍 Stratégie de Tests**

#### **Tests Unitaires**
```rpg
// Tests logique métier
dcl-proc test_product_validation export;
  dcl-pi *n ind end-pi;
  
  dcl-ds input likeDS(product_input_t);
  dcl-s isValid ind;
  
  // Test nom requis
  clear input;
  input.name = '';
  isValid = product_validateInput(input);
  assert(isValid = *OFF : 'Name should be required');
  
  // Test prix positif
  input.name = 'Test Product';
  input.price = -10.00;
  isValid = product_validateInput(input);
  assert(isValid = *OFF : 'Price should be positive');
  
  return *ON;
end-proc;
```

#### **Tests d'Intégration**
```bash
# Collection endpoints
curl -X GET "http://server:44000/api/products" \
  -H "Accept: application/json"

# Pagination
curl -X GET "http://server:44000/api/products?_page=1&_limit=10"

# Filtres
curl -X GET "http://server:44000/api/products?name_like=laptop&active=true"

# CRUD complet
curl -X POST "http://server:44000/api/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":99.99,"category_id":1}'
```

#### **Tests Performance**
```powershell
# Load testing avec Artillery
artillery run tests/load/products.yml

# Monitoring réponse
.\scripts\Monitor-ApiPerformance.ps1 -Resource "products" -Duration 300
```

### **📊 Métriques Qualité**

#### **Critères de Succès**
- **Réponse < 100ms** pour collections < 1000 items
- **Couverture tests > 80%** du code métier
- **Conformité REST 100%** (headers, status codes)
- **Build BOB** sans erreurs ni warnings

---

## 🚀 Déploiement & Production

### **📦 Processus de Build**

#### **Build Local**
```powershell
# Build ressource spécifique
bob --build src/product

# Build complet projet
bob --build

# Build avec tests
bob --build --test
```

#### **Configuration Production**
```ini
# bob.config.json
{
  "build": {
    "target": "PROD",
    "library": "ARCHIAPI",
    "optimization": "full"
  },
  "deploy": {
    "server": "IBMI-PROD",
    "library": "ARCHIAPI"
  }
}
```

### **🔄 Pipeline CI/CD**

#### **GitHub Actions**
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build with BOB
        run: bob --build --target=PROD
        
      - name: Run Tests
        run: bob --test
        
      - name: Deploy to IBM i
        run: bob --deploy --environment=PROD
```

### **📊 Monitoring Production**

#### **Métriques Essentielles**
- **Temps de réponse** par endpoint
- **Taux d'erreur** par ressource
- **Utilisation CPU/Mémoire** IBM i
- **Logs d'erreurs** centralisés

#### **Alerting**
```rpg
// Monitoring intégré
dcl-proc CMAGIC_logMetrics export;
  dcl-pi *n;
    endpoint varchar(100) const;
    responseTime int(10) const;
    statusCode int(10) const;
  end-pi;
  
  // Log vers système monitoring
  if responseTime > 1000; // > 1 seconde
    CKOOL_logWarning('Slow response: ' + endpoint + 
      ' took ' + %char(responseTime) + 'ms');
  endif;
  
  if statusCode >= 500;
    CKOOL_logError('Server error: ' + endpoint + 
      ' returned ' + %char(statusCode));
  endif;
  
end-proc;
```

---

## 📚 Bonnes Pratiques

### **💡 Conventions Code**

#### **Nommage**
```rpg
// Ressources : minuscules, pluriel
/api/products
/api/customers
/api/orders

// Procedures : ressource_action
product_getCollection()
customer_validateInput()
order_calculateTotal()

// Variables : camelCase avec préfixe type
dcl-s sProductName varchar(100);
dcl-s nTotalCount int(10);
dcl-s bIsValid ind;
```

#### **Gestion d'Erreurs**
```rpg
// Toujours utiliser monitor/on-error
monitor;
  // Code métier
on-error;
  CKOOL_logError('Error in ' + %proc + ': ' + %str(%error));
  return *OFF;
endmon;

// Messages d'erreur explicites
if not product_exists(productId);
  CREST_sendError(response : 404 : 'Product not found: ' + %char(productId));
  return *OFF;
endif;
```

### **🔒 Sécurité**

#### **Validation Input**
```rpg
// Validation systématique
dcl-proc product_validateInput export;
  dcl-pi *n ind;
    input likeDS(product_input_t) const;
  end-pi;
  
  // Champs requis
  if %len(%trimr(input.name)) = 0;
    return *OFF;
  endif;
  
  // Validation métier
  if input.price <= 0;
    return *OFF;
  endif;
  
  // Injection SQL protection (parameterized queries only)
  // Pas de concaténation directe dans SQL
  
  return *ON;
end-proc;
```

#### **Authentification**
```rpg
// Headers sécurité
il_addHttpHeader(response : 'X-Content-Type-Options' : 'nosniff');
il_addHttpHeader(response : 'X-Frame-Options' : 'DENY');
il_addHttpHeader(response : 'X-XSS-Protection' : '1; mode=block');
```

---

## 🎯 Troubleshooting

### **🔧 Problèmes Fréquents**

#### **Build Errors**
```bash
# Erreur: Module not found
Solution: Vérifier binding sources (.bnd)

# Erreur: Prototype mismatch  
Solution: Synchroniser .rpgleinc avec implémentation

# Erreur: SQL compilation
Solution: Vérifier autorisation QSQL*, syntaxe SQL
```

#### **Runtime Errors**
```bash
# Erreur: X-Total-Count manquant
Solution: Ajouter header + Access-Control-Expose-Headers

# Erreur: Collection retourne objet  
Solution: Vérifier structure JSON, doit être tableau []

# Erreur: 500 Internal Server Error
Solution: Consulter logs IBM i, monitor/on-error
```

### **📊 Debug Tools**

#### **Logging**
```rpg
// Debug logging
if CMAGIC_isDebugMode();
  CKOOL_logDebug('Processing request: ' + %trimr(endpoint));
  CKOOL_logDebug('Parameters: ' + %trimr(params));
endif;
```

#### **Performance Profiling**
```bash
# Profiling SQL
STRDBG PGM(MYLIB/PRODUCT)
ADDPJE PGM(MYLIB/PRODUCT)

# Monitor job
WRKACTJOB SBS(QHTTPSVR)
```

---

## 📖 Ressources Additionnelles

### **🔗 Documentation**
- [ILEastic GitHub](https://github.com/sitemule/ILEastic)
- [BOB Build System](https://github.com/IBM/ibmi-bob)
- [REST API Best Practices](https://restfulapi.net/)

### **🎓 Formation Continue**
- **IBM i Modernization** : Techniques et outils
- **API Design** : Standards et patterns
- **DevOps IBM i** : Automation et CI/CD

---

*Guide maintenu par l'équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*