# 🎓 Formation RPG ILE Moderne

*Parcours complet d'apprentissage RPG ILE pour le développement d'APIs REST*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Objectifs de Formation

### **🏆 Compétences Cibles**
- Maîtriser RPG ILE free format moderne
- Comprendre l'intégration SQL native
- Développer des APIs REST avec ILEastic
- Appliquer les bonnes pratiques IBM i

### **👥 Public Cible**
- Développeurs RPG traditionnels (fixed format)
- Développeurs web découvrant IBM i
- Architectes souhaitant moderniser
- Équipes passant aux APIs REST

---

## 📚 Module 1 : Fondamentaux RPG ILE Free Format

### **🔤 Syntaxe Moderne**

#### **Structure de Base**
```rpg
**free
// Programme moderne - pas de colonnes fixes
ctl-opt nomain thread(*serialize) decedit('0,') datfmt(*iso);

// Inclusions en début de source
/copy QCPYSRC,PROTOTYPES
/copy QCPYILE,ILEASTIC

// Procédure principale
dcl-proc main export;
  dcl-pi *n ind end-pi;
  
  // Variables locales
  dcl-s message varchar(100);
  
  // Logique
  message = 'Hello from modern RPG!';
  dsply message;
  
  return *ON;
end-proc;
```

#### **Variables et Types Modernes**
```rpg
// Types de données recommandés
dcl-s sName varchar(100);           // Chaînes variables
dcl-s nCount int(10);               // Entiers standard
dcl-s dAmount packed(9:2);          // Décimaux packés
dcl-s bIsActive ind;                // Indicateurs
dcl-s tTimestamp timestamp;         // Horodatage

// Tableaux dynamiques
dcl-s aNumbers int(10) dim(100);
dcl-s aNames varchar(50) dim(50);

// Pointeurs
dcl-s pData pointer;
dcl-s pBuffer pointer;
```

### **🏗️ Structures de Données**

#### **Data Structures Templates**
```rpg
// Template réutilisable
dcl-ds employee_t template qualified;
  id int(10);
  firstName varchar(50);
  lastName varchar(50);
  email varchar(100);
  salary packed(9:2);
  active ind;
  createdDate date;
end-ds;

// Utilisation du template
dcl-ds employee likeDS(employee_t);
dcl-ds employees likeDS(employee_t) dim(100);
```

#### **Qualified Data Structures**
```rpg
// Structure qualifiée pour éviter conflits
dcl-ds person qualified;
  name varchar(100);
  address qualified;
    street varchar(100);
    city varchar(50);
    zipCode varchar(10);
  end-ds;
end-ds;

// Accès qualifié
person.name = 'John Doe';
person.address.city = 'Paris';
```

### **🔧 Procédures et Fonctions**

#### **Procédures avec Paramètres**
```rpg
// Prototype
dcl-pr calculateTax export;
  amount packed(9:2) const;
  taxRate packed(5:4) const;
  return packed(9:2);
end-pr;

// Implémentation
dcl-proc calculateTax export;
  dcl-pi *n packed(9:2);
    amount packed(9:2) const;
    taxRate packed(5:4) const;
  end-pi;
  
  dcl-s result packed(9:2);
  
  if amount > 0 and taxRate >= 0;
    result = amount * taxRate;
  else;
    result = 0;
  endif;
  
  return result;
end-proc;
```

#### **Gestion d'Erreurs Moderne**
```rpg
dcl-proc processEmployee export;
  dcl-pi *n ind;
    employeeId int(10) const;
    employeeData likeDS(employee_t);
  end-pi;
  
  monitor;
    // Logique métier pouvant échouer
    employeeData = getEmployeeById(employeeId);
    
    if employeeData.id = 0;
      // Employé non trouvé
      return *OFF;
    endif;
    
    return *ON;
    
  on-error;
    // Log de l'erreur
    logError('Error in processEmployee: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🗄️ Module 2 : SQL Intégré Avancé

### **📊 Embedded SQL Moderne**

#### **Requêtes de Base**
```rpg
// Variables host
dcl-s employeeId int(10);
dcl-s employeeName varchar(100);
dcl-s departmentName varchar(50);

// SELECT avec JOIN
exec sql 
  SELECT e.name, d.department_name
  INTO :employeeName, :departmentName
  FROM employees e
  INNER JOIN departments d ON e.dept_id = d.id
  WHERE e.id = :employeeId;

// Vérification résultat
select;
  when sqlcode = 0;
    // Succès
  when sqlcode = 100;
    // Pas de données trouvées
  other;
    // Erreur SQL
    logSqlError(sqlcode : sqlstate);
endsl;
```

#### **Curseurs Dynamiques**
```rpg
// SQL dynamique avec curseur
dcl-proc getEmployeesList export;
  dcl-pi *n int(10);
    searchCriteria varchar(1000) const;
    employees likeDS(employee_t) dim(100);
  end-pi;
  
  dcl-s sqlStmt varchar(4000);
  dcl-s count int(10) inz(0);
  dcl-s employee likeDS(employee_t);
  
  // Construction requête dynamique
  sqlStmt = 'SELECT id, first_name, last_name, email, salary, active ' +
            'FROM employees';
            
  if %len(%trimr(searchCriteria)) > 0;
    sqlStmt += ' WHERE ' + searchCriteria;
  endif;
  
  sqlStmt += ' ORDER BY last_name, first_name';
  
  // Exécution avec curseur
  exec sql PREPARE stmt FROM :sqlStmt;
  exec sql DECLARE cursor1 CURSOR FOR stmt;
  exec sql OPEN cursor1;
  
  dow sqlcode = 0 and count < %elem(employees);
    exec sql FETCH cursor1 INTO :employee.id, :employee.firstName, 
      :employee.lastName, :employee.email, :employee.salary, :employee.active;
      
    if sqlcode = 0;
      count += 1;
      employees(count) = employee;
    endif;
  enddo;
  
  exec sql CLOSE cursor1;
  
  return count;
end-proc;
```

### **🔄 Transactions et Performance**

#### **Gestion Transactions**
```rpg
dcl-proc transferFunds export;
  dcl-pi *n ind;
    fromAccount int(10) const;
    toAccount int(10) const;
    amount packed(9:2) const;
  end-pi;
  
  monitor;
    // Démarrer transaction
    exec sql SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    exec sql COMMIT HOLD;
    
    // Débiter compte source
    exec sql 
      UPDATE accounts 
      SET balance = balance - :amount,
          updated_at = CURRENT_TIMESTAMP
      WHERE account_id = :fromAccount
        AND balance >= :amount;
    
    if sqlcode <> 0;
      exec sql ROLLBACK;
      return *OFF;
    endif;
    
    // Créditer compte destination
    exec sql
      UPDATE accounts
      SET balance = balance + :amount,
          updated_at = CURRENT_TIMESTAMP
      WHERE account_id = :toAccount;
    
    if sqlcode <> 0;
      exec sql ROLLBACK;
      return *OFF;
    endif;
    
    // Valider transaction
    exec sql COMMIT;
    return *ON;
    
  on-error;
    exec sql ROLLBACK;
    return *OFF;
  endmon;
  
end-proc;
```

#### **Optimisation Requêtes**
```rpg
// Requête optimisée avec index hints
exec sql
  SELECT /*+ INDEX(employees, emp_dept_active_idx) */
         id, name, email
  FROM employees
  WHERE department_id = :deptId
    AND active = 'Y'
  ORDER BY name
  OPTIMIZE FOR 20 ROWS;

// Pagination efficace
exec sql
  SELECT id, name, email
  FROM employees
  WHERE department_id = :deptId
    AND active = 'Y'
  ORDER BY id
  LIMIT :pageSize OFFSET :offsetValue;
```

---

## 🌐 Module 3 : JSON et APIs Modernes

### **📝 Manipulation JSON Native**

#### **Parsing JSON**
```rpg
// Structure pour JSON
dcl-ds customerData qualified template;
  id int(10);
  name varchar(100);
  email varchar(200);
  preferences qualified;
    newsletter ind;
    language varchar(10);
  end-ds;
  addresses qualified dim(5);
    type varchar(20);
    street varchar(100);
    city varchar(50);
  end-ds;
end-ds;

// Parser JSON complexe
dcl-proc parseCustomerJson export;
  dcl-pi *n ind;
    jsonString varchar(4000) const;
    customer likeDS(customerData);
  end-pi;
  
  monitor;
    data-into customer %data(jsonString : 'doc=string case=any');
    return *ON;
  on-error;
    logError('JSON parsing failed: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

#### **Génération JSON**
```rpg
// Génération JSON avec options
dcl-proc generateCustomerJson export;
  dcl-pi *n varchar(4000);
    customer likeDS(customerData) const;
  end-pi;
  
  dcl-s jsonOutput varchar(4000);
  
  data-gen jsonOutput %data(customer : 
    'doc=string case=convert trim=all skipnull=yes');
  
  return jsonOutput;
end-proc;

// JSON avec structure personnalisée
dcl-proc generateApiResponse export;
  dcl-pi *n varchar(8000);
    success ind const;
    message varchar(200) const;
    data varchar(4000) const;
  end-pi;
  
  dcl-ds response qualified;
    success ind;
    message varchar(200);
    timestamp char(26);
    data varchar(4000);
  end-ds;
  
  dcl-s jsonResponse varchar(8000);
  
  response.success = success;
  response.message = message;
  response.timestamp = %char(%timestamp());
  response.data = data;
  
  data-gen jsonResponse %data(response : 'doc=string case=convert');
  
  return jsonResponse;
end-proc;
```

### **🔗 Intégration Web Services**

#### **Client HTTP Simple**
```rpg
// Appel service externe
dcl-proc callExternalApi export;
  dcl-pi *n varchar(2000);
    url varchar(500) const;
    headers varchar(1000) const;
  end-pi;
  
  dcl-s response varchar(2000);
  dcl-s curlCmd varchar(1000);
  
  // Construction commande curl
  curlCmd = 'curl -s -H "' + %trimr(headers) + '" "' + %trimr(url) + '"';
  
  // Exécution via system()
  response = executeSystemCommand(curlCmd);
  
  return response;
end-proc;
```

---

## 🚀 Module 4 : ILEastic Framework

### **⚙️ Configuration Serveur**

#### **Serveur de Base**
```rpg
**free
ctl-opt main(main);

/copy QCPYILE,ILEASTIC

dcl-proc main;
  dcl-s config pointer;
  dcl-s router pointer;
  
  // Configuration serveur
  config = il_newConfig();
  il_configSetPort(config : 44001);
  il_configSetHost(config : '*ANY');
  il_configSetLogging(config : *ON);
  
  // Créer router
  router = il_newRouter(config);
  
  // Middleware global
  il_addMiddleware(router : %paddr(corsMiddleware));
  il_addMiddleware(router : %paddr(loggingMiddleware));
  
  // Routes API
  setupApiRoutes(router);
  
  // Démarrer serveur
  il_listen(router);
end-proc;
```

#### **Middleware Personnalisé**
```rpg
// Middleware CORS
dcl-proc corsMiddleware export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
    next pointer const;
  end-pi;
  
  // Headers CORS
  il_addHttpHeader(response : 'Access-Control-Allow-Origin' : '*');
  il_addHttpHeader(response : 'Access-Control-Allow-Methods' : 
    'GET, POST, PUT, DELETE, OPTIONS');
  il_addHttpHeader(response : 'Access-Control-Allow-Headers' : 
    'Content-Type, Authorization');
  
  // Continuer vers handler suivant
  return il_nextMiddleware(next : request : response);
end-proc;

// Middleware logging
dcl-proc loggingMiddleware export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
    next pointer const;
  end-pi;
  
  dcl-s startTime timestamp;
  dcl-s endTime timestamp;
  dcl-s duration int(10);
  dcl-s method varchar(10);
  dcl-s path varchar(200);
  
  startTime = %timestamp();
  method = il_getRequestMethod(request);
  path = il_getRequestPath(request);
  
  // Exécuter handler
  il_nextMiddleware(next : request : response);
  
  endTime = %timestamp();
  duration = %diff(endTime : startTime : *mseconds);
  
  // Log de la requête
  logApiCall(method : path : duration);
  
  return *ON;
end-proc;
```

### **🛣️ Routing Avancé**

#### **Routes avec Paramètres**
```rpg
dcl-proc setupApiRoutes export;
  dcl-pi *n;
    router pointer const;
  end-pi;
  
  // Routes collection
  il_addRoute(router : '/api/employees' : IL_GET : %paddr(getEmployees));
  il_addRoute(router : '/api/employees' : IL_POST : %paddr(createEmployee));
  
  // Routes avec paramètres
  il_addRoute(router : '/api/employees/{id}' : IL_GET : %paddr(getEmployee));
  il_addRoute(router : '/api/employees/{id}' : IL_PUT : %paddr(updateEmployee));
  il_addRoute(router : '/api/employees/{id}' : IL_DELETE : %paddr(deleteEmployee));
  
  // Routes actions spécialisées
  il_addRoute(router : '/api/employees/{id}/promote' : IL_POST : %paddr(promoteEmployee));
  il_addRoute(router : '/api/employees/{id}/suspend' : IL_POST : %paddr(suspendEmployee));
  
  // Route de santé
  il_addRoute(router : '/api/health' : IL_GET : %paddr(healthCheck));
  
end-proc;
```

#### **Handlers REST Complets**
```rpg
// Handler GET collection avec pagination
dcl-proc getEmployees export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-s page int(10) inz(1);
  dcl-s limit int(10) inz(20);
  dcl-s offset int(10);
  dcl-s totalCount int(10);
  dcl-s jsonData varchar(32000);
  
  monitor;
    // Parser paramètres query
    page = %int(il_getQueryParam(request : '_page' : '1'));
    limit = %int(il_getQueryParam(request : '_limit' : '20'));
    
    // Calculer offset
    offset = (page - 1) * limit;
    
    // Récupérer données avec pagination
    jsonData = getEmployeesData(offset : limit : totalCount);
    
    // Headers REST standard
    il_addHttpHeader(response : 'Content-Type' : 'application/json');
    il_addHttpHeader(response : 'X-Total-Count' : %char(totalCount));
    il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
    
    // Réponse
    il_responseWrite(response : %addr(jsonData) : %len(%trimr(jsonData)));
    
    return *ON;
    
  on-error;
    sendErrorResponse(response : 500 : 'Internal server error');
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🧪 Module 5 : Tests et Qualité

### **🔍 Tests Unitaires RPG**

#### **Framework de Tests Simple**
```rpg
// Framework de tests basique
dcl-proc assert export;
  dcl-pi *n;
    condition ind const;
    message varchar(200) const;
  end-pi;
  
  if not condition;
    dsply ('ASSERTION FAILED: ' + message);
    // Ou logger l'erreur
  else;
    dsply ('TEST PASSED: ' + message);
  endif;
  
end-proc;

// Test d'une fonction métier
dcl-proc testCalculateTax export;
  dcl-pi *n ind end-pi;
  
  dcl-s result packed(9:2);
  
  // Test cas normal
  result = calculateTax(100.00 : 0.20);
  assert(result = 20.00 : 'Tax calculation normal case');
  
  // Test cas limite
  result = calculateTax(0 : 0.20);
  assert(result = 0 : 'Tax calculation zero amount');
  
  // Test cas d'erreur
  result = calculateTax(-100 : 0.20);
  assert(result = 0 : 'Tax calculation negative amount');
  
  return *ON;
end-proc;
```

### **🎯 Validation et Bonnes Pratiques**

#### **Validation d'Entrée**
```rpg
dcl-proc validateEmployeeInput export;
  dcl-pi *n ind;
    employee likeDS(employee_t) const;
    errors varchar(1000);
  end-pi;
  
  dcl-s errorList varchar(1000) inz('');
  
  // Validation nom requis
  if %len(%trimr(employee.firstName)) = 0;
    errorList += 'First name is required. ';
  endif;
  
  if %len(%trimr(employee.lastName)) = 0;
    errorList += 'Last name is required. ';
  endif;
  
  // Validation email format
  if %len(%trimr(employee.email)) > 0;
    if not isValidEmail(employee.email);
      errorList += 'Invalid email format. ';
    endif;
  endif;
  
  // Validation salaire
  if employee.salary < 0;
    errorList += 'Salary cannot be negative. ';
  endif;
  
  errors = errorList;
  return (%len(%trimr(errorList)) = 0);
  
end-proc;

// Validation email basique
dcl-proc isValidEmail export;
  dcl-pi *n ind;
    email varchar(200) const;
  end-pi;
  
  // Validation simple avec %check
  if %check('@' : email) = 0;
    return *OFF; // Pas de @
  endif;
  
  if %check('.' : email) = 0;
    return *OFF; // Pas de point
  endif;
  
  // Validation plus poussée possible avec regex
  return *ON;
end-proc;
```

---

## 🔧 Module 6 : Outils et Debugging

### **🐛 Techniques de Debug**

#### **Logging Structuré**
```rpg
// Logger avec niveaux
dcl-proc writeLog export;
  dcl-pi *n;
    level varchar(10) const;     // DEBUG, INFO, WARN, ERROR
    module varchar(50) const;
    procedure varchar(50) const;
    message varchar(500) const;
  end-pi;
  
  dcl-s logEntry varchar(1000);
  dcl-s timestamp char(26);
  
  timestamp = %char(%timestamp());
  
  logEntry = %trimr(timestamp) + ' [' + %trimr(level) + '] ' +
             %trimr(module) + '.' + %trimr(procedure) + ': ' +
             %trimr(message);
             
  // Écrire vers IFS
  writeToLogFile(logEntry);
  
  // Afficher si mode debug
  if %subst(%trimr(level) : 1 : 1) = 'D'; // DEBUG
    dsply logEntry;
  endif;
  
end-proc;

// Macros pour simplifier usage
/define LOG_DEBUG(module:proc:msg) writeLog('DEBUG':module:proc:msg)
/define LOG_INFO(module:proc:msg) writeLog('INFO':module:proc:msg)
/define LOG_ERROR(module:proc:msg) writeLog('ERROR':module:proc:msg)
```

### **📊 Performance Profiling**

#### **Mesure Performance**
```rpg
dcl-proc profileProcedure export;
  dcl-pi *n;
    procedureName varchar(50) const;
    procedurePtr pointer const;
    // Paramètres procédure à tester
  end-pi;
  
  dcl-s startTime timestamp;
  dcl-s endTime timestamp;
  dcl-s duration int(10);
  
  startTime = %timestamp();
  
  // Appel procédure (simulation)
  // callprocedurepointer(procedurePtr : params);
  
  endTime = %timestamp();
  duration = %diff(endTime : startTime : *mseconds);
  
  LOG_INFO('PROFILER' : 'profileProcedure' : 
    procedureName + ' executed in ' + %char(duration) + 'ms');
  
end-proc;
```

---

## 🎯 Exercices Pratiques

### **💻 Exercice 1 : API Employee CRUD**

#### **Objectif**
Créer une API REST complète pour gestion d'employés avec :
- CRUD complet (Create, Read, Update, Delete)
- Pagination et filtres
- Validation d'entrée
- Gestion d'erreurs

#### **Structure à Implémenter**
```rpg
// employee.rpgleinc
dcl-ds employee_t template qualified export;
  id int(10);
  firstName varchar(50);
  lastName varchar(50);
  email varchar(100);
  department varchar(50);
  salary packed(9:2);
  active ind;
  createdDate date;
  updatedDate timestamp;
end-ds;

// Prototypes à implémenter
dcl-pr employee_getCollection export;
  offset int(10) const;
  limit int(10) const;
  filters varchar(1000) const;
  totalCount int(10);
  return varchar(32000);
end-pr;

dcl-pr employee_getById export;
  id int(10) const;
  employee likeDS(employee_t);
  return ind;
end-pr;

dcl-pr employee_create export;
  inputData likeDS(employee_t) const;
  newEmployee likeDS(employee_t);
  return ind;
end-pr;

dcl-pr employee_update export;
  id int(10) const;
  inputData likeDS(employee_t) const;
  updatedEmployee likeDS(employee_t);
  return ind;
end-pr;

dcl-pr employee_delete export;
  id int(10) const;
  return ind;
end-pr;
```

### **💻 Exercice 2 : Filtres Avancés**

#### **Objectif**
Implémenter un système de filtres dynamiques pour l'API Employee :
- Filtres par nom (LIKE)
- Filtres par département
- Filtres par salaire (range)
- Filtres par statut actif

#### **Code de Base**
```rpg
dcl-proc buildWhereClause export;
  dcl-pi *n varchar(1000);
    filters varchar(2000) const;
  end-pi;
  
  dcl-s whereClause varchar(1000) inz('');
  dcl-s filterArray varchar(100) dim(20);
  dcl-s filterCount int(10);
  dcl-s i int(10);
  
  // Parser filters string "name_like=john&dept=IT&salary_gte=50000"
  filterCount = parseFilters(filters : filterArray);
  
  for i = 1 to filterCount;
    // Traiter chaque filtre
    // TODO: Implémenter logique
  endfor;
  
  return whereClause;
end-proc;
```

---

## 📊 Évaluation et Certification

### **📝 Test de Connaissances**

#### **Questions Techniques**
1. Quelle est la différence entre `varchar` et `char` en RPG ILE ?
2. Comment gérer les erreurs avec `monitor/on-error` ?
3. Expliquer l'utilisation de `data-into` et `data-gen`
4. Quels sont les avantages des procédures `export` ?
5. Comment optimiser une requête SQL avec pagination ?

#### **Exercice Final**
Créer une API REST complète pour une ressource "Products" avec :
- Structure de données appropriée
- CRUD complet avec ILEastic
- Filtres et pagination
- Validation et gestion d'erreurs
- Tests unitaires
- Documentation

### **🏆 Critères de Réussite**
- **Code fonctionnel** compilant sans erreur
- **API conforme** aux standards REST
- **Tests passants** pour tous les endpoints
- **Documentation** complète et claire
- **Bonnes pratiques** appliquées

---

## 📚 Ressources Complémentaires

### **📖 Documentation**
- [IBM RPG ILE Reference](https://www.ibm.com/docs/en/i/7.5?topic=languages-ile-rpg)
- [ILEastic Documentation](https://github.com/sitemule/ILEastic)
- [SQL for IBM i](https://www.ibm.com/docs/en/i/7.5?topic=reference-sql)

### **🎥 Tutoriels Vidéo**
- RPG ILE Free Format Basics
- JSON Integration in RPG
- Building REST APIs with ILEastic
- Modern IBM i Development

### **💬 Communautés**
- [IBM i Community](https://community.ibm.com/community/user/power/communities/community-home?CommunityKey=62b3fe17-cc3f-4b0f-b3c8-7b72f86dbbfd)
- [RPG Evolution](https://www.rpg-evolution.com/)
- [GitHub IBM i Projects](https://github.com/topics/ibmi)

---

*Formation RPG ILE Moderne - Équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*