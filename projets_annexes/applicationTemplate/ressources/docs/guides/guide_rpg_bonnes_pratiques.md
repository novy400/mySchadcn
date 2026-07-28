# Guide RPG ILE - Bonnes Pratiques ArchiAPI

> **Guide de référence pour développeurs RPG ILE et GitHub Copilot**  
> Basé sur les patterns validés de `src/employee`  
> **Version**: 1.0 (Octobre 2025) - Document évolutif

## 🎯 Objectif

Ce guide établit les **conventions RPG ILE** du projet ArchiAPI pour :
- ✅ Assurer la cohérence du code
- ✅ Faciliter la maintenance
- ✅ Optimiser les performances
- ✅ Guider GitHub Copilot
- ✅ Former les nouveaux développeurs

---

## 📐 Architecture Modulaire par Ressource

### **Principe : Séparation des Responsabilités**

Chaque ressource (Employee, Customer, etc.) suit une structure modulaire stricte :

```
src/[resource]/
├── [resource].sqlrpgle          # ⚙️ Logique métier + SQL
├── [resource].rest.sqlrpgle     # 🌐 Handlers HTTP + JSON
├── [resource].route.sqlrpgle    # 🛣️ Configuration routes
├── [resource].main.rpgle        # 🚀 Point d'entrée serveur (optionnel)
├── [resource].bnd               # 🔗 Binding source
└── Rules.mk                     # 🔨 Configuration build
```

### **Responsabilités Claires**

| Module | Rôle | Interdit |
|--------|------|----------|
| **`.sqlrpgle`** | SQL, validation, logique business | Génération JSON, HTTP |
| **`.rest.sqlrpgle`** | Parse HTTP, appels métier, JSON | SQL direct, logique métier |
| **`.route.sqlrpgle`** | Mapping routes ILEastic | Logique métier, SQL |
| **`.main.rpgle`** | Configuration serveur | Logique métier |

---

## 🏗️ Structure d'un Module Métier (`.sqlrpgle`)

### **Template Standard**

```rpg
**free

///
// Module métier [Resource]
//
// @author [Nom]
// @date [Date]
// @version 1.0.0
//
// Responsabilités:
// - Requêtes SQL (CRUD)
// - Validation des données
// - Logique métier
// - Transformations de données
///

ctl-opt nomain;
ctl-opt bnddir('ILEASTIC':'CMAGIC':'CKOOL');

// ⚠️ Includes SANS préfixe 'includes/' (géré par build)
/include '[resource].rpgleinc'
/include 'sqlStates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'cmagic.rpgleinc'
/include 'ckool.rpgleinc'

// ============================================================================
// RECHERCHE AVEC FILTRES
// ============================================================================

dcl-proc [resource]_search export;
  dcl-pi *N ind;                                // ⚠️ Utilise *N dans code réel
    pContext likeDS(CMAGIC_context) const;      // ⚠️ Préfixe 'p' obligatoire
    pTotalCount like(CMAGIC_totalCount);        // OUT
    pItems pointer;                              // OUT liste chaînée
    pErrors likeDS(GLOBAL_listError);           // OUT
  end-pi;

  dcl-ds lErrors likeDS(GLOBAL_listError);     // ⚠️ Préfixe 'l' obligatoire
  dcl-s lSelect varchar(2000);
  dcl-s lWhere varchar(2000) inz('');
  dcl-s lOrderBy varchar(200) inz('');
  dcl-s lLimit varchar(50) inz('');
  dcl-s lTotalCount int(10);

  dcl-s supportedFields varchar(32) dim(20);
  dcl-s sortableFields varchar(32) dim(10);
  dcl-s searchableFields varchar(32) dim(10);

  // Configuration champs filtrables
  setupFilters();

  // Construction requête base
  lSelect = 'SELECT id, field1, field2, field3 FROM [table]';

  // Application filtres
  lWhere = CMAGIC_buildWhereClause(filters : supportedFields : searchableFields);
  if lWhere <> '';
    lSelect += ' WHERE ' + lWhere;
  endif;

  // Comptage total AVANT pagination
  exec sql PREPARE countStmt FROM :lSelect;
  exec sql DECLARE countCursor CURSOR FOR countStmt;
  exec sql OPEN countCursor;
  exec sql FETCH FROM countCursor INTO :lTotalCount;
  exec sql CLOSE countCursor;

  result.totalCount = lTotalCount;

  // Tri
  lOrderBy = CMAGIC_buildOrderByClause(filters : sortableFields);
  if lOrderBy <> '';
    lSelect += ' ORDER BY ' + lOrderBy;
  endif;

  // Pagination
  lLimit = CMAGIC_buildLimitClause(filters);
  if lLimit <> '';
    lSelect += ' LIMIT ' + lLimit;
  endif;

  // Exécution requête paginée
  exec sql PREPARE selectStmt FROM :lSelect;
  exec sql DECLARE selectCursor CURSOR FOR selectStmt;
  exec sql OPEN selectCursor;

  result.data = fetchResults();

  exec sql CLOSE selectCursor;

  return result;

end-proc;

// ============================================================================
// CONFIGURATION FILTRES
// ============================================================================

dcl-proc setupFilters;
  // Champs filtrables (WHERE field = ?)
  supportedFields(1) = 'id';
  supportedFields(2) = 'field1';
  supportedFields(3) = 'field2';
  // ... jusqu'à 20 max

  // Champs triables (ORDER BY)
  sortableFields(1) = 'id';
  sortableFields(2) = 'field1';
  // ... jusqu'à 10 max

  // Champs recherchables (LIKE %?%)
  searchableFields(1) = 'field1';
  searchableFields(2) = 'field2';
  // ... jusqu'à 10 max
end-proc;

// ============================================================================
// RÉCUPÉRATION PAR ID
// ============================================================================

dcl-proc [resource]_getById export;
  dcl-pi [resource]_getById likeds([resource]_detail_t);
    id likeds(GLOBAL_id) const;
  end-pi;

  dcl-ds result likeds([resource]_detail_t);
  dcl-s lSelect varchar(1000);

  lSelect = 'SELECT * FROM [table] WHERE id = ?';

  exec sql PREPARE getStmt FROM :lSelect;
  exec sql EXECUTE getStmt USING :id INTO :result;

  if sqlcode <> 0;
    result.id = 0; // Indique non trouvé
  endif;

  return result;
end-proc;

// ============================================================================
// CRÉATION
// ============================================================================

dcl-proc [resource]_create export;
  dcl-pi [resource]_create likeds([resource]_detail_t);
    input likeds([resource]_input_t) const;
  end-pi;

  dcl-ds result likeds([resource]_detail_t);
  dcl-s newId int(10);

  monitor;
    // Validation des données
    if not validate_input(input);
      result.id = -1; // Erreur validation
      return result;
    endif;

    // Insertion
    exec sql INSERT INTO [table] (field1, field2, created)
             VALUES (:input.field1, :input.field2, CURRENT_TIMESTAMP);

    if sqlcode = 0;
      // Récupération ID généré
      exec sql VALUES IDENTITY_VAL_LOCAL() INTO :newId;
      result = [resource]_getById(newId);
    else;
      CKOOL_logError('Erreur INSERT: ' + %char(sqlcode));
      result.id = -2; // Erreur SQL
    endif;

  on-error;
    CKOOL_logError('Exception [resource]_create: ' + %str(%error));
    result.id = -3; // Erreur exception
  endmon;

  return result;
end-proc;

// ============================================================================
// MISE À JOUR
// ============================================================================

dcl-proc [resource]_update export;
  dcl-pi [resource]_update likeds([resource]_detail_t);
    id likeds(GLOBAL_id) const;
    input likeds([resource]_input_t) const;
  end-pi;

  dcl-ds result likeds([resource]_detail_t);

  monitor;
    // Validation existence
    result = [resource]_getById(id);
    if result.id = 0;
      return result; // Non trouvé
    endif;

    // Validation données
    if not validate_input(input);
      result.id = -1;
      return result;
    endif;

    // Mise à jour
    exec sql UPDATE [table]
             SET field1 = :input.field1,
                 field2 = :input.field2,
                 updated = CURRENT_TIMESTAMP
             WHERE id = :id;

    if sqlcode = 0;
      result = [resource]_getById(id);
    else;
      CKOOL_logError('Erreur UPDATE: ' + %char(sqlcode));
      result.id = -2;
    endif;

  on-error;
    CKOOL_logError('Exception [resource]_update: ' + %str(%error));
    result.id = -3;
  endmon;

  return result;
end-proc;

// ============================================================================
// SUPPRESSION
// ============================================================================

dcl-proc [resource]_delete export;
  dcl-pi [resource]_delete ind;
    id likeds(GLOBAL_id) const;
  end-pi;

  dcl-ds existing likeds([resource]_detail_t);

  monitor;
    // Vérifier existence
    existing = [resource]_getById(id);
    if existing.id = 0;
      return *OFF;
    endif;

    // Suppression
    exec sql DELETE FROM [table] WHERE id = :id;

    if sqlcode = 0;
      return *ON;
    else;
      CKOOL_logError('Erreur DELETE: ' + %char(sqlcode));
      return *OFF;
    endif;

  on-error;
    CKOOL_logError('Exception [resource]_delete: ' + %str(%error));
    return *OFF;
  endmon;

end-proc;

// ============================================================================
// VALIDATION PRIVÉE
// ============================================================================

dcl-proc validate_input;
  dcl-pi validate_input ind;
    input likeds([resource]_input_t) const;
  end-pi;

  // Validation champs obligatoires
  if %len(%trim(input.field1)) = 0;
    CKOOL_logError('Champ field1 obligatoire');
    return *OFF;
  endif;

  // Validation formats
  if not isValidEmail(input.email);
    CKOOL_logError('Email invalide');
    return *OFF;
  endif;

  // Validation contraintes métier
  if input.amount < 0;
    CKOOL_logError('Montant négatif interdit');
    return *OFF;
  endif;

  return *ON;
end-proc;
```

---

## 🌐 Structure d'un Module REST (`.rest.sqlrpgle`)

### **Template Standard**

```rpg
**free

///
// Module REST [Resource]
//
// Responsabilités:
// - Parse requêtes HTTP
// - Génération JSON
// - Gestion erreurs HTTP
// - Appels modules métier
///

ctl-opt nomain;
ctl-opt bnddir('ILEASTIC':'CMAGIC':'CKOOL');

/include 'includes/[resource].rpgleinc'
/include 'includes/ileastic.rpgleinc'
/include 'includes/cmagic.rpgleinc'

// ============================================================================
// GET COLLECTION
// ============================================================================

dcl-proc [resource]_getCollection export;
  dcl-pi [resource]_getCollection;
    request pointer value;
    response pointer value;
  end-pi;

  dcl-ds filters likeds(searchFilters_t);
  dcl-ds result likeds(searchResult_t);
  dcl-s jsonResponse varchar(1000000);

  monitor;
    // Parse paramètres requête
    filters = CMAGIC_parseQueryParams(request);

    // Appel module métier
    result = [resource]_search(filters);

    // Génération JSON
    jsonResponse = CMAGIC_buildJsonArray(result.data);

    // Headers obligatoires
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'X-Total-Count' : %char(result.totalCount));
    il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');

    // Réponse
    il_responseWrite(response : jsonResponse);
    il_responseStatus(response : 200);

  on-error;
    CKOOL_logError('Erreur [resource]_getCollection: ' + %str(%error));
    il_responseWrite(response : '{"error": "Internal server error"}');
    il_responseStatus(response : 500);
  endmon;

end-proc;

// ============================================================================
// GET ITEM
// ============================================================================

dcl-proc [resource]_getItem export;
  dcl-pi [resource]_getItem;
    request pointer value;
    response pointer value;
  end-pi;

  dcl-s id int(10);
  dcl-ds item likeds([resource]_detail_t);
  dcl-s jsonResponse varchar(100000);

  monitor;
    // Récupération ID depuis URL
    id = %int(il_getPathParameter(request : 'id'));

    // Appel module métier
    item = [resource]_getById(id);

    if item.id = 0;
      il_responseWrite(response : '{"error": "Resource not found"}');
      il_responseStatus(response : 404);
      return;
    endif;

    // Génération JSON
    jsonResponse = CMAGIC_buildJsonObject(item);

    // Headers
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');

    // Réponse
    il_responseWrite(response : jsonResponse);
    il_responseStatus(response : 200);

  on-error;
    CKOOL_logError('Erreur [resource]_getItem: ' + %str(%error));
    il_responseWrite(response : '{"error": "Internal server error"}');
    il_responseStatus(response : 500);
  endmon;

end-proc;

// ============================================================================
// POST CREATE
// ============================================================================

dcl-proc [resource]_create export;
  dcl-pi [resource]_create;
    request pointer value;
    response pointer value;
  end-pi;

  dcl-ds input likeds([resource]_input_t);
  dcl-ds created likeds([resource]_detail_t);
  dcl-s requestBody varchar(100000);
  dcl-s jsonResponse varchar(100000);

  monitor;
    // Parse JSON body
    requestBody = il_getRequestBody(request);
    input = CMAGIC_parseJson(requestBody);

    // Appel module métier
    created = [resource]_create(input);

    if created.id < 0;
      // Erreur validation ou SQL
      il_responseWrite(response : '{"error": "Creation failed"}');
      il_responseStatus(response : 400);
      return;
    endif;

    // Génération JSON
    jsonResponse = CMAGIC_buildJsonObject(created);

    // Headers
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'Location' : '/api/[resources]/' + %char(created.id));

    // Réponse 201 Created
    il_responseWrite(response : jsonResponse);
    il_responseStatus(response : 201);

  on-error;
    CKOOL_logError('Erreur [resource]_create: ' + %str(%error));
    il_responseWrite(response : '{"error": "Internal server error"}');
    il_responseStatus(response : 500);
  endmon;

end-proc;

// ============================================================================
// PUT UPDATE
// ============================================================================

dcl-proc [resource]_update export;
  dcl-pi [resource]_update;
    request pointer value;
    response pointer value;
  end-pi;

  dcl-s id int(10);
  dcl-ds input likeds([resource]_input_t);
  dcl-ds updated likeds([resource]_detail_t);
  dcl-s requestBody varchar(100000);
  dcl-s jsonResponse varchar(100000);

  monitor;
    // Récupération ID
    id = %int(il_getPathParameter(request : 'id'));

    // Parse JSON body
    requestBody = il_getRequestBody(request);
    input = CMAGIC_parseJson(requestBody);

    // Appel module métier
    updated = [resource]_update(id : input);

    if updated.id = 0;
      il_responseWrite(response : '{"error": "Resource not found"}');
      il_responseStatus(response : 404);
      return;
    endif;

    if updated.id < 0;
      il_responseWrite(response : '{"error": "Update failed"}');
      il_responseStatus(response : 400);
      return;
    endif;

    // Génération JSON
    jsonResponse = CMAGIC_buildJsonObject(updated);

    // Headers
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');

    // Réponse
    il_responseWrite(response : jsonResponse);
    il_responseStatus(response : 200);

  on-error;
    CKOOL_logError('Erreur [resource]_update: ' + %str(%error));
    il_responseWrite(response : '{"error": "Internal server error"}');
    il_responseStatus(response : 500);
  endmon;

end-proc;

// ============================================================================
// DELETE
// ============================================================================

dcl-proc [resource]_delete export;
  dcl-pi [resource]_delete;
    request pointer value;
    response pointer value;
  end-pi;

  dcl-s id int(10);
  dcl-s success ind;

  monitor;
    // Récupération ID
    id = %int(il_getPathParameter(request : 'id'));

    // Appel module métier
    success = [resource]_delete(id);

    if not success;
      il_responseWrite(response : '{"error": "Resource not found"}');
      il_responseStatus(response : 404);
      return;
    endif;

    // Réponse 200 OK (ou 204 No Content)
    il_responseWrite(response : '{"message": "Resource deleted"}');
    il_responseStatus(response : 200);

  on-error;
    CKOOL_logError('Erreur [resource]_delete: ' + %str(%error));
    il_responseWrite(response : '{"error": "Internal server error"}');
    il_responseStatus(response : 500);
  endmon;

end-proc;
```

---

## 🛣️ Structure Module Routes (`.route.sqlrpgle`)

### **Template Standard**

```rpg
**free

///
// Module Routes [Resource]
//
// Responsabilités:
// - Configuration routes ILEastic
// - Mapping URL → Handler
///

ctl-opt nomain;
ctl-opt bnddir('ILEASTIC');

/include 'includes/ileastic.rpgleinc'
/include 'includes/[resource].rpgleinc'

// ============================================================================
// CONFIGURATION ROUTES
// ============================================================================

dcl-proc [resource]_setupRoutes export;
  dcl-pi [resource]_setupRoutes;
    router pointer value;
  end-pi;

  // Routes CRUD standard
  il_addRoute(router : IL_GET    : '/api/[resources]'     : %paddr('[resource]_getCollection'));
  il_addRoute(router : IL_GET    : '/api/[resources]/:id' : %paddr('[resource]_getItem'));
  il_addRoute(router : IL_POST   : '/api/[resources]'     : %paddr('[resource]_create'));
  il_addRoute(router : IL_PUT    : '/api/[resources]/:id' : %paddr('[resource]_update'));
  il_addRoute(router : IL_DELETE : '/api/[resources]/:id' : %paddr('[resource]_delete'));

  // Routes actions métier (optionnel)
  // il_addRoute(router : IL_POST : '/api/[resources]/:id/[action]' : %paddr('[resource]_[action]'));

end-proc;
```

---

## 📦 Fichiers de Configuration

### **Binding Source (`.bnd`)**

```
STRPGMEXP PGMLVL(*CURRENT)

  /* Procédures exportées - Module métier */
  EXPORT SYMBOL('[resource]_search')
  EXPORT SYMBOL('[resource]_getById')
  EXPORT SYMBOL('[resource]_create')
  EXPORT SYMBOL('[resource]_update')
  EXPORT SYMBOL('[resource]_delete')

  /* Procédures exportées - Module REST */
  EXPORT SYMBOL('[resource]_getCollection')
  EXPORT SYMBOL('[resource]_getItem')
  EXPORT SYMBOL('[resource]_createItem')
  EXPORT SYMBOL('[resource]_updateItem')
  EXPORT SYMBOL('[resource]_deleteItem')

  /* Procédures exportées - Module Routes */
  EXPORT SYMBOL('[resource]_setupRoutes')

ENDPGMEXP
```

### **Rules.mk (Configuration Build)**

```makefile
# Variables
RESOURCE = [resource]
MODULES = $(RESOURCE) $(RESOURCE).rest $(RESOURCE).route

# Service program
$(RESOURCE).SRVPGM: $(MODULES:%=%.MODULE)
	system "CRTSRVPGM SRVPGM($(BIN_LIB)/$(RESOURCE)) +
	        MODULE($(BIN_LIB)/$(RESOURCE) +
	               $(BIN_LIB)/$(RESOURCE)REST +
	               $(BIN_LIB)/$(RESOURCE)ROUTE) +
	        EXPORT(*ALL) +
	        BNDSRVPGM((ILEASTIC) (CMAGIC) (CKOOL)) +
	        TEXT('Service Program $(RESOURCE)')"

# Modules individuels
$(RESOURCE).MODULE: $(RESOURCE).sqlrpgle
	system "CRTRPGMOD MODULE($(BIN_LIB)/$(RESOURCE)) +
	        SRCSTMF('$(SRC)/$(RESOURCE)/$(RESOURCE).sqlrpgle') +
	        DBGVIEW(*SOURCE)"

$(RESOURCE).rest.MODULE: $(RESOURCE).rest.sqlrpgle
	system "CRTRPGMOD MODULE($(BIN_LIB)/$(RESOURCE)REST) +
	        SRCSTMF('$(SRC)/$(RESOURCE)/$(RESOURCE).rest.sqlrpgle') +
	        DBGVIEW(*SOURCE)"

$(RESOURCE).route.MODULE: $(RESOURCE).route.sqlrpgle
	system "CRTRPGMOD MODULE($(BIN_LIB)/$(RESOURCE)ROUTE) +
	        SRCSTMF('$(SRC)/$(RESOURCE)/$(RESOURCE).route.sqlrpgle') +
	        DBGVIEW(*SOURCE)"

.PHONY: clean
clean:
	-system "DLTMOD MODULE($(BIN_LIB)/$(RESOURCE))"
	-system "DLTMOD MODULE($(BIN_LIB)/$(RESOURCE)REST)"
	-system "DLTMOD MODULE($(BIN_LIB)/$(RESOURCE)ROUTE)"
	-system "DLTSRVPGM SRVPGM($(BIN_LIB)/$(RESOURCE))"
```

---

## 📋 Bonnes Pratiques RPG ILE

### **1. Gestion d'Erreurs OBLIGATOIRE**

✅ **BON**
```rpg
monitor;
  // Code métier
  exec sql INSERT INTO table VALUES (:data);
  if sqlcode <> 0;
    CKOOL_logError('Erreur SQL: ' + %char(sqlcode));
    return *OFF;
  endif;
on-error;
  CKOOL_logError('Exception: ' + %str(%error));
  return *OFF;
endmon;
```

❌ **MAUVAIS**
```rpg
exec sql INSERT INTO table VALUES (:data);
// Pas de gestion d'erreur !
```

### **2. Logging Systématique**

✅ **BON**
```rpg
CKOOL_logInfo('Début traitement [resource] ID: ' + %char(id));
// ... traitement
CKOOL_logInfo('Fin traitement [resource] ID: ' + %char(id));
```

✅ **Erreurs explicites**
```rpg
CKOOL_logError('Validation échouée pour champ: ' + fieldName + ' valeur: ' + value);
```

### **3. Validation des Entrées**

✅ **BON**
```rpg
dcl-proc validate_input;
  dcl-pi validate_input ind;
    input likeds([resource]_input_t) const;
  end-pi;

  // Vérifications obligatoires
  if %len(%trim(input.requiredField)) = 0;
    CKOOL_logError('Champ requiredField obligatoire');
    return *OFF;
  endif;

  // Vérifications format
  if not isValidEmail(input.email);
    CKOOL_logError('Email invalide: ' + input.email);
    return *OFF;
  endif;

  // Vérifications métier
  if input.amount < 0;
    CKOOL_logError('Montant négatif interdit: ' + %char(input.amount));
    return *OFF;
  endif;

  return *ON;
end-proc;
```

### **4. Requêtes SQL Optimisées**

✅ **BON - Count AVANT pagination**
```rpg
// 1. Compter total
lSelect = 'SELECT COUNT(*) FROM table WHERE conditions';
exec sql PREPARE countStmt FROM :lSelect;
exec sql EXECUTE countStmt INTO :totalCount;

// 2. Récupérer page
lSelect = 'SELECT * FROM table WHERE conditions LIMIT ? OFFSET ?';
exec sql PREPARE selectStmt FROM :lSelect;
exec sql EXECUTE selectStmt USING :limit, :offset INTO :results;
```

❌ **MAUVAIS - Compter avec LIMIT**
```rpg
// Faux ! COUNT ignore LIMIT
lSelect = 'SELECT COUNT(*) FROM table WHERE conditions LIMIT 10';
```

### **5. Conventions de Nommage**

| Type | Convention | Exemple |
|------|-----------|---------|
| **Module** | `[resource].sqlrpgle` | `employee.sqlrpgle` |
| **Procedure publique** | `[resource]_[action]` | `employee_search` |
| **Procedure privée** | `[action]_internal` | `validate_input` |
| **Variable locale** | `l[Type]` | `lSelect`, `lWhere` |
| **Paramètre** | `p[Type]` | `pId`, `pFilters` |
| **Structure** | `[resource]_[type]_t` | `employee_detail_t` |
| **Constante** | `[MODULE]_[NAME]` | `CMAGIC_MAX_FILTERS` |

### **6. Documentation des Procédures**

✅ **BON**
```rpg
///
// Recherche d'employés avec filtres avancés
//
// @param filters Critères de recherche (pagination, tri, filtres)
// @return searchResult_t Résultat avec totalCount + tableau data
//
// @example
//   dcl-ds filters likeds(searchFilters_t);
//   filters.page = 1;
//   filters.limit = 10;
//   result = employee_search(filters);
//
// @throws Aucune exception - erreurs loggées
///
dcl-proc employee_search export;
  dcl-pi employee_search likeds(searchResult_t);
    filters likeds(searchFilters_t) const;
  end-pi;
  // ...
end-proc;
```

### **7. Structures de Données Typées**

✅ **BON - Types réutilisables**
```rpg
// Dans includes/[resource].rpgleinc

dcl-ds [resource]_detail_t template qualified;
  id likeds(GLOBAL_id);
  field1 varchar(50);
  field2 packed(9:2);
  created timestamp;
end-ds;

dcl-ds [resource]_input_t template qualified;
  field1 varchar(50);
  field2 packed(9:2);
  // Pas de id, created, updated
end-ds;
```

### **8. Gestion des Transactions**

✅ **BON - Transaction explicite**
```rpg
monitor;
  exec sql SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  exec sql START TRANSACTION;

  // Opérations multiples
  exec sql INSERT INTO table1 VALUES (:data1);
  exec sql UPDATE table2 SET field = :value WHERE id = :id;

  exec sql COMMIT;
  return *ON;

on-error;
  exec sql ROLLBACK;
  CKOOL_logError('Transaction rollback: ' + %str(%error));
  return *OFF;
endmon;
```

### **9. Performance - Curseurs vs Tableaux**

✅ **BON - Curseur pour gros volumes**
```rpg
exec sql DECLARE cursor1 CURSOR FOR selectStmt;
exec sql OPEN cursor1;

dow sqlcode = 0;
  exec sql FETCH FROM cursor1 INTO :record;
  if sqlcode = 0;
    // Traiter record
  endif;
enddo;

exec sql CLOSE cursor1;
```

✅ **BON - Tableau pour petits volumes**
```rpg
dcl-ds results likeds([resource]_item_t) dim(1000);
dcl-s count int(10);

exec sql SELECT * FROM table INTO :results;
count = %elem(results);
```

### **10. Tests Unitaires**

✅ **BON - Module de test**
```rpg
dcl-proc test_[resource]_search export;
  dcl-ds filters likeds(searchFilters_t);
  dcl-ds result likeds(searchResult_t);

  // Setup
  filters.page = 1;
  filters.limit = 10;

  // Exécution
  result = [resource]_search(filters);

  // Assertions
  assert(result.totalCount > 0 : 'Total count doit être > 0');
  assert(%elem(result.data) <= 10 : 'Max 10 résultats par page');

  CKOOL_logInfo('test_[resource]_search: PASSED');
end-proc;
```

---

## 🚫 Anti-Patterns à Éviter

### **1. SQL Direct dans Module REST**

❌ **MAUVAIS**
```rpg
// Dans [resource].rest.sqlrpgle
dcl-proc [resource]_getCollection export;
  // ...
  exec sql SELECT * FROM table INTO :results; // NON !
end-proc;
```

✅ **BON**
```rpg
// Dans [resource].rest.sqlrpgle
dcl-proc [resource]_getCollection export;
  // ...
  result = [resource]_search(filters); // Appel module métier
end-proc;
```

### **2. Génération JSON dans Module Métier**

❌ **MAUVAIS**
```rpg
// Dans [resource].sqlrpgle
dcl-proc [resource]_search export;
  // ...
  jsonResponse = '{"data": [...]}'; // NON !
  return jsonResponse;
end-proc;
```

✅ **BON**
```rpg
// Dans [resource].sqlrpgle
dcl-proc [resource]_search export;
  // ...
  return result; // Structure de données
end-proc;

// Dans [resource].rest.sqlrpgle
jsonResponse = CMAGIC_buildJsonArray(result.data);
```

### **3. Magic Numbers**

❌ **MAUVAIS**
```rpg
if result.id = -1; // Que signifie -1 ?
```

✅ **BON**
```rpg
dcl-c ERR_VALIDATION -1;
dcl-c ERR_SQL -2;
dcl-c ERR_EXCEPTION -3;

if result.id = ERR_VALIDATION;
```

### **4. Variables Globales**

❌ **MAUVAIS**
```rpg
dcl-s gTotalCount int(10); // Variable globale partagée
```

✅ **BON**
```rpg
// Toujours passer en paramètre ou retourner dans structure
dcl-ds result likeds(searchResult_t);
result.totalCount = lTotalCount;
return result;
```

### **5. Oubli du Header X-Total-Count**

❌ **MAUVAIS**
```rpg
// Dans [resource]_getCollection
il_responseWrite(response : jsonResponse);
// Manque X-Total-Count !
```

✅ **BON**
```rpg
il_addHttpHeader(response : 'X-Total-Count' : %char(result.totalCount));
il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
il_responseWrite(response : jsonResponse);
```

---

## 🎯 Checklist Avant Commit

- [ ] **Architecture**: Modules métier/REST/routes bien séparés
- [ ] **Gestion erreurs**: `monitor`/`on-error` sur toutes les opérations critiques
- [ ] **Logging**: Erreurs et étapes importantes loggées via CKOOL
- [ ] **Validation**: Toutes les entrées utilisateur validées
- [ ] **SQL**: Count AVANT pagination, curseurs optimisés
- [ ] **Headers HTTP**: X-Total-Count présent pour collections
- [ ] **Status HTTP**: 200, 201, 404, 400, 500 correctement utilisés
- [ ] **Nommage**: Conventions respectées (préfixes l/p, suffixes _t)
- [ ] **Documentation**: Procédures exportées documentées
- [ ] **Tests**: Au moins un test unitaire par procédure publique
- [ ] **Compilation**: `makei build` réussit sans warnings
- [ ] **Binding**: Toutes les procédures exportées listées dans `.bnd`

---

## 🚀 Commandes Build & Test

### **Build Complet**
```bash
cd /home/[user]/projects/applicationTemplate
makei build -l src/[resource]
```

### **Build Incrémental**
```bash
makei build -t [RESOURCE].SRVPGM
```

### **Tests cURL**
```bash
# Collection
curl "http://server:44000/api/[resources]?_page=1&_limit=10"

# Item
curl "http://server:44000/api/[resources]/[id]"

# Création
curl -X POST "http://server:44000/api/[resources]" \
  -H "Content-Type: application/json" \
  -d '{"field1": "value1", "field2": 123}'

# Mise à jour
curl -X PUT "http://server:44000/api/[resources]/[id]" \
  -H "Content-Type: application/json" \
  -d '{"field1": "new_value"}'

# Suppression
curl -X DELETE "http://server:44000/api/[resources]/[id]"
```

---

## 📚 Ressources de Référence

1. **Code de référence**: `src/employee` (pattern validé)
2. **Documentation API**: `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
3. **Guide pratique**: `ressources/docs/guides/guide_nouvelle_api_rest.md`
4. **PRD CMagic**: `ressources/docs/dsl/docs/dsl_langium/prd_projet.md`

---

## 🎓 Formation & Onboarding

### **Parcours Nouveau Développeur**

**Jour 1 - Théorie**
- Lire ce guide RPG ILE
- Consulter `ibmi_rest_api_instructions.md`
- Analyser structure `src/employee`

**Jour 2 - Pratique**
- Créer ressource simple (ex: Department)
- Suivre checklist validation
- Tests cURL complets

**Jour 3 - Revue**
- Code review avec pair
- Correction anti-patterns
- Validation métriques qualité

### **Prompt Copilot Type**

```
@workspace Consulte le guide RPG ILE (guide_rpg_bonnes_pratiques.md) 
et ibmi_rest_api_instructions.md pour créer une nouvelle ressource 
"products" avec les champs: productCode (6), description (100), 
price (decimal 9,2), category (50). Respecte strictement la séparation 
modules métier/REST/routes et inclus gestion erreurs + validation.
```

---

## � État de Validation

### **✅ Conventions Validées** (Extraites du Code Réel)

Ce guide a été **mis à jour** sur base de l'analyse du code `src/employee` existant.

**Document de référence**: `CONVENTIONS_REELLES_EXTRAITES.md`

#### **Confirmé dans le code:**
- ✅ Préfixe `p` pour paramètres
- ✅ Préfixe `l` pour variables locales
- ✅ Return `ind` (*ON/*OFF) pour succès/échec
- ✅ Framework CREST pour centralisation REST
- ✅ Logging via `CKOOL_logMessage()`
- ✅ Curseurs SQL avec `on-exit` cleanup
- ✅ Liste chaînée (llist) pour collections
- ✅ Versioning dans binding source

#### **⚠️ Différences Détectées:**
- Procédure métier: `employee_change` (pas `update`)
- Procédures REST: suffixe `_rest` obligatoire
- Paramètre routes: `config` (pas `router`)
- `dcl-pi *N` (pas de nom explicite)
- Structure ID imbriquée: `id.code` (pas simple `id`)

Consulter **`CONVENTIONS_REELLES_EXTRAITES.md`** pour détails complets.

### **📋 Travail Restant**

#### **Harmonisation Nécessaire**
- [ ] Décider: `_update` vs `_change` (métier/REST incohérent)
- [ ] Standardiser messages erreur (JSON vs texte)
- [ ] Documenter pattern ID imbriqué
- [ ] Expliquer choix framework CREST
- [ ] Documenter fonctions JSON conversion

#### **Guides Complémentaires à Créer**
- [ ] Guide framework CREST (détails)
- [ ] Guide liste chaînée llist
- [ ] Guide versioning service programs
- [ ] Guide testing patterns
- [ ] Guide mapping API ↔ SQL

---

**Version**: 2.0 (Octobre 2025)  
**Statut**: Basé sur code réel `src/employee` - Conventions validées  
**Prochaine étape**: Créer templates générateurs basés sur ces conventions
