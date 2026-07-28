# Guide Pratique : Créer une Nouvelle API REST

> **Basé sur le pattern validé `ibmi_rest_api_instructions.md`**

## 🎯 **Checklist Rapide (2 heures)**

### **1. Préparation (10 min)**
```bash
# Copier template Employee (sur machine de développement ou IBM i)  
cp -r src/employee src/[nouvelle-ressource]
cd src/[nouvelle-ressource]

# Renommer fichiers
mv employee.* [ressource].*
mv employee.main.rpgle [ressource].main.rpgle
mv employee.rest.sqlrpgle [ressource].rest.sqlrpgle  
mv employee.route.sqlrpgle [ressource].route.sqlrpgle
mv employee.sqlrpgle [ressource].sqlrpgle
mv employee.bnd [ressource].bnd

# Copier include
cp includes/employee.rpgleinc includes/[ressource].rpgleinc
```

### **2. Adaptation Structures (30 min)**
```rpg
// filepath: includes/[ressource].rpgleinc
// Adapter selon table DB2

/if not defined([RESSOURCE]_INCLUDE)
/define [RESSOURCE]_INCLUDE

// Structure détaillée (pour GET /api/[ressource]/id)
dcl-ds [ressource]_detail_t template qualified;
  id likeds(GLOBAL_id);
  // ... champs spécifiques selon table DB2
  nom varchar(50);
  email varchar(100);
  dateCreation timestamp;
end-ds;

// Structure liste (pour GET /api/[ressource])
dcl-ds [ressource]_item_t template qualified;
  id likeds(GLOBAL_id);
  // ... sous-ensemble des champs (optimisation performance)
  nom varchar(50);
  email varchar(100);
end-ds;

// Structure pour création/modification
dcl-ds [ressource]_input_t template qualified;
  // ... champs modifiables (sans id, dates auto)
  nom varchar(50);
  email varchar(100);
end-ds;

/endif
```

### **3. Adaptation SQL (45 min)**
```rpg
// Dans [ressource].sqlrpgle

dcl-proc [ressource]_search export;
  dcl-pi [ressource]_search likeds(searchResult_t);
    filters likeds(searchFilters_t) const;
  end-pi;
  
  dcl-s lSelect varchar(1000);
  dcl-s lFrom varchar(200);
  dcl-s lWhere varchar(2000) inz('');
  dcl-s lOrderBy varchar(200) inz('');
  
  // Adapter selon votre table
  lSelect = 'select [id], [nom], [email], [datecreation] from [VOTRE_TABLE]';
  
  // Dans setupFilters - liste champs filtrables
  supportedFields(1) = '[champ1]';      // Ex: 'custno'
  supportedFields(2) = '[champ2]';      // Ex: 'custname'  
  supportedFields(3) = '[champ3]';      // Ex: 'email'
  supportedFields(4) = '[champ4]';      // Ex: 'city'
  // ...
  
  // Champs pour tri
  sortableFields(1) = '[champ1]';
  sortableFields(2) = '[champ2]';
  // ...
  
  // Champs pour recherche textuelle (opérateur q=)
  searchableFields(1) = '[champ_text1]'; // Ex: 'custname'
  searchableFields(2) = '[champ_text2]'; // Ex: 'email'
  // ...
end-proc;

dcl-proc [ressource]_getById export;
  dcl-pi [ressource]_getById likeds([ressource]_detail_t);
    id likeds(GLOBAL_id) const;
  end-pi;
  
  dcl-s lSelect varchar(1000);
  
  // SELECT complet pour détail
  lSelect = 'select [tous_les_champs] from [VOTRE_TABLE] where [id_field] = ?';
  
  // ... logique récupération
end-proc;
```

### **4. Adaptation Routes (30 min)**
```rpg
// Dans [ressource].route.sqlrpgle

dcl-proc [ressource]_setupRoutes export;
  dcl-pi [ressource]_setupRoutes;
    router pointer value;
  end-pi;
  
  // Routes CRUD standard
  il_addRoute(router : IL_GET    : '/api/[ressources]'     : %paddr('[ressource]_getCollection'));
  il_addRoute(router : IL_GET    : '/api/[ressources]/:id' : %paddr('[ressource]_getItem'));
  il_addRoute(router : IL_POST   : '/api/[ressources]'     : %paddr('[ressource]_create'));
  il_addRoute(router : IL_PUT    : '/api/[ressources]/:id' : %paddr('[ressource]_update'));
  il_addRoute(router : IL_DELETE : '/api/[ressources]/:id' : %paddr('[ressource]_delete'));
  
  // Routes actions métier (optionnel)
  il_addRoute(router : IL_POST : '/api/[ressources]/:id/[action]' : %paddr('[ressource]_[action]'));
end-proc;
```

### **5. Compilation & Tests (20 min)**

#### **Build avec BOB**
```bash
# Sur IBM i via SSH
cd /home/[user]/projects/applicationTemplate

# Build de la nouvelle ressource
makei build -l src/[ressource]

# Ou build incrémental si déjà compilé avant
makei build -t [RESSOURCE].SRVPGM
```

#### **Tests de Validation API**
```bash
# Test 1: Collection accessible
curl "http://server:44000/api/[ressources]"

# Test 2: Pagination
curl "http://server:44000/api/[ressources]?_page=1&_limit=5"

# Test 3: Item individuel
curl "http://server:44000/api/[ressources]/[id]"

# Test 4: Header X-Total-Count présent
curl -I "http://server:44000/api/[ressources]"

# Test 5: Filtres exacts
curl "http://server:44000/api/[ressources]?[champ]=valeur"

# Test 6: Filtres avancés
curl "http://server:44000/api/[ressources]?[champ]_gte=valeur"
curl "http://server:44000/api/[ressources]?[champ]_like=pattern"

# Test 7: Recherche texte
curl "http://server:44000/api/[ressources]?q=terme"

# Test 8: Création
curl -X POST "http://server:44000/api/[ressources]" \
  -H "Content-Type: application/json" \
  -d '{"[champ]": "valeur"}'
```

## 🚀 **Exemple Concret : Customer API**

### **Fichiers à Créer/Modifier**
```
src/customer/
├── customer.main.rpgle          # Point d'entrée
├── customer.route.sqlrpgle      # Définition routes
├── customer.rest.sqlrpgle       # Handlers HTTP
├── customer.sqlrpgle            # Logique métier + SQL
├── customer.bnd                 # Binding source
└── Rules.mk                     # Règles compilation

includes/
└── customer.rpgleinc            # Structures de données
```

### **Structure Customer**
```rpg
// filepath: includes/customer.rpgleinc

/if not defined(CUSTOMER_INCLUDE)
/define CUSTOMER_INCLUDE

dcl-ds customer_detail_t template qualified;
  id likeds(GLOBAL_id);
  custno varchar(6);
  custname varchar(50);
  email varchar(100);
  phone varchar(20);
  address varchar(200);
  city varchar(50);
  zipcode varchar(10);
  creditLimit packed(9:2);
  created timestamp;
  updated timestamp;
end-ds;

dcl-ds customer_item_t template qualified;
  id likeds(GLOBAL_id);
  custno varchar(6);
  custname varchar(50);
  email varchar(100);
  city varchar(50);
  creditLimit packed(9:2);
end-ds;

dcl-ds customer_input_t template qualified;
  custname varchar(50);
  email varchar(100);
  phone varchar(20);
  address varchar(200);
  city varchar(50);
  zipcode varchar(10);
  creditLimit packed(9:2);
end-ds;

/endif
```

### **SQL Customer** 
```rpg
// Dans customer.sqlrpgle

dcl-proc customer_search export;
  dcl-pi customer_search likeds(searchResult_t);
    filters likeds(searchFilters_t) const;
  end-pi;
  
  // SELECT optimisé pour liste
  lSelect = 'select custno, custname, email, city, creditlimit ' +
            'from customer';
  
  // Champs filtrables
  supportedFields(1) = 'custno';
  supportedFields(2) = 'custname';
  supportedFields(3) = 'email';
  supportedFields(4) = 'city';
  supportedFields(5) = 'creditlimit';
  
  // Champs pour tri
  sortableFields(1) = 'custno';
  sortableFields(2) = 'custname';
  sortableFields(3) = 'creditlimit';
  
  // Champs pour recherche textuelle
  searchableFields(1) = 'custname';
  searchableFields(2) = 'email';
end-proc;

dcl-proc customer_getById export;
  dcl-pi customer_getById likeds(customer_detail_t);
    id likeds(GLOBAL_id) const;
  end-pi;
  
  // SELECT complet pour détail
  lSelect = 'select * from customer where custno = ?';
end-proc;
```

### **Tests Customer**
```bash
# Collection avec pagination
curl "http://server:44000/api/customers?_page=1&_limit=10"

# Filtres par ville  
curl "http://server:44000/api/customers?city=PARIS"

# Filtres par limite de crédit
curl "http://server:44000/api/customers?creditlimit_gte=10000"

# Recherche par nom
curl "http://server:44000/api/customers?q=DUPONT"

# Tri par nom
curl "http://server:44000/api/customers?_sort=custname&_order=ASC"

# Détail client
curl "http://server:44000/api/customers/000001"

# Création client
curl -X POST "http://server:44000/api/customers" \
  -H "Content-Type: application/json" \
  -d '{
    "custname": "Nouveau Client",
    "email": "client@example.com",
    "city": "PARIS",
    "creditlimit": 15000
  }'
```

## ⚡ **Pattern Réutilisable**

### **Template Générique**
Pour chaque nouvelle ressource, suivre cette séquence :

1. **Analyser** : Structure table DB2
2. **Copier** : Template Employee
3. **Renommer** : Tous les fichiers/fonctions
4. **Adapter** : Structures selon table
5. **Modifier** : SQL SELECT + champs filtrables
6. **Tester** : cURL + validation pattern
7. **Documenter** : README spécifique

### **Temps Estimés**
| Étape | Temps | Détail |
|-------|-------|--------|
| **Préparation** | 10 min | Copie + renommage |
| **Structures** | 30 min | Adaptation selon DB2 |
| **SQL** | 45 min | Requêtes + filtres |
| **Routes** | 30 min | Configuration endpoints |
| **Compilation & Tests** | 20 min | BOB build + validation cURL |
| **TOTAL** | **2h15** | **API complète** |

### **Optimisations Possibles**
- **Script de génération** : Réduire à 30 min
- **Templates paramétrés** : Réduire à 15 min
- **Générateur CMagic** : Réduire à 2 min

## 📋 **Checklist Validation Complète**

### **Tests Obligatoires**
- [ ] GET /api/[ressources] retourne tableau JSON
- [ ] Header X-Total-Count présent dans réponse collection
- [ ] Pagination fonctionne (_page, _limit)
- [ ] Tri fonctionne (_sort, _order)
- [ ] Filtres simples fonctionnent (field=value)
- [ ] Filtres avancés fonctionnent (_gte, _lte, _like, _ne)
- [ ] Recherche textuelle fonctionne (q=terme)
- [ ] GET /api/[ressources]/[id] retourne objet JSON
- [ ] POST, PUT, DELETE fonctionnent avec données valides
- [ ] Codes de statut HTTP corrects (200, 201, 404, 400, 500)
- [ ] Headers CORS configurés si nécessaire

### **Tests Performance**
- [ ] Temps de réponse < 200ms pour collection (1000 records)
- [ ] Temps de réponse < 100ms pour item unique
- [ ] Pagination efficace (OFFSET/LIMIT optimisé)
- [ ] Index sur champs filtrables fréquents

### **Tests Intégration**
- [ ] Data Provider React-Admin fonctionne
- [ ] Compatible ra-data-simple-rest
- [ ] Tests avec Appsmith/Retool (optionnel)
- [ ] Import/export données possible

### **Documentation**
- [ ] README spécifique à la ressource
- [ ] Exemples cURL complets
- [ ] Structure de données documentée
- [ ] Actions métier documentées

## 🛠️ **Scripts Utiles**

### **Script Validation Automatique**
```bash
#!/bin/bash
# validate_new_api.sh [resource_name]

RESOURCE=$1
BASE_URL="http://your-ibmi:44000/api"

echo "🔍 Validation API $RESOURCE"
echo "=========================="

# Test 1: Collection accessible
echo "Test 1: Collection..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/$RESOURCE")
if [ "$STATUS" = "200" ]; then
    echo "✅ Collection accessible"
else
    echo "❌ Collection inaccessible (Status: $STATUS)"
fi

# Test 2: Header X-Total-Count
echo "Test 2: Header X-Total-Count..."
HEADERS=$(curl -s -I "$BASE_URL/$RESOURCE")
if echo "$HEADERS" | grep -i "x-total-count" > /dev/null; then
    echo "✅ X-Total-Count présent"
else
    echo "❌ X-Total-Count manquant"
fi

# Test 3: Format JSON tableau
echo "Test 3: Format JSON..."
RESPONSE=$(curl -s "$BASE_URL/$RESOURCE?_limit=1")
if echo "$RESPONSE" | jq empty 2>/dev/null && echo "$RESPONSE" | grep -E '^\[.*\]$' > /dev/null; then
    echo "✅ JSON tableau valide"
else
    echo "❌ Format JSON incorrect"
fi

# Test 4: Pagination
echo "Test 4: Pagination..."
PAGE1=$(curl -s "$BASE_URL/$RESOURCE?_page=1&_limit=2")
PAGE2=$(curl -s "$BASE_URL/$RESOURCE?_page=2&_limit=2")
if [ "$PAGE1" != "$PAGE2" ]; then
    echo "✅ Pagination fonctionnelle"
else
    echo "❌ Pagination ne fonctionne pas"
fi

echo ""
echo "🎯 Validation $RESOURCE terminée!"
```

### **Générateur Squelette (Futur)**
```bash
#!/bin/bash
# generate_api.sh [resource_name] [table_name]

RESOURCE=$1
TABLE=$2

echo "🏗️ Génération API $RESOURCE basée sur table $TABLE"

# Copier template
cp -r src/employee src/$RESOURCE
cd src/$RESOURCE

# Renommer fichiers
for file in employee.*; do
    mv "$file" "${file/employee/$RESOURCE}"
done

# Remplacer dans fichiers
find . -type f -name "*.rpgle" -o -name "*.rpgleinc" | xargs sed -i "s/employee/$RESOURCE/g"
find . -type f -name "*.rpgle" -o -name "*.rpgleinc" | xargs sed -i "s/EMPLOYEE/${RESOURCE^^}/g"

echo "✅ Squelette API $RESOURCE généré"
echo "📝 Prochaines étapes :"
echo "   1. Adapter includes/$RESOURCE.rpgleinc selon table $TABLE"
echo "   2. Modifier SQL dans $RESOURCE.sqlrpgle"
echo "   3. Tester avec validate_new_api.sh $RESOURCE"
```

## 🎯 **Prochaines Évolutions**

### **Générateur Automatique (Sprint 3)**
- **Analyseur DB2** : Extract structure table automatiquement
- **Génération structures** : Types RPG selon colonnes DB2
- **Génération SQL** : SELECT automatique selon métadonnées
- **Tests auto** : Génération tests cURL selon API

### **Templates Avancés**
- **Actions métier** : Templates pour actions custom
- **Relations** : Support foreign keys et joins
- **Validations** : Templates contraintes métier
- **Audit** : Templates logging et historique

### **Intégration CMagic DSL**
```cmagic
entity Customer {
    custno: String(6) primary,
    custname: String(50) required,
    email: Email,
    creditLimit: Decimal(9,2) default(0),
    
    // → Génère automatiquement customer.*.rpgle
    // → Selon ce pattern validé
}
```

---

**Ce guide est basé sur le pattern éprouvé documenté dans `ibmi_rest_api_instructions.md` et permet de créer rapidement des APIs REST standardisées et cohérentes.**