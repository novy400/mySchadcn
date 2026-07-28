# 🌐 Formation API REST IBM i

*Formation spécialisée pour le développement d'APIs REST modernes sur IBM i*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Objectifs de Formation

### **🏆 Compétences Cibles**
- Concevoir des APIs REST conformes aux standards
- Implémenter avec ILEastic sur IBM i
- Intégrer avec frameworks frontend modernes
- Optimiser performance et sécurité

### **👥 Public Cible**
- Développeurs IBM i expérimentés
- Architectes modernisant legacy
- Équipes intégrant frontend/backend
- DevOps automatisant déploiements

---

## 📚 Module 1 : Fondements REST et Standards Web

### **🌐 Concepts REST Fondamentaux**

#### **Principes Architecturaux**
```
REST (Representational State Transfer)
├── Client-Server Architecture
├── Stateless Communication  
├── Cacheable Responses
├── Uniform Interface
├── Layered System
└── Code on Demand (optionnel)
```

#### **Méthodes HTTP Standards**
```
GET     /api/employees         # Collection - Lecture
GET     /api/employees/{id}    # Item - Lecture  
POST    /api/employees         # Création
PUT     /api/employees/{id}    # Modification complète
PATCH   /api/employees/{id}    # Modification partielle
DELETE  /api/employees/{id}    # Suppression
OPTIONS /api/employees         # Métadonnées (CORS)
```

#### **Status Codes Essentiels**
```http
# Succès
200 OK                  # Opération réussie
201 Created            # Ressource créée
204 No Content         # Suppression réussie

# Redirection  
301 Moved Permanently  # Resource déplacée
304 Not Modified       # Cache valide

# Erreurs Client
400 Bad Request        # Données invalides
401 Unauthorized       # Authentification requise
403 Forbidden         # Accès refusé
404 Not Found         # Ressource inexistante
409 Conflict          # Conflit (version, contrainte)
422 Unprocessable Entity # Validation échouée

# Erreurs Serveur
500 Internal Server Error # Erreur interne
503 Service Unavailable  # Service indisponible
```

### **📄 Format JSON et Standards**

#### **Structure Collection**
```json
// GET /api/employees
[
  {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe", 
    "email": "john.doe@company.com",
    "department": "IT",
    "active": true
  },
  {
    "id": 2,
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@company.com", 
    "department": "HR",
    "active": true
  }
]

// Headers obligatoires
X-Total-Count: 150
Access-Control-Expose-Headers: X-Total-Count
```

#### **Structure Item**
```json
// GET /api/employees/1
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@company.com",
  "department": "IT", 
  "salary": 75000.00,
  "active": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-10-30T14:25:00Z"
}
```

#### **Réponses d'Erreur Standardisées**
```json
// Erreur 400 - Validation
{
  "error": {
    "code": 400,
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "salary", 
        "message": "Salary must be positive"
      }
    ]
  }
}

// Erreur 500 - Interne
{
  "error": {
    "code": 500,
    "message": "Internal server error",
    "timestamp": "2024-10-31T15:30:00Z",
    "requestId": "req-123456"
  }
}
```

---

## 🏗️ Module 2 : Architecture API sur IBM i

### **🎨 Patterns Architecturaux**

#### **Architecture en Couches**
```
┌─────────────────────────────────────┐
│           HTTP Layer                │  ← ILEastic, CORS, Auth
├─────────────────────────────────────┤
│           REST Layer                │  ← Routing, JSON, Validation
├─────────────────────────────────────┤  
│         Business Layer              │  ← Logique métier, Rules
├─────────────────────────────────────┤
│          Data Layer                 │  ← SQL, Transactions, Cache
├─────────────────────────────────────┤
│         Database Layer              │  ← DB2 for i, Tables, Index
└─────────────────────────────────────┘
```

#### **Structure Fichiers ArchiAPI**
```
src/employee/
├── employee.main.rpgle         # HTTP Server + Routing
├── employee.route.sqlrpgle     # Route Configuration  
├── employee.rest.sqlrpgle      # REST Handlers
├── employee.sqlrpgle           # Business Logic
└── employee.bnd                # Binding Sources

includes/
└── employee.rpgleinc           # Prototypes + Structures
```

### **🔧 Configuration ILEastic Avancée**

#### **Serveur Multi-Ressources**
```rpg
**free
ctl-opt main(main);

/copy QCPYILE,ILEASTIC
/copy QCPYSRC,EMPLOYEE_PR
/copy QCPYSRC,CUSTOMER_PR

dcl-proc main;
  dcl-s config pointer;
  dcl-s router pointer;
  
  // Configuration serveur
  config = il_newConfig();
  il_configSetPort(config : 44001);
  il_configSetHost(config : '*ANY');
  il_configSetLogging(config : *ON);
  il_configSetTimeout(config : 300); // 5 minutes
  
  // Router principal
  router = il_newRouter(config);
  
  // Middleware global
  il_addMiddleware(router : %paddr(corsMiddleware));
  il_addMiddleware(router : %paddr(authMiddleware));
  il_addMiddleware(router : %paddr(loggingMiddleware));
  il_addMiddleware(router : %paddr(errorHandlerMiddleware));
  
  // Configuration routes par ressource
  employee_setupRoutes(router);
  customer_setupRoutes(router);
  department_setupRoutes(router);
  
  // Route health check
  il_addRoute(router : '/api/health' : IL_GET : %paddr(healthCheckHandler));
  
  // Démarrage serveur
  il_listen(router);
end-proc;
```

#### **Middleware Complet**
```rpg
// Middleware authentification
dcl-proc authMiddleware export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
    next pointer const;
  end-pi;
  
  dcl-s authHeader varchar(200);
  dcl-s token varchar(100);
  dcl-s isValid ind;
  
  // Routes publiques (pas d'auth)
  if %scan('/health' : il_getRequestPath(request)) > 0;
    return il_nextMiddleware(next : request : response);
  endif;
  
  // Vérifier header Authorization
  authHeader = il_getRequestHeader(request : 'Authorization');
  
  if %len(%trimr(authHeader)) = 0;
    sendUnauthorizedResponse(response);
    return *OFF;
  endif;
  
  // Extraire token Bearer
  if %subst(authHeader : 1 : 7) = 'Bearer ';
    token = %subst(authHeader : 8);
    isValid = validateToken(token);
    
    if isValid;
      return il_nextMiddleware(next : request : response);
    endif;
  endif;
  
  sendUnauthorizedResponse(response);
  return *OFF;
end-proc;

// Middleware gestion erreurs globales
dcl-proc errorHandlerMiddleware export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
    next pointer const;
  end-pi;
  
  monitor;
    return il_nextMiddleware(next : request : response);
  on-error;
    sendInternalErrorResponse(response);
    logError('Unhandled error in request: ' + 
      il_getRequestPath(request) + ' - ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🛠️ Module 3 : Implémentation Handlers REST

### **📊 Pattern Collection GET**

#### **Handler Collection avec Filtres Avancés**
```rpg
dcl-proc employee_getCollection export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-ds context likeDS(CMAGIC_context);
  dcl-s jsonData varchar(32000);
  dcl-s totalCount int(10);
  dcl-s executionTime int(10);
  dcl-s startTime timestamp;
  
  startTime = %timestamp();
  
  monitor;
    // Parser paramètres REST
    CMAGIC_parseRestParams(request : context);
    
    // Validation paramètres
    if not validatePaginationParams(context.pagination);
      sendBadRequestResponse(response : 'Invalid pagination parameters');
      return *OFF;
    endif;
    
    // Appel logique métier
    if not employee_getCollectionData(context : jsonData : totalCount);
      sendInternalErrorResponse(response);
      return *OFF;
    endif;
    
    // Headers REST standards
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'X-Total-Count' : %char(totalCount));
    il_addHttpHeader(response : 'X-Page-Count' : 
      %char(%div(totalCount + context.pagination.limit - 1 : context.pagination.limit)));
    il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 
      'X-Total-Count, X-Page-Count');
    
    // Métriques performance
    executionTime = %diff(%timestamp() : startTime : *mseconds);
    il_addHttpHeader(response : 'X-Response-Time' : %char(executionTime) + 'ms');
    
    // Cache headers
    il_addHttpHeader(response : 'Cache-Control' : 'public, max-age=300'); // 5 min
    il_addHttpHeader(response : 'ETag' : generateETag(jsonData));
    
    // Réponse
    il_responseWrite(response : %addr(jsonData) : %len(%trimr(jsonData)));
    
    // Log metrics
    logApiMetrics('GET' : '/api/employees' : executionTime : 200 : totalCount);
    
    return *ON;
    
  on-error;
    sendInternalErrorResponse(response);
    logError('Error in employee_getCollection: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

### **🎯 Pattern Item GET**

#### **Handler Item avec Cache**
```rpg
dcl-proc employee_getItem export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-s employeeId int(10);
  dcl-s jsonData varchar(8000);
  dcl-s etag varchar(50);
  dcl-s ifNoneMatch varchar(50);
  
  monitor;
    // Extraire ID depuis URL
    employeeId = %int(il_getPathParam(request : 'id'));
    
    if employeeId <= 0;
      sendBadRequestResponse(response : 'Invalid employee ID');
      return *OFF;
    endif;
    
    // Vérifier cache client (ETag)
    ifNoneMatch = il_getRequestHeader(request : 'If-None-Match');
    etag = getEmployeeETag(employeeId);
    
    if %len(%trimr(ifNoneMatch)) > 0 and ifNoneMatch = etag;
      il_setStatus(response : 304); // Not Modified
      return *ON;
    endif;
    
    // Récupérer données
    if not employee_getItemData(employeeId : jsonData);
      sendNotFoundResponse(response : 'Employee not found');
      return *OFF;
    endif;
    
    // Headers réponse
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'ETag' : etag);
    il_addHttpHeader(response : 'Last-Modified' : getEmployeeLastModified(employeeId));
    il_addHttpHeader(response : 'Cache-Control' : 'private, max-age=60');
    
    // Réponse
    il_responseWrite(response : %addr(jsonData) : %len(%trimr(jsonData)));
    
    return *ON;
    
  on-error;
    sendInternalErrorResponse(response);
    return *OFF;
  endmon;
  
end-proc;
```

### **✏️ Pattern POST/PUT avec Validation**

#### **Handler POST Create**
```rpg
dcl-proc employee_create export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-s requestBody varchar(4000);
  dcl-ds inputEmployee likeDS(employee_input_t);
  dcl-ds newEmployee likeDS(employee_detail_t);
  dcl-s validationErrors varchar(1000);
  dcl-s jsonResponse varchar(8000);
  
  monitor;
    // Lire body de la requête
    requestBody = il_getRequestBody(request);
    
    if %len(%trimr(requestBody)) = 0;
      sendBadRequestResponse(response : 'Request body is required');
      return *OFF;
    endif;
    
    // Parser JSON input
    data-into inputEmployee %data(requestBody : 'doc=string case=any');
    
    // Validation input
    if not employee_validateInput(inputEmployee : validationErrors);
      sendValidationErrorResponse(response : validationErrors);
      return *OFF;
    endif;
    
    // Vérifier unicité (email par exemple)
    if employee_emailExists(inputEmployee.email);
      sendConflictResponse(response : 'Email already exists');
      return *OFF;
    endif;
    
    // Création en base
    if not employee_createRecord(inputEmployee : newEmployee);
      sendInternalErrorResponse(response);
      return *OFF;
    endif;
    
    // Générer réponse JSON
    data-gen jsonResponse %data(newEmployee : 'doc=string case=convert');
    
    // Headers création
    il_setStatus(response : 201); // Created
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'Location' : '/api/employees/' + %char(newEmployee.id));
    
    // Réponse avec objet créé
    il_responseWrite(response : %addr(jsonResponse) : %len(%trimr(jsonResponse)));
    
    // Log audit
    auditLog('CREATE' : 'EMPLOYEE' : %char(newEmployee.id) : 'Employee created');
    
    return *ON;
    
  on-error;
    sendInternalErrorResponse(response);
    logError('Error in employee_create: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

#### **Handler PUT Update avec Optimistic Locking**
```rpg
dcl-proc employee_update export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-s employeeId int(10);
  dcl-s requestBody varchar(4000);
  dcl-s ifMatch varchar(50);
  dcl-ds inputEmployee likeDS(employee_input_t);
  dcl-ds updatedEmployee likeDS(employee_detail_t);
  dcl-s currentETag varchar(50);
  dcl-s validationErrors varchar(1000);
  dcl-s jsonResponse varchar(8000);
  
  monitor;
    // Extraire ID
    employeeId = %int(il_getPathParam(request : 'id'));
    
    // Vérifier existence
    if not employee_exists(employeeId);
      sendNotFoundResponse(response : 'Employee not found');
      return *OFF;
    endif;
    
    // Optimistic locking avec ETag
    ifMatch = il_getRequestHeader(request : 'If-Match');
    currentETag = getEmployeeETag(employeeId);
    
    if %len(%trimr(ifMatch)) > 0 and ifMatch <> currentETag;
      sendConflictResponse(response : 'Resource has been modified by another user');
      return *OFF;
    endif;
    
    // Parser input
    requestBody = il_getRequestBody(request);
    data-into inputEmployee %data(requestBody : 'doc=string case=any');
    
    // Validation
    if not employee_validateInput(inputEmployee : validationErrors);
      sendValidationErrorResponse(response : validationErrors);
      return *OFF;
    endif;
    
    // Mise à jour
    if not employee_updateRecord(employeeId : inputEmployee : updatedEmployee);
      sendInternalErrorResponse(response);
      return *OFF;
    endif;
    
    // Réponse
    data-gen jsonResponse %data(updatedEmployee : 'doc=string case=convert');
    
    il_addHttpHeader(response : 'Content-Type' : 'application/json; charset=utf-8');
    il_addHttpHeader(response : 'ETag' : getEmployeeETag(employeeId));
    
    il_responseWrite(response : %addr(jsonResponse) : %len(%trimr(jsonResponse)));
    
    // Log audit
    auditLog('UPDATE' : 'EMPLOYEE' : %char(employeeId) : 'Employee updated');
    
    return *ON;
    
  on-error;
    sendInternalErrorResponse(response);
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🔍 Module 4 : Filtres et Recherche Avancés

### **🎯 Système de Filtres Dynamiques**

#### **Parser de Filtres REST**
```rpg
// Structure filtre standardisée
dcl-ds filter_t template qualified;
  field varchar(50);
  operator varchar(10);     // =, <>, >, <, >=, <=, LIKE, IN
  value varchar(200);
  dataType varchar(10);     // STRING, NUMBER, DATE, BOOLEAN
end-ds;

dcl-proc parseRestFilters export;
  dcl-pi *n int(10);
    queryString varchar(2000) const;
    filters likeDS(filter_t) dim(50);
  end-pi;
  
  dcl-s paramArray varchar(100) dim(100);
  dcl-s paramCount int(10);
  dcl-s filterCount int(10) inz(0);
  dcl-s i int(10);
  dcl-s paramName varchar(50);
  dcl-s paramValue varchar(200);
  dcl-s operatorPos int(10);
  
  // Séparer paramètres (&)
  paramCount = splitString(queryString : '&' : paramArray);
  
  for i = 1 to paramCount;
    // Ignorer paramètres spéciaux (_page, _limit, _sort)
    if %subst(paramArray(i) : 1 : 1) = '_';
      iter;
    endif;
    
    // Séparer nom=valeur
    if parseKeyValue(paramArray(i) : paramName : paramValue);
      filterCount += 1;
      
      // Détecter opérateur dans le nom du paramètre
      select;
        when %scan('_like' : paramName) > 0;
          filters(filterCount).field = %subst(paramName : 1 : %scan('_like' : paramName) - 1);
          filters(filterCount).operator = 'LIKE';
          filters(filterCount).value = '%' + %trimr(paramValue) + '%';
          filters(filterCount).dataType = 'STRING';
          
        when %scan('_gte' : paramName) > 0;
          filters(filterCount).field = %subst(paramName : 1 : %scan('_gte' : paramName) - 1);
          filters(filterCount).operator = '>=';
          filters(filterCount).value = paramValue;
          filters(filterCount).dataType = 'NUMBER';
          
        when %scan('_lte' : paramName) > 0;
          filters(filterCount).field = %subst(paramName : 1 : %scan('_lte' : paramName) - 1);
          filters(filterCount).operator = '<=';
          filters(filterCount).value = paramValue;
          filters(filterCount).dataType = 'NUMBER';
          
        when %scan('_ne' : paramName) > 0;
          filters(filterCount).field = %subst(paramName : 1 : %scan('_ne' : paramName) - 1);
          filters(filterCount).operator = '<>';
          filters(filterCount).value = paramValue;
          
        other;
          // Égalité par défaut
          filters(filterCount).field = paramName;
          filters(filterCount).operator = '=';
          filters(filterCount).value = paramValue;
      endsl;
    endif;
  endfor;
  
  return filterCount;
end-proc;
```

#### **Générateur WHERE Clause Dynamique**
```rpg
dcl-proc buildWhereClause export;
  dcl-pi *n varchar(2000);
    filters likeDS(filter_t) dim(50) const;
    filterCount int(10) const;
    tableAlias varchar(10) const;
  end-pi;
  
  dcl-s whereClause varchar(2000) inz('');
  dcl-s condition varchar(200);
  dcl-s i int(10);
  dcl-s fieldMapping ds qualified;
    // Mapping champs API vers DB
    name varchar(50) inz('e.first_name || '' '' || e.last_name');
    email varchar(50) inz('e.email');
    department varchar(50) inz('d.department_name');
    salary varchar(50) inz('e.salary');
    active varchar(50) inz('e.active');
  end-ds;
  
  if filterCount = 0;
    return '';
  endif;
  
  whereClause = 'WHERE ';
  
  for i = 1 to filterCount;
    if i > 1;
      whereClause += ' AND ';
    endif;
    
    // Construire condition selon type et opérateur
    condition = buildFilterCondition(filters(i) : fieldMapping);
    whereClause += condition;
  endfor;
  
  return whereClause;
end-proc;

dcl-proc buildFilterCondition export;
  dcl-pi *n varchar(200);
    filter likeDS(filter_t) const;
    fieldMapping ds const qualified;
  end-pi;
  
  dcl-s condition varchar(200);
  dcl-s dbField varchar(50);
  dcl-s value varchar(200);
  
  // Mapper champ API vers champ DB
  select;
    when filter.field = 'name';
      dbField = fieldMapping.name;
    when filter.field = 'email';
      dbField = fieldMapping.email;
    when filter.field = 'department';
      dbField = fieldMapping.department;
    when filter.field = 'salary';
      dbField = fieldMapping.salary;
    when filter.field = 'active';
      dbField = fieldMapping.active;
    other;
      // Champ non supporté
      return '1=1'; // Condition neutre
  endsl;
  
  // Formater valeur selon type
  select;
    when filter.dataType = 'STRING';
      value = '''' + %trimr(filter.value) + '''';
    when filter.dataType = 'NUMBER';
      value = %trimr(filter.value);
    when filter.dataType = 'BOOLEAN';
      if %upper(%trimr(filter.value)) = 'TRUE';
        value = '''Y''';
      else;
        value = '''N''';
      endif;
    other;
      value = '''' + %trimr(filter.value) + '''';
  endsl;
  
  // Construire condition
  select;
    when filter.operator = 'LIKE';
      condition = 'UPPER(' + dbField + ') LIKE UPPER(' + value + ')';
    other;
      condition = dbField + ' ' + filter.operator + ' ' + value;
  endsl;
  
  return condition;
end-proc;
```

### **🔎 Recherche Full-Text**

#### **Recherche Multi-Champs**
```rpg
dcl-proc employee_search export;
  dcl-pi *n int(10);
    searchTerm varchar(200) const;
    employees likeDS(employee_item_t) dim(100);
  end-pi;
  
  dcl-s sql varchar(4000);
  dcl-s searchPattern varchar(210);
  dcl-s count int(10) inz(0);
  
  if %len(%trimr(searchTerm)) < 2;
    return 0; // Minimum 2 caractères
  endif;
  
  searchPattern = '%' + %upper(%trimr(searchTerm)) + '%';
  
  sql = 'SELECT e.id, e.first_name, e.last_name, e.email, ' +
        '       d.department_name, e.active ' +
        'FROM employees e ' +
        'LEFT JOIN departments d ON e.dept_id = d.id ' +
        'WHERE (UPPER(e.first_name) LIKE ? ' +
        '   OR UPPER(e.last_name) LIKE ? ' +
        '   OR UPPER(e.email) LIKE ? ' +
        '   OR UPPER(d.department_name) LIKE ?) ' +
        '  AND e.active = ''Y'' ' +
        'ORDER BY ' +
        '  CASE ' +
        '    WHEN UPPER(e.first_name) LIKE ? THEN 1 ' +
        '    WHEN UPPER(e.last_name) LIKE ? THEN 2 ' +
        '    WHEN UPPER(e.email) LIKE ? THEN 3 ' +
        '    ELSE 4 ' +
        '  END, e.last_name, e.first_name ' +
        'LIMIT 50';
  
  exec sql PREPARE search_stmt FROM :sql;
  exec sql DECLARE search_cursor CURSOR FOR search_stmt;
  exec sql OPEN search_cursor USING :searchPattern, :searchPattern, 
    :searchPattern, :searchPattern, :searchPattern, :searchPattern, :searchPattern;
  
  dow sqlcode = 0 and count < %elem(employees);
    exec sql FETCH search_cursor INTO :employees(count + 1);
    if sqlcode = 0;
      count += 1;
    endif;
  enddo;
  
  exec sql CLOSE search_cursor;
  
  return count;
end-proc;
```

---

## 🔒 Module 5 : Sécurité et Authentification

### **🛡️ Authentification JWT**

#### **Validation Token JWT**
```rpg
dcl-proc validateJwtToken export;
  dcl-pi *n ind;
    token varchar(500) const;
    userInfo ds qualified;
      userId varchar(50);
      username varchar(100);
      roles varchar(200);
      expiresAt timestamp;
    end-ds;
  end-pi;
  
  dcl-s header varchar(200);
  dcl-s payload varchar(1000);
  dcl-s signature varchar(100);
  dcl-s expectedSignature varchar(100);
  dcl-s payloadJson varchar(1000);
  
  monitor;
    // Séparer les 3 parties du JWT (header.payload.signature)
    if not parseJwtParts(token : header : payload : signature);
      return *OFF;
    endif;
    
    // Vérifier signature
    expectedSignature = calculateJwtSignature(header + '.' + payload);
    if signature <> expectedSignature;
      return *OFF;
    endif;
    
    // Decoder payload (Base64)
    payloadJson = base64Decode(payload);
    
    // Parser payload JSON
    data-into userInfo %data(payloadJson : 'doc=string case=any');
    
    // Vérifier expiration
    if userInfo.expiresAt < %timestamp();
      return *OFF; // Token expiré
    endif;
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

### **🔐 Autorisation Basée sur Rôles**

#### **Système RBAC**
```rpg
dcl-proc checkEndpointPermission export;
  dcl-pi *n ind;
    userRoles varchar(200) const;
    endpoint varchar(100) const;
    method varchar(10) const;
  end-pi;
  
  dcl-s roles varchar(50) dim(10);
  dcl-s roleCount int(10);
  dcl-s i int(10);
  dcl-s hasPermission ind inz(*OFF);
  
  // Parser roles (comma separated)
  roleCount = splitString(userRoles : ',' : roles);
  
  // Définir permissions par endpoint/méthode
  select;
    // Lecture - accessible à tous les utilisateurs connectés
    when method = 'GET';
      hasPermission = *ON;
      
    // Création - rôle HR ou ADMIN
    when method = 'POST' and %scan('/employees' : endpoint) > 0;
      for i = 1 to roleCount;
        if %upper(%trimr(roles(i))) = 'HR' or %upper(%trimr(roles(i))) = 'ADMIN';
          hasPermission = *ON;
          leave;
        endif;
      endfor;
      
    // Modification - rôle HR ou ADMIN
    when method = 'PUT' and %scan('/employees' : endpoint) > 0;
      for i = 1 to roleCount;
        if %upper(%trimr(roles(i))) = 'HR' or %upper(%trimr(roles(i))) = 'ADMIN';
          hasPermission = *ON;
          leave;
        endif;
      endfor;
      
    // Suppression - rôle ADMIN uniquement
    when method = 'DELETE';
      for i = 1 to roleCount;
        if %upper(%trimr(roles(i))) = 'ADMIN';
          hasPermission = *ON;
          leave;
        endif;
      endfor;
      
    other;
      hasPermission = *OFF;
  endsl;
  
  return hasPermission;
end-proc;
```

---

## 📊 Module 6 : Performance et Monitoring

### **⚡ Optimisation Performance**

#### **Cache Intelligent**
```rpg
// Cache en mémoire avec TTL
dcl-ds cacheEntry_t template qualified;
  key varchar(100);
  data varchar(8000);
  createdAt timestamp;
  ttlSeconds int(10);
end-ds;

dcl-s cache likeDS(cacheEntry_t) dim(1000);
dcl-s cacheSize int(10) inz(0);

dcl-proc cacheGet export;
  dcl-pi *n varchar(8000);
    key varchar(100) const;
  end-pi;
  
  dcl-s i int(10);
  dcl-s now timestamp;
  dcl-s ageSeconds int(10);
  
  now = %timestamp();
  
  for i = 1 to cacheSize;
    if cache(i).key = key;
      ageSeconds = %diff(now : cache(i).createdAt : *seconds);
      
      if ageSeconds <= cache(i).ttlSeconds;
        return cache(i).data; // Cache hit
      else;
        // Cache expiré, le supprimer
        cacheRemove(key);
        return '';
      endif;
    endif;
  endfor;
  
  return ''; // Cache miss
end-proc;

dcl-proc cacheSet export;
  dcl-pi *n;
    key varchar(100) const;
    data varchar(8000) const;
    ttlSeconds int(10) const;
  end-pi;
  
  // Supprimer existant si présent
  cacheRemove(key);
  
  // Ajouter nouveau (si place disponible)
  if cacheSize < %elem(cache);
    cacheSize += 1;
    cache(cacheSize).key = key;
    cache(cacheSize).data = data;
    cache(cacheSize).createdAt = %timestamp();
    cache(cacheSize).ttlSeconds = ttlSeconds;
  endif;
  
end-proc;
```

#### **Métriques Détaillées**
```rpg
dcl-proc recordApiMetrics export;
  dcl-pi *n;
    endpoint varchar(100) const;
    method varchar(10) const;
    statusCode int(10) const;
    responseTimeMs int(10) const;
    resultCount int(10) const;
  end-pi;
  
  dcl-s metricsEntry varchar(500);
  dcl-s timestamp char(26);
  
  timestamp = %char(%timestamp());
  
  metricsEntry = %trimr(timestamp) + '|' +
                 %trimr(method) + '|' +
                 %trimr(endpoint) + '|' +
                 %char(statusCode) + '|' +
                 %char(responseTimeMs) + '|' +
                 %char(resultCount);
  
  // Écrire vers fichier métriques
  writeToMetricsFile(metricsEntry);
  
  // Alerting temps de réponse
  if responseTimeMs > 1000;
    logWarning('PERFORMANCE' : 'Slow API response: ' + endpoint + 
      ' took ' + %char(responseTimeMs) + 'ms');
  endif;
  
  // Alerting erreurs
  if statusCode >= 500;
    logError('API_ERROR' : 'Server error on ' + endpoint + 
      ' - Status: ' + %char(statusCode));
  endif;
  
end-proc;
```

---

## 🧪 Module 7 : Tests et Validation

### **🔍 Tests d'Intégration**

#### **Framework de Tests API**
```rpg
dcl-proc runApiTests export;
  dcl-pi *n ind end-pi;
  
  dcl-s testsPassed int(10) inz(0);
  dcl-s testsTotal int(10) inz(0);
  
  // Tests CRUD Employee
  testsTotal += 1;
  if testEmployeeCrud();
    testsPassed += 1;
  endif;
  
  // Tests pagination
  testsTotal += 1;
  if testPagination();
    testsPassed += 1;
  endif;
  
  // Tests filtres
  testsTotal += 1;
  if testFiltering();
    testsPassed += 1;
  endif;
  
  // Tests erreurs
  testsTotal += 1;
  if testErrorHandling();
    testsPassed += 1;
  endif;
  
  // Résultat final
  logInfo('TESTS' : 'runApiTests' : 
    %char(testsPassed) + '/' + %char(testsTotal) + ' tests passed');
  
  return (testsPassed = testsTotal);
end-proc;

dcl-proc testEmployeeCrud export;
  dcl-pi *n ind end-pi;
  
  dcl-s employeeId int(10);
  dcl-s testData varchar(1000);
  dcl-s response varchar(2000);
  dcl-s statusCode int(10);
  
  monitor;
    // Test CREATE
    testData = '{"firstName":"Test","lastName":"User","email":"test@company.com"}';
    response = callApiEndpoint('POST' : '/api/employees' : testData : statusCode);
    
    if statusCode <> 201;
      logError('TEST' : 'testEmployeeCrud' : 'CREATE failed - Status: ' + %char(statusCode));
      return *OFF;
    endif;
    
    // Extraire ID créé
    employeeId = extractIdFromResponse(response);
    
    // Test READ
    response = callApiEndpoint('GET' : '/api/employees/' + %char(employeeId) : '' : statusCode);
    
    if statusCode <> 200;
      logError('TEST' : 'testEmployeeCrud' : 'READ failed - Status: ' + %char(statusCode));
      return *OFF;
    endif;
    
    // Test UPDATE
    testData = '{"firstName":"Updated","lastName":"User","email":"updated@company.com"}';
    response = callApiEndpoint('PUT' : '/api/employees/' + %char(employeeId) : testData : statusCode);
    
    if statusCode <> 200;
      logError('TEST' : 'testEmployeeCrud' : 'UPDATE failed - Status: ' + %char(statusCode));
      return *OFF;
    endif;
    
    // Test DELETE
    response = callApiEndpoint('DELETE' : '/api/employees/' + %char(employeeId) : '' : statusCode);
    
    if statusCode <> 200;
      logError('TEST' : 'testEmployeeCrud' : 'DELETE failed - Status: ' + %char(statusCode));
      return *OFF;
    endif;
    
    logInfo('TEST' : 'testEmployeeCrud' : 'All CRUD operations passed');
    return *ON;
    
  on-error;
    logError('TEST' : 'testEmployeeCrud' : 'Exception: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🎯 Projet Final : API E-Commerce

### **📋 Spécifications**

#### **Ressources à Implémenter**
```
Products API
├── GET /api/products                    # Collection avec filtres
├── GET /api/products/{id}              # Détail produit
├── POST /api/products                  # Création produit
├── PUT /api/products/{id}              # Modification produit
├── DELETE /api/products/{id}           # Suppression produit
└── POST /api/products/{id}/restock     # Action métier

Categories API  
├── GET /api/categories                 # Collection catégories
├── GET /api/categories/{id}/products   # Produits d'une catégorie
└── ...

Orders API
├── GET /api/orders                     # Commandes utilisateur
├── POST /api/orders                    # Nouvelle commande
├── PUT /api/orders/{id}/status         # Changer statut
└── ...
```

#### **Fonctionnalités Avancées**
- **Authentification JWT** complète
- **Autorisation RBAC** (Customer, Employee, Admin)
- **Filtres avancés** (prix, catégorie, stock, etc.)
- **Recherche full-text** produits
- **Cache intelligent** pour performances
- **Audit trail** complet
- **Tests automatisés** 100% endpoints

### **🏆 Critères d'Évaluation**

```markdown
## Architecture (25 points)
- [ ] Structure modulaire respectée
- [ ] Séparation responsabilités claire
- [ ] Patterns REST standards appliqués
- [ ] Gestion erreurs robuste

## Fonctionnalités (35 points)
- [ ] CRUD complet toutes ressources
- [ ] Filtres et pagination fonctionnels
- [ ] Authentification/autorisation
- [ ] Actions métier implémentées

## Qualité Code (25 points)
- [ ] Code RPG moderne et lisible
- [ ] Validation input complète
- [ ] Performance optimisée
- [ ] Documentation technique

## Tests (15 points)
- [ ] Tests unitaires métier
- [ ] Tests d'intégration API
- [ ] Validation conformité REST
- [ ] Couverture > 80%
```

---

## 📚 Ressources et Certification

### **📖 Documentation Référence**
- [REST API Design Guide](https://restfulapi.net/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [JSON API Specification](https://jsonapi.org/)
- [ILEastic Documentation](https://github.com/sitemule/ILEastic)

### **🎓 Certification ArchiAPI**
- **Formation théorique** : 40 heures
- **Travaux pratiques** : 60 heures
- **Projet final** : API E-Commerce complète
- **Évaluation** : Présentation + Code review

### **🏅 Niveaux Certification**
- **Associate** : APIs REST de base
- **Professional** : Architecture avancée + Performance
- **Expert** : Mentoring + Architecture enterprise

---

*Formation API REST IBM i - Équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*