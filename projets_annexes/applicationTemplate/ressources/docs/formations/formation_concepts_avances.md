# 🚀 Formation Concepts Avancés - IBM i Moderne

*Formation spécialisée sur les concepts avancés pour le développement moderne sur IBM i*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Objectifs de Formation

### **🏆 Compétences Avancées**
- Maîtriser IFS (Integrated File System)
- SQL avancé et optimisation
- Manipulation JSON complexe
- Programmation système et APIs
- Intégration technologies modernes

### **👥 Public Expert**
- Développeurs IBM i expérimentés
- Architectes techniques
- Lead developers modernisant legacy
- Équipes DevOps IBM i

---

## 📁 Module 1 : IFS (Integrated File System) Avancé

### **🗂️ Architecture IFS**

#### **Structure Système**
```
/QSYS.LIB/                    # Système traditionnel (libraries)
├── MYLIB.LIB/
│   ├── MYFILE.FILE/
│   └── MYPGM.PGM
/QOpenSys/                    # Open Source ecosystem
├── pkgs/                     # Packages yum/RPM
├── usr/                      # Unix-style directories
└── QIBM/                     # IBM tools
/home/                        # User directories
├── USER1/
└── DEVELOPER/
/tmp/                         # Temporary files
/www/                         # Web content
└── archiapi/
    ├── htdocs/
    ├── logs/
    └── conf/
```

#### **Concepts Fondamentaux**
```rpg
// Types de fichiers IFS
dcl-c FILE_TYPE_REGULAR const(1);
dcl-c FILE_TYPE_DIRECTORY const(2);
dcl-c FILE_TYPE_LINK const(3);

// Permissions Unix-style
dcl-c S_IRUSR const(256);    // Owner read
dcl-c S_IWUSR const(128);    // Owner write  
dcl-c S_IXUSR const(64);     // Owner execute
dcl-c S_IRGRP const(32);     // Group read
dcl-c S_IWGRP const(16);     // Group write
dcl-c S_IXGRP const(8);      // Group execute
dcl-c S_IROTH const(4);      // Other read
dcl-c S_IWOTH const(2);      // Other write
dcl-c S_IXOTH const(1);      // Other execute
```

### **📂 Manipulation Fichiers IFS**

#### **Lecture/Écriture Basique**
```rpg
dcl-proc writeTextFile export;
  dcl-pi *n ind;
    filePath varchar(256) const;
    content varchar(32000) const;
  end-pi;
  
  dcl-s fd int(10);
  dcl-s bytesWritten int(10);
  
  monitor;
    // Ouvrir fichier (créer si n'existe pas)
    fd = open(%trimr(filePath) : 
              O_WRONLY + O_CREAT + O_TRUNC :
              S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH);
    
    if fd < 0;
      return *OFF;
    endif;
    
    // Écrire contenu
    bytesWritten = write(fd : %addr(content) : %len(%trimr(content)));
    
    // Fermer fichier
    close(fd);
    
    return (bytesWritten > 0);
    
  on-error;
    if fd >= 0;
      close(fd);
    endif;
    return *OFF;
  endmon;
  
end-proc;

dcl-proc readTextFile export;
  dcl-pi *n varchar(32000);
    filePath varchar(256) const;
  end-pi;
  
  dcl-s fd int(10);
  dcl-s buffer char(32000);
  dcl-s bytesRead int(10);
  dcl-s content varchar(32000) inz('');
  
  monitor;
    fd = open(%trimr(filePath) : O_RDONLY);
    
    if fd < 0;
      return '';
    endif;
    
    // Lire par chunks
    dow;
      bytesRead = read(fd : %addr(buffer) : %size(buffer));
      
      if bytesRead <= 0;
        leave;
      endif;
      
      content += %subst(buffer : 1 : bytesRead);
    enddo;
    
    close(fd);
    return content;
    
  on-error;
    if fd >= 0;
      close(fd);
    endif;
    return '';
  endmon;
  
end-proc;
```

#### **Manipulation Répertoires**
```rpg
dcl-proc createDirectory export;
  dcl-pi *n ind;
    dirPath varchar(256) const;
    recursive ind const;
  end-pi;
  
  dcl-s result int(10);
  dcl-s parentPath varchar(256);
  dcl-s pos int(10);
  
  monitor;
    // Créer répertoire simple
    result = mkdir(%trimr(dirPath) : S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH);
    
    if result = 0;
      return *ON; // Succès
    endif;
    
    // Si récursif et erreur = répertoire parent n'existe pas
    if recursive and errno() = ENOENT;
      // Extraire répertoire parent
      pos = %scanr('/' : %trimr(dirPath));
      if pos > 1;
        parentPath = %subst(dirPath : 1 : pos - 1);
        
        // Créer parent récursivement
        if createDirectory(parentPath : *ON);
          // Réessayer création
          result = mkdir(%trimr(dirPath) : S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH);
          return (result = 0);
        endif;
      endif;
    endif;
    
    return *OFF;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;

dcl-proc listDirectory export;
  dcl-pi *n int(10);
    dirPath varchar(256) const;
    entries likeDS(dirEntry_t) dim(500);
  end-pi;
  
  dcl-ds dirEntry_t template qualified;
    name varchar(256);
    type int(10);        // 1=file, 2=dir
    size int(20);
    modified timestamp;
  end-ds;
  
  dcl-s dirPtr pointer;
  dcl-s entryPtr pointer;
  dcl-s count int(10) inz(0);
  
  monitor;
    dirPtr = opendir(%trimr(dirPath));
    
    if dirPtr = *null;
      return 0;
    endif;
    
    // Lire entrées
    dow count < %elem(entries);
      entryPtr = readdir(dirPtr);
      
      if entryPtr = *null;
        leave;
      endif;
      
      count += 1;
      // Extraire informations depuis structure dirent
      extractDirEntryInfo(entryPtr : entries(count));
    enddo;
    
    closedir(dirPtr);
    return count;
    
  on-error;
    if dirPtr <> *null;
      closedir(dirPtr);
    endif;
    return 0;
  endmon;
  
end-proc;
```

### **📋 Surveillance et Monitoring IFS**

#### **Surveillance Changements Fichiers**
```rpg
// Surveillance basique avec timestamps
dcl-proc monitorFileChanges export;
  dcl-pi *n ind;
    filePath varchar(256) const;
    lastModified timestamp;
    hasChanged ind;
  end-pi;
  
  dcl-ds fileStats qualified;
    st_mode int(10);
    st_size int(20);
    st_mtime int(10);
    // ... autres champs stat()
  end-ds;
  
  dcl-s currentModified timestamp;
  dcl-s result int(10);
  
  monitor;
    result = stat(%trimr(filePath) : %addr(fileStats));
    
    if result <> 0;
      hasChanged = *OFF;
      return *OFF; // Fichier n'existe pas
    endif;
    
    // Convertir timestamp Unix vers timestamp RPG
    currentModified = unixTimeToTimestamp(fileStats.st_mtime);
    
    hasChanged = (currentModified > lastModified);
    
    if hasChanged;
      lastModified = currentModified;
    endif;
    
    return *ON;
    
  on-error;
    hasChanged = *OFF;
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🗄️ Module 2 : SQL Avancé et Optimisation

### **⚡ Techniques Optimisation Avancées**

#### **Index Strategies**
```sql
-- Index composé optimisé pour filtres multiples
CREATE INDEX employees_search_idx 
ON employees (department_id, active, salary DESC, last_name);

-- Index partiel pour données actives
CREATE INDEX employees_active_idx 
ON employees (last_name, first_name) 
WHERE active = 'Y';

-- Index expression pour recherche insensible à la casse
CREATE INDEX employees_name_upper_idx 
ON employees (UPPER(last_name), UPPER(first_name));

-- Statistiques à jour pour optimiseur
RUNSTATS FOR TABLE mylib/employees;
RUNSTATS FOR INDEX mylib/employees_search_idx;
```

#### **Requêtes Complexes Optimisées**
```rpg
// Requête avec CTE et window functions
dcl-proc getEmployeeRankings export;
  dcl-pi *n int(10);
    departmentId int(10) const;
    rankings likeDS(employeeRanking_t) dim(100);
  end-pi;
  
  dcl-ds employeeRanking_t template qualified;
    id int(10);
    name varchar(100);
    salary packed(9:2);
    rankInDept int(10);
    salaryPercentile int(10);
    avgDeptSalary packed(9:2);
  end-ds;
  
  dcl-s sql varchar(4000);
  dcl-s count int(10) inz(0);
  
  sql = 'WITH dept_stats AS ( ' +
        '  SELECT department_id, ' +
        '         AVG(salary) as avg_salary, ' +
        '         COUNT(*) as emp_count ' +
        '  FROM employees ' +
        '  WHERE active = ''Y'' ' +
        '  GROUP BY department_id ' +
        '), ' +
        'ranked_employees AS ( ' +
        '  SELECT e.id, ' +
        '         e.first_name || '' '' || e.last_name as name, ' +
        '         e.salary, ' +
        '         ROW_NUMBER() OVER ( ' +
        '           PARTITION BY e.department_id ' +
        '           ORDER BY e.salary DESC ' +
        '         ) as rank_in_dept, ' +
        '         PERCENT_RANK() OVER ( ' +
        '           PARTITION BY e.department_id ' +
        '           ORDER BY e.salary ' +
        '         ) * 100 as salary_percentile, ' +
        '         ds.avg_salary ' +
        '  FROM employees e ' +
        '  JOIN dept_stats ds ON e.department_id = ds.department_id ' +
        '  WHERE e.active = ''Y'' ' +
        '    AND e.department_id = ? ' +
        ') ' +
        'SELECT id, name, salary, rank_in_dept, ' +
        '       salary_percentile, avg_salary ' +
        'FROM ranked_employees ' +
        'ORDER BY rank_in_dept';
  
  exec sql PREPARE ranking_stmt FROM :sql;
  exec sql DECLARE ranking_cursor CURSOR FOR ranking_stmt;
  exec sql OPEN ranking_cursor USING :departmentId;
  
  dow sqlcode = 0 and count < %elem(rankings);
    exec sql FETCH ranking_cursor INTO :rankings(count + 1);
    if sqlcode = 0;
      count += 1;
    endif;
  enddo;
  
  exec sql CLOSE ranking_cursor;
  
  return count;
end-proc;
```

### **🔄 Transactions Avancées**

#### **Isolation Levels et Locking**
```rpg
dcl-proc complexBusinessTransaction export;
  dcl-pi *n ind;
    orderId int(10) const;
    items likeDS(orderItem_t) dim(50) const;
    itemCount int(10) const;
  end-pi;
  
  dcl-ds orderItem_t template qualified;
    productId int(10);
    quantity int(10);
    price packed(9:2);
  end-ds;
  
  dcl-s i int(10);
  dcl-s availableStock int(10);
  dcl-s savepoint varchar(20);
  
  monitor;
    // Démarrer transaction avec isolation SERIALIZABLE
    exec sql SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    exec sql COMMIT HOLD;
    
    // Savepoint pour rollback partiel si nécessaire
    savepoint = 'SP_' + %char(%timestamp());
    exec sql SAVEPOINT :savepoint;
    
    // Vérifier et réserver stock pour chaque item
    for i = 1 to itemCount;
      // Lock optimiste avec retry
      exec sql 
        SELECT stock_quantity
        INTO :availableStock  
        FROM products
        WHERE id = :items(i).productId
        FOR UPDATE SKIP LOCKED;
      
      if sqlcode = 100;
        // Produit non trouvé
        exec sql ROLLBACK TO SAVEPOINT :savepoint;
        return *OFF;
      elseif sqlcode <> 0;
        // Erreur SQL
        exec sql ROLLBACK;
        return *OFF;
      endif;
      
      // Vérifier stock suffisant
      if availableStock < items(i).quantity;
        exec sql ROLLBACK TO SAVEPOINT :savepoint;
        return *OFF;
      endif;
      
      // Réserver stock
      exec sql 
        UPDATE products 
        SET stock_quantity = stock_quantity - :items(i).quantity,
            reserved_quantity = reserved_quantity + :items(i).quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = :items(i).productId;
        
      if sqlcode <> 0;
        exec sql ROLLBACK TO SAVEPOINT :savepoint;
        return *OFF;
      endif;
      
      // Insérer ligne commande
      exec sql
        INSERT INTO order_items 
        (order_id, product_id, quantity, unit_price, total_price)
        VALUES (:orderId, :items(i).productId, :items(i).quantity,
                :items(i).price, :items(i).quantity * :items(i).price);
                
      if sqlcode <> 0;
        exec sql ROLLBACK TO SAVEPOINT :savepoint;
        return *OFF;
      endif;
    endfor;
    
    // Mettre à jour total commande
    exec sql
      UPDATE orders 
      SET total_amount = (
        SELECT SUM(total_price) 
        FROM order_items 
        WHERE order_id = :orderId
      ),
      status = 'CONFIRMED',
      updated_at = CURRENT_TIMESTAMP
      WHERE id = :orderId;
    
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

### **📊 SQL Analytique et Reporting**

#### **Business Intelligence Queries**
```rpg
dcl-proc generateSalesReport export;
  dcl-pi *n int(10);
    startDate date const;
    endDate date const;
    reportData likeDS(salesReport_t) dim(100);
  end-pi;
  
  dcl-ds salesReport_t template qualified;
    period varchar(20);
    totalOrders int(10);
    totalRevenue packed(15:2);
    avgOrderValue packed(9:2);
    topProduct varchar(100);
    topCategory varchar(50);
    growthPercent packed(5:2);
  end-ds;
  
  dcl-s sql varchar(8000);
  dcl-s count int(10) inz(0);
  
  sql = 'WITH daily_sales AS ( ' +
        '  SELECT DATE(o.created_at) as sale_date, ' +
        '         COUNT(DISTINCT o.id) as orders_count, ' +
        '         SUM(o.total_amount) as revenue, ' +
        '         AVG(o.total_amount) as avg_order ' +
        '  FROM orders o ' +
        '  WHERE DATE(o.created_at) BETWEEN ? AND ? ' +
        '    AND o.status = ''COMPLETED'' ' +
        '  GROUP BY DATE(o.created_at) ' +
        '), ' +
        'weekly_aggregates AS ( ' +
        '  SELECT YEAR(sale_date) || ''-W'' || ' +
        '         LPAD(WEEK(sale_date), 2, ''0'') as period, ' +
        '         SUM(orders_count) as total_orders, ' +
        '         SUM(revenue) as total_revenue, ' +
        '         AVG(avg_order) as avg_order_value ' +
        '  FROM daily_sales ' +
        '  GROUP BY YEAR(sale_date), WEEK(sale_date) ' +
        '), ' +
        'product_rankings AS ( ' +
        '  SELECT period, ' +
        '         p.name as product_name, ' +
        '         c.name as category_name, ' +
        '         SUM(oi.quantity) as units_sold, ' +
        '         ROW_NUMBER() OVER ( ' +
        '           PARTITION BY period ' +
        '           ORDER BY SUM(oi.quantity) DESC ' +
        '         ) as product_rank ' +
        '  FROM weekly_aggregates wa ' +
        '  JOIN orders o ON YEAR(o.created_at) || ''-W'' || ' +
        '                   LPAD(WEEK(o.created_at), 2, ''0'') = wa.period ' +
        '  JOIN order_items oi ON o.id = oi.order_id ' +
        '  JOIN products p ON oi.product_id = p.id ' +
        '  JOIN categories c ON p.category_id = c.id ' +
        '  GROUP BY period, p.name, c.name ' +
        ') ' +
        'SELECT wa.period, wa.total_orders, wa.total_revenue, ' +
        '       wa.avg_order_value, pr.product_name, pr.category_name, ' +
        '       COALESCE( ' +
        '         ((wa.total_revenue - prev_wa.total_revenue) / ' +
        '          prev_wa.total_revenue) * 100, 0 ' +
        '       ) as growth_percent ' +
        'FROM weekly_aggregates wa ' +
        'LEFT JOIN weekly_aggregates prev_wa ON ' +
        '  prev_wa.period = ( ' +
        '    SELECT MAX(period) FROM weekly_aggregates ' +
        '    WHERE period < wa.period ' +
        '  ) ' +
        'LEFT JOIN product_rankings pr ON ' +
        '  wa.period = pr.period AND pr.product_rank = 1 ' +
        'ORDER BY wa.period';
  
  exec sql PREPARE report_stmt FROM :sql;
  exec sql DECLARE report_cursor CURSOR FOR report_stmt;
  exec sql OPEN report_cursor USING :startDate, :endDate;
  
  dow sqlcode = 0 and count < %elem(reportData);
    exec sql FETCH report_cursor INTO :reportData(count + 1);
    if sqlcode = 0;
      count += 1;
    endif;
  enddo;
  
  exec sql CLOSE report_cursor;
  
  return count;
end-proc;
```

---

## 📄 Module 3 : JSON Avancé et Transformations

### **🔄 JSON Complexe et Nested Objects**

#### **Parsing JSON Hiérarchique**
```rpg
// Structure complexe avec objets imbriqués
dcl-ds orderComplete_t template qualified;
  id int(10);
  orderNumber varchar(20);
  status varchar(20);
  totalAmount packed(9:2);
  customer qualified;
    id int(10);
    name varchar(100);
    email varchar(200);
    address qualified;
      street varchar(100);
      city varchar(50);
      postalCode varchar(10);
      country varchar(50);
    end-ds;
  end-ds;
  items qualified dim(50);
    productId int(10);
    productName varchar(100);
    quantity int(10);
    unitPrice packed(9:2);
    subtotal packed(9:2);
  end-ds;
  shipping qualified;
    method varchar(50);
    cost packed(9:2);
    estimatedDate date;
    trackingNumber varchar(50);
  end-ds;
  metadata qualified;
    createdAt timestamp;
    updatedAt timestamp;
    source varchar(20);
    notes varchar(500);
  end-ds;
end-ds;

dcl-proc parseComplexOrder export;
  dcl-pi *n ind;
    jsonString varchar(32000) const;
    order likeDS(orderComplete_t);
  end-pi;
  
  monitor;
    // Parser JSON avec support objets imbriqués
    data-into order %data(jsonString : 
      'doc=string case=any allowextra=yes countprefix=item_count');
    
    return *ON;
    
  on-error;
    logError('JSON parsing failed: ' + %str(%error));
    return *OFF;
  endmon;
  
end-proc;
```

#### **Génération JSON Dynamique**
```rpg
dcl-proc buildDynamicJsonResponse export;
  dcl-pi *n varchar(32000);
    baseObject pointer const;
    includeFields varchar(500) const; // comma-separated
    excludeFields varchar(500) const; // comma-separated  
    transformRules varchar(1000) const; // field mappings
  end-pi;
  
  dcl-s jsonResult varchar(32000);
  dcl-s includeArray varchar(50) dim(50);
  dcl-s excludeArray varchar(50) dim(50);
  dcl-s includeCount int(10);
  dcl-s excludeCount int(10);
  dcl-s options varchar(500);
  
  // Parser listes de champs
  includeCount = splitString(includeFields : ',' : includeArray);
  excludeCount = splitString(excludeFields : ',' : excludeArray);
  
  // Construire options data-gen
  options = 'doc=string case=convert trim=all';
  
  if includeCount > 0;
    options += ' include=' + %trimr(includeFields);
  endif;
  
  if excludeCount > 0;
    options += ' exclude=' + %trimr(excludeFields);
  endif;
  
  // Générer JSON avec options
  data-gen jsonResult %data(baseObject : options);
  
  // Appliquer transformations si spécifiées
  if %len(%trimr(transformRules)) > 0;
    jsonResult = applyJsonTransformations(jsonResult : transformRules);
  endif;
  
  return jsonResult;
end-proc;

dcl-proc applyJsonTransformations export;
  dcl-pi *n varchar(32000);
    jsonString varchar(32000) const;
    transformRules varchar(1000) const;
  end-pi;
  
  dcl-s result varchar(32000);
  dcl-s rules varchar(100) dim(20);
  dcl-s ruleCount int(10);
  dcl-s i int(10);
  dcl-s fromField varchar(50);
  dcl-s toField varchar(50);
  
  result = jsonString;
  
  // Parser règles de transformation (format: oldField=newField)
  ruleCount = splitString(transformRules : ',' : rules);
  
  for i = 1 to ruleCount;
    if parseKeyValue(rules(i) : fromField : toField);
      // Remplacer nom de champ dans JSON
      result = %scanrpl('"' + %trimr(fromField) + '":' : 
                       '"' + %trimr(toField) + '":' : result);
    endif;
  endfor;
  
  return result;
end-proc;
```

### **🔍 JSON Schema Validation**

#### **Validation Avancée**
```rpg
dcl-proc validateJsonSchema export;
  dcl-pi *n ind;
    jsonData varchar(32000) const;
    schemaRules varchar(2000) const;
    validationErrors varchar(1000);
  end-pi;
  
  dcl-s errors varchar(1000) inz('');
  dcl-s rules varchar(200) dim(50);
  dcl-s ruleCount int(10);
  dcl-s i int(10);
  dcl-s fieldName varchar(50);
  dcl-s validation varchar(100);
  dcl-s fieldValue varchar(500);
  
  // Parser règles (format: fieldName:type:required:pattern)
  ruleCount = splitString(schemaRules : '|' : rules);
  
  for i = 1 to ruleCount;
    if validateSingleField(jsonData : rules(i) : fieldValue);
      // Champ valide, continuer
    else;
      // Ajouter erreur
      if %len(%trimr(errors)) > 0;
        errors += ', ';
      endif;
      errors += 'Field ' + fieldName + ' validation failed';
    endif;
  endfor;
  
  validationErrors = errors;
  return (%len(%trimr(errors)) = 0);
end-proc;

dcl-proc validateSingleField export;
  dcl-pi *n ind;
    jsonData varchar(32000) const;
    fieldRule varchar(200) const;
    extractedValue varchar(500);
  end-pi;
  
  dcl-s ruleParts varchar(50) dim(4);
  dcl-s partCount int(10);
  dcl-s fieldName varchar(50);
  dcl-s fieldType varchar(20);
  dcl-s isRequired varchar(10);
  dcl-s pattern varchar(100);
  dcl-s value varchar(500);
  
  // Parser règle: fieldName:type:required:pattern
  partCount = splitString(fieldRule : ':' : ruleParts);
  
  if partCount >= 3;
    fieldName = ruleParts(1);
    fieldType = ruleParts(2);
    isRequired = ruleParts(3);
    if partCount >= 4;
      pattern = ruleParts(4);
    endif;
  else;
    return *OFF;
  endif;
  
  // Extraire valeur du JSON
  value = extractJsonField(jsonData : fieldName);
  extractedValue = value;
  
  // Vérifier si requis
  if %upper(%trimr(isRequired)) = 'TRUE' and %len(%trimr(value)) = 0;
    return *OFF; // Champ requis manquant
  endif;
  
  // Si pas de valeur et pas requis, OK
  if %len(%trimr(value)) = 0;
    return *ON;
  endif;
  
  // Validation selon type
  select;
    when %upper(%trimr(fieldType)) = 'NUMBER';
      return isNumeric(value);
      
    when %upper(%trimr(fieldType)) = 'EMAIL';
      return isValidEmail(value);
      
    when %upper(%trimr(fieldType)) = 'DATE';
      return isValidDate(value);
      
    when %upper(%trimr(fieldType)) = 'BOOLEAN';
      return (%upper(%trimr(value)) = 'TRUE' or %upper(%trimr(value)) = 'FALSE');
      
    when %upper(%trimr(fieldType)) = 'STRING';
      if %len(%trimr(pattern)) > 0;
        return matchesPattern(value : pattern);
      endif;
      return *ON;
      
    other;
      return *ON; // Type non reconnu, accepter
  endsl;
  
end-proc;
```

---

## 🔧 Module 4 : APIs Système et Intégration

### **📡 Appels API Système IBM i**

#### **Gestion Jobs et Processus**
```rpg
// API QUSRJOBI - Information job
dcl-pr QUSRJOBI export;
  receiverVariable char(32767) options(*varsize);
  receiverLength int(10) const;
  format char(8) const;
  qualifiedJobName char(26) const;
  internalJobId char(16) const;
  errorCode char(32767) options(*varsize : *nopass);
end-pr;

dcl-proc getJobInformation export;
  dcl-pi *n ind;
    jobInfo ds qualified;
      jobName char(10);
      userName char(10);
      jobNumber char(6);
      status char(10);
      type char(1);
      subtype char(1);
      cpuTimeUsed int(10);
      totalResponseTime int(10);
      memoryPool int(10);
      priority int(10);
    end-ds;
  end-pi;
  
  dcl-ds jobInfo0200 qualified template;
    bytesReturned int(10);
    bytesAvailable int(10);
    jobName char(10);
    userName char(10);
    jobNumber char(6);
    internalJobId char(16);
    status char(10);
    type char(1);
    subtype char(1);
    runPriority int(10);
    timeSlice int(10);
    defaultWait int(10);
    purgeTime int(10);
    cpuTimeUsed int(10);
    systemPoolId int(10);
    processingUnit int(10);
    priority int(10);
    // ... autres champs
  end-ds;
  
  dcl-ds jobData likeDS(jobInfo0200);
  dcl-ds errorDs qualified;
    bytesProvided int(10) inz(%size(errorDs));
    bytesAvailable int(10);
    exceptionId char(7);
    reserved char(1);
    // ... champs erreur
  end-ds;
  
  monitor;
    QUSRJOBI(jobData : %size(jobData) : 'JOBI0200' : '*' : '' : errorDs);
    
    if errorDs.bytesAvailable > 0;
      return *OFF;
    endif;
    
    // Copier données pertinentes
    jobInfo.jobName = jobData.jobName;
    jobInfo.userName = jobData.userName;
    jobInfo.jobNumber = jobData.jobNumber;
    jobInfo.status = jobData.status;
    jobInfo.type = jobData.type;
    jobInfo.subtype = jobData.subtype;
    jobInfo.cpuTimeUsed = jobData.cpuTimeUsed;
    jobInfo.priority = jobData.priority;
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

#### **Gestion Messages et Journalisation**
```rpg
// API QMHSNDPM - Envoyer message programme
dcl-pr QMHSNDPM export;
  messageId char(7) const;
  qualifiedMessageFile char(20) const;
  messageData char(32767) options(*varsize : *nopass) const;
  messageDataLength int(10) const;
  messageType char(10) const;
  callStackEntry char(10) const;
  callStackCounter int(10) const;
  messageKey char(4);
  errorCode char(32767) options(*varsize);
end-pr;

dcl-proc sendProgramMessage export;
  dcl-pi *n ind;
    messageText varchar(500) const;
    messageType varchar(10) const; // *INFO, *COMP, *DIAG, *ESCAPE
    targetProgram varchar(10) const;
  end-pi;
  
  dcl-s messageKey char(4);
  dcl-ds errorDs qualified;
    bytesProvided int(10) inz(%size(errorDs));
    bytesAvailable int(10);
    exceptionId char(7);
    reserved char(1);
  end-ds;
  
  monitor;
    QMHSNDPM('CPF9898' : 'QCPFMSG   *LIBL' : 
             %trimr(messageText) : %len(%trimr(messageText)) :
             %trimr(messageType) : %trimr(targetProgram) : 0 :
             messageKey : errorDs);
    
    return (errorDs.bytesAvailable = 0);
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

### **🔄 Intégration Services Externes**

#### **Client HTTP Avancé**
```rpg
dcl-proc callRestService export;
  dcl-pi *n ind;
    method varchar(10) const;
    url varchar(500) const;
    headers varchar(2000) const;
    requestBody varchar(32000) const;
    responseBody varchar(32000);
    statusCode int(10);
  end-pi;
  
  dcl-s curlCommand varchar(4000);
  dcl-s tempFile varchar(100);
  dcl-s headerFile varchar(100);
  dcl-s result int(10);
  
  monitor;
    // Générer noms fichiers temporaires
    tempFile = '/tmp/curl_response_' + %char(%timestamp() : *HMS0) + '.tmp';
    headerFile = '/tmp/curl_headers_' + %char(%timestamp() : *HMS0) + '.tmp';
    
    // Construire commande curl
    curlCommand = 'curl -s -w "%{http_code}" ';
    
    // Méthode HTTP
    if %upper(%trimr(method)) <> 'GET';
      curlCommand += '-X ' + %upper(%trimr(method)) + ' ';
    endif;
    
    // Headers
    if %len(%trimr(headers)) > 0;
      curlCommand += parseHeadersForCurl(headers);
    endif;
    
    // Body pour POST/PUT
    if %len(%trimr(requestBody)) > 0;
      curlCommand += '-d ''' + %trimr(requestBody) + ''' ';
    endif;
    
    // URL et redirection sortie
    curlCommand += '"' + %trimr(url) + '" ';
    curlCommand += '-o ' + tempFile + ' ';
    curlCommand += '-D ' + headerFile;
    
    // Exécuter curl
    result = system(%trimr(curlCommand));
    
    if result = 0;
      // Lire réponse
      responseBody = readTextFile(tempFile);
      
      // Extraire status code depuis headers
      statusCode = extractStatusCode(headerFile);
      
      // Nettoyer fichiers temporaires
      unlink(%trimr(tempFile));
      unlink(%trimr(headerFile));
      
      return *ON;
    else;
      return *OFF;
    endif;
    
  on-error;
    // Nettoyer fichiers en cas d'erreur
    unlink(%trimr(tempFile));
    unlink(%trimr(headerFile));
    return *OFF;
  endmon;
  
end-proc;

dcl-proc parseHeadersForCurl export;
  dcl-pi *n varchar(1000);
    headers varchar(2000) const;
  end-pi;
  
  dcl-s result varchar(1000) inz('');
  dcl-s headerArray varchar(200) dim(20);
  dcl-s headerCount int(10);
  dcl-s i int(10);
  
  headerCount = splitString(headers : '|' : headerArray);
  
  for i = 1 to headerCount;
    if %len(%trimr(headerArray(i))) > 0;
      result += '-H "' + %trimr(headerArray(i)) + '" ';
    endif;
  endfor;
  
  return result;
end-proc;
```

### **⚙️ Intégration Message Queues**

#### **Interface MQ/JMS Basique**
```rpg
dcl-proc sendToMessageQueue export;
  dcl-pi *n ind;
    queueName varchar(50) const;
    message varchar(32000) const;
    priority int(10) const;
    correlationId varchar(50) const;
  end-pi;
  
  dcl-s queueHandle int(10);
  dcl-s messageId varchar(50);
  
  monitor;
    // Ouvrir queue (simulation - adapter selon MQ utilisé)
    queueHandle = openQueue(%trimr(queueName) : 'WRITE');
    
    if queueHandle <= 0;
      return *OFF;
    endif;
    
    // Envoyer message
    if sendMessage(queueHandle : message : priority : correlationId : messageId);
      closeQueue(queueHandle);
      return *ON;
    else;
      closeQueue(queueHandle);
      return *OFF;
    endif;
    
  on-error;
    if queueHandle > 0;
      closeQueue(queueHandle);
    endif;
    return *OFF;
  endmon;
  
end-proc;

dcl-proc receiveFromMessageQueue export;
  dcl-pi *n ind;
    queueName varchar(50) const;
    message varchar(32000);
    timeoutSeconds int(10) const;
    messageId varchar(50);
  end-pi;
  
  dcl-s queueHandle int(10);
  dcl-s startTime timestamp;
  dcl-s currentTime timestamp;
  dcl-s elapsedSeconds int(10);
  
  monitor;
    queueHandle = openQueue(%trimr(queueName) : 'READ');
    
    if queueHandle <= 0;
      return *OFF;
    endif;
    
    startTime = %timestamp();
    
    // Polling avec timeout
    dow;
      if receiveMessage(queueHandle : message : messageId);
        closeQueue(queueHandle);
        return *ON;
      endif;
      
      // Vérifier timeout
      currentTime = %timestamp();
      elapsedSeconds = %diff(currentTime : startTime : *seconds);
      
      if elapsedSeconds >= timeoutSeconds;
        leave; // Timeout
      endif;
      
      // Attendre avant retry
      sleep(1);
    enddo;
    
    closeQueue(queueHandle);
    return *OFF; // Timeout
    
  on-error;
    if queueHandle > 0;
      closeQueue(queueHandle);
    endif;
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🚀 Module 5 : Programmation Asynchrone et Parallélisme

### **⚡ Threading et Concurrence**

#### **Workers Background**
```rpg
dcl-proc startBackgroundWorker export;
  dcl-pi *n int(10);
    workerFunction pointer const;
    parameters pointer const;
    maxRetries int(10) const;
  end-pi;
  
  dcl-s workerId int(10);
  dcl-s command varchar(500);
  dcl-s workerLibrary varchar(10) inz('WORKERS');
  
  monitor;
    // Générer ID unique worker
    workerId = generateWorkerId();
    
    // Créer job background
    command = 'SBMJOB JOB(WORKER' + %char(workerId) + ') ' +
             'JOBQ(QBATCH) ' +
             'CMD(CALL PGM(' + workerLibrary + '/WORKER) ' +
             'PARM(''' + %char(workerId) + '''))';
    
    system(%trimr(command));
    
    // Enregistrer worker dans table de suivi
    registerWorker(workerId : workerFunction : parameters : maxRetries);
    
    return workerId;
    
  on-error;
    return -1;
  endmon;
  
end-proc;

dcl-proc monitorWorkers export;
  dcl-pi *n ind end-pi;
  
  dcl-s workers likeDS(workerStatus_t) dim(100);
  dcl-s workerCount int(10);
  dcl-s i int(10);
  dcl-s currentStatus varchar(20);
  
  dcl-ds workerStatus_t template qualified;
    id int(10);
    status varchar(20);
    startTime timestamp;
    lastHeartbeat timestamp;
    retryCount int(10);
    maxRetries int(10);
  end-ds;
  
  monitor;
    // Récupérer liste workers actifs
    workerCount = getActiveWorkers(workers);
    
    for i = 1 to workerCount;
      currentStatus = checkWorkerStatus(workers(i).id);
      
      select;
        when currentStatus = 'COMPLETED';
          // Worker terminé avec succès
          cleanupWorker(workers(i).id);
          
        when currentStatus = 'FAILED';
          // Worker échoué
          if workers(i).retryCount < workers(i).maxRetries;
            // Retry
            retryWorker(workers(i).id);
          else;
            // Abandon après max retries
            markWorkerFailed(workers(i).id);
          endif;
          
        when currentStatus = 'RUNNING';
          // Vérifier heartbeat
          if %diff(%timestamp() : workers(i).lastHeartbeat : *minutes) > 5;
            // Worker semble bloqué
            killWorker(workers(i).id);
            if workers(i).retryCount < workers(i).maxRetries;
              retryWorker(workers(i).id);
            endif;
          endif;
          
        other;
          // Statut inconnu, investiguer
          logWarning('WORKER' : 'Unknown worker status: ' + currentStatus);
      endsl;
    endfor;
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

### **📡 Event-Driven Architecture**

#### **Système d'Événements**
```rpg
dcl-ds event_t template qualified;
  id varchar(50);
  type varchar(50);
  source varchar(100);
  data varchar(8000);
  timestamp timestamp;
  correlationId varchar(50);
  retryCount int(10);
end-ds;

dcl-proc publishEvent export;
  dcl-pi *n ind;
    eventType varchar(50) const;
    eventSource varchar(100) const;
    eventData varchar(8000) const;
    correlationId varchar(50) const;
  end-pi;
  
  dcl-ds event likeDS(event_t);
  dcl-s eventId varchar(50);
  
  monitor;
    // Générer ID unique
    eventId = generateEventId();
    
    // Construire événement
    event.id = eventId;
    event.type = eventType;
    event.source = eventSource;
    event.data = eventData;
    event.timestamp = %timestamp();
    event.correlationId = correlationId;
    event.retryCount = 0;
    
    // Persister événement
    if not storeEvent(event);
      return *OFF;
    endif;
    
    // Publier vers subscribers
    if not notifySubscribers(event);
      return *OFF;
    endif;
    
    // Log événement
    logInfo('EVENT' : 'publishEvent' : 
      'Published event ' + eventType + ' from ' + eventSource);
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;

dcl-proc subscribeToEvents export;
  dcl-pi *n ind;
    eventType varchar(50) const;
    handlerFunction pointer const;
    filterCriteria varchar(500) const;
  end-pi;
  
  dcl-ds subscription qualified;
    id varchar(50);
    eventType varchar(50);
    handler pointer;
    filter varchar(500);
    isActive ind;
    createdAt timestamp;
  end-ds;
  
  monitor;
    subscription.id = generateSubscriptionId();
    subscription.eventType = eventType;
    subscription.handler = handlerFunction;
    subscription.filter = filterCriteria;
    subscription.isActive = *ON;
    subscription.createdAt = %timestamp();
    
    // Enregistrer subscription
    return registerSubscription(subscription);
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;

dcl-proc processEvents export;
  dcl-pi *n ind end-pi;
  
  dcl-s pendingEvents likeDS(event_t) dim(100);
  dcl-s eventCount int(10);
  dcl-s i int(10);
  dcl-s processed ind;
  
  monitor;
    // Récupérer événements en attente
    eventCount = getPendingEvents(pendingEvents);
    
    for i = 1 to eventCount;
      processed = processEvent(pendingEvents(i));
      
      if processed;
        markEventProcessed(pendingEvents(i).id);
      else;
        // Increment retry count
        incrementEventRetry(pendingEvents(i).id);
        
        // Check max retries
        if pendingEvents(i).retryCount >= 3;
          markEventFailed(pendingEvents(i).id);
        endif;
      endif;
    endfor;
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

---

## 🎯 Projet Final : Plateforme E-Commerce Avancée

### **📋 Architecture Complète**

#### **Microservices sur IBM i**
```
ArchiAPI Advanced Platform
├── Product Service
│   ├── CRUD Operations
│   ├── Inventory Management  
│   ├── Price Engine
│   └── Search & Recommendations
├── Order Service
│   ├── Order Processing
│   ├── Payment Integration
│   ├── Shipping Coordination
│   └── Status Tracking
├── Customer Service
│   ├── Profile Management
│   ├── Authentication
│   ├── Preferences
│   └── Loyalty Program
├── Analytics Service
│   ├── Real-time Metrics
│   ├── Business Intelligence
│   ├── Performance Monitoring
│   └── Predictive Analytics
└── Integration Layer
    ├── External APIs
    ├── Message Queues
    ├── Event Streaming
    └── Data Synchronization
```

### **🎯 Fonctionnalités Avancées à Implémenter**

#### **1. Système de Cache Multi-Niveau**
```rpg
// Cache L1: Mémoire application
// Cache L2: Redis/Memcached
// Cache L3: Base de données
dcl-proc getWithCache export;
  dcl-pi *n varchar(8000);
    cacheKey varchar(100) const;
    dataSource pointer const;
    ttlSeconds int(10) const;
  end-pi;
  
  dcl-s data varchar(8000);
  
  // L1: Cache mémoire
  data = memoryCache_get(cacheKey);
  if %len(%trimr(data)) > 0;
    return data;
  endif;
  
  // L2: Cache externe (Redis simulation)
  data = externalCache_get(cacheKey);
  if %len(%trimr(data)) > 0;
    memoryCache_set(cacheKey : data : ttlSeconds);
    return data;
  endif;
  
  // L3: Source de données
  data = callDataSource(dataSource);
  if %len(%trimr(data)) > 0;
    memoryCache_set(cacheKey : data : ttlSeconds);
    externalCache_set(cacheKey : data : ttlSeconds * 2);
  endif;
  
  return data;
end-proc;
```

#### **2. Event Sourcing et CQRS**
```rpg
// Command side - Write operations
dcl-proc processOrderCommand export;
  dcl-pi *n ind;
    command likeDS(orderCommand_t) const;
  end-pi;
  
  dcl-s events likeDS(event_t) dim(10);
  dcl-s eventCount int(10);
  
  monitor;
    // Valider commande
    if not validateOrderCommand(command);
      return *OFF;
    endif;
    
    // Générer événements
    eventCount = generateOrderEvents(command : events);
    
    // Persister événements (Event Store)
    if not persistEvents(events : eventCount);
      return *OFF;
    endif;
    
    // Publier événements
    publishEvents(events : eventCount);
    
    return *ON;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;

// Query side - Read operations
dcl-proc getOrderProjection export;
  dcl-pi *n ind;
    orderId int(10) const;
    projection likeDS(orderProjection_t);
  end-pi;
  
  // Lire depuis vue matérialisée optimisée pour lecture
  return getProjectionFromReadStore(orderId : projection);
end-proc;
```

#### **3. Circuit Breaker Pattern**
```rpg
dcl-ds circuitBreaker_t template qualified;
  serviceName varchar(50);
  state varchar(10);        // CLOSED, OPEN, HALF_OPEN
  failureCount int(10);
  lastFailureTime timestamp;
  successCount int(10);
  failureThreshold int(10);
  timeout int(10);          // seconds
end-ds;

dcl-proc callWithCircuitBreaker export;
  dcl-pi *n ind;
    serviceName varchar(50) const;
    serviceCall pointer const;
    parameters pointer const;
    result varchar(8000);
  end-pi;
  
  dcl-ds breaker likeDS(circuitBreaker_t);
  dcl-s callResult ind;
  
  monitor;
    // Récupérer état circuit breaker
    getCircuitBreakerState(serviceName : breaker);
    
    select;
      when breaker.state = 'OPEN';
        // Circuit ouvert, vérifier timeout
        if %diff(%timestamp() : breaker.lastFailureTime : *seconds) > breaker.timeout;
          breaker.state = 'HALF_OPEN';
          updateCircuitBreakerState(breaker);
        else;
          // Retourner échec rapide
          return *OFF;
        endif;
        
      when breaker.state = 'HALF_OPEN';
        // Test call
        callResult = callService(serviceCall : parameters : result);
        
        if callResult;
          // Succès, fermer circuit
          breaker.state = 'CLOSED';
          breaker.failureCount = 0;
          breaker.successCount += 1;
        else;
          // Échec, rouvrir circuit
          breaker.state = 'OPEN';
          breaker.failureCount += 1;
          breaker.lastFailureTime = %timestamp();
        endif;
        
        updateCircuitBreakerState(breaker);
        return callResult;
        
      when breaker.state = 'CLOSED';
        // Circuit fermé, appel normal
        callResult = callService(serviceCall : parameters : result);
        
        if callResult;
          breaker.successCount += 1;
          if breaker.failureCount > 0;
            breaker.failureCount = 0; // Reset sur succès
          endif;
        else;
          breaker.failureCount += 1;
          breaker.lastFailureTime = %timestamp();
          
          // Vérifier seuil d'ouverture
          if breaker.failureCount >= breaker.failureThreshold;
            breaker.state = 'OPEN';
          endif;
        endif;
        
        updateCircuitBreakerState(breaker);
        return callResult;
    endsl;
    
  on-error;
    return *OFF;
  endmon;
  
end-proc;
```

### **🏆 Critères d'Excellence**

```markdown
## Architecture Avancée (30 points)
- [ ] Microservices modulaires
- [ ] Event-driven communication
- [ ] Circuit breaker pattern
- [ ] Cache multi-niveau
- [ ] Monitoring complet

## Performance (25 points)  
- [ ] Réponse < 50ms endpoints simples
- [ ] Réponse < 200ms requêtes complexes
- [ ] Support 1000+ requêtes/minute
- [ ] Optimisation SQL avancée
- [ ] Gestion mémoire efficace

## Sécurité (25 points)
- [ ] Authentication multi-facteur
- [ ] Authorization fine-grained
- [ ] Audit trail complet
- [ ] Chiffrement données sensibles
- [ ] Protection contre OWASP Top 10

## Innovation (20 points)
- [ ] Machine Learning integration
- [ ] Real-time analytics
- [ ] Predictive features
- [ ] Advanced search
- [ ] Recommendation engine
```

---

## 📚 Ressources Expert

### **📖 Documentation Avancée**
- [IBM i API Reference](https://www.ibm.com/docs/en/i/7.5?topic=interfaces-api-reference)
- [SQL Advanced Features](https://www.ibm.com/docs/en/i/7.5?topic=reference-sql)
- [IFS Programming Guide](https://www.ibm.com/docs/en/i/7.5?topic=file-system-programming)

### **🎯 Certification Expert**
- **Formation** : 80 heures théorie + pratique
- **Projet** : Plateforme e-commerce complète
- **Mentorat** : 20 heures avec expert senior
- **Évaluation** : Architecture review + Code review + Présentation

---

*Formation Concepts Avancés IBM i - Équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*