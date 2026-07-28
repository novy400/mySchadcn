# Procédures d'Initialisation REST CMAGIC

## 📋 Vue d'ensemble

Les nouvelles procédures d'initialisation REST permettent de **regrouper et centraliser** les validations courantes dans les APIs REST, évitant la duplication de code et standardisant les patterns.

## 🎯 Procédures Disponibles

### 1. `CREST_initRestRequest` - Collections avec Filtres
**Utilisation** : Procédures GET qui supportent pagination, tri et filtres  
**Exemple** : `GET /employees`, `GET /customers`

```rpg
dcl-ds lContext likeDS(CMAGIC_context) inz;

// ✅ AVANT : 2 étapes séparées
if (not CREST_validateAcceptHeader(request : response));
  return;
endif;
lContext = CMAGIC_parseQueryParams(request : employee_getSupportedFields());

// 🚀 APRÈS : 1 seule ligne !
if (not CREST_initRestRequest(request : response : 
                              employee_getSupportedFields() : lContext));
  return;
endif;
```

**Ce que fait cette procédure :**
- ✅ Valide le header `Accept` (JSON requis)
- ✅ Parse tous les paramètres REST (`_page`, `_limit`, `_sort`, filtres, etc.)
- ✅ Configure automatiquement le context CMAGIC
- ✅ Gère les erreurs et configure la response en cas d'échec

### 2. `CREST_initSimpleRestRequest` - Accès Simple
**Utilisation** : Procédures GET simples sans paramètres  
**Exemple** : `GET /employees/{id}`, `GET /customers/{code}`

```rpg
// ✅ AVANT : 1 validation manuelle
if (not CREST_validateAcceptHeader(request : response));
  return;
endif;

// 🚀 APRÈS : 1 ligne centralisée !
if (not CREST_initSimpleRestRequest(request : response));
  return;
endif;
```

**Ce que fait cette procédure :**
- ✅ Valide le header `Accept` (JSON requis)
- ✅ Gère les erreurs et configure la response en cas d'échec

### 3. `CREST_initWriteRestRequest` - Opérations d'Écriture
**Utilisation** : Procédures POST/PUT qui reçoivent du JSON  
**Exemple** : `POST /employees`, `PUT /employees/{id}`

```rpg
// ✅ AVANT : 1 validation manuelle
if (not CREST_validateContentType(request : response));
  return;
endif;

// 🚀 APRÈS : 1 ligne centralisée !
if (not CREST_initWriteRestRequest(request : response));
  return;
endif;
```

**Ce que fait cette procédure :**
- ✅ Valide le header `Content-Type` (application/json requis)
- ✅ Gère les erreurs et configure la response en cas d'échec

## 🏗️ Pattern d'Utilisation Standard

### GET Collection (avec filtres)
```rpg
dcl-proc resource_getlist_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  
  // 🚀 Initialisation REST centralisée
  if (not CREST_initRestRequest(request : response : 
                                resource_getSupportedFields() : lContext));
    return;
  endif;
  
  // Votre logique métier...
  if resource_search(lContext : lTotalCount : lItems : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    CREST_addHeaders(response : lTotalCount);
    il_responseWrite(response : resourcesToJson(lItems : lTotalCount));
  endif;
end-proc;
```

### GET Item (accès simple)
```rpg
dcl-proc resource_getone_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(resource_detail_t);
  dcl-s cId varchar(10);
  
  // 🚀 Validation REST simplifiée
  if (not CREST_initSimpleRestRequest(request : response));
    return;
  endif;
  
  // Votre logique métier...
  cId = il_getPathParameter(request : 'id' : '');
  if resource_getByID(cId : lDetail : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : resourceToJson(lDetail));
  endif;
end-proc;
```

### POST/PUT (opérations d'écriture)
```rpg
dcl-proc resource_create_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(resource_detail_t);
  
  // 🚀 Validation REST pour écriture
  if (not CREST_initWriteRestRequest(request : response));
    return;
  endif;
  
  // Votre logique métier...
  lDetail = jsonToResource(il_getRequestContent(request));
  if resource_create(lDetail : lId : lErrors);
    response.status = IL_HTTP_CREATED;
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : resourceToJson(lDetail));
  endif;
end-proc;
```

## ✅ Avantages

### **1. Réduction du Code**
- **Avant** : 3-4 lignes répétitives par procédure REST
- **Après** : 1 seule ligne d'initialisation

### **2. Standardisation**
- Validations uniformes dans toutes les APIs
- Messages d'erreur cohérents
- Headers HTTP standardisés

### **3. Maintenance Facilitée**
- Modification d'une validation = 1 seul endroit à changer
- Nouvelles validations automatiquement appliquées partout
- Debugging centralisé avec logs CKOOL

### **4. Compatibilité**
- ✅ Compatible avec le pattern Employee existant
- ✅ Compatible React-Admin, Appsmith, Retool
- ✅ Respect des standards REST

## 🔧 Migration

Pour migrer une API existante :

1. **Remplacer** les validations manuelles par l'appel centralisé
2. **Vérifier** que le comportement reste identique
3. **Tester** les endpoint modifiés
4. **Compiler** avec BOB pour validation

```bash
# Test de compilation
bob --build src/employee

# Test fonctionnel  
curl "http://server:44000/api/employees"
curl "http://server:44000/api/employees/000010"
```

## 🎯 Règles d'Usage

### **Quand utiliser CREST_initRestRequest :**
- ✅ GET collections avec pagination/filtres
- ✅ Endpoints supportant `?_page=1&_limit=10`
- ✅ APIs avec filtres avancés (`?nom_like=Smith`)

### **Quand utiliser CREST_initSimpleRestRequest :**
- ✅ GET simples (item par ID)
- ✅ Endpoints sans paramètres de query
- ✅ Opérations de lecture basiques

### **Quand utiliser CREST_initWriteRestRequest :**
- ✅ POST avec payload JSON
- ✅ PUT avec payload JSON  
- ✅ Toute opération modifiant des données

---

**💡 Ces procédures sont l'évolution logique du pattern CMAGIC REST pour réduire la duplication et améliorer la maintenabilité.**