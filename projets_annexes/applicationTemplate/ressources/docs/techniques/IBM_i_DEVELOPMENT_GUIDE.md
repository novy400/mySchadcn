# 🖥️ Guide de Développement IBM i - Spécificités Plateforme

*Guide spécialisé pour le développement moderne sur IBM i*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Introduction IBM i

### **🏛️ Contexte Plateforme**
IBM i (anciennement AS/400, iSeries) est une plateforme d'entreprise robuste avec des spécificités uniques pour le développement moderne d'APIs REST.

#### **🔑 Avantages Clés**
- **Intégration native** avec bases de données DB2
- **Sécurité enterprise-grade** intégrée
- **Stabilité légendaire** (uptime 99.9%+)
- **Performance** optimisée pour transactions
- **Écosystème mature** RPG/COBOL/C

#### **⚡ Défis Modernes**
- **Courbe d'apprentissage** pour développeurs web
- **Outils de développement** traditionnels
- **Intégration CI/CD** complexe
- **APIs modernes** depuis code legacy

---

## 🛠️ Environnement de Développement

### **📋 Configuration Workspace**

#### **VS Code pour IBM i**
```json
// .vscode/settings.json
{
  "code-for-ibmi.connectionSettings": [
    {
      "name": "IBM-DEV",
      "host": "your-ibmi-server.com",
      "username": "DEVELOPER",
      "privateKey": "~/.ssh/ibmi_key"
    }
  ],
  "code-for-ibmi.sourceFileSettings": {
    "QRPGLESRC": {
      "extensions": ["rpgle", "sqlrpgle"]
    },
    "QRPGLEINC": {
      "extensions": ["rpgleinc"]
    }
  }
}
```

#### **Extensions Essentielles**
```
Code for IBM i               # Connexion & développement
RPGLE Language Support       # Syntaxe RPG moderne
DB2 for i Extension         # Base de données
IBMi Development Pack       # Suite complète
GitPod Leeway              # Git workflow
```

### **🔐 Connexion & Authentification**

#### **SSH Key Setup**
```bash
# Générer clé SSH (sur PC)
ssh-keygen -t rsa -b 4096 -C "developer@company.com"

# Copier vers IBM i
ssh-copy-id DEVELOPER@your-ibmi-server.com

# Tester connexion
ssh DEVELOPER@your-ibmi-server.com
```

#### **Configuration PASE**
```bash
# Sur IBM i - Activer SSH
CHGTCPSVR SVRSPCVAL(*SSHD) AUTOSTART(*YES)
STRTCPSVR SERVER(*SSHD)

# Installer packages requis
/QOpenSys/pkgs/bin/yum install git nodejs npm python3
```

---

## 📚 Spécificités RPG ILE Moderne

### **🎨 Syntaxe Free Format**

#### **Structure de Base**
```rpg
**free
// Programme moderne RPG ILE
ctl-opt nomain thread(*serialize) decedit('0,') datfmt(*iso);

// Headers standards
/copy QCPYSRC,PROTOTYPE

dcl-proc myProcedure export;
  dcl-pi *n ind;
    input varchar(100) const;
    output varchar(200);
  end-pi;
  
  dcl-s result varchar(200);
  
  monitor;
    // Logique métier
    result = processInput(input);
    output = result;
    return *ON;
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

#### **Gestion Mémoire Moderne**
```rpg
// Allocation dynamique
dcl-s dataPtr pointer;
dcl-s dataSize int(10) inz(1000);

dataPtr = %alloc(dataSize);

monitor;
  // Utilisation pointer
  
on-error;
  // Nettoyage
endmon;

if dataPtr <> *null;
  dealloc dataPtr;
endif;
```

### **🔄 Intégration JSON Native**

#### **Parsing JSON**
```rpg
// Parser JSON avec DATA-INTO
dcl-ds employee_t template qualified;
  id int(10);
  name varchar(100);
  email varchar(200);
  active ind;
end-ds;

dcl-ds employee likeDS(employee_t);
dcl-s jsonString varchar(1000);

jsonString = '{"id":123,"name":"John Doe","email":"john@company.com","active":true}';

data-into employee %data(jsonString : 'doc=string case=any');
```

#### **Génération JSON**
```rpg
// Génération JSON avec DATA-GEN
dcl-ds response_t template qualified;
  success ind;
  message varchar(200);
  data likeDS(employee_t);
end-ds;

dcl-ds response likeDS(response_t);
dcl-s jsonOutput varchar(2000);

response.success = *ON;
response.message = 'Employee retrieved successfully';
response.data = employee;

data-gen jsonOutput %data(response : 'doc=string case=convert');
```

### **🗄️ SQL Intégré Avancé**

#### **Embedded SQL Moderne**
```rpg
// SQL avec host variables
dcl-s employeeId int(10);
dcl-s employeeName varchar(100);
dcl-s salary packed(9:2);

exec sql 
  SELECT name, salary 
  INTO :employeeName, :salary
  FROM employees 
  WHERE id = :employeeId;

if sqlcode = 0;
  // Succès
elseif sqlcode = 100;
  // Pas trouvé
else;
  // Erreur SQL
  logSqlError(sqlcode : sqlstate);
endif;
```

#### **Curseurs Dynamiques**
```rpg
// SQL dynamique avec curseur
dcl-s sqlStatement varchar(4000);
dcl-s whereClause varchar(1000);

sqlStatement = 'SELECT * FROM employees';

if %len(%trimr(whereClause)) > 0;
  sqlStatement += ' WHERE ' + whereClause;
endif;

exec sql PREPARE stmt FROM :sqlStatement;
exec sql DECLARE cursor1 CURSOR FOR stmt;
exec sql OPEN cursor1;

dow sqlcode = 0;
  exec sql FETCH cursor1 INTO :employee;
  if sqlcode = 0;
    processEmployee(employee);
  endif;
enddo;

exec sql CLOSE cursor1;
```

---

## 🌐 Développement Web avec ILEastic

### **🚀 Configuration ILEastic**

#### **Installation**
```bash
# Sur IBM i
cd /tmp
git clone https://github.com/sitemule/ILEastic.git
cd ILEastic

# Compilation
CRTBNDPGM PGM(MYLIB/ILEASTIC) SRCSTMF('/tmp/ILEastic/src/ileastic.rpgle')
```

#### **Serveur HTTP de Base**
```rpg
**free
ctl-opt main(main);

/copy QCPYILE,ILEASTIC

dcl-proc main;
  dcl-s config pointer;
  dcl-s router pointer;
  
  // Configuration serveur
  config = il_newConfig();
  il_configSetPort(config : 44000);
  il_configSetHost(config : '*ANY');
  
  // Router
  router = il_newRouter(config);
  
  // Routes
  il_addRoute(router : '/api/hello' : IL_GET : %paddr(helloHandler));
  
  // Démarrage serveur
  il_listen(router);
end-proc;

dcl-proc helloHandler export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-s message varchar(100);
  
  message = '{"message":"Hello from IBM i!"}';
  
  il_addHttpHeader(response : 'Content-Type' : 'application/json');
  il_responseWrite(response : %addr(message) : %len(%trimr(message)));
  
  return *ON;
end-proc;
```

### **📡 Gestion CORS**

#### **Headers CORS Standards**
```rpg
dcl-proc setCorsHeaders export;
  dcl-pi *n;
    response pointer const;
  end-pi;
  
  il_addHttpHeader(response : 'Access-Control-Allow-Origin' : '*');
  il_addHttpHeader(response : 'Access-Control-Allow-Methods' : 
    'GET, POST, PUT, DELETE, OPTIONS');
  il_addHttpHeader(response : 'Access-Control-Allow-Headers' : 
    'Content-Type, Authorization, X-Requested-With');
  il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 
    'X-Total-Count, X-Page-Count');
end-proc;

// Handler OPTIONS global
dcl-proc corsPreflightHandler export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  setCorsHeaders(response);
  il_responseWrite(response : %addr('') : 0);
  
  return *ON;
end-proc;
```

---

## 🗃️ Base de Données DB2 for i

### **🔍 Techniques Optimisation**

#### **Index Strategy**
```sql
-- Index pour APIs REST
CREATE INDEX EMPLOYEE_API_IDX1 
ON EMPLOYEES (ACTIVE, DEPARTMENT_ID, CREATED_DATE);

-- Index pour recherche texte
CREATE INDEX EMPLOYEE_SEARCH_IDX 
ON EMPLOYEES (UPPER(LAST_NAME), UPPER(FIRST_NAME));

-- Statistiques à jour
RUNSTATS FOR TABLE MYLIB/EMPLOYEES;
```

#### **SQL Performance**
```rpg
// Requête optimisée avec LIMIT/OFFSET
exec sql 
  SELECT e.id, e.name, d.department_name
  FROM employees e
  LEFT JOIN departments d ON e.dept_id = d.id
  WHERE e.active = 'Y'
  ORDER BY e.name
  LIMIT :pageSize OFFSET :offsetValue;

// Éviter SELECT *
exec sql
  SELECT id, name, email  -- Colonnes spécifiques
  FROM employees
  WHERE status = :statusFilter;
```

### **📊 Gestion Transactions**

#### **Transaction Patterns**
```rpg
// Transaction explicite
exec sql SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
exec sql COMMIT HOLD;

monitor;
  // Opérations multiples
  exec sql INSERT INTO orders VALUES(...);
  exec sql UPDATE inventory SET quantity = quantity - :qty WHERE id = :itemId;
  exec sql INSERT INTO order_items VALUES(...);
  
  exec sql COMMIT;
  
on-error;
  exec sql ROLLBACK;
  return *OFF;
endmon;
```

#### **Locking Strategy**
```sql
-- Lock optimiste avec timestamp
SELECT id, name, updated_at 
FROM employees 
WHERE id = ?
FOR UPDATE SKIP LOCKED;

-- Update avec version check
UPDATE employees 
SET name = ?, updated_at = CURRENT_TIMESTAMP
WHERE id = ? AND updated_at = ?;
```

---

## 🔧 Outils Build & Déploiement

### **📦 BOB Build System**

#### **Configuration bob.json**
```json
{
  "version": "0.1.0",
  "build": [
    {
      "name": "employee-api",
      "type": "rpgle",
      "source": "src/employee/employee.main.rpgle",
      "output": "EMPLOYEE",
      "library": "ARCHIAPI"
    }
  ],
  "dependencies": [
    {
      "name": "ileastic",
      "library": "ILEASTIC"
    }
  ]
}
```

#### **Scripts Build**
```bash
# Build local
bob --build employee-api

# Build avec tests
bob --build --test

# Deploy vers IBM i
bob --deploy --target=DEV
```

### **🚀 Automation Deployment**

#### **Script Deployment**
```bash
#!/bin/bash
# deploy-to-ibmi.sh

IBM_HOST="your-ibmi-server.com"
IBM_USER="DEVELOPER"
TARGET_LIB="ARCHIAPI"

# Upload sources
scp -r src/ ${IBM_USER}@${IBM_HOST}:/tmp/archiapi/

# Remote compilation
ssh ${IBM_USER}@${IBM_HOST} << EOF
cd /tmp/archiapi
bob --build --library=${TARGET_LIB}
EOF

echo "Deployment completed"
```

---

## 🔍 Debug & Monitoring

### **🐛 Debug Techniques**

#### **Debug Interactif**
```rpg
// Points d'arrêt dans code
if ENVIRONMENT = 'DEV';
  // Debug break point
  monitor;
    // Code à débugger
  on-error;
    // Log erreur détaillée
    logDetailedError(%proc : %line : %str(%error));
  endmon;
endif;
```

#### **Logging Avancé**
```rpg
// Logger personnalisé
dcl-proc logToIFS export;
  dcl-pi *n;
    level varchar(10) const;    // DEBUG, INFO, ERROR
    module varchar(50) const;
    message varchar(500) const;
  end-pi;
  
  dcl-s timestamp char(26);
  dcl-s logEntry varchar(1000);
  dcl-s fd int(10);
  
  timestamp = %char(%timestamp());
  logEntry = timestamp + ' [' + level + '] ' + module + ': ' + message + x'0A';
  
  fd = open('/tmp/logs/archiapi.log' : O_WRONLY + O_CREAT + O_APPEND : 
    S_IRUSR + S_IWUSR);
  
  if fd >= 0;
    write(fd : %addr(logEntry) : %len(%trimr(logEntry)));
    close(fd);
  endif;
  
end-proc;
```

### **📊 Performance Monitoring**

#### **Métriques Job**
```rpg
// Monitoring ressources job
dcl-proc getJobMetrics export;
  dcl-pi *n;
    cpuUsed packed(15:5);
    memoryUsed int(20);
  end-pi;
  
  dcl-ds jobInfo qualified template;
    bytesProvided int(10);
    bytesAvailable int(10);
    jobName char(28);
    cpuUsed packed(15:5);
    // ... autres champs
  end-ds;
  
  dcl-ds jobData likeDS(jobInfo);
  
  // API QUSRJOBI
  QUSRJOBI(jobData : %size(jobData) : 'JOBI0400' : '*' : '');
  
  cpuUsed = jobData.cpuUsed;
  // memoryUsed = jobData.memoryUsed;
  
end-proc;
```

---

## 🔒 Sécurité IBM i

### **👤 Authentification**

#### **User Profile Integration**
```rpg
// Validation utilisateur IBM i
dcl-proc validateUser export;
  dcl-pi *n ind;
    username varchar(10) const;
    password varchar(128) const;
  end-pi;
  
  dcl-pr QSYGETPH export;
    userId char(10) const;
    password char(10) const;
    profileHandle char(12);
    errorDs char(256) options(*varsize);
  end-pr;
  
  dcl-s profileHandle char(12);
  dcl-s errorDs char(256);
  
  monitor;
    QSYGETPH(username : password : profileHandle : errorDs);
    return *ON;
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

#### **Authorization Lists**
```rpg
// Vérification autorisation
dcl-proc checkAuthority export;
  dcl-pi *n ind;
    userId varchar(10) const;
    resource varchar(100) const;
    operation varchar(10) const;  // READ, WRITE, DELETE
  end-pi;
  
  // Utiliser QSYSCHK API pour vérifier autorisations
  // Implementation spécifique selon besoins
  
  return *ON; // Temporaire
end-proc;
```

### **🛡️ Audit & Compliance**

#### **Audit Trail**
```rpg
// Log audit des actions
dcl-proc auditLog export;
  dcl-pi *n;
    userId varchar(10) const;
    action varchar(50) const;
    resource varchar(100) const;
    details varchar(500) const;
  end-pi;
  
  dcl-s auditEntry varchar(1000);
  dcl-s timestamp char(26);
  
  timestamp = %char(%timestamp());
  
  auditEntry = %trimr(timestamp) + '|' +
               %trimr(userId) + '|' +
               %trimr(action) + '|' +
               %trimr(resource) + '|' +
               %trimr(details);
  
  // Écrire vers journal audit
  writeToAuditJournal(auditEntry);
  
end-proc;
```

---

## 📈 Optimisations Avancées

### **⚡ Performance Tuning**

#### **Memory Pool Optimization**
```bash
# Configuration pools mémoire
CHGSHRPOOL POOL(2) SIZE(2048000)  # Base pool
CHGSHRPOOL POOL(3) SIZE(512000)   # Interactive pool
CHGSHRPOOL POOL(4) SIZE(1024000)  # Batch pool
```

#### **Connection Pooling**
```rpg
// Pool connexions DB
dcl-ds connectionPool_t template qualified;
  connections pointer dim(100);
  available ind dim(100);
  maxConnections int(10) inz(100);
  currentCount int(10) inz(0);
end-ds;

dcl-s connectionPool likeDS(connectionPool_t);

dcl-proc getConnection export;
  dcl-pi *n pointer end-pi;
  
  dcl-s i int(10);
  
  // Chercher connexion disponible
  for i = 1 to connectionPool.maxConnections;
    if connectionPool.available(i) = *ON;
      connectionPool.available(i) = *OFF;
      return connectionPool.connections(i);
    endif;
  endfor;
  
  // Créer nouvelle si possible
  if connectionPool.currentCount < connectionPool.maxConnections;
    return createNewConnection();
  endif;
  
  return *null; // Pool plein
end-proc;
```

### **🔄 Caching Strategies**

#### **Application Cache**
```rpg
// Cache simple en mémoire
dcl-ds cacheEntry_t template qualified;
  key varchar(100);
  value varchar(4000);
  timestamp timestamp;
  ttl int(10); // secondes
end-ds;

dcl-s cache likeDS(cacheEntry_t) dim(1000);
dcl-s cacheCount int(10) inz(0);

dcl-proc cacheGet export;
  dcl-pi *n varchar(4000);
    key varchar(100) const;
  end-pi;
  
  dcl-s i int(10);
  dcl-s now timestamp;
  
  now = %timestamp();
  
  for i = 1 to cacheCount;
    if cache(i).key = key;
      // Vérifier expiration
      if %diff(now : cache(i).timestamp : *seconds) <= cache(i).ttl;
        return cache(i).value;
      endif;
    endif;
  endfor;
  
  return ''; // Not found ou expired
end-proc;
```

---

## 🎯 Best Practices IBM i

### **💡 Conventions Plateforme**

#### **Nommage Objets**
```
Libraries: 8 caractères max, MAJUSCULES
Programs: 10 caractères max, descriptif
Files: 10 caractères max, suffixe type (PF, LF)
Fields: 30 caractères max, camelCase
```

#### **Organisation Source**
```
QRPGLESRC     # Sources RPG ILE
QRPGLEINC     # Includes/Prototypes  
QSQLRPGLE     # RPG avec SQL intégré
QCLSRC        # Commandes CL
QDDSSRC       # Définitions base
```

### **🚨 Erreurs Communes**

#### **Performance Pitfalls**
```rpg
// ❌ ÉVITER
exec sql SELECT * FROM huge_table;  // Scan complet

// ✅ RECOMMANDÉ  
exec sql SELECT id, name FROM huge_table WHERE index_field = :value;

// ❌ ÉVITER
for i = 1 to 10000;
  exec sql INSERT INTO table VALUES(:data(i));
endfor;

// ✅ RECOMMANDÉ
exec sql INSERT INTO table SELECT * FROM session.temp_data;
```

#### **Memory Leaks**
```rpg
// ❌ ÉVITER
dcl-s ptr pointer;
ptr = %alloc(1000);
// Oubli dealloc

// ✅ RECOMMANDÉ
dcl-s ptr pointer;
ptr = %alloc(1000);
monitor;
  // Utilisation
on-error;
  // Cleanup
endmon;
if ptr <> *null;
  dealloc ptr;
endif;
```

---

## 📚 Ressources IBM i

### **🔗 Documentation Officielle**
- [IBM i Knowledge Center](https://www.ibm.com/docs/en/i)
- [RPG ILE Reference](https://www.ibm.com/docs/en/i/7.5?topic=languages-ile-rpg)
- [SQL Reference](https://www.ibm.com/docs/en/i/7.5?topic=reference-sql)

### **🌟 Communautés**
- [IBM i OSS Community](https://ibmi-oss.org/)
- [RPG-Evolution](https://www.rpg-evolution.com/)
- [Code for IBM i](https://github.com/codefori)

### **🛠️ Outils Recommandés**
- **RDi** (Rational Developer for i)
- **ACS** (Access Client Solutions)
- **Navigator for i** (Web interface)

---

*Guide spécialisé IBM i - Équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*