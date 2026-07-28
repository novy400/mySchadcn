# Instructions Complètes API REST Standard - IBMi RPG ILE Free + ILEastic

TODO: revoir et compléter

> **Guide complet pour GitHub Copilot / Claude Sonnet 4**
>
> Documentation pour créer une API REST standard compatible React-Admin, Appsmith, Retool
> sur IBM i avec RPG ILE Free Format et ILEastic

---

## 📋 TABLE DES MATIÈRES

1. [Objectif et Stack Technique](#objectif)
2. [Format REST Standard](#format-rest)
3. [Architecture et Structure](#architecture)
4. [Paramètres de Requête](#parametres)
5. [Structures CMAGIC](#structures-cmagic)
6. [Implémentation Routes ILEastic](#routes-ileastic)
7. [Implémentation Logique Métier](#logique-metier)
8. [Conversion JSON](#conversion-json)
9. [Points Critiques](#points-critiques)
10. [Tests et Debug](#tests-debug)
11. [Prompts pour Copilot](#prompts-copilot)
12. [Checklist de Validation](#checklist)
13. [Data Provider React-Admin](#data-provider)
14. [Roadmap et Ressources](#roadmap)

---

`<a name="objectif"></a>`

## 🎯 1. OBJECTIF ET STACK TECHNIQUE

### Objectif

Créer une API REST standard sur IBMi compatible avec React-Admin, Appsmith, Retool et tous les outils low-code modernes.

### Stack Technique

- **Plateforme** : IBM i (AS/400)
- **Langage** : RPG ILE Free Format (`**free`)
- **Framework Web** : ILEastic (https://github.com/sitemule/ILEastic)
- **Base de données** : DB2 for i (embedded SQL)
- **Format échange** : JSON
- **Logging** : CKOOL (module logging custom)
- **Build IBMi** : BOB (https://github.com/IBM/ibmi-bob)

### Avantages du Format Standard

- ✅ Compatible universel (tous outils low-code)
- ✅ Standards HTTP (headers, codes status)
- ✅ Pas de lock-in technologique
- ✅ Documentable avec Swagger/OpenAPI
- ✅ Testable avec cURL, Postman

---

`<a name="format-rest"></a>`

## 📝 2. FORMAT REST STANDARD

### 2.1 Réponse GET Collection

**Requête :**

```
GET /api/employees?_page=1&_limit=10&_sort=lastname&_order=asc
```

**Réponse HTTP :**

```
HTTP/1.1 200 OK
Content-Type: application/json
X-Total-Count: 156
Access-Control-Expose-Headers: X-Total-Count

[
  {
    "id": "000010",
    "prenom": "CHRISTINE",
    "nom": "HAAS",
    "initiale": "I",
    "service": "A00"
  },
  {
    "id": "000020",
    "prenom": "MICHAEL",
    "nom": "THOMPSON",
    "initiale": "L",
    "service": "B01"
  }
]
```

**Points clés :**

- ✅ Réponse = **tableau JSON** `[...]`
- ✅ Header **X-Total-Count** = nombre total d'éléments (pas juste la page)
- ✅ Header **X-Total-Count exposé** dans CORS

### 2.2 Réponse GET One

**Requête :**

```
GET /api/employees/000010
```

**Réponse HTTP :**

```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "000010",
  "prenom": "CHRISTINE",
  "nom": "HAAS",
  "initiale": "I",
  "service": "A00",
  "dateEmbauche": "1965-01-01",
  "dateNaissance": "1933-08-14",
  "genre": "F",
  "salaire": 52750.00
}
```

**Point clé :**

- ✅ Réponse = **objet JSON** `{...}` (pas un tableau)

### 2.3 Réponse POST Create

**Requête :**

```
POST /api/employees
Content-Type: application/json

{
  "prenom": "JOHN",
  "nom": "DOE",
  "service": "A00",
  "salaire": 50000
}
```

**Réponse HTTP :**

```
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": "000999",
  "prenom": "JOHN",
  "nom": "DOE",
  "service": "A00",
  "salaire": 50000
}
```

**Point clé :**

- ✅ Code status **201 Created** (pas 200)

### 2.4 Réponse PUT Update

**Requête :**

```
PUT /api/employees/000010
Content-Type: application/json

{
  "nom": "HAAS-SMITH",
  "salaire": 55000
}
```

**Réponse HTTP :**

```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "000010",
  "prenom": "CHRISTINE",
  "nom": "HAAS-SMITH",
  "service": "A00",
  "salaire": 55000.00
}
```

### 2.5 Réponse DELETE

**Requête :**

```
DELETE /api/employees/000999
```

**Réponse HTTP :**

```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "000999",
  "prenom": "JOHN",
  "nom": "DOE"
}
```

### 2.6 Réponse Erreur

**Réponse HTTP :**

```
HTTP/1.1 404 Not Found
Content-Type: application/json

{ "errors":[
  {
    "zone": "id",
    "code": "not_found",
    "valeur": "000999",
    "text": "Employee with id 000999 not found",
    "textUtilisateur": "Employee with id 000999 not found"
  },
  ...
  {
    "zone": "general",
    "code": "not_found",
    "text": "Employee with id 000999 not found",
    "textUtilisateur": "Employee with id 000999 not found"
  }
]
}
```

**Codes HTTP à utiliser :**

- `200 OK` : Succès GET, PUT, DELETE
- `201 Created` : Succès POST
- `400 Bad Request` : Validation échouée, paramètres invalides
- `404 Not Found` : Ressource non trouvée
- `500 Internal Server Error` : Erreur serveur

---

`<a name="parametres"></a>`

## 🔧 3. PARAMÈTRES DE REQUÊTE

### 3.1 Pagination

**Paramètres :**

- `_page` : Numéro de page (commence à 1)
- `_limit` : Nombre d'éléments par page

**Exemples :**

```
GET /api/employees?_page=1&_limit=10    # Page 1, 10 éléments
GET /api/employees?_page=2&_limit=20    # Page 2, 20 éléments
GET /api/employees?_page=3&_limit=5     # Page 3, 5 éléments
```

**Calcul offset :**

```
offset = (page - 1) × limit
```

### 3.2 Tri

**Paramètres :**

- `_sort` : Nom du champ à trier
- `_order` : Direction (`asc` ou `desc`)

**Exemples :**

```
GET /api/employees?_sort=lastname&_order=asc
GET /api/employees?_sort=salary&_order=desc
GET /api/employees?_sort=hiredate&_order=desc
```

### 3.3 Filtres Simples (Égalité)

**Format :**

```
GET /api/employees?field=value
```

**Exemples :**

```
GET /api/employees?workdept=A00
GET /api/employees?sex=M
GET /api/employees?workdept=A00&sex=M    # Filtres multiples (AND)
```

### 3.4 Filtres Avancés (Opérateurs)

**Opérateurs supportés :**

| Suffixe   | Opérateur SQL | Signification       | Exemple               |
| --------- | -------------- | ------------------- | --------------------- |
| (aucun)   | `=`          | Égalité           | `workdept=A00`      |
| `_like` | `LIKE`       | Contient            | `lastname_like=HAA` |
| `_gte`  | `>=`         | Supérieur ou égal | `salary_gte=50000`  |
| `_lte`  | `<=`         | Inférieur ou égal | `salary_lte=100000` |
| `_gt`   | `>`          | Supérieur strict   | `salary_gt=50000`   |
| `_lt`   | `<`          | Inférieur strict   | `salary_lt=100000`  |
| `_ne`   | `<>`         | Différent          | `workdept_ne=A00`   |

**Exemples :**

```
GET /api/employees?lastname_like=HAA          # LIKE '%HAA%'
GET /api/employees?salary_gte=50000           # >= 50000
GET /api/employees?salary_lte=100000          # <= 100000
GET /api/employees?workdept_ne=A00            # <> 'A00'
GET /api/employees?salary_gte=50000&salary_lte=100000  # BETWEEN
```

### 3.5 Recherche Full-Text

**Paramètre :**

- `q` : Terme de recherche global

**Exemple :**

```
GET /api/employees?q=CHRISTINE
```

**Comportement :**
Cherche dans plusieurs champs (firstname, lastname, etc.)

### 3.6 Combinaison Complète

**Exemple réel :**

```
GET /api/employees?_page=2&_limit=20&_sort=lastname&_order=asc&workdept=A00&salary_gte=50000
```

**Signification :**

- Page 2
- 20 éléments par page
- Tri par nom croissant
- Département = A00
- Salaire >= 50000

---

`<a name="architecture"></a>`

## 🏗️ 4. ARCHITECTURE ET STRUCTURE

### 4.1 Structure de Fichiers

```
/includes
  ├── employee.rpgleinc            # Prototypes et types
  ├── ...  
  ├── cmagic.rpgleinc              # Structures pagination/tri/filtres
  ├── emprest.rpgleinc             # Constantes REST
  └── global.rpgleinc              # Constantes globales
/src
├──/main
  ├── Rules.mk                     # Makefile pour compilation BOB 
  └── gestemp.main.rpgle          # Point d'entrée, main() avec modules (routes, handlers)
├──/employee
  ├── Rules.mk                     # Makefile pour compilation BOB 
  ├── README_REST_API.md           # Documentation spécifique
  ├── REST_API_EXAMPLES.md         # Exemples d'appels API
      ...
  ├── employee.route.sqlrpgle      # Module de configuration des routes ILEastic
  ├── employee.rest.sqlrpgle       # Module de gestion des Handlers REST (GET, POST, PUT, DELETE)
  ├── employee.sqlrpgle            # Logique métier + accès DB2
  └── employee.rest.bnd           # Binding pour module REST

```

### 4.2 Rôle des includes.

**cmagic.rpgleinc**

- Structures génériques pagination/tri/filtres
- Utilisable pour toutes les ressources

**`composant`.rpgleinc**

- Prototypes procédures
- Structures de données
- Templates

### 4.3 Rôle du main

**gestemp.main.rpgle**

- Point d'entrée du programme
- Configuration ILEastic (port, host)
- Enregistrement des routes de chaque `composant`.
- Démarrage du serveur `il_listen()`

### 4.4 Rôle de Chaque `composant`

**`composant`.route.sqlrpgle**

- Définition des routes REST
- Mapping URL → Handler
- `il_addRoute()` pour chaque endpoint

**`composant`.rest.sqlrpgle**

- Handlers REST (procédures export)
- Parse des paramètres HTTP
- Appel logique métier
- Génération JSON
- Gestion erreurs HTTP

**`composant`.sqlrpgle**

- Logique métier pure
- Accès DB2 (SQL embedded)
- Validation données
- Pas de HTTP, pas de JSON

---

`<a name="structures-cmagic"></a>`

## 📊 5. STRUCTURES CMAGIC

### 5.1 Fichier cmagic.rpgleinc COMPLET

```rpg
**free
/if defined(CMAGIC_H_DEFINED)   
/eof                         
/endif                       
/define CMAGIC_H_DEFINED  

// ------------------------------------------------------------------//
// printf (c)                                                       //
// ------------------------------------------------------------------//

// Constantes
dcl-c CMAGIC_DEFAULT_LIMIT 10;
dcl-c CMAGIC_MAX_FILTERS 20;
dcl-c CMAGIC_MAX_SORTS 10;
dcl-c CMAGIC_MAX_SUPPORTED_FIELDS 50;
// Opérateurs supportés pour les filtres
dcl-c CMAGIC_OP_EQUAL '=';
dcl-c CMAGIC_OP_NOT_EQUAL '<>';
dcl-c CMAGIC_OP_LIKE 'LIKE';
dcl-c CMAGIC_OP_GREATER '>';
dcl-c CMAGIC_OP_GREATER_EQUAL '>=';
dcl-c CMAGIC_OP_LESS '<';
dcl-c CMAGIC_OP_LESS_EQUAL '<=';

// Variables globales
dcl-s CMAGIC_totalCount int(10);
dcl-s CMAGIC_items pointer;

// Structure de pagination
dcl-ds CMAGIC_pagination template qualified;
   numPage int(10); // Numéro de page (commence à 1)
   perPage int(10); // Éléments par page
end-ds;

// Structure de tri
dcl-ds CMAGIC_sort template qualified;
   field char(32); // Nom du champ à trier
   order char(32); // ASC ou DESC
end-ds;

// Structure de filtre
dcl-ds CMAGIC_filter template qualified;
   field char(32);      // Nom du champ
   operator char(10);   // =, <>, LIKE, >=, <=, >, <
   value char(100);     // Valeur du filtre
end-ds;


// Context global (pagination + tri + filtres)
dcl-ds CMAGIC_context template qualified;
  dcl-ds pagination likeDS(CMAGIC_pagination);
  dcl-ds sort likeDS(CMAGIC_sort) dim(CMAGIC_MAX_SORTS);
  dcl-ds filter likeDS(CMAGIC_filter) dim(CMAGIC_MAX_FILTERS);
end-ds;

// Structure des champs filtre
dcl-enum typeChamp qualified;
  CHARACTER 'C';
  NUMERIC 'N';
  DATE 'D';
end-enum;

dcl-ds CMAGIC_supportedField template qualified;
   name char(32);      // Nom du champ
   sqlField char(32);   // Nom du champ SQL
   dataType char(1);   // Type de données (char, int, date, etc.)
end-ds;

dcl-ds CMAGIC_supportedFields template qualified;
    dcl-ds supportedFields likeDS(CMAGIC_supportedField) dim(CMAGIC_MAX_SUPPORTED_FIELDS);
end-ds;

```

### 5.2 Utilisation des Structures

**Dans les handlers REST :**

```rpg
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields); 
  // ⚡ Définir les champs supportés pour les filtres et tris
  clear lSupportedFields;
  clear lErrors;  
  if not employee_getSupportedFields(lSupportedFields:lErrors);
  endif; 
  // ⚡ CREST : Initialisation REST centralisée (validation + parsing)
  if (not CREST_initRestRequest(request : lSupportedFields
                                : response : lContext));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Debug log before calling employee_search
  CKOOL_logMessage('About to call employee_search with context');
  CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));
  CKOOL_logMessage('Pagination perPage: ' + %char(lContext.pagination.perPage));
  
  // Appel de votre procédure existante
  monitor;
    if employee_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('employee_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
  
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response : lTotalCount);
  
      // Write array with total count header for React Admin
      il_responseWrite(response : employeesToJson(lItems : lTotalCount));
    else;
      CKOOL_logMessage('employee_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;

```

**Dans CREST_initRestRequest :**

```rpg
dcl-proc CREST_initRestRequest export;
  dcl-pi *N ind;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
    response likeds(IL_response);
    context likeDS(CMAGIC_context);
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT CREST_initRestRequest ===');
  
  // 1. Validation Accept header
  if (not validateAcceptHeader(request : response));
    CKOOL_logMessage('CREST_initRestRequest : échec validation Accept header');
    return *OFF;
  endif;
  
  // 2. Parsing centralisé des paramètres de requête
  context = parseQueryParams(request : supportedFields);
  CKOOL_logMessage('CREST_initRestRequest : parsing avec supportedFields');
  
  CKOOL_logMessage('=== FIN CREST_initRestRequest - Succès ===');
  return *ON;
end-proc;
...
dcl-proc parseQueryParams;
  dcl-pi *n likeds(CMAGIC_context);
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  
  CKOOL_logMessage('=== DÉBUT parseQueryParams ===');
  
  // 1. Configuration pagination
  setupPagination(request : context);
  
  // 2. Configuration tri
  setupSorting(request : context);
  
  // 3. Configuration filtres (avec ou sans champs supportés)
  setupFilters(request : supportedFields : context );
  CKOOL_logMessage('Filtres configurés avec supportedFields');
  
  CKOOL_logMessage('=== FIN parseQueryParams ===');
  return context;
end-proc;

```

---

`<a name="routes-ileastic"></a>`

## 🛣️ 6. IMPLÉMENTATION ROUTES ILEASTIC

### 6.1 Configuration Main (gestemp.main.rpgle)

```rpg
**FREE

ctl-opt thread(*CONCURRENT)
        option(*nodebugio:*srcstmt:*nounref)
        pgminfo(*PCML:*MODULE)
        alwnull(*usrctl)
        main(main)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'emproute.rpgleinc'
/include 'emprest.rpgleinc'
/include 'ckool.rpgleinc'

// Include du plugin CORS officiel ILEastic
/include 'ileastic/cors_h.rpginc'

dcl-proc main;
  dcl-ds config likeds(il_config);
 CKOOL_logMessage('Employee API Server Starting...');
  config.port = 44000;
  config.host = '*ANY';
 CKOOL_logMessage('Server configured on port ' + %char(config.port));
  
  // Configuration CORS avec plugin officiel ILEastic
  il_addPlugin(config : %paddr('il_addCorsHeaders') : IL_PREREQUEST);
  
  // Configuration CORS pour APIs REST (permettre tout pour développement)
  il_cors_addCorsConfigurationValues('.*' : '*' : '*' : '*' : *ON);
  
  // Setup complete employee API routes
  employee_registerAPI(config);
  
 CKOOL_logMessage('Starting server...');
  il_listen(config);
 CKOOL_logMessage('Server stopped');
end-proc;

dcl-proc loadConfig;
  dcl-pi *n likeds(il_config) end-pi;

  dcl-ds config likeds(il_config) inz;

  config.port = 44000;
  config.host = '*ANY';

  return config;
end-proc;

```

### 6.2 Configuration Routes (employee.route.sqlrpgle)

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
// Main route setup procedure
dcl-proc employee_setupRoutes export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Add middleware for logging all employee requests
  // il_addMiddleware(config : %paddr('employee_logMiddleware') : '^/api/employees/.*$');
  
  // Routes CRUD compatible with React Admin simple rest data provider
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
  
  // // CORS preflight handling
  // il_addRoute(config : %paddr('employee_options') : IL_OPTIONS : '^/api/employees/.*$');
  
  // // Utility routes
  // il_addRoute(config : %paddr('employee_health') : IL_GET : '^/api/employees/health$');
  // il_addRoute(config : %paddr('employee_apiDocs') : IL_GET : '^/api/employees/docs$');
  
end-proc;

// Register complete employee API with all endpoints
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

### 6.3 Handler GET Collection (employee.rest.sqlrpgle)

```rpg

// GET /employees - Search with pagination (React Admin compatible)
dcl-proc employee_getlist_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError);

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields); 
  // ⚡ Définir les champs supportés pour les filtres et tris
  clear lSupportedFields;
  clear lErrors;  
  if not employee_getSupportedFields(lSupportedFields:lErrors);
  endif; 
  // ⚡ CREST : Initialisation REST centralisée (validation + parsing)
  if (not CREST_initRestRequest(request : lSupportedFields
                                : response : lContext));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Debug log before calling employee_search
  CKOOL_logMessage('About to call employee_search with context');
  CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));
  CKOOL_logMessage('Pagination perPage: ' + %char(lContext.pagination.perPage));
  
  // Appel de votre procédure existante
  monitor;
    if employee_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('employee_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
  
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response : lTotalCount);
  
      // Write array with total count header for React Admin
      il_responseWrite(response : employeesToJson(lItems : lTotalCount));
    else;
      CKOOL_logMessage('employee_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    CKOOL_logMessage('Exception in employee_search call: ' + %trimr(%char(%error)));
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Exception during search: ' + 
        %trimr(%char(%error)) + '"}');
  endmon;
  
  on-exit;
    // Clean up
    if (lItems <> *null);
      list_clear(lItems);
    endif;
end-proc;
```

### 6.4 Helper setupPagination (CREST.sqlrpgle)

```rpg
///
// Setup pagination parameters from HTTP request
//
// Extracts pagination parameters from HTTP request and populates 
// the CMAGIC context pagination structure with validated values.
// Supports both React Admin formats: simple REST (page/perPage) 
// and classic (_page/_limit).
///
dcl-proc setupPagination;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  dcl-ds lRequest likeDS(request);  
  dcl-s pageParam varchar(10);
  dcl-s limitParam varchar(10);
  
  // Initialisation.
  CKOOL_logMessage('=== DÉBUT setupPagination ===');
  clear lRequest;
  lRequest = request;
 
  // Valeurs par défaut CMAGIC
  context.pagination.numPage = 1;
  context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
  
  // Traitement.
  // 1. Format simple REST (priorité)
  pageParam = il_getQueryParameter(lRequest : 'page' : '');
  limitParam = il_getQueryParameter(lRequest : 'perPage' : '');
  
  if (%len(%trim(pageParam)) > 0 or %len(%trim(limitParam)) > 0);
    CKOOL_logMessage('Format simple REST détecté');
    monitor;
      if (%len(%trim(pageParam)) > 0);
        context.pagination.numPage = %int(%trim(pageParam));
        CKOOL_logMessage('page = ' + %trim(pageParam));
      endif;
      if (%len(%trim(limitParam)) > 0);
        context.pagination.perPage = %int(%trim(limitParam));
        CKOOL_logMessage('perPage = ' + %trim(limitParam));
      endif;
    on-error;
      CKOOL_logMessage('Erreur conversion simple REST, valeurs par défaut');
      context.pagination.numPage = 1;
      context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
    endmon;
  else;
    // 2. Format classique React Admin
    pageParam = il_getQueryParameter(lRequest : '_page' : '');
    limitParam = il_getQueryParameter(lRequest : '_limit' : '');
  
    monitor;
      if (%len(%trim(pageParam)) > 0);
        context.pagination.numPage = %int(%trim(pageParam));
        CKOOL_logMessage('_page = ' + %trim(pageParam));
      endif;
      if (%len(%trim(limitParam)) > 0);
        context.pagination.perPage = %int(%trim(limitParam));
        CKOOL_logMessage('_limit = ' + %trim(limitParam));
      endif;
    on-error;
      CKOOL_logMessage('Erreur conversion classique, valeurs par défaut');
      context.pagination.numPage = 1;
      context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
    endmon;
  endif;
  
  // Validation selon constantes CMAGIC
  if (context.pagination.numPage < 1);
    CKOOL_logMessage('Page invalide, correction à 1');
    context.pagination.numPage = 1;
  endif;
  if (context.pagination.perPage < 1);
    context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
  endif;
  if (context.pagination.perPage > 100);
    CKOOL_logMessage('PerPage trop élevé, limitation à 100');
    context.pagination.perPage = 100;
  endif;
  
  CKOOL_logMessage('=== FIN setupPagination - Page: ' + %char(context.pagination.numPage) + 
                   ' PerPage: ' + %char(context.pagination.perPage) + ' ===');
end-proc;
```

### 6.5 Helper setupFilters (CREST.sqlrpgle)

```rpg
///
// Setup dynamic filters from HTTP request parameters
//
// Analyzes ILEastic request parameters to detect REST filters and 
// populates the CMAGIC context filter array.
///
dcl-proc setupFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;  
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-s filterIndex int(5) inz(1);
  dcl-s filterValue varchar(100);
  dcl-s baseField varchar(32);
  dcl-s i int(5);
  dcl-s fieldsCount int(5);
  dcl-ds lSupportedField likeDS(CMAGIC_supportedField) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-ds lRequest likeDS(request);
  
  // initialisation 
  CKOOL_logMessage('=== DÉBUT setupFilters ===');
  clear lRequest;
  lRequest = request;
  clear context.filter;
  lSupportedFields = supportedFields;
  
  // traitement
  // tri par name desc 
  SORTA(D) lSupportedFields.supportedFields(*).name;  
  // Parcourir tous les champs supportés
  for-each lSupportedField in lSupportedFields.supportedFields;
    if %len(%trim(lSupportedField.name)) = *zeros;
      leave;
    endif;
    baseField = %trim(lSupportedField.name);
  
    // 1. Filtre simple (égalité)
    filterValue = il_getQueryParameter(lRequest : baseField : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' = ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 2. Filtre LIKE
    filterValue = il_getQueryParameter(lRequest : baseField + '_like' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = 'LIKE';
      context.filter(filterIndex).value = '%' + %trim(filterValue) + '%';
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' LIKE ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 3. Filtre >=
    filterValue = il_getQueryParameter(lRequest : baseField + '_gte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '>=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' >= ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 4. Filtre <=
    filterValue = il_getQueryParameter(lRequest : baseField + '_lte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' <= ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 5. Filtre <>
    filterValue = il_getQueryParameter(lRequest : baseField + '_ne' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<>';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' <> ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 6. Filtre >
    filterValue = il_getQueryParameter(lRequest : baseField + '_gt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '>';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' > ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  
    // 7. Filtre <
    filterValue = il_getQueryParameter(lRequest : baseField + '_lt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' < ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  endfor;
  
  // Gestion de la recherche générale 'q'
  filterValue = il_getQueryParameter(lRequest : 'q' : '');
  if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
    context.filter(filterIndex).field = 'SEARCH';
    context.filter(filterIndex).operator = 'LIKE';
    context.filter(filterIndex).value = '%' + %trim(filterValue) + '%';
    CKOOL_logMessage('Recherche générale: ' + %trim(filterValue));
    filterIndex += 1;
  endif;
  
  CKOOL_logMessage('=== FIN setupFilters - ' + %char(filterIndex - 1) + ' filtres ===');
end-proc;
```

### 6.6 Helper setupSorting (CREST.sqlrpgle)

```rpg
///
// Setup dynamic sorting from HTTP request parameters
//
// Extracts sorting parameters from request and populates CMAGIC context.
// Supports both React Admin formats.
///
dcl-proc setupSorting;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-s sortField varchar(100);
  dcl-s sortOrder varchar(10);
  dcl-s sortIndex int(5) inz(1);
  dcl-s i int(5);
  dcl-ds lRequest likeDS(request);

  // Initialisation.
  CKOOL_logMessage('=== DÉBUT setupSorting ===');
  clear lRequest;
  lRequest = request;  
  clear context.sort;
  
  // Traitement.
  // Format simple REST (priorité)
  sortField = il_getQueryParameter(lRequest : 'sort' : '');
  sortOrder = il_getQueryParameter(lRequest : 'order' : 'ASC');
  
  // Fallback format classique
  if (%len(%trim(sortField)) = 0);
    sortField = il_getQueryParameter(lRequest : '_sort' : '');
    sortOrder = il_getQueryParameter(lRequest : '_order' : 'ASC');
  endif;
  
  if (%len(%trim(sortField)) > 0);
    context.sort(sortIndex).field = %trim(sortField);
    context.sort(sortIndex).order = %trim(sortOrder);
    CKOOL_logMessage('Tri principal: ' + %trim(sortField) + ' ' + %trim(sortOrder));
    sortIndex = 2;
  endif;
  
  // Tris additionnels pour cas avancés
  // Format: ?sort1=field1&order1=ASC&sort2=field2&order2=DESC
  for i = 1 to 4; // Support jusqu'à 4 tris additionnels
    sortField = il_getQueryParameter(lRequest : 'sort' + %char(i) : '');
    sortOrder = il_getQueryParameter(lRequest : 'order' + %char(i) : 'ASC');
    if (%len(%trim(sortField)) > 0 and sortIndex <= %elem(context.sort));
      context.sort(sortIndex).field = %trim(sortField);
      context.sort(sortIndex).order = %trim(sortOrder);  
      CKOOL_logMessage('Tri ' + %char(i) + ': ' + %trim(sortField) + ' ' 
        + %trim(sortOrder));
      sortIndex += 1;
    endif;
  endfor;
  
  CKOOL_logMessage('=== FIN setupSorting ===');
end-proc;
```

---

`<a name="logique-metier"></a>`

## 💼 7. IMPLÉMENTATION LOGIQUE MÉTIER

### 7.1 Procédure employee_search (employee.sqlrpgle)

```rpg
dcl-proc employee_search export;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-s lLimit int(10);
  dcl-s lOffset int(10);
  dcl-s lSelect char(5000);
  dcl-s lSelCount like(lSelect);
  dcl-s lWhere like(lSelect);
  dcl-s lOrderBy like(lSelect);
  dcl-s lFirst ind;
  dcl-ds lItemFiltre likeDS(CMAGIC_filter);
  dcl-ds lItemSort likeDS(CMAGIC_sort);
  dcl-s lItems pointer;
  // dcl-ds lItem likeds(employee_item_t) inz;
//   dcl-ds lItem;
//     id likeDS(employee_detail_t.id);
//     nom like(employee_detail_t.nom);
// end-ds;
  dcl-ds lItem likeDS(employee_item_t);

  dcl-ds lItemSQL qualified;
    code char(6);
    prenom like(employee_detail_t.prenom);  
    nom like(employee_detail_t.nom);
    initiale like(employee_detail_t.initiale);
    service like(employee_detail_t.service);
  end-ds;
//   dcl-ds lItem qualified;
//   dcl-ds id;
//     code char(6);
//   end-ds;
//     nom like(employee_detail_t.nom);
// end-ds;
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);
  dcl-s dbFieldName varchar(32);
  dcl-s isNumericField ind;
  dcl-ds lContext likeds(pContext);
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lIt int(5);
  //initialisation
    clear pTotalCount;
    clear pItems;
    clear pErrors;
    clear lItems;
    clear lContext;
    lContext = pContext;
    lItems = list_create();
    clear lSupportedFields;
    clear lErrors;
    if not employee_getSupportedFields(lSupportedFields:lErrors);
    endif;
  // contrôle context.
   
  // limit => number of rows per page
    lLimit = pContext.pagination.perPage;
  // offset start
    lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
    if lLimit < 1;
      lLimit = CMAGIC_DEFAULT_LIMIT;
    endif;  
  // traitement 
    clear lSelect;
    lSelect = 'select empno, firstnme, lastname, midinit, workdept ' 
            + ' from employee';
    // filtre 
    clear lWhere;
    lFirst = *on;
    SORTA(D) lContext.filter(*).field; 
    for-each lItemFiltre in lContext.filter;
      if %len(%trim(lItemFiltre.field)) = *zeros;
        leave;
      endif;
  
      if lFirst;
        lWhere = 'WHERE';
        lFirst = *off;
      else;
        lWhere = %trim(lWhere) + ' AND' ;
      endif;
  
      // Traitement spécial pour la recherche générale 'q'
      if %trim(lItemFiltre.field) = 'q';
        // Recherche sur plusieurs champs pour 'q' (nom, prenom, service)
        lWhere = ' ' + %trim(lWhere) + ' (';
        lWhere = %trim(lWhere) + 'UPPER(lastname) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ' OR UPPER(firstnme) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ' OR UPPER(workdept) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ')';
      else;
        // Filtres normaux avec operator explicite
        clear lString;
        lString = %trim(lItemFiltre.value);
        // chercher dans la liste des champs supportés
        isNumericField = *off;
        SORTA(D) lSupportedFields.supportedFields(*).name;  

        clear lIt;
        lIt = %lookup(%trim(lItemFiltre.field)
          :lSupportedFields.supportedFields(*).name);
        // Vérifier si le champ est numérique
        if lIt > 0;
          if lSupportedFields.supportedFields(lIt).dataType = typeChamp.NUMERIC;
            isNumericField = *on;
          endif;
          // Mapper les noms de champs vers les noms de colonnes DB
          clear dbFieldName;
          dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
        else;
          iter;
        endif;
    
        if not (%trim(lItemFiltre.operator) = CMAGIC_OP_LIKE);
          if not isNumericField;
            lWhere = ' ' + %trim(lWhere) + ' upper(' + %trim(dbFieldName) + ')';
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          else;  
            lWhere = ' ' + %trim(lWhere) + '  ' + %trim(dbFieldName) ;
          endif;
        else;  
          lWhere = ' ' + %trim(lWhere) + ' upper(' + %trim(dbFieldName) + ')';
        endif;
        // Utiliser l'operator du filtre
        select;
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LIKE;
            lWhere = ' ' + %trim(lWhere) + ' LIKE ';
            // S'assurer que la valeur contient des % pour LIKE
            if %scan('%' : %trim(lString)) = 0;
              lString = '%' + %trim(lString) + '%';
            endif;
            lWhere = %trim(lWhere) + ' UPPER(' 
              + GLOBAL_QUOTE + %upper(%trim(lString)) + GLOBAL_QUOTE + ')';
          when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' >= ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' <= ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER;
            lWhere = ' ' + %trim(lWhere) + ' > ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS;
            lWhere = ' ' + %trim(lWhere) + ' < ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_NOT_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' <> ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          other; // CMAGIC_OP_EQUAL ou par défaut
            lWhere = ' ' + %trim(lWhere) + ' = ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
        endsl;
      endif;
    endfor;
    if lWhere <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lWhere); 
    endif;
    lSelCount = 'select count(*) from (' +
    %trim(lSelect) +') a';
    // DEBUG
    snd-msg *INFO ('LSELECT ' + %trim(lSelect) + '/');
    // le tri 
    clear lOrderBy;
    lFirst = *on;
    SORTA(D) lContext.sort(*).field; 
    for-each lItemSort in lContext.sort;
      if %len(%trim(lItemSort.field)) = *zeros;
        leave;
      endif;
      // Mapper les noms de champs vers les noms de colonnes DB ***
      clear dbFieldName;
      clear lIt;
      lIt = %lookup(%trim(lItemSort.field)
         :lSupportedFields.supportedFields(*).name);
      if lIt > *zeros;
        dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
      else;
        iter;
      endif;  
      if lFirst;
        lOrderBy = 'Order by';
        lFirst = *off;
      else;
        lOrderBy = %trim(lOrderBy) + ' ,' ;
      endif;
      lOrderBy = ' ' +%trim(lOrderBy) + ' ' + %trim(dbFieldName);
      lOrderBy = ' ' + %trim(lOrderBy) + ' ' + %trim(lItemSort.order); 
    endfor;
    if lOrderBy <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lOrderBy); 
    endif;
    // la requete complete avec la pagination 
    lSelect = %trim(lSelect)  + 
  ' LIMIT ' + %char(lLimit) + 
  ' OFFSET ' + %char(lOffset);
  //Prepare
    Exec sql prepare SqlStmt From :lSelect;
  //PrÃ©paration du curseur
    Exec sql declare cListe  cursor for SqlStmt;
  //Ouverture du curseur
    Exec SQL open cListe; 
    if (sqlState <> SQL_OK);
    clear lError;
    lError.code = %trim(sqlState);
    // exec sql GET DIAGNOSTICS CONDITION 1 :lError.text = MESSAGE_TEXT;
    CKOOL_ThrowError(lError);
  endif;
  dow (sqlState = SQL_OK);
    //ÂšLecture suivante du curseur
     clear lItemSQL;
    Exec SQL Fetch Next
    From cListe
    Into :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    // ajout de l'item dans la liste
    clear lItem;
    lItem = lItemSQL;
    list_add(lItems: %addr(lItem): %size(lItem));
  
    enddo;
  // comptage total                                   
  //Prepare
    Exec sql prepare SqlStmt2 From :lSelCount;
  //PrÃ©paration du curseur
    Exec sql declare cCountListe  cursor for SqlStmt2;
  //Ouverture du curseur
    Exec SQL open cCountListe; 
  //ÂšLecture suivante du curseur
    clear lCount;
    Exec SQL   FETCH cCountListe into :lCount;   

  // finalisation 
    pItems = lItems;
    pTotalCount = lCount;
    return *on;
    on-exit ErrorHappened;
      //fermeture  du curseur
      Exec SQL close cListe; 
      //fermeture  du curseur
      Exec SQL close cCountListe; 
      if ErrorHappened;
          list_dispose(lItems);
          return *off;
      endif;
end-proc; 
```

### 7.2 Autres Procédures CRUD

**employee_getByID** - Déjà correct dans votre code
**employee_create** - Déjà correct dans votre code
**employee_change** - Déjà correct dans votre code
**employee_delete** - Déjà correct dans votre code

`<a name="conversion-json"></a>`

## 📄 8. CONVERSION JSON

### 8.1 employeesToJson (Collection) (employee.rest.sqlrpgle)

```rpg
// Helper functions for JSON conversion

///
// Convert list of employees to JSON array
//
// Converts a linked list of employees to JSON format with total count
// for React Admin compatibility.
//
// @param **in**  employees   pointer to linked list of employee items
// @param **in**  totalCount  total number of employees found
// @return JSON string representation of employee list
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc employeesToJson;
  dcl-pi *n varchar(1048576);
    employees pointer const;
    totalCount like(CMAGIC_totalCount) const;
  end-pi;

  dcl-s json varchar(1048576);
  dcl-s first ind inz(*on);
  dcl-ds employee likeds(employee_item_t) based(ptr);
  
  json = '[';
  
  ptr = list_iterate(employees);
  dow (ptr <> *null);
    if (not first);
      json += ',';
    endif;
    json += employeeItemToJson(employee);
    first = *off;
    ptr = list_iterate(employees);
  enddo;
  
  json += ']';
  
  return json;
end-proc;
```

### 8.2 employeeToJson (Objet unique) (employee.rest.sqlrpgle)

```rpg
dcl-proc employeeToJson;
  dcl-pi *n varchar(4096);
    employee likeds(employee_detail_t) const;
  end-pi;

  dcl-s json varchar(4096);
  
  json = '{';
  json += '"id":"' + %trim(employee.id.code) + '",';
  json += '"prenom":"' + escapeJson(%trim(employee.prenom)) + '",';
  json += '"nom":"' + escapeJson(%trim(employee.nom)) + '",';
  json += '"initiale":"' + %trim(employee.initiale) + '",';
  json += '"service":"' + %trim(employee.service) + '",';
  json += '"dateEmbauche":"' + %char(employee.dateEmbauche : *iso) + '",';
  json += '"dateNaissance":"' + %char(employee.dateNaissance : *iso) + '",';
  json += '"genre":"' + %trim(employee.genre) + '",';
  json += '"salaire":' + %char(employee.salaire);  // Pas de quotes pour nombre
  json += '}';
  
  return json;
end-proc;
```

### 8.3 Helper escapeString (crest.sqlrpgle)

- Échapper les chaînes pour JSON

```rpg
dcl-proc escapeString;
  dcl-pi *n varchar(1000);
    value varchar(1000) const;
  end-pi;
  
  dcl-s result varchar(1000);
  
  result = value;
  
  // Échapper les caractères spéciaux JSON
  result = %scanrpl('\' : '\\' : result);  // Backslash en premier
  result = %scanrpl('"' : '\"' : result);  // Guillemets
  result = %scanrpl(x'0D' : '\r' : result); // Carriage return
  result = %scanrpl(x'0A' : '\n' : result); // Line feed
  result = %scanrpl(x'09' : '\t' : result); // Tab
  
  return result;
end-proc;
```

### 8.4 CREST_errorsToJson (Liste d'erreurs)

```rpg
dcl-proc CREST_errorsToJson export;
  dcl-pi *n varchar(2048);
    errors likeds(GLOBAL_listError) const;
  end-pi;
  
  dcl-s json varchar(2048);
  dcl-ds lErrors likeds(GLOBAL_listError);
  dcl-ds lError likeds(errorItem);
  dcl-s first ind inz(*on);
  
  clear lErrors;
  lErrors = errors;
  json = '{"errors":[';
  
  for-each lError in lErrors.listError;
    if lError.text = *blanks;
      leave;
    endif;
  
    if (not first);
      json += ',';
    endif;
  
    json += '{';
    json += '"code":"' + escapeString(%trim(lError.code)) + '",';
    json += '"zone":"' + escapeString(%trim(lError.nomZone)) + '",';
    json += '"valeur":"' + escapeString(%trim(lError.valeur)) + '",';
    json += '"texte":"' + escapeString(%trim(lError.text)) + '",';
    json += '"texteUser":"' + escapeString(%trim(lError.textUser)) + '"';
    json += '}';
  
    first = *off;
  endfor;
  
  json += ']}';
  return json;
end-proc;
```

`<a name="points-critiques"></a>`

## 🚨 9. POINTS CRITIQUES (NE PAS OUBLIER)

### 9.1 Header X-Total-Count OBLIGATOIRE

```rpg
// ✅ CORRECT
il_addHeader(response : 'X-Total-Count' : %char(lTotalCount));
il_responseWrite(response : employeesToJson(lItems : lTotalCount));

// ❌ INCORRECT
il_responseWrite(response : employeesToJson(lItems : lTotalCount));
// Manque le header !
```

### 9.2 Compter AVANT Pagination

```rpg
// ✅ CORRECT
lSelCount = 'select count(*) from (' + %trim(lSelect) + ') a';
// ... puis ajouter LIMIT/OFFSET
lSelect = %trim(lSelect) + ' LIMIT ' + %char(lLimit) + ' OFFSET ' + %char(lOffset);

// ❌ INCORRECT
lSelect = %trim(lSelect) + ' LIMIT ' + %char(lLimit) + ' OFFSET ' + %char(lOffset);
lSelCount = 'select count(*) from (' + %trim(lSelect) + ') a';
// Le count inclut le LIMIT, donc faux !
```

### 9.3 Tableau vs Objet JSON

```rpg
// ✅ CORRECT - Collection
json = '[';
// ... items
json += ']';

// ✅ CORRECT - Objet unique
json = '{';
// ... fields
json += '}';

// ❌ INCORRECT - Collection en objet
json = '{"data":[...],"total":123}';  // Pas de wrapper !
```

### 9.4 Utiliser operator du Filtre

```rpg
// ✅ CORRECT
lOperator = %trim(lItemFiltre.operator);
lWhere = %trim(lWhere) + ' ' + %trim(lItemFiltre.field);
lWhere = %trim(lWhere) + ' ' + lOperator;
lWhere = %trim(lWhere) + ' ' + GLOBAL_QUOTE + lValue + GLOBAL_QUOTE;

// ❌ INCORRECT
lWhere = %trim(lWhere) + ' ' + %trim(lItemFiltre.field) + ' = ' + ...;
// Ignore l'opérateur !
```

### 9.5 Validation des Paramètres

```rpg
// ✅ CORRECT
if (lContext.pagination.numPage < 1);
  lContext.pagination.numPage = 1;
endif;

if (lContext.pagination.perPage < 1);
  lContext.pagination.perPage = 10;
endif;

if (lContext.pagination.perPage > 100);
  lContext.pagination.perPage = 100;
endif;
```

### 9.6 Gestion d'Erreurs MONITOR

```rpg
// ✅ CORRECT
monitor;
  // Code susceptible d'erreur
  if employee_search(...);
    // Success
  else;
    // Error
  endif;
on-error;
  CKOOL_logMessage('Exception: ' + %char(%error));
  response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
endmon;
```

### 9.7 Codes HTTP Appropriés

```rpg
// ✅ CORRECT
response.status = IL_HTTP_OK;              // 200 - GET, PUT, DELETE OK
response.status = IL_HTTP_CREATED;         // 201 - POST créé
response.status = IL_HTTP_BAD_REQUEST;     // 400 - Validation
response.status = IL_HTTP_NOT_FOUND;       // 404 - Ressource introuvable
response.status = IL_HTTP_INTERNAL_SERVER_ERROR;  // 500 - Erreur serveur
```

`<a name="tests-debug"></a>`

## 🧪 10. TESTS ET DEBUG

### 10.1 Tests cURL Complets

```bash
# === TESTS DE BASE ===

# Santé du serveur
curl http://your-ibmi:44000/health

# Liste simple
curl http://your-ibmi:44000/api/employees

# Vérifier header X-Total-Count
curl -I http://your-ibmi:44000/api/employees

# === TESTS PAGINATION ===

# Page 1, 5 éléments
curl "http://your-ibmi:44000/api/employees?_page=1&_limit=5"

# Page 2, 10 éléments
curl "http://your-ibmi:44000/api/employees?_page=2&_limit=10"

# === TESTS TRI ===

# Tri par nom croissant
curl "http://your-ibmi:44000/api/employees?_sort=lastname&_order=asc"

# Tri par salaire décroissant
curl "http://your-ibmi:44000/api/employees?_sort=salary&_order=desc"

# === TESTS FILTRES SIMPLES ===

# Département A00
curl "http://your-ibmi:44000/api/employees?workdept=A00"

# Sexe M
curl "http://your-ibmi:44000/api/employees?sex=M"

# Filtres multiples
curl "http://your-ibmi:44000/api/employees?workdept=A00&sex=M"

# === TESTS FILTRES AVANCÉS ===

# LIKE
curl "http://your-ibmi:44000/api/employees?lastname_like=HAA"

# >= (supérieur ou égal)
curl "http://your-ibmi:44000/api/employees?salary_gte=50000"

# <= (inférieur ou égal)
curl "http://your-ibmi:44000/api/employees?salary_lte=100000"

# BETWEEN (combinaison)
curl "http://your-ibmi:44000/api/employees?salary_gte=50000&salary_lte=100000"

# <> (différent)
curl "http://your-ibmi:44000/api/employees?workdept_ne=A00"

# === TEST RECHERCHE FULL-TEXT ===

curl "http://your-ibmi:44000/api/employees?q=CHRISTINE"

# === TEST COMBINAISON COMPLÈTE ===

curl "http://your-ibmi:44000/api/employees?_page=1&_limit=10&_sort=lastname&_order=asc&workdept=A00&salary_gte=50000"

# === TESTS CRUD ===

# GET un employé
curl "http://your-ibmi:44000/api/employees/000010"

# POST créer
curl -X POST "http://your-ibmi:44000/api/employees" \
  -H "Content-Type: application/json" \
  -d '{
    "prenom":"JOHN",
    "nom":"DOE",
    "initiale":"J",
    "service":"A00",
    "genre":"M",
    "dateNaissance":"1990-01-01",
    "dateEmbauche":"2024-01-01",
    "salaire":50000
  }'

# PUT modifier
curl -X PUT "http://your-ibmi:44000/api/employees/000010" \
  -H "Content-Type: application/json" \
  -d '{
    "nom":"HAAS-SMITH",
    "salaire":55000
  }'

# DELETE
curl -X DELETE "http://your-ibmi:44000/api/employees/000999"

# === TESTS D'ERREUR ===

# Ressource inexistante
curl "http://your-ibmi:44000/api/employees/999999"

# Paramètres invalides
curl "http://your-ibmi:44000/api/employees?_page=abc"

# POST sans body
curl -X POST "http://your-ibmi:44000/api/employees" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 10.2 Debug et Troubleshooting

- Si X-Total-Count non visible :

```rpg
// Vérifier qu'il est ajouté
il_addHeader(response : 'X-Total-Count' : %char(lTotalCount));

// Vérifier qu'il est exposé (dans main ou middleware CORS)
il_addHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
```

- Si filtres ne fonctionnent pas :

```rpg
// Ajouter logs dans setupFilters
for i = 1 to filterIndex - 1;
  CKOOL_logMessage('Filter ' + %char(i) + ': ' + 
                   %trim(context.filter(i).field) + ' ' +
                   %trim(context.filter(i).operator) + ' ' +
                   %trim(context.filter(i).value));
endfor;

// Logger le SQL généré
CKOOL_logMessage('SQL WHERE: ' + %trim(lWhere));
```

- Si pagination incorrecte :

```rpg
// Logger les valeurs
CKOOL_logMessage('numPage: ' + %char(pContext.pagination.numPage));
CKOOL_logMessage('perPage: ' + %char(pContext.pagination.perPage));
CKOOL_logMessage('Offset: ' + %char(lOffset));
CKOOL_logMessage('Limit: ' + %char(lLimit));
CKOOL_logMessage('Total Count: ' + %char(lCount));
```

- Si erreurs SQL :

```rpg
if (sqlState <> SQL_OK);
  CKOOL_logMessage('SQL State: ' + sqlState);
  exec sql GET DIAGNOSTICS CONDITION 1 :lError.text = MESSAGE_TEXT;
  CKOOL_logMessage('SQL Error: ' + %trim(lError.text));
  CKOOL_logMessage('SQL Statement: ' + %trim(lSelect));
endif;
```

`<a name="prompts-copilot"></a>`

## 🎓 11. PROMPTS POUR COPILOT

### 11.1 Créer une nouvelle ressource

```md
Crée un module REST RPG pour la ressource "departments" en suivant le pattern de employee avec :
- Fichiers : department.rest.sqlrpgle, department.route.sqlrpgle, department.sqlrpgle, department.rpgleinc
- Routes : GET /api/departments (liste), GET /api/departments/{id}, POST, PUT, DELETE
- Structures : department_detail_t et department_item_t
- Utilise CMAGIC_context pour pagination/tri/filtres
- Retourne tableau JSON avec X-Total-Count pour GET collection
- Base SQL : table DEPARTMENT (deptno, deptname, mgrno, admrdept)
```

### 11.2 Améliorer setupFilters

```md
Dans employee.rest.sqlrpgle, améliore setupFilters pour :
- Ajouter le support de tous les opérateurs (_like, _gte, _lte, _gt, _lt, _ne)
- Stocker l'opérateur dans CMAGIC_filter.operator
- Gérer correctement le paramètre q pour recherche full-text
- Logger chaque filtre détecté pour debug
- Valider que les champs sont dans la liste supportedFields
```

### 11.3 Optimiser employee_search

```md
Dans employee.sqlrpgle, optimise employee_search pour :
- Utiliser context.filter(x).operator au lieu de détecter % dans value
- Gérer les valeurs numériques vs texte pour les quotes SQL
- Ajouter un cas spécial pour operator='SEARCH' (recherche full-text)
- Logger le SQL généré (SELECT et COUNT)
- Améliorer la gestion d'erreurs SQL avec messages détaillés
- Assurer que le COUNT est fait avant l'ajout de LIMIT/OFFSET
```

### 11.4 Créer une action métier

```md
Crée une procédure et un handler REST pour POST /api/employees/{id}/increase-salary qui :
- Handler dans employee.rest.sqlrpgle : employee_increasesalary_rest
- Procédure dans employee.sqlrpgle : employee_applySalaryIncrease
- Paramètres JSON : amount (montant augmentation en %)
- Validation : amount > 0 et <= 50
- Met à jour salary = salary * (1 + amount/100)
- Retourne l'employé mis à jour avec le nouveau salaire
- Gère les erreurs (employé inexistant, montant invalide)
- Status 200 si OK, 400 si erreur métier, 404 si employé non trouvé
```

### 11.5 Ajouter logging performance

```md
Dans employee_getlist_rest, ajoute :
- Variable startTime et endTime (timestamp)
- Calcul duration = %diff(endTime : startTime : *MS)
- Log en fin de procédure avec :
  * Durée d'exécution en ms
  * Nombre de filtres appliqués
  * Total trouvé vs retourné
  * Paramètres pagination
```

### 11.6 Créer tests automatisés

```md
Crée un programme de test RPG test_employee_api.rpgle qui :
- Teste employee_search avec différentes combinaisons pagination/tri/filtres
- Vérifie que le total count est correct
- Vérifie que les filtres sont bien appliqués
- Teste les cas limites (page invalide, limit trop grand)
- Affiche les résultats des tests (OK/KO)
- Utilise des données de la table EMPLOYEE
```

`<a name="checklist"></a>`

## ✅ 12. Checklist de Validation

### Routes ILEastic

- [ ] `GET /api/employees` retourne un tableau JSON
- [ ] `GET /api/employees/{id}` retourne un objet JSON
- [ ] `POST /api/employees` crée avec status 201
- [ ] `PUT /api/employees/{id}` met à jour avec status 200
- [ ] `DELETE /api/employees/{id}` supprime avec status 200

### Headers HTTP

- [ ] `X-Total-Count` présent dans GET collection
- [ ] `X-Total-Count` contient le total GLOBAL (pas juste la page)
- [ ] `X-Total-Count` exposé via `Access-Control-Expose-Headers`
- [ ] `Content-Type: application/json` sur toutes les réponses

### Pagination

- [ ] Paramètres `*page` et `*limit` supportés
- [ ] Page commence à 1 (pas 0)
- [ ] Offset calculé : `(page - 1) × limit`
- [ ] Total count calculé AVANT `LIMIT/OFFSET` dans SQL
- [ ] Validation `page >= 1` et `limit >= 1`
- [ ] Limite max (ex: 100) pour éviter surcharge

### Tri

- [ ] Paramètres `*sort` et `*order` supportés
- [ ] `ORDER BY` construit dynamiquement
- [ ] `order` accepte `ASC` et `DESC` (case insensitive)
- [ ] Tri par défaut si non spécifié

### Filtres

- [ ] Égalité simple (`field=value`)
- [ ] Opérateur `_like` avec `%` automatique
- [ ] Opérateurs `*gte`, `*lte`, `*gt`, `*lt`, `_ne` supportés
- [ ] Recherche full-text avec `q`
- [ ] `WHERE` construit dynamiquement avec `AND`
- [ ] Gestion quotes pour texte vs numérique

### SQL

- [ ] Prepared statements utilisés
- [ ] Curseurs ouverts et fermés proprement
- [ ] `sqlState` vérifié après chaque `exec sql`
- [ ] Erreurs SQL loggées avec `GET DIAGNOSTICS`
- [ ] Count fait sur requête AVANT pagination

### JSON

- [ ] `employeesToJson` retourne `[...]`
- [ ] `employeeToJson` retourne `{...}`
- [ ] Échappement guillemets et caractères spéciaux
- [ ] Pas de virgule trailing dans tableaux
- [ ] Nombres sans quotes, texte avec quotes
- [ ] Dates au format ISO 8601

### Erreurs

- [ ] `MONITOR/ON-ERROR` sur toutes les procédures
- [ ] Codes HTTP appropriés (200, 201, 400, 404, 500)
- [ ] Messages d'erreur en JSON
- [ ] Logging avec `CKOOL_logMessage`
- [ ] `On-exit` pour cleanup (curseurs, listes)

### Performance

- [ ] SQL optimisé avec indexes appropriés
- [ ] Pas de `SELECT *` si pas nécessaire
- [ ] Limite max sur pagination
- [ ] Logging temps d'exécution

`<a name="data-provider"></a>`

## 📱 13. DATA PROVIDER REACT-ADMIN

```javascript
import { fetchUtils } from 'react-admin';
import { stringify } from 'query-string';

const apiUrl = 'http://your-ibmi-server:44000/api';
const httpClient = fetchUtils.fetchJson;

export const dataProvider = {
  getList: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
  
    const query = {
      _page: page,
      _limit: perPage,
      _sort: field,
      _order: order,
      ...params.filter
    };
  
    const url = `${apiUrl}/${resource}?${stringify(query)}`;
    const { headers, json } = await httpClient(url);
  
    return {
      data: json,
      total: parseInt(headers.get('x-total-count') || '0', 10)
    };
  },
  
  getOne: async (resource, params) => {
    const url = `${apiUrl}/${resource}/${params.id}`;
    const { json } = await httpClient(url);
    return { data: json };
  },
  
  getMany: async (resource, params) => {
    const requests = params.ids.map(id => 
      httpClient(`${apiUrl}/${resource}/${id}`)
    );
    const responses = await Promise.all(requests);
    return { data: responses.map(({ json }) => json) };
  },
  
  getManyReference: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
  
    const query = {
      _page: page,
      _limit: perPage,
      _sort: field,
      _order: order,
      [params.target]: params.id,
      ...params.filter
    };
  
    const url = `${apiUrl}/${resource}?${stringify(query)}`;
    const { headers, json } = await httpClient(url);
  
    return {
      data: json,
      total: parseInt(headers.get('x-total-count') || '0', 10)
    };
  },
  
  create: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}`, {
      method: 'POST',
      body: JSON.stringify(params.data)
    });
    return { data: json };
  },
  
  update: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
      method: 'PUT',
      body: JSON.stringify(params.data)
    });
    return { data: json };
  },
  
  updateMany: async (resource, params) => {
    const requests = params.ids.map(id =>
      httpClient(`${apiUrl}/${resource}/${id}`, {
        method: 'PUT',
        body: JSON.stringify(params.data)
      })
    );
    await Promise.all(requests);
    return { data: params.ids };
  },
  
  delete: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
      method: 'DELETE'
    });
    return { data: json };
  },
  
  deleteMany: async (resource, params) => {
    const requests = params.ids.map(id =>
      httpClient(`${apiUrl}/${resource}/${id}`, { method: 'DELETE' })
    );
    await Promise.all(requests);
    return { data: params.ids };
  }
};
```
---

`<a name="roadmap"></a>`

## 🚀 14. ROADMAP ET RESSOURCES

### Phase 1 : Fondations (Fait ✅)

- [X] Structure de base avec ILEastic
- [X] GET collection avec pagination basique
- [X] GET one
- [X] Header X-Total-Count
- [X] POST, PUT, DELETE

### Phase 2 : Filtres Avancés (En cours)

- [ ] Modifier CMAGIC_filter pour ajouter operator
- [ ] setupFilters complet avec tous les opérateurs
- [ ] Adapter employee_search pour utiliser operator
- [ ] Tests complets de tous les opérateurs

### Phase 3 : Optimisation

- [ ] Validation complète des données
- [ ] Gestion erreurs métier détaillée
- [ ] Logging performance sur chaque endpoint
- [ ] Cache pour requêtes fréquentes
- [ ] Index DB2 optimaux

### Phase 4 : Actions Métier

- [ ] POST /employees/{id}/increase-salary
- [ ] POST /employees/{id}/promote
- [ ] POST /employees/{id}/transfer
- [ ] Historique des actions

### Phase 5 : Documentation et Tests

- [ ] Documentation OpenAPI/Swagger
- [ ] Tests automatisés RPG
- [ ] Tests d'intégration
- [ ] Guide déploiement

### Ressources

**ILEastic**

- GitHub : https://github.com/sitemule/ILEastic
- Documentation : https://github.com/sitemule/ILEastic/wiki
- Exemples : https://github.com/sitemule/ILEastic/tree/master/examples

**RPG ILE Free**

- IBM i 7.5 Documentation
- SQL pour RPG : IBM DB2 for i SQL Reference
- JSON en RPG : YAJL library ou DATA-INTO

**Standards REST**

- HTTP Status Codes : https://httpstatuses.com/
- REST API Best Practices
- Pagination Patterns

---

## 📝 NOTES FINALES POUR COPILOT

### Ordre de Priorité des Instructions

1. **TOUJOURS** retourner tableau `[...]` pour GET collection
2. **TOUJOURS** retourner objet `{...}` pour GET one
3. **TOUJOURS** inclure header `X-Total-Count` pour GET collection
4. **TOUJOURS** compter le total AVANT LIMIT/OFFSET dans SQL
5. **TOUJOURS** exposer `X-Total-Count` dans CORS
6. **TOUJOURS** utiliser `context.filter(x).operator` dans le WHERE
7. **TOUJOURS** valider les paramètres (page >= 1, limit >= 1)
8. **TOUJOURS** gérer les erreurs avec MONITOR/ON-ERROR
9. **TOUJOURS** retourner les codes HTTP appropriés
10. **TOUJOURS** logger les erreurs et infos importantes

### Principes de Code RPG

- **Clarté avant concision** : Code lisible et maintenable
- **Commentaires** : Expliquer les parties complexes
- **Cohérence** : Même pattern pour toutes les ressources
- **Validation** : Toujours valider avant d'exécuter
- **Erreurs explicites** : Messages d'erreur clairs en JSON
- **Logging** : Logger avec CKOOL_logMessage
- **Cleanup** : ON-EXIT pour fermer curseurs et libérer mémoire
- **Performance** : Optimiser SQL avec indexes

### Format SQL Recommandé

```rpg
// Construction WHERE
lWhere = 'WHERE field1 = ''value1'' AND field2 >= 100';

// Construction ORDER BY
lOrderBy = 'ORDER BY field1 ASC, field2 DESC';

// Construction finale avec pagination
lSelect = 'SELECT ... FROM table ' + %trim(lWhere) + ' ' + 
          %trim(lOrderBy) + ' LIMIT ' + %char(lLimit) + 
          ' OFFSET ' + %char(lOffset);

// Count AVANT pagination
lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelectBase) + 
            ' ' + %trim(lWhere) + ') a';
```

### Conventions de Nommage

**Procédures exportées (handlers REST) :**

- `resourcename_action_rest` : ex. `employee_getlist_rest`

**Procédures métier :**

- `resourcename_action` : ex. `employee_search`, `employee_getByID`

**Helpers privés :**

- `actionDescription` : ex. `setupFilters`, `employeesToJson`

**Variables locales :**

- Préfixe `l` : ex. `lContext`, `lTotalCount`, `lItems`
- Préfixe `p` pour paramètres : ex. `pContext`, `pTotalCount`

**Structures de données :**

- Suffixe `_t` pour templates : ex. `employee_detail_t`, `employee_item_t`

---

## 🎯 DÉMARRAGE RAPIDE

### Pour Créer une Nouvelle Ressource

1. **Copier les fichiers employee.xxx**
2. **Renommer avec le nouveau nom de ressource**
3. **Adapter les structures de données** (detail_t, item_t)
4. **Modifier le SQL** (table, champs)
5. **Adapter les champs filtrables** dans setupFilters
6. **Tester avec cURL**
7. **Créer le Data Provider React-Admin**

### Pour Ajouter un Filtre

1. **Ajouter le champ** dans supportedFields (setupFilters)
2. **Aucune autre modification nécessaire** (les opérateurs sont gérés automatiquement)
3. **Tester** : `curl "http://server/api/resource?field_gte=value"`

### Pour Ajouter une Action Métier

1. **Créer la procédure métier** dans resource.sqlrpgle
2. **Créer le handler REST** dans resource.rest.sqlrpgle
3. **Ajouter la route** dans resource.route.sqlrpgle :
   ```rpg
   il_addRoute(config : %paddr('resource_action_rest') 
     : IL_POST : '^/api/resource/([0-9A-Za-z]+)/action$');
   ```
4. **Tester** : `curl -X POST "http://server/api/resource/id/action" -d '{...}'`

## ✅ VALIDATION FINALE

Avant de considérer l'API complète :

1. Tous les tests cURL passent
2. Header X-Total-Count présent et correct
3. Pagination fonctionne correctement
4. Tous les opérateurs de filtres fonctionnent
5. Tri fonctionne (ASC et DESC)
6. Recherche full-text fonctionne
7. CRUD complet fonctionne (GET, POST, PUT, DELETE)
8. Codes HTTP corrects (200, 201, 400, 404, 500)
9. Erreurs en JSON bien formaté
10. Data Provider React-Admin fonctionne
