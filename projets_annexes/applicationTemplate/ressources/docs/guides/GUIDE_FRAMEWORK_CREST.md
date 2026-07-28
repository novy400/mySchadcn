# Guide Framework CREST
## CMAGIC REST Framework pour IBM i

**Version:** 1.0  
**Date:** Janvier 2025  
**Auteur:** Équipe ArchiAPI  
**Source:** Conventions extraites du code réel `src/crest/crest.sqlrpgle`

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [API Publique](#api-publique)
4. [Procédures Internes](#procédures-internes)
5. [Patterns d'Utilisation](#patterns-dutilisation)
6. [Gestion d'Erreurs](#gestion-derreurs)
7. [Exemples Réels](#exemples-réels)

---

## Vue d'Ensemble

### Qu'est-ce que CREST ?

**CREST** (CMAGIC REST Framework) est la fusion de deux composants :
- **CMAGIC** : Contexte de gestion pagination/tri/filtres
- **ILEastic** : Framework HTTP pour IBM i

**Objectif** : Centraliser la logique REST répétitive pour éviter duplication de code dans chaque ressource.

### Responsabilités

**CREST prend en charge :**
- Validation des headers HTTP (Accept, Content-Type)
- Parsing des paramètres de requête (_page, _limit, _sort, filtres)
- Configuration du contexte CMAGIC
- Ajout des headers REST standard (CORS, X-Total-Count)
- Génération JSON d'erreurs

**CREST NE prend PAS en charge :**
- Logique métier spécifique
- Requêtes SQL
- Validation des données métier
- Gestion de la base de données

---

## Architecture

### Structure de Fichiers

```
src/crest/
├── crest.sqlrpgle        # Implémentation service program
├── crest.bnd             # Binding source avec versioning
└── Rules.mk              # Configuration build

includes/
└── crest.rpgleinc        # Prototypes et structures publiques
```

### Dépendances

```rpgle
/include 'ileastic/ileastic.rpgle'  // Framework HTTP
/include 'cmagic.rpgleinc'          // Contexte REST
/include 'global.rpgleinc'          // Types globaux
/include 'ckool.rpgleinc'           // Logging
```

### Niveaux de Versioning

**Binding Source** (`crest.bnd`) :
```
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('CREST.0.0.1')
  EXPORT SYMBOL('CREST_addHeaders')
  EXPORT SYMBOL('CREST_initRestRequest')
  EXPORT SYMBOL('CREST_initSimpleRestRequest')
  EXPORT SYMBOL('CREST_initWriteRestRequest')
  EXPORT SYMBOL('CREST_errorsToJson')
  EXPORT SYMBOL('CREST_simpleError')
  EXPORT SYMBOL('escapeString')
ENDPGMEXP
```

---

## API Publique

### 1. CREST_addHeaders

**Objectif** : Ajouter les headers REST standard à la réponse HTTP.

**Prototype** :
```rpgle
dcl-pr CREST_addHeaders extproc(*dclcase);
  response likeds(IL_response);
  totalCount like(CMAGIC_totalCount) const options(*nopass);
end-pr;
```

**Paramètres** :
- `response` : Structure réponse ILEastic (modifiée)
- `totalCount` : *(Optionnel)* Nombre total d'éléments pour collections

**Headers Ajoutés** :
```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Expose-Headers: X-Total-Count
X-Total-Count: {totalCount}  // Si fourni
```

**Utilisation** :
```rpgle
// GET collection avec count
CREST_addHeaders(response : lTotalCount);

// GET single item sans count
CREST_addHeaders(response);

// POST/PUT/DELETE
CREST_addHeaders(response);
```

**⚠️ OBLIGATOIRE** : Appeler dans TOUS les handlers REST, même en cas d'erreur.

---

### 2. CREST_initRestRequest

**Objectif** : Initialiser une requête REST avec validation ET parsing des paramètres.

**Prototype** :
```rpgle
dcl-pr CREST_initRestRequest ind extproc(*dclcase);
  request likeds(IL_request) const;
  supportedFields likeDs(CMAGIC_supportedFields) const;
  response likeds(IL_response);
  context likeDS(CMAGIC_context);
end-pr;
```

**Paramètres** :
- `request` : Requête HTTP ILEastic (entrée)
- `supportedFields` : Configuration champs supportés (entrée)
- `response` : Réponse HTTP (modifiée en cas d'erreur)
- `context` : Contexte CMAGIC rempli (sortie)

**Retour** :
- `*ON` : Validation réussie, context rempli
- `*OFF` : Erreur validation, response configurée avec erreur 406

**Workflow Interne** :
1. Valide header `Accept` (doit accepter `application/json` ou `*/*`)
2. Parse pagination (_page, _limit ou page, perPage)
3. Parse tri (_sort, _order ou sort, order)
4. Parse filtres dynamiques (=, _like, _gte, _lte, _ne, _gt, _lt)
5. Parse recherche générale (q)

**Utilisation Typique** :
```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  dcl-ds supportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lList pointer;
  
  // Initialisation avec validation + parsing
  supportedFields = employee_getSupportedFields();
  if not CREST_initRestRequest(request : supportedFields : response : context);
    return; // Erreur déjà envoyée
  endif;
  
  // Utilisation du contexte pour requête métier
  lList = employee_search(context : lTotalCount);
  
  // Headers + JSON
  CREST_addHeaders(response : lTotalCount);
  il_responseWriteStream(response : '[');
  // ... écriture JSON
  il_responseWriteStream(response : ']');
end-proc;
```

---

### 3. CREST_initSimpleRestRequest

**Objectif** : Initialiser une requête REST avec validation SEULEMENT (pas de parsing).

**Prototype** :
```rpgle
dcl-pr CREST_initSimpleRestRequest ind extproc(*dclcase);
  request likeds(IL_request) const;
  response likeds(IL_response);
end-pr;
```

**Paramètres** :
- `request` : Requête HTTP ILEastic (entrée)
- `response` : Réponse HTTP (modifiée en cas d'erreur)

**Retour** :
- `*ON` : Validation réussie
- `*OFF` : Erreur validation, response configurée

**Workflow Interne** :
1. Valide header `Accept` uniquement

**Utilisation Typique** :
```rpgle
dcl-proc employee_getone_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lId int(10);
  dcl-ds lDetail likeds(employee_detail_t) inz;
  
  // Validation simple (pas de filtres/pagination nécessaires)
  if not CREST_initSimpleRestRequest(request : response);
    return;
  endif;
  
  // Extraction ID depuis URL
  lId = %int(il_getParmStr(request : 'id'));
  
  // Logique métier
  if not employee_getByID(lId : lDetail);
    // Erreur 404
    return;
  endif;
  
  // Réponse JSON
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**⚠️ À utiliser pour** :
- GET `/api/resource/{id}` (item unique)
- Toute opération sans pagination/tri/filtres

---

### 4. CREST_initWriteRestRequest

**Objectif** : Initialiser une requête REST d'écriture (POST/PUT) avec validation Content-Type.

**Prototype** :
```rpgle
dcl-pr CREST_initWriteRestRequest ind extproc(*dclcase);
  request likeds(IL_request) const;
  response likeds(IL_response);
end-pr;
```

**Paramètres** :
- `request` : Requête HTTP ILEastic (entrée)
- `response` : Réponse HTTP (modifiée en cas d'erreur)

**Retour** :
- `*ON` : Validation réussie
- `*OFF` : Erreur validation (415 Unsupported Media Type)

**Workflow Interne** :
1. Valide header `Content-Type` (doit contenir `application/json`)
2. Permissif si pas de contenu dans body

**Utilisation Typique** :
```rpgle
dcl-proc employee_create_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(employee_detail_t) inz;
  dcl-ds lErrors likeds(GLOBAL_listError) inz;
  dcl-s lJsonInput varchar(10000);
  
  // Validation Content-Type
  if not CREST_initWriteRestRequest(request : response);
    return;
  endif;
  
  // Parse JSON body
  lJsonInput = il_getRequestContent(request);
  employee_jsonToDetail(lJsonInput : lDetail);
  
  // Logique métier
  if not employee_create(lDetail : lErrors);
    response.status = IL_HTTP_BAD_REQUEST;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;
  
  // Succès 201
  response.status = IL_HTTP_CREATED;
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**⚠️ À utiliser pour** :
- POST `/api/resource`
- PUT `/api/resource/{id}`
- PATCH `/api/resource/{id}`

---

### 5. CREST_errorsToJson

**Objectif** : Convertir structure d'erreurs en JSON standard.

**Prototype** :
```rpgle
dcl-pr CREST_errorsToJson varchar(2048) extproc(*dclcase);
  errors likeds(GLOBAL_listError) const;
end-pr;
```

**Paramètres** :
- `errors` : Structure GLOBAL_listError à convertir

**Retour** :
- JSON au format `{"errors":[{...},{...}]}`

**Format JSON Retourné** :
```json
{
  "errors": [
    {
      "code": "ERR001",
      "zone": "EMPNO",
      "valeur": "123456",
      "texte": "Numéro employé déjà existant",
      "texteUser": "Ce numéro employé existe déjà"
    }
  ]
}
```

**Utilisation** :
```rpgle
dcl-ds lErrors likeds(GLOBAL_listError) inz;

// Logique métier avec validation
if not employee_create(lDetail : lErrors);
  response.status = IL_HTTP_BAD_REQUEST;
  CREST_addHeaders(response);
  il_responseWrite(response : CREST_errorsToJson(lErrors)); // Conversion ici
  return;
endif;
```

**⚠️ Caractères Spéciaux** : Escape automatique via `escapeString()`.

---

### 6. CREST_simpleError

**Objectif** : Créer rapidement un JSON d'erreur simple.

**Prototype** :
```rpgle
dcl-pr CREST_simpleError varchar(1000) extproc(*dclcase);
  errorMessage varchar(500) const;
end-pr;
```

**Paramètres** :
- `errorMessage` : Message d'erreur simple

**Retour** :
- JSON au format `{"error":"message"}`

**Format JSON Retourné** :
```json
{
  "error": "Employee not found"
}
```

**Utilisation** :
```rpgle
// Ressource non trouvée
if not employee_getByID(lId : lDetail);
  response.status = IL_HTTP_NOT_FOUND;
  CREST_addHeaders(response);
  il_responseWrite(response : CREST_simpleError('Employee not found'));
  return;
endif;
```

**⚠️ Cas d'Usage** : Erreurs simples sans détail de validation (404, 500, etc.).

---

### 7. escapeString

**Objectif** : Échapper les caractères spéciaux JSON.

**Prototype** :
```rpgle
dcl-pr escapeString varchar(1000) extproc(*dclcase);
  text varchar(1000) const;
end-pr;
```

**Paramètres** :
- `text` : Texte à échapper

**Retour** :
- Texte avec caractères JSON échappés

**Caractères Échappés** :
| Caractère | Échappement |
|-----------|-------------|
| `"`       | `\"`        |
| `\`       | `\\`        |
| Newline   | `\n`        |
| Return    | `\r`        |
| Tab       | `\t`        |

**Utilisation** :
```rpgle
// Génération JSON manuelle
json = '{"name":"' + escapeString(%trim(lDetail.name)) + '"}';
```

**⚠️ Automatique** : `CREST_errorsToJson()` et `CREST_simpleError()` utilisent déjà `escapeString()`.

---

## Procédures Internes

### setupPagination

**Objectif** : Extraire et valider les paramètres de pagination.

**Signature** :
```rpgle
dcl-proc setupPagination;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
```

**Paramètres Supportés** :
| Format             | Paramètre | Valeur par Défaut | Validation                  |
|--------------------|-----------|-------------------|-----------------------------|
| Simple REST        | `page`    | 1                 | >= 1                        |
| Simple REST        | `perPage` | 25                | 1 ≤ valeur ≤ 100            |
| React Admin Classic| `_page`   | 1                 | >= 1                        |
| React Admin Classic| `_limit`  | 25                | 1 ≤ valeur ≤ 100            |

**Workflow** :
1. Teste format Simple REST (`page`, `perPage`)
2. Fallback sur format Classic (`_page`, `_limit`)
3. Applique valeurs par défaut si manquantes
4. Valide limites (page >= 1, perPage <= 100)
5. Log toutes les étapes avec CKOOL

**Exemple Requête** :
```
GET /api/employees?page=2&perPage=10
```

**Contexte Résultant** :
```rpgle
context.pagination.numPage = 2;
context.pagination.perPage = 10;
```

---

### setupFilters

**Objectif** : Extraire et configurer les filtres dynamiques depuis paramètres de requête.

**Signature** :
```rpgle
dcl-proc setupFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
    context likeDS(CMAGIC_context);
  end-pi;
```

**Opérateurs Supportés** :
| Suffixe   | Opérateur SQL | Exemple URL                         | Résultat SQL              |
|-----------|---------------|-------------------------------------|---------------------------|
| *(aucun)* | `=`           | `?empno=000010`                     | `empno = '000010'`        |
| `_like`   | `LIKE`        | `?lastname_like=Smith`              | `lastname LIKE '%Smith%'` |
| `_gte`    | `>=`          | `?salary_gte=50000`                 | `salary >= 50000`         |
| `_lte`    | `<=`          | `?salary_lte=100000`                | `salary <= 100000`        |
| `_ne`     | `<>`          | `?workdept_ne=D11`                  | `workdept <> 'D11'`       |
| `_gt`     | `>`           | `?salary_gt=50000`                  | `salary > 50000`          |
| `_lt`     | `<`           | `?salary_lt=100000`                 | `salary < 100000`         |
| `q`       | `LIKE`        | `?q=smith` (recherche générale)     | Recherche multi-champs    |

**Workflow** :
1. Trie `supportedFields` par nom DESC (champs longs d'abord pour éviter conflits)
2. Pour chaque champ supporté :
   - Teste tous les opérateurs dans l'ordre
   - Ajoute filtre si paramètre trouvé
3. Gère recherche générale `q` en dernier
4. Log chaque filtre détecté

**Exemple Requête** :
```
GET /api/employees?lastname_like=Smith&salary_gte=50000&workdept_ne=D11
```

**Contexte Résultant** :
```rpgle
context.filter(1).field = 'lastname';
context.filter(1).operator = 'LIKE';
context.filter(1).value = '%Smith%';

context.filter(2).field = 'salary';
context.filter(2).operator = '>=';
context.filter(2).value = '50000';

context.filter(3).field = 'workdept';
context.filter(3).operator = '<>';
context.filter(3).value = 'D11';
```

**⚠️ Important** :
- Maximum `CMAGIC_MAX_FILTERS` filtres (défini dans `cmagic.rpgleinc`)
- Tri DESC critique pour éviter `lastname` match avant `lastname_like`
- LIKE ajoute automatiquement `%` au début et fin

---

### setupSorting

**Objectif** : Extraire et configurer le tri depuis paramètres de requête.

**Signature** :
```rpgle
dcl-proc setupSorting;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
```

**Paramètres Supportés** :
| Format             | Paramètre | Valeur par Défaut | Exemple                   |
|--------------------|-----------|-------------------|---------------------------|
| Simple REST        | `sort`    | —                 | `sort=lastname`           |
| Simple REST        | `order`   | `ASC`             | `order=DESC`              |
| React Admin Classic| `_sort`   | —                 | `_sort=lastname`          |
| React Admin Classic| `_order`  | `ASC`             | `_order=DESC`             |
| Multi-tri          | `sort1..4`| `ASC`             | `sort1=dept&order1=ASC`   |

**Workflow** :
1. Teste format Simple REST (`sort`, `order`)
2. Fallback sur format Classic (`_sort`, `_order`)
3. Gère multi-tri avec suffixes numériques (1-4)
4. Valeur par défaut `ASC` si order manquant
5. Log chaque tri configuré

**Exemple Requête** :
```
GET /api/employees?sort=lastname&order=ASC&sort1=workdept&order1=DESC
```

**Contexte Résultant** :
```rpgle
context.sort(1).field = 'lastname';
context.sort(1).order = 'ASC';

context.sort(2).field = 'workdept';
context.sort(2).order = 'DESC';
```

**⚠️ Limitation** : Maximum 5 tris (1 principal + 4 additionnels).

---

### validateAcceptHeader

**Objectif** : Valider que le client accepte JSON.

**Signature** :
```rpgle
dcl-proc validateAcceptHeader;
  dcl-pi *n ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
  end-pi;
```

**Retour** :
- `*ON` : Header valide ou absent (permissif)
- `*OFF` : Header incompatible, erreur 406 configurée

**Headers Acceptés** :
- `Accept: application/json`
- `Accept: */*`
- *(absent)* : OK par tolérance

**Réponse d'Erreur** :
```http
HTTP/1.1 406 Not Acceptable
Content-Type: application/json

{"error":"JSON response required"}
```

**Workflow** :
1. Récupère header `Accept`
2. Si vide → OK (permissif)
3. Si contient `application/json` ou `*/*` → OK
4. Sinon → Erreur 406 via `setError()`

---

### validateContentType

**Objectif** : Valider le Content-Type pour opérations d'écriture.

**Signature** :
```rpgle
dcl-proc validateContentType;
  dcl-pi *n ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
    expectedType varchar(100) const options(*nopass);
  end-pi;
```

**Paramètres** :
- `expectedType` : *(Optionnel)* Type attendu, défaut `application/json`

**Retour** :
- `*ON` : Header valide ou body vide
- `*OFF` : Header invalide, erreur 415 configurée

**Réponse d'Erreur** :
```http
HTTP/1.1 415 Unsupported Media Type
Content-Type: application/json

{"error":"Content-Type application/json required"}
```

**Workflow** :
1. Type attendu par défaut `application/json`
2. Si body vide → OK (permissif)
3. Si Content-Type contient type attendu → OK
4. Sinon → Erreur 415 via `setError()`

---

### setError

**Objectif** : Configurer réponse d'erreur HTTP standardisée.

**Signature** :
```rpgle
dcl-proc setError;
  dcl-pi *n;
    response likeds(IL_response);
    httpStatus int(10) const;
    errorMessage varchar(500) const;
  end-pi;
```

**Workflow** :
1. Configure status HTTP
2. Configure Content-Type JSON
3. Ajoute headers REST via `CREST_addHeaders()`
4. Écrit JSON via `CREST_simpleError()`
5. Log erreur via CKOOL

**Utilisation Interne** :
```rpgle
// Dans validateAcceptHeader
setError(response : IL_HTTP_NOT_ACCEPTABLE : 'JSON response required');

// Dans validateContentType
setError(response : IL_HTTP_UNSUPPORTED_MEDIA_TYPE : 
         'Content-Type application/json required');
```

**⚠️ Privée** : Non exportée, utilisée uniquement par procédures de validation CREST.

---

## Patterns d'Utilisation

### Pattern 1: GET Collection avec Filtres/Pagination

**Cas d'usage** : Liste employés avec pagination, tri, filtres.

**Code** :
```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  dcl-ds supportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lList pointer;
  
  // 1. Initialisation complète (validation + parsing)
  supportedFields = employee_getSupportedFields();
  if not CREST_initRestRequest(request : supportedFields : response : context);
    return; // Erreur 406 déjà envoyée
  endif;
  
  // 2. Appel logique métier avec contexte
  lList = employee_search(context : lTotalCount);
  
  // 3. Préparation réponse
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response : lTotalCount); // OBLIGATOIRE avec count
  
  // 4. Écriture JSON collection
  il_responseWriteStream(response : '[');
  // ... loop sur lList + JSON
  il_responseWriteStream(response : ']');
  
  // 5. Cleanup
  list_dispose(lList);
end-proc;
```

**Points Clés** :
- ✅ `CREST_initRestRequest()` valide ET parse
- ✅ `context` passé à métier
- ✅ `X-Total-Count` fourni via `CREST_addHeaders()`
- ✅ Retour immédiat si validation échoue

---

### Pattern 2: GET Item Unique

**Cas d'usage** : Récupérer un employé par ID.

**Code** :
```rpgle
dcl-proc employee_getone_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lId int(10);
  dcl-ds lDetail likeds(employee_detail_t) inz;
  
  // 1. Validation simple (pas de parsing nécessaire)
  if not CREST_initSimpleRestRequest(request : response);
    return;
  endif;
  
  // 2. Extraction ID depuis URL
  lId = %int(il_getParmStr(request : 'id'));
  
  // 3. Logique métier
  if not employee_getByID(lId : lDetail);
    response.status = IL_HTTP_NOT_FOUND;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_simpleError('Employee not found'));
    return;
  endif;
  
  // 4. Réponse succès
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response); // Sans count
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**Points Clés** :
- ✅ `CREST_initSimpleRestRequest()` pour validation légère
- ✅ Pas de contexte CMAGIC nécessaire
- ✅ Erreur 404 avec `CREST_simpleError()`
- ✅ Headers même pour erreur

---

### Pattern 3: POST Création

**Cas d'usage** : Créer un nouvel employé.

**Code** :
```rpgle
dcl-proc employee_create_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(employee_detail_t) inz;
  dcl-ds lErrors likeds(GLOBAL_listError) inz;
  dcl-s lJsonInput varchar(10000);
  
  // 1. Validation Content-Type
  if not CREST_initWriteRestRequest(request : response);
    return;
  endif;
  
  // 2. Parse JSON body
  lJsonInput = il_getRequestContent(request);
  employee_jsonToDetail(lJsonInput : lDetail);
  
  // 3. Logique métier avec validation
  if not employee_create(lDetail : lErrors);
    response.status = IL_HTTP_BAD_REQUEST;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;
  
  // 4. Succès 201 avec objet créé
  response.status = IL_HTTP_CREATED;
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**Points Clés** :
- ✅ `CREST_initWriteRestRequest()` pour POST/PUT
- ✅ 201 Created pour création réussie
- ✅ 400 Bad Request + `CREST_errorsToJson()` pour erreurs validation
- ✅ Retour objet créé dans body

---

### Pattern 4: PUT Modification

**Cas d'usage** : Modifier un employé existant.

**Code** :
```rpgle
dcl-proc employee_update_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lId int(10);
  dcl-ds lDetail likeds(employee_detail_t) inz;
  dcl-ds lErrors likeds(GLOBAL_listError) inz;
  dcl-s lJsonInput varchar(10000);
  
  // 1. Validation Content-Type
  if not CREST_initWriteRestRequest(request : response);
    return;
  endif;
  
  // 2. Extraction ID + Parse JSON
  lId = %int(il_getParmStr(request : 'id'));
  lJsonInput = il_getRequestContent(request);
  employee_jsonToDetail(lJsonInput : lDetail);
  
  // 3. Logique métier
  if not employee_update(lId : lDetail : lErrors);
    response.status = IL_HTTP_BAD_REQUEST;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;
  
  // 4. Succès 200 avec objet modifié
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**Points Clés** :
- ✅ Même validation que POST
- ✅ 200 OK (pas 201) pour modification
- ✅ Retour objet modifié

---

### Pattern 5: DELETE Suppression

**Cas d'usage** : Supprimer un employé.

**Code** :
```rpgle
dcl-proc employee_delete_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lId int(10);
  dcl-ds lDetail likeds(employee_detail_t) inz;
  
  // 1. Validation simple
  if not CREST_initSimpleRestRequest(request : response);
    return;
  endif;
  
  // 2. Extraction ID
  lId = %int(il_getParmStr(request : 'id'));
  
  // 3. Lecture avant suppression (pour retour)
  if not employee_getByID(lId : lDetail);
    response.status = IL_HTTP_NOT_FOUND;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_simpleError('Employee not found'));
    return;
  endif;
  
  // 4. Suppression métier
  if not employee_delete(lId);
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_simpleError('Delete failed'));
    return;
  endif;
  
  // 5. Succès 200 avec objet supprimé
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**Points Clés** :
- ✅ 404 si ressource inexistante
- ✅ 200 OK + retour objet supprimé
- ✅ Lecture avant suppression pour retourner données

---

## Gestion d'Erreurs

### Codes HTTP Standards

| Code | Constant ILEastic           | Cas d'Usage                          |
|------|-----------------------------|--------------------------------------|
| 200  | `IL_HTTP_OK`                | Succès GET/PUT/DELETE                |
| 201  | `IL_HTTP_CREATED`           | Succès POST                          |
| 400  | `IL_HTTP_BAD_REQUEST`       | Erreur validation métier             |
| 404  | `IL_HTTP_NOT_FOUND`         | Ressource introuvable                |
| 406  | `IL_HTTP_NOT_ACCEPTABLE`    | Accept header incompatible           |
| 415  | `IL_HTTP_UNSUPPORTED_MEDIA_TYPE` | Content-Type incompatible    |
| 500  | `IL_HTTP_INTERNAL_SERVER_ERROR` | Erreur serveur                |

### Pattern Erreur Validation Métier

```rpgle
if not employee_create(lDetail : lErrors);
  response.status = IL_HTTP_BAD_REQUEST;
  CREST_addHeaders(response);
  il_responseWrite(response : CREST_errorsToJson(lErrors));
  return;
endif;
```

**JSON Retourné** :
```json
{
  "errors": [
    {
      "code": "ERR001",
      "zone": "EMPNO",
      "valeur": "999999",
      "texte": "Numéro employé invalide",
      "texteUser": "Le numéro doit être entre 000001 et 999998"
    }
  ]
}
```

### Pattern Erreur Simple

```rpgle
if not employee_getByID(lId : lDetail);
  response.status = IL_HTTP_NOT_FOUND;
  CREST_addHeaders(response);
  il_responseWrite(response : CREST_simpleError('Employee not found'));
  return;
endif;
```

**JSON Retourné** :
```json
{
  "error": "Employee not found"
}
```

### Workflow Monitor/On-Error

**⚠️ Important** : CREST ne gère PAS les exceptions SQL/RPG directement.

**Pattern Recommandé dans Handlers REST** :
```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  monitor;
    // Logique CREST + métier
    if not CREST_initRestRequest(...);
      return;
    endif;
    // ...
  on-error;
    CKOOL_logError('Erreur inattendue dans employee_getlist_rest');
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;
```

---

## Exemples Réels

### Exemple Complet: Employee Search

**Source** : `src/employee/employee.rest.sqlrpgle`

```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  dcl-ds supportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lList pointer;
  dcl-ds lItem likeds(employee_item_t) based(lItemPtr);
  dcl-s lItemPtr pointer;
  dcl-s first ind inz(*on);
  dcl-s lJson varchar(5000);
  
  // Initialisation CREST avec parsing complet
  supportedFields = employee_getSupportedFields();
  if not CREST_initRestRequest(request : supportedFields : response : context);
    return;
  endif;
  
  // Recherche métier avec contexte
  lList = employee_search(context : lTotalCount);
  
  // Configuration réponse
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response : lTotalCount);
  
  // Écriture JSON collection
  il_responseWriteStream(response : '[');
  
  lItemPtr = list_getFirst(lList);
  dow (lItemPtr <> *null);
    if (not first);
      il_responseWriteStream(response : ',');
    endif;
    
    lJson = employee_itemToJson(lItem);
    il_responseWriteStream(response : lJson);
    
    lItemPtr = list_getNext(lList);
    first = *off;
  enddo;
  
  il_responseWriteStream(response : ']');
  
  // Cleanup
  list_dispose(lList);
end-proc;
```

**Requête Exemple** :
```
GET /api/employees?page=2&perPage=5&sort=lastname&order=ASC&lastname_like=Smith&salary_gte=50000
```

**Headers Réponse** :
```http
HTTP/1.1 200 OK
Content-Type: application/json
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Expose-Headers: X-Total-Count
X-Total-Count: 23
```

**Body Réponse** :
```json
[
  {
    "id": "000010",
    "firstname": "CHRISTINE",
    "lastname": "SMITH",
    "workdept": "E01",
    "salary": 52750.00
  },
  {
    "id": "000020",
    "firstname": "MICHAEL",
    "lastname": "SMITHSON",
    "workdept": "D21",
    "salary": 61250.00
  }
]
```

---

### Exemple Complet: Employee Create

**Source** : `src/employee/employee.rest.sqlrpgle`

```rpgle
dcl-proc employee_create_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(employee_detail_t) inz;
  dcl-ds lErrors likeds(GLOBAL_listError) inz;
  dcl-s lJsonInput varchar(10000);
  
  // Validation Content-Type
  if not CREST_initWriteRestRequest(request : response);
    return;
  endif;
  
  // Parse JSON input
  lJsonInput = il_getRequestContent(request);
  employee_jsonToDetail(lJsonInput : lDetail);
  
  // Création métier avec validation
  if not employee_create(lDetail : lErrors);
    response.status = IL_HTTP_BAD_REQUEST;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;
  
  // Succès 201
  response.status = IL_HTTP_CREATED;
  CREST_addHeaders(response);
  il_responseWrite(response : employee_detailToJson(lDetail));
end-proc;
```

**Requête Exemple** :
```http
POST /api/employees HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "empno": "999999",
  "firstname": "JOHN",
  "lastname": "DOE",
  "workdept": "D11",
  "salary": 55000.00
}
```

**Réponse Succès** :
```http
HTTP/1.1 201 Created
Content-Type: application/json
Access-Control-Allow-Origin: *
...

{
  "id": {
    "code": "999999"
  },
  "empno": "999999",
  "firstname": "JOHN",
  "lastname": "DOE",
  "workdept": "D11",
  "salary": 55000.00,
  "hiredate": "2025-01-15"
}
```

**Réponse Erreur Validation** :
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
...

{
  "errors": [
    {
      "code": "ERR001",
      "zone": "EMPNO",
      "valeur": "999999",
      "texte": "Numéro employé déjà existant",
      "texteUser": "Ce numéro d'employé existe déjà dans la base"
    }
  ]
}
```

---

## Checklist Intégration CREST

### ✅ Pour GET Collection (`/api/resource`)

- [ ] Appeler `CREST_initRestRequest()` avec `supportedFields`
- [ ] Retourner immédiatement si validation échoue
- [ ] Passer `context` à fonction métier `resource_search()`
- [ ] Récupérer `totalCount` depuis métier
- [ ] Appeler `CREST_addHeaders(response : totalCount)`
- [ ] Retourner **tableau JSON** `[...]`
- [ ] Disposer liste avec `list_dispose()`

### ✅ Pour GET Item (`/api/resource/{id}`)

- [ ] Appeler `CREST_initSimpleRestRequest()`
- [ ] Extraire ID depuis URL avec `il_getParmStr()`
- [ ] Gérer erreur 404 si ressource inexistante
- [ ] Appeler `CREST_addHeaders(response)` (sans count)
- [ ] Retourner **objet JSON** `{...}`

### ✅ Pour POST Create (`/api/resource`)

- [ ] Appeler `CREST_initWriteRestRequest()`
- [ ] Parser JSON body avec fonction dédiée
- [ ] Valider et créer via fonction métier
- [ ] Gérer erreurs validation avec `CREST_errorsToJson()`
- [ ] Retourner **201 Created** + objet créé
- [ ] Appeler `CREST_addHeaders(response)`

### ✅ Pour PUT Update (`/api/resource/{id}`)

- [ ] Appeler `CREST_initWriteRestRequest()`
- [ ] Extraire ID depuis URL
- [ ] Parser JSON body
- [ ] Valider et modifier via fonction métier
- [ ] Gérer erreurs validation avec `CREST_errorsToJson()`
- [ ] Retourner **200 OK** + objet modifié
- [ ] Appeler `CREST_addHeaders(response)`

### ✅ Pour DELETE (`/api/resource/{id}`)

- [ ] Appeler `CREST_initSimpleRestRequest()`
- [ ] Extraire ID depuis URL
- [ ] Lire ressource avant suppression (pour retour)
- [ ] Gérer erreur 404 si inexistante
- [ ] Supprimer via fonction métier
- [ ] Retourner **200 OK** + objet supprimé
- [ ] Appeler `CREST_addHeaders(response)`

### ✅ Général

- [ ] Toujours appeler `CREST_addHeaders()` même en cas d'erreur
- [ ] Utiliser constantes `IL_HTTP_*` pour status
- [ ] Logger avec `CKOOL_logMessage()`
- [ ] Wrapper dans `monitor/on-error` pour exceptions
- [ ] Tester avec curl ou Bruno

---

## Références

### Fichiers Source

- **Implémentation** : `src/crest/crest.sqlrpgle`
- **Prototypes** : `includes/crest.rpgleinc`
- **Binding** : `src/crest/crest.bnd`
- **Exemple Réel** : `src/employee/employee.rest.sqlrpgle`

### Documents Liés

- **Guide RPG Bonnes Pratiques** : `ressources/docs/guides/guide_rpg_bonnes_pratiques.md`
- **Conventions Réelles** : `ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md`
- **Instructions Copilot** : `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`

### Dépendances

- **CMAGIC** : Structures contexte REST (pagination, tri, filtres)
- **ILEastic** : Framework HTTP IBM i
- **CKOOL** : Logging
- **llist** : Gestion listes chaînées
- **GLOBAL** : Types globaux (erreurs, etc.)

---

**📌 Règle d'Or** : CREST centralise la logique REST répétitive. Utiliser systématiquement ses procédures d'initialisation pour garantir la cohérence des APIs.

**🎯 Prochaine Étape** : Consulter le **Guide Liste Chaînée llist** pour comprendre la gestion des collections retournées par les fonctions métier.
