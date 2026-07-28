# Conventions Réelles Extraites du Code Employee

> **Analyse du code réel** `src/employee/*`  
> **Date**: Octobre 2025  
> **But**: Documenter les conventions ACTUELLES utilisées dans le projet

---

## 📋 Vue d'Ensemble Architecture

### **Structure Fichiers Réelle**

```
src/employee/
├── employee.sqlrpgle         # ✅ Logique métier + SQL
├── employee.rest.sqlrpgle    # ✅ Handlers REST + JSON
├── employee.route.sqlrpgle   # ✅ Configuration routes
├── employee.bnd              # ✅ Exports avec versioning
└── Rules.mk                  # ✅ Configuration build
```

**✅ Conforme** à l'architecture proposée dans le guide.

---

## 🏗️ Conventions Réelles - Module Métier

### **1. En-tête Standard (employee.sqlrpgle)**

```rpg
**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');

/include 'employee.rpgleinc'
/include 'sqlStates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'
```

**Conventions observées:**
- ✅ `**free` format obligatoire
- ✅ `ctl-opt nomain` pour service program
- ✅ Options: `*nodebugio`, `*srcstmt`, `*nounref`
- ✅ `alwnull(*usrctl)` pour gestion NULL SQL
- ✅ Binding directories multiples séparés par `:`
- ✅ Includes SANS préfixe `includes/` (chemin géré par build)

### **1. Décisions de Nommage Restantes**

- [ ] **Décider:** `getlist` vs `getCollection` (actuellement `getlist`)
- [ ] **Décider:** `getone` vs `getItem` (actuellement `getone`)
- [ ] Documenter choix dans guide officiel

### **2. Améliorer Cohérence**

#### **Pattern Recherche**
```rpg
dcl-proc employee_search export;
  dcl-pi *N ind;                              // ⚠️ *N au lieu du nom
   pContext likeDS(CMAGIC_context) const;     // Préfixe 'p'
   pTotalCount like(CMAGIC_totalCount);       // OUT par référence
   pItems pointer;                             // OUT pointer liste
   pErrors likeDS(GLOBAL_listError);          // OUT erreurs
  end-pi;
```

**Conventions:**
- ✅ Nom procédure: `[resource]_[action]`
- ⚠️ **dcl-pi *N** (pas de nom explicite)
- ✅ Paramètres input: préfixe **`p`** + `const`
- ✅ Paramètres output: préfixe **`p`** (pas const)
- ✅ Return: `ind` (*ON/*OFF) pour succès/échec
- ✅ Multiple outputs via paramètres OUT

#### **Pattern GetByID**
```rpg
dcl-proc employee_getByID export;
  dcl-pi *N ind;
    pId likeDS(employee_detail_t.id) const;
    pDetail likeds(employee_detail_t);        // OUT
    pErrors likeDS(GLOBAL_listError);         // OUT
  end-pi;
```

#### **Pattern Create**
```rpg
dcl-proc employee_create export;
  dcl-pi *N ind;
    pDetail likeds(employee_detail_t) const;  // IN (données complètes)
    pId likeDS(employee_detail_t.id);         // OUT (ID généré)
    pErrors likeDS(GLOBAL_listError);         // OUT
  end-pi;
```

#### **Pattern Change (Update)**
```rpg
dcl-proc employee_update export;             // ✅ "update" harmonisé
  dcl-pi *N ind;
    pId likeDS(employee_detail_t.id) const;
    pDetail likeds(employee_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
```

#### **Pattern Delete**
```rpg
dcl-proc employee_delete export;
  dcl-pi *N ind;
    pId likeDS(employee_detail_t.id) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
```

**✅ HARMONISÉ:** Utilisation de **`employee_update`** cohérent avec `create`, `delete`

### **3. Conventions Nommage Variables**

#### **Variables Locales**
```rpg
dcl-ds lErrors likeDS(GLOBAL_listError);     // Préfixe 'l'
dcl-s lLimit int(10);
dcl-s lOffset int(10);
dcl-s lSelect char(5000);                     // SQL queries
dcl-s lSelCount like(lSelect);
dcl-s lWhere like(lSelect);
dcl-s lOrderBy like(lSelect);
dcl-s lFirst ind;                             // Flags
dcl-ds lItemFiltre likeDS(CMAGIC_filter);
dcl-ds lItemSort likeDS(CMAGIC_sort);
dcl-s lItems pointer;
dcl-ds lItem likeDS(employee_item_t);
dcl-s lCount like(CMAGIC_totalCount);
dcl-ds lError likeds(errorItem) inz;
dcl-s lOperateur char(4);
dcl-s ErrorHappened ind;                      // ⚠️ PascalCase!
dcl-s lPos int(5);
dcl-s lString like(CMAGIC_filter.value);
dcl-s dbFieldName varchar(32);                // ⚠️ camelCase!
dcl-s isNumericField ind;                     // ⚠️ camelCase!
```

**Conventions observées:**
- ✅ Préfixe **`l`** (local) pour variables locales
- ✅ Préfixe **`p`** (parameter) pour paramètres
- ⚠️ **Mix de styles**: `lVariable`, `camelCase`, `PascalCase`
- ✅ Structures SQL: `lSelect`, `lWhere`, `lOrderBy`
- ✅ Types spécifiques: `char()`, `varchar()`, `int()`

#### **Structures Temporaires SQL**
```rpg
dcl-ds lItemSQL qualified;
  code char(6);
  prenom like(employee_detail_t.prenom);    
  nom like(employee_detail_t.nom);
  initiale like(employee_detail_t.initiale);
  service like(employee_detail_t.service);
end-ds;
```

**Convention:** Suffixe `SQL` pour structures intermédiaires mapping DB

### **4. Gestion d'Erreurs Réelle**

#### **Pattern Monitor/On-Error**
```rpg
monitor;
  if employee_create(lDetail : lId : lErrors);
    // Success
    exec sql COMMIT;
    response.status = IL_HTTP_CREATED;
  else;
    response.status = IL_HTTP_BAD_REQUEST;
  endif;
on-error;
  exec sql ROLLBACK;
  CKOOL_logMessage('Exception in employee_create: ' + %trimr(%char(%error)));
  response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
endmon;
```

**Conventions:**
- ✅ `monitor`/`on-error` sur opérations critiques
- ✅ Logging avec **`CKOOL_logMessage`** (pas `CKOOL_logError`)
- ✅ `exec sql COMMIT/ROLLBACK` explicites
- ✅ `%trimr(%char(%error))` pour numéro erreur

#### **Pattern On-Exit**
```rpg
on-exit ErrorHappened;
  // Fermeture curseur
  Exec SQL close cListe; 
  Exec SQL close cCountListe; 
  if ErrorHappened;
    list_dispose(lItems);
    return *off;
  endif;
end-proc;
```

**Convention:** Utilisation `on-exit` pour cleanup ressources

### **5. Construction SQL Dynamique**

#### **Pattern Filtres avec CMAGIC**
```rpg
// Configuration champs supportés
clear lSupportedFields;
clear lErrors;  
if not employee_getSupportedFields(lSupportedFields:lErrors);
endif; 

// Traitement filtres
SORTA(D) lContext.filter(*).field; 
for-each lItemFiltre in lContext.filter;
  if %len(%trim(lItemFiltre.field)) = *zeros;
    leave;
  endif;
  
  // Recherche générale 'q'
  if %trim(lItemFiltre.field) = 'q';
    lWhere = ' ' + %trim(lWhere) + ' (';
    lWhere = %trim(lWhere) + 'UPPER(lastname) LIKE UPPER(' 
      + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
    lWhere = %trim(lWhere) + ' OR UPPER(firstnme) LIKE UPPER(' 
      + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
    lWhere = %trim(lWhere) + ')';
  else;
    // Filtres normaux avec mapping champs
    lIt = %lookup(%trim(lItemFiltre.field)
      :lSupportedFields.supportedFields(*).name);
    
    if lIt > 0;
      dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
      
      // Gestion opérateurs
      select;
        when %trim(lItemFiltre.operator) = CMAGIC_OP_LIKE;
          lWhere = ' ' + %trim(lWhere) + ' LIKE ';
        when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER_EQUAL;
          lWhere = ' ' + %trim(lWhere) + ' >= ';
        // ... autres opérateurs
      endsl;
    endif;
  endif;
endfor;
```

**Conventions:**
- ✅ Fonction dédiée `employee_getSupportedFields()` pour configuration
- ✅ `SORTA(D)` pour trier filtres (descendant)
- ✅ Support recherche `q` (query générique) sur multiples champs
- ✅ Mapping noms API → noms SQL via `supportedFields`
- ✅ Gestion opérateurs CMAGIC (`=`, `<>`, `LIKE`, `>=`, `<=`)
- ✅ Utilisation constante `GLOBAL_QUOTE` pour quotes

#### **Pattern Pagination**
```rpg
// Comptage AVANT pagination
lSelCount = 'select count(*) from (' + %trim(lSelect) +') a';

// Pagination APRÈS filtres et tri
lSelect = %trim(lSelect) + 
  ' LIMIT ' + %char(lLimit) + 
  ' OFFSET ' + %char(lOffset);
```

**⚠️ IMPORTANT:** Vous faites `COUNT(*)` sur **sous-requête** `(SELECT ... WHERE ...) a`

#### **Pattern Curseur**
```rpg
// Préparation
Exec sql prepare SqlStmt From :lSelect;
Exec sql declare cListe cursor for SqlStmt;
Exec SQL open cListe; 

if (sqlState <> SQL_OK);
  clear lError;
  lError.code = %trim(sqlState);
  CKOOL_ThrowError(lError);
endif;

// Fetch en boucle
dow (sqlState = SQL_OK);
  clear lItemSQL;
  Exec SQL Fetch Next From cListe Into :lItemSQL;
  if (sqlState <> SQL_OK);
    leave;
  endif;
  
  // Ajout dans liste chaînée
  clear lItem;
  lItem = lItemSQL;
  list_add(lItems: %addr(lItem): %size(lItem));
enddo;

// Fermeture dans on-exit
```

**Conventions:**
- ✅ Curseurs nommés: `cListe`, `cCountListe`
- ✅ Vérification `sqlState <> SQL_OK`
- ✅ Utilisation `CKOOL_ThrowError()` pour exceptions
- ✅ Liste chaînée via `list_add()` (llist library)
- ✅ Cleanup curseurs dans `on-exit`

### **6. Logging et Debug**

```rpg
// Debug SQL
snd-msg *INFO ('LSELECT ' + %trim(lSelect) + '/');

// Logging avant appel
CKOOL_logMessage('About to call employee_search with context');
CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));

// Logging succès
CKOOL_logMessage('employee_search succeeded - Total count: ' + %char(lTotalCount));

// Logging erreur
CKOOL_logMessage('employee_search failed');
CKOOL_logMessage('Exception in employee_search call: ' + %trimr(%char(%error)));
```

**Conventions:**
- ✅ `snd-msg *INFO` pour debug développement
- ✅ `CKOOL_logMessage()` pour logging production
- ✅ Pas de distinction `logInfo/logError` - tout via `logMessage`
- ✅ `%char()` pour conversion numérique
- ✅ `%trimr()` pour trim à droite

---

## 🌐 Conventions Réelles - Module REST

### **1. En-tête Standard (employee.rest.sqlrpgle)**

```rpg
**free

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC':'CREST');

/include 'ileastic/ileastic.rpgle'
/include 'employee.rpgleinc'
/include 'emprest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'crest.rpgleinc'
/include 'llist/llist_h.rpgle'
```

**Conventions:**
- ✅ Binding directories: ajout `ILEASTIC` et `CREST`
- ✅ Include `ileastic/ileastic.rpgle` (avec chemin relatif)
- ✅ Include `emprest.rpgleinc` (prototypes REST spécifiques)
- ✅ Include `crest.rpgleinc` (framework CREST)

### **2. Signatures Procédures REST**

#### **Pattern GET Collection**
```rpg
dcl-proc employee_getlist_rest export;        // ⚠️ Suffixe '_rest'
  dcl-pi *N;
    request likeds(IL_request);               // ⚠️ PAS const
    response likeds(IL_response);             // ⚠️ PAS const
  end-pi;
```

**Conventions:**
- ✅ Nom: `[resource]_[action]_rest`
- ⚠️ **Suffixe `_rest`** (pas dans le guide initial)
- ✅ Paramètres ILEastic: `IL_request`, `IL_response`
- ⚠️ **Pas de `const`** sur request/response (modifiés)
- ✅ Pas de return (void)

#### **Autres Actions REST**
```rpg
employee_getone_rest      // GET /employees/{id}
employee_create_rest      // POST /employees
employee_update_rest      // PUT /employees/{id}
employee_delete_rest      // DELETE /employees/{id}
```

**⚠️ IMPORTANT:** Vous utilisez:
- `getlist` au lieu de `getCollection`
- `getone` au lieu de `getItem`
- `update` au lieu de `change` (incohérence avec métier!)

### **3. Pattern Initialisation REST avec CREST**

#### **GET avec Filtres/Pagination**
```rpg
dcl-ds lContext likeDS(CMAGIC_context) inz;
dcl-s lTotalCount like(CMAGIC_totalCount);
dcl-s lItems pointer;
dcl-ds lSupportedFields likeds(CMAGIC_supportedFields); 

// Configuration champs supportés
clear lSupportedFields;
clear lErrors;  
if not employee_getSupportedFields(lSupportedFields:lErrors);
endif; 

// ⚡ CREST : Initialisation REST centralisée
if (not CREST_initRestRequest(request : lSupportedFields
                              : response : lContext));
  return; // Validation échouée, response configurée
endif;

// Appel métier
monitor;
  if employee_search(lContext : lTotalCount : lItems : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    
    // Headers standardisés via CREST
    CREST_addHeaders(response : lTotalCount);
    
    // JSON array
    il_responseWrite(response : employeesToJson(lItems : lTotalCount));
  else;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Search failed"}');
  endif;
on-error;
  response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
  il_responseWrite(response : '{"error":"Exception..."}');
endmon;

on-exit;
  if (lItems <> *null);
    list_clear(lItems);
  endif;
```

**Conventions CREST:**
- ✅ `CREST_initRestRequest()` pour validation + parsing
- ✅ `CREST_addHeaders()` pour headers standard (X-Total-Count, CORS)
- ✅ Return précoce si validation échoue
- ✅ `on-exit` pour cleanup liste chaînée

#### **GET Simple (by ID)**
```rpg
// ⚡ CREST : Validation REST simplifiée
if (not CREST_initSimpleRestRequest(request : response));
  return;
endif;

// Récupération ID
cId = il_getPathParameter(request : 'id' : '');
if (%len(%trim(cId)) = 0);
  response.status = IL_HTTP_BAD_REQUEST;
  il_responseWrite(response : 'Invalid employee id');
  return;
endif;

lId.code = cId;

if employee_getByID(lId : lDetail : lErrors);
  response.status = IL_HTTP_OK;
  response.contentType = IL_MEDIA_TYPE_JSON;
  il_responseWrite(response : employeeToJson(lDetail));
else;
  response.status = IL_HTTP_NOT_FOUND;
  il_responseWrite(response : 'No employee with id ' + cId);
endif;
```

**Conventions:**
- ✅ `CREST_initSimpleRestRequest()` pour GET simple
- ✅ `il_getPathParameter()` pour extraire paramètre URL
- ✅ Validation longueur ID
- ✅ Messages erreur simples (pas JSON structuré)

#### **POST/PUT (Write Operations)**
```rpg
// ⚡ CREST : Validation REST pour écriture
if (not CREST_initWriteRestRequest(request : response));
  return;
endif;

// Parse JSON
lDetail = jsonToEmployee(il_getRequestContent(request));
create = (%len(%trim(lDetail.id.code)) = 0);

monitor;
  if employee_create(lDetail : lId : lErrors);
    lDetail.id = lId;
    exec sql COMMIT;
    
    if (create);
      response.status = IL_HTTP_CREATED;
    else;
      response.status = IL_HTTP_OK;
    endif;
    
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : employeeToJson(lDetail));
  else;
    response.status = IL_HTTP_BAD_REQUEST;
    // ...
  endif;
on-error;
  exec sql ROLLBACK;
  // ...
endmon;
```

**Conventions:**
- ✅ `CREST_initWriteRestRequest()` pour POST/PUT
- ✅ `il_getRequestContent()` pour body JSON
- ✅ Fonction `jsonToEmployee()` pour parse JSON
- ✅ Détection create vs update via présence ID
- ✅ `exec sql COMMIT` explicite en cas de succès
- ✅ Status `IL_HTTP_CREATED` (201) pour création

### **4. Status HTTP Utilisés**

```rpg
IL_HTTP_OK                  // 200 - Success
IL_HTTP_CREATED             // 201 - Création réussie
IL_HTTP_BAD_REQUEST         // 400 - Données invalides
IL_HTTP_NOT_FOUND           // 404 - Ressource non trouvée
IL_HTTP_INTERNAL_SERVER_ERROR  // 500 - Erreur serveur
```

**⚠️ Pas d'autres codes** (pas de 204, 409, 422, etc.)

### **5. Génération JSON**

```rpg
// Collection → JSON array
il_responseWrite(response : employeesToJson(lItems : lTotalCount));

// Item → JSON object
il_responseWrite(response : employeeToJson(lDetail));

// Erreur simple
il_responseWrite(response : '{"error":"Search failed"}');
il_responseWrite(response : 'Invalid employee id');  // ⚠️ Pas JSON!
```

**Conventions:**
- ✅ Fonctions dédiées `employeesToJson()` et `employeeToJson()`
- ⚠️ Messages erreur **parfois JSON, parfois texte brut**
- ✅ Pas d'échappement manuel (géré par fonctions)

---

## 🛣️ Conventions Réelles - Module Routes

### **1. En-tête Standard (employee.route.sqlrpgle)**

```rpg
**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'employee.rpgleinc'
/include 'emprest.rpgleinc'
/include 'emproute.rpgleinc'
/include 'ckool.rpgleinc'
```

**Conventions:**
- ✅ Include `emproute.rpgleinc` (prototypes routes)
- ✅ Binding `ILEASTIC` obligatoire

### **2. Configuration Routes**

```rpg
dcl-proc employee_setupRoutes export;
  dcl-pi *N;
    config likeds(il_config);                // ⚠️ 'config' pas 'router'
  end-pi;
  
  // Routes CRUD
  il_addRoute(config : %paddr('employee_getlist_rest') 
    : IL_GET : '^/api/employees/?$');
  il_addRoute(config : %paddr('employee_getone_rest') 
    : IL_GET : '^/api/employees/{id}$');
  il_addRoute(config : %paddr('employee_create_rest') 
    : IL_POST : '^/api/employees/?$');
  il_addRoute(config : %paddr('employee_update_rest') 
    : IL_PUT : '^/api/employees/{id}$');
  il_addRoute(config : %paddr('employee_delete_rest') 
    : IL_DELETE : '^/api/employees/{id}$');
end-proc;
```

**Conventions:**
- ⚠️ Paramètre nommé **`config`** (pas `router`)
- ✅ Type: `likeds(il_config)` (ILEastic)
- ✅ `%paddr('procedure_name')` entre quotes
- ✅ Ordre: `config`, `handler`, `method`, `pattern`
- ✅ Patterns regex: `^/api/[resources]/?$`
- ✅ Paramètre URL: `{id}` dans pattern
- ✅ Noms pluriels: `/api/employees` (pas `/api/employee`)

### **3. Procédure d'Enregistrement API**

```rpg
dcl-proc employee_registerAPI export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Setup all employee routes
  employee_setupRoutes(config);
  
  // Log API registration
  CKOOL_logMessage('Employee API routes registered successfully');
end-proc;
```

**Convention:** Procédure wrapper `_registerAPI` pour logging

---

## 📦 Conventions Réelles - Fichiers Configuration

### **1. Binding Source (employee.bnd)**

```bnd
STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_create')  
  EXPORT SYMBOL('employee_display')
  EXPORT SYMBOL('employee_isValid')  
ENDPGMEXP

STRPGMEXP  PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.2')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
ENDPGMEXP

STRPGMEXP  PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Conventions:**
- ✅ **Versioning** avec `PGMLVL(*CURRENT)` et `PGMLVL(*PRV)`
- ✅ Signature format: `'[RESOURCE].[MAJOR].[MINOR].[PATCH]'`
- ✅ Exports incrémentaux (version 1 < version 2 < version 3)
- ✅ **Quotes simples** autour des symboles
- ⚠️ **Seulement procédures métier** exportées (pas REST, pas routes)

### **2. Structures de Données (employee.rpgleinc)**

```rpg
// Énumérations
dcl-enum employee_listeAction qualified;
  creation 'create';
  modification 'update';
  suppression 'delete';
  consultation 'read';
  habilitation 'habilitation';
end-enum;

dcl-enum employee_listeGenre qualified;
  masculin 'M';
  feminin 'F';
end-enum;

// Template type
dcl-s employee_genre char(1) template;

// Structure détail complète
dcl-ds employee_detail_t template qualified;
  dcl-ds id;                           // ⚠️ Structure imbriquée pour ID
    code char(6);
  end-ds;
  prenom varchar(12);
  nom varchar(15);
  initiale char(1);
  service char(3);
  dateEmbauche date;
  dateNaissance date;
  genre like(employee_genre);
  salaire packed(9:2);
end-ds;

// Structure item (liste)
dcl-ds employee_item_t template qualified;
  id likeDS(employee_detail_t.id);     // ⚠️ Réutilisation structure ID
  prenom like(employee_detail_t.prenom);
  nom like(employee_detail_t.nom);
  initiale like(employee_detail_t.initiale);
  service like(employee_detail_t.service);
end-ds;
```

**Conventions:**
- ✅ Suffixe `_t` pour templates
- ✅ `qualified` pour éviter conflits noms
- ⚠️ **Structure ID imbriquée** (pas simple `id char(6)`)
- ✅ Types SQL: `varchar()`, `date`, `packed()`
- ✅ Réutilisation types via `like()` et `likeDS()`
- ✅ Pas de structure `_input_t` distincte

### **3. Documentation Procédures**

```rpg
///
// Search Employees
//
// Returns a paginate list of found Employees 
//  regarding the search critéria send in the context.
//
// @param **in**  context (pagination,sort,filter) critérias
// @param **out** itemCount count of item found based on filter critérias
// @param **out** items pointer to the linked list of item Employee
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag Employe
// @tag CMAGIC
///
dcl-pr employee_search ind extproc(*dclcase);
   context likeDS(CMAGIC_context) const;
   totalCount like(CMAGIC_totalCount);
   items pointer;
   errors likeDS(GLOBAL_listError);
end-pr;
```

**Conventions:**
- ✅ Bloc `///` pour documentation (pas JSDoc `/**`)
- ✅ Tags `@param`, `@return`, `@throws`, `@tag`
- ✅ Direction: `**in**`, `**out**` en gras
- ✅ Prototypes `dcl-pr` dans `.rpgleinc`
- ✅ `extproc(*dclcase)` pour export

---

## 🔧 Conventions Réelles - Framework CREST

### **1. Fonctions d'Initialisation**

```rpg
// Validation + parsing complet (GET avec filtres)
CREST_initRestRequest(request : supportedFields : response : context)

// Validation simple (GET sans filtres)
CREST_initSimpleRestRequest(request : response)

// Validation write (POST/PUT)
CREST_initWriteRestRequest(request : response)
```

**Return:** `ind` (*ON/*OFF) - *OFF = erreur, response déjà configurée

### **2. Fonctions Utilitaires**

```rpg
// Headers standard (CORS + X-Total-Count)
CREST_addHeaders(response : totalCount)

// Conversion erreurs → JSON
CREST_errorsToJson(errors)

// Erreur simple
CREST_simpleError(errorMessage)
```

### **3. Pattern Validation Champs**

```rpg
dcl-proc employee_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeDS(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  // Configuration champs API → SQL
  clear pSupportedFields;
  
  pSupportedFields.supportedFields(1).name = 'id';
  pSupportedFields.supportedFields(1).sqlField = 'empno';
  pSupportedFields.supportedFields(1).dataType = typeChamp.STRING;
  
  pSupportedFields.supportedFields(2).name = 'nom';
  pSupportedFields.supportedFields(2).sqlField = 'lastname';
  pSupportedFields.supportedFields(2).dataType = typeChamp.STRING;
  
  // ... autres champs
  
  return *ON;
end-proc;
```

**Conventions:**
- ✅ Fonction dédiée `_getSupportedFields()` exportée
- ✅ Mapping: `name` (API) → `sqlField` (DB)
- ✅ `dataType` pour distinction numérique/string
- ✅ Utilisé pour validation et construction SQL

---

## 📊 Structures CMAGIC Réelles

### **1. Context Global**

```rpg
dcl-ds CMAGIC_context template qualified;
  dcl-ds pagination likeDS(CMAGIC_pagination);
  sort likeDS(CMAGIC_sort) dim(CMAGIC_MAX_SORTS);
  filter likeDS(CMAGIC_filter) dim(CMAGIC_MAX_FILTERS);
end-ds;

dcl-ds CMAGIC_pagination template qualified;
   numPage int(10);    // ⚠️ Commence à 1
   perPage int(10);
end-ds;

dcl-ds CMAGIC_sort template qualified;
   field char(32);
   order char(32);     // 'ASC' ou 'DESC'
end-ds;

dcl-ds CMAGIC_filter template qualified;
   field char(32);
   operator char(10);  // '=', '<>', 'LIKE', '>=', '<=', '>', '<'
   value char(100);
end-ds;
```

### **2. Constantes CMAGIC**

```rpg
dcl-c CMAGIC_DEFAULT_LIMIT 10;
dcl-c CMAGIC_MAX_FILTERS 20;
dcl-c CMAGIC_MAX_SORTS 10;
dcl-c CMAGIC_MAX_SUPPORTED_FIELDS 50;

// Opérateurs
dcl-c CMAGIC_OP_EQUAL '=';
dcl-c CMAGIC_OP_NOT_EQUAL '<>';
dcl-c CMAGIC_OP_LIKE 'LIKE';
dcl-c CMAGIC_OP_GREATER '>';
dcl-c CMAGIC_OP_GREATER_EQUAL '>=';
dcl-c CMAGIC_OP_LESS '<';
dcl-c CMAGIC_OP_LESS_EQUAL '<=';
```

### **3. Supported Fields**

```rpg
dcl-ds CMAGIC_supportedFields template qualified;
  dcl-ds supportedFields dim(CMAGIC_MAX_SUPPORTED_FIELDS) qualified;
    name varchar(32);        // Nom API
    sqlField varchar(32);    // Nom colonne SQL
    dataType int(3);         // typeChamp.STRING ou typeChamp.NUMERIC
  end-ds;
end-ds;
```

---

## 🎯 Différences Clés avec Guide Initial

### **✅ Harmonisations Réalisées**

| Aspect | Avant | Après | Statut |
|--------|-------|-------|---------|
| **Procédure métier** | `employee_change` | `employee_update` | ✅ **HARMONISÉ** |
| **Cohérence CRUD** | Incohérent | `create/update/delete` | ✅ **HARMONISÉ** |
| **Documentation** | Obsolète | À jour | ✅ **HARMONISÉ** |

### **⚠️ Différences Restantes (à décider)**

### **⚠️ Différences Restantes (à décider)**

| Aspect | Guide Initial | Code Réel | Décision |
|--------|--------------|-----------|----------|
| **Nom GET collection** | `getCollection` | `getlist` | ⚠️ À décider |
| **Nom GET item** | `getItem` | `getone` | ⚠️ À décider |
| **Nom param routes** | `router` | `config` | ✅ Garder `config` |
| **dcl-pi** | Nom explicite | `*N` | ✅ Garder `*N` |
| **Structure ID** | Simple `id char(6)` | Imbriquée `id.code` | ✅ Garder imbriquée |
| **Messages erreur** | JSON structuré | Mix JSON/texte | ⚠️ À uniformiser |
| **Logging** | `logInfo/logError` | Seulement `logMessage` | ✅ Garder `logMessage` |
| **Binding exports** | Tout exporter | Seulement métier | ✅ Garder sélectif |

### **✅ Bonnes Pratiques Confirmées**

- ✅ Séparation modules métier/REST/routes stricte
- ✅ Pattern recherche avec CMAGIC context
- ✅ Curseurs SQL + liste chaînée
- ✅ Monitor/on-error systématique
- ✅ Framework CREST pour centralisation
- ✅ Versioning binding source
- ✅ Support filtres avancés (LIKE, >=, <=, etc.)
- ✅ Recherche générale `q` sur multiples champs

---

## 📝 Recommandations

### **✅ Harmonisations Réalisées (28 Oct 2025)**

- [x] **Renommer** `employee_change` → `employee_update` dans module métier
- [x] **Mettre à jour** prototype dans `employee.rpgleinc`
- [x] **Mettre à jour** binding source `employee.bnd`
- [x] **Vérifier** appels dans `employee.rest.sqlrpgle`
- [x] **Documenter** changements dans ce fichier

**Résultat:** Cohérence CRUD complète: `search`, `getByID`, `create`, `update`, `delete`

### **1. Décisions de Nommage Restantes**

- [ ] Messages erreur **toujours JSON** (pas texte brut)
- [ ] Décider: `dcl-pi *N` vs nom explicite
- [ ] Documenter pattern ID imbriqué (pourquoi `id.code`?)

### **3. Documentation**

- [ ] Expliquer choix framework CREST
- [ ] Documenter fonctions JSON (`employeeToJson`, etc.)
- [ ] Guide mapping champs API ↔ SQL

### **4. Guides à Créer**

- [ ] Guide framework CREST (usage, patterns)
- [ ] Guide liste chaînée llist (quand/comment)
- [ ] Guide versioning binding source
- [ ] Guide testing (patterns actuels)

---

## ✅ Checklist Conformité Code Réel

**Pour nouvelle ressource, suivre `employee` exactement:**

- [ ] **Métier**: Procédures `search`, `getByID`, `create`, `update`, `delete` ✅
- [ ] **REST**: Suffixe `_rest` (ex: `product_getlist_rest`)
- [ ] **Paramètres**: Préfixe `p`, `const` pour IN
- [ ] **Variables locales**: Préfixe `l`
- [ ] **Return**: `ind` (*ON/*OFF) pour succès
- [ ] **Logging**: `CKOOL_logMessage()` partout
- [ ] **SQL**: Curseurs + `on-exit` cleanup
- [ ] **CREST**: `CREST_init*` au début handlers REST
- [ ] **Binding**: Versioning + exports métier seulement
- [ ] **Structures**: ID imbriqué `id.code`
- [ ] **SupportedFields**: Fonction dédiée `_getSupportedFields()`

---

**Document vivant** - Mis à jour le 28 octobre 2025  
**Dernière harmonisation**: `employee_change` → `employee_update`
