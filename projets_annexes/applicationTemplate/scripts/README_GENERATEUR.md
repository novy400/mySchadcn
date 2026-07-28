# 🚀 Générateur de Ressources API REST

> Script PowerShell pour générer automatiquement une nouvelle ressource API REST conforme aux conventions ArchiAPI

## 📋 Vue d'Ensemble

Le script `generate_resource.ps1` génère tous les fichiers nécessaires pour une nouvelle ressource API REST en suivant **exactement** les conventions validées de `src/employee`.

### **Fichiers Générés**

```
src/[resource]/
├── [resource].sqlrpgle          # Module métier (CRUD + SQL)
├── [resource].rest.sqlrpgle     # Module REST (handlers HTTP/JSON)
├── [resource].route.sqlrpgle    # Configuration routes ILEastic
├── [resource].bnd               # Binding source avec versioning
├── Rules.mk                     # Configuration build
└── README.md                    # Documentation spécifique

includes/
└── [resource].rpgleinc          # Structures + prototypes
```

## 🎯 Usage

### **Commande Basique**

```powershell
.\scripts\generate_resource.ps1 -Name "product" -Table "PRODUCT"
```

**Génère:**
- Routes: `/api/products`
- ID: `productno` (char(6))
- Structures: `product_detail_t`, `product_item_t`
- Procédures: `product_search`, `product_getByID`, `product_create`, `product_update`, `product_delete`

### **Commande Avancée**

```powershell
.\scripts\generate_resource.ps1 `
  -Name "customer" `
  -Table "CUSTOMER" `
  -PluralName "customers" `
  -IdField "custid" `
  -IdType "int(10)"
```

## 📝 Paramètres

| Paramètre | Type | Obligatoire | Description | Exemple |
|-----------|------|-------------|-------------|---------|
| `-Name` | String | ✅ | Nom ressource (singulier) | `"product"` |
| `-Table` | String | ✅ | Nom table DB2 | `"PRODUCT"` |
| `-PluralName` | String | ❌ | Nom pluriel routes | `"products"` |
| `-IdField` | String | ❌ | Nom champ ID DB2 | `"prodid"` |
| `-IdType` | String | ❌ | Type RPG du champ ID | `"char(6)"` ou `"int(10)"` |
| `-OutputDir` | String | ❌ | Répertoire sortie | `"src/myresource"` |

### **Valeurs par Défaut**

- **PluralName**: Auto-généré (`product` → `products`, `category` → `categories`)
- **IdField**: `[name]no` (ex: `productno`, `customerno`)
- **IdType**: `char(6)` (compatible IBM i standard)
- **OutputDir**: `src/[name]`

## 🏗️ Structure Générée

### **1. Module Métier ([resource].sqlrpgle)**

```rpg
dcl-proc product_search export;        // ✅ Recherche paginée
dcl-proc product_getByID export;       // ✅ Détail par ID
dcl-proc product_create export;        // ✅ Création
dcl-proc product_update export;        // ✅ Mise à jour
dcl-proc product_delete export;        // ✅ Suppression
dcl-proc product_isValid export;       // ✅ Validation
dcl-proc product_getSupportedFields;   // ✅ Config filtres
```

**Fonctionnalités:**
- ✅ Gestion erreurs avec `monitor`/`on-error`
- ✅ Logging via `CKOOL_logMessage`
- ✅ Liste chaînée (llist) pour collections
- ✅ Support filtres CMAGIC
- ✅ Curseurs SQL optimisés

### **2. Module REST ([resource].rest.sqlrpgle)**

```rpg
dcl-proc product_getlist_rest export;  // GET /api/products
dcl-proc product_getone_rest export;   // GET /api/products/{id}
dcl-proc product_create_rest export;   // POST /api/products
dcl-proc product_update_rest export;   // PUT /api/products/{id}
dcl-proc product_delete_rest export;   // DELETE /api/products/{id}
```

**Fonctionnalités:**
- ✅ Framework CREST pour validation
- ✅ Headers standard (CORS, X-Total-Count)
- ✅ Status HTTP corrects (200, 201, 404, 400, 500)
- ✅ Transactions SQL (COMMIT/ROLLBACK)
- ✅ Conversion JSON (TODO: à implémenter)

### **3. Module Routes ([resource].route.sqlrpgle)**

```rpg
dcl-proc product_setupRoutes export;
dcl-proc product_registerAPI export;
```

**Configuration:**
- Routes CRUD complètes
- Patterns regex ILEastic
- Logging enregistrement

### **4. Structures ([resource].rpgleinc)**

```rpg
dcl-ds product_detail_t template qualified;
  dcl-ds id;
    code char(6);  // ou type personnalisé
  end-ds;
  // TODO: Ajouter champs table
end-ds;

dcl-ds product_item_t template qualified;
  id likeDS(product_detail_t.id);
  // TODO: Champs liste
end-ds;
```

**Conventions:**
- ✅ ID imbriqué `id.code`
- ✅ Suffixe `_t` pour templates
- ✅ `qualified` pour éviter conflits
- ✅ Prototypes documentés (format JSDoc-like)

### **5. Binding Source ([resource].bnd)**

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('PRODUCT.1.0.0')
  EXPORT SYMBOL('product_search')
  EXPORT SYMBOL('product_getByID')
  EXPORT SYMBOL('product_create')
  EXPORT SYMBOL('product_update')
  EXPORT SYMBOL('product_delete')
  EXPORT SYMBOL('product_isValid')
  EXPORT SYMBOL('product_getSupportedFields')
ENDPGMEXP
```

**Conventions:**
- ✅ Versioning avec PGMLVL
- ✅ Signature format `[RESOURCE].[MAJOR].[MINOR].[PATCH]`
- ✅ Seulement procédures métier exportées

## 📚 Exemple Complet

### **Génération**

```powershell
cd c:\Users\giyvovie\Documents\mesProjets\archiapi\applicationTemplate

.\scripts\generate_resource.ps1 -Name "product" -Table "PRODUCT"
```

**Sortie:**
```
🚀 Génération ressource API REST
=================================
Ressource    : product
Table DB2    : PRODUCT
Routes API   : /api/products
Champ ID     : productno (char(6))
Destination  : c:\...\src\product

✅ Répertoire créé: src\product
✅ Généré: product.sqlrpgle
✅ Généré: product.rest.sqlrpgle
✅ Généré: product.route.sqlrpgle
✅ Généré: includes\product.rpgleinc
✅ Généré: product.bnd
✅ Généré: Rules.mk
✅ Généré: README.md

🎉 Génération terminée avec succès!
```

### **Complétion**

1. **Éditer structures** (`includes/product.rpgleinc`):
   ```rpg
   dcl-ds product_detail_t template qualified;
     dcl-ds id;
       code char(6);
     end-ds;
     description varchar(100);
     price packed(9:2);
     category varchar(50);
     inStock int(10);
   end-ds;
   ```

2. **Configurer mapping SQL** (`product.sqlrpgle`):
   ```rpg
   dcl-proc product_getSupportedFields export;
     pSupportedFields.supportedFields(1).name = 'id';
     pSupportedFields.supportedFields(1).sqlField = 'productno';
     pSupportedFields.supportedFields(1).dataType = typeChamp.STRING;
     
     pSupportedFields.supportedFields(2).name = 'description';
     pSupportedFields.supportedFields(2).sqlField = 'description';
     pSupportedFields.supportedFields(2).dataType = typeChamp.STRING;
     // ...
   end-proc;
   ```

3. **Implémenter SQL** (voir `src/employee/employee.sqlrpgle` comme référence)

4. **Créer fonctions JSON** (voir `emprest.rpgleinc` comme référence)

5. **Compiler**:
   ```bash
   makei build -l src/product
   ```

6. **Enregistrer routes** (dans serveur principal):
   ```rpg
   /include 'productroute.rpgleinc'
   
   product_registerAPI(config);
   ```

7. **Tester**:
   ```bash
   curl "http://server:44000/api/products?_page=1&_limit=10"
   ```

## ✅ Checklist Post-Génération

- [ ] Compléter structures dans `includes/[resource].rpgleinc`
- [ ] Configurer `[resource]_getSupportedFields()` (mapping API ↔ SQL)
- [ ] Implémenter SQL dans `[resource]_search` (filtres/tri/pagination)
- [ ] Implémenter SQL dans `[resource]_create` (INSERT)
- [ ] Implémenter SQL dans `[resource]_update` (UPDATE)
- [ ] Ajouter validations dans `[resource]_isValid`
- [ ] Créer fonctions conversion JSON
- [ ] Compiler: `makei build -l src/[resource]`
- [ ] Enregistrer routes dans serveur principal
- [ ] Tester tous les endpoints (GET, POST, PUT, DELETE)
- [ ] Vérifier header `X-Total-Count` sur collections
- [ ] Tester filtres avancés (`_like`, `_gte`, `_lte`, `q`)
- [ ] Tester pagination (`_page`, `_limit`)
- [ ] Tester tri (`_sort`, `_order`)

## 🎯 Conventions Appliquées

Le code généré respecte **100%** des conventions extraites de `src/employee`:

✅ **Nommage:**
- Procédures: `[resource]_[action]`
- REST: suffixe `_rest`
- Paramètres: préfixe `p`
- Variables locales: préfixe `l`
- Structures: suffixe `_t`

✅ **Patterns:**
- Return `ind` (*ON/*OFF)
- `dcl-pi *N` pour procédures
- ID imbriqué `id.code`
- Monitor/on-error systématique
- Framework CREST
- Liste chaînée llist
- Curseurs SQL avec cleanup

✅ **Standards:**
- Binding avec versioning
- Routes regex ILEastic
- Status HTTP corrects
- Headers CORS + X-Total-Count
- Logging CKOOL

## 📖 Documentation Référence

- **Guide RPG**: `ressources/docs/guides/guide_rpg_bonnes_pratiques.md`
- **Conventions**: `ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md`
- **Code validé**: `src/employee/*`

## 🐛 Troubleshooting

### **Erreur: Permission denied**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Compilation échoue**
- Vérifier que tous les includes existent
- Vérifier binding directories dans `ctl-opt`
- Consulter joblog IBM i

### **Routes non reconnues**
- Vérifier que `[resource]_registerAPI()` est appelé dans serveur
- Redémarrer le service HTTP

## 🚀 Évolutions Futures

- [ ] Option `-FromTable` : extraction automatique schéma DB2
- [ ] Génération tests unitaires automatiques
- [ ] Génération fonctions JSON automatique
- [ ] Support relations entre ressources
- [ ] Support actions métier custom
- [ ] Génération documentation OpenAPI/Swagger

---

**Version**: 1.0  
**Date**: 28 octobre 2025  
**Auteur**: ArchiAPI Team  
**Licence**: Interne
