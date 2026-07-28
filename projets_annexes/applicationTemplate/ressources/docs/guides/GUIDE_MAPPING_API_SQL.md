# Guide Mapping API ↔ SQL
## Configuration Champs Supportés pour Filtres et Tri Dynamiques

**Version:** 1.0  
**Date:** Janvier 2025  
**Auteur:** Équipe ArchiAPI  
**Source:** Conventions extraites de `employee.sqlrpgle`, `employee_getSupportedFields()`, `crest.sqlrpgle`

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Problématique](#problématique)
3. [Architecture CMAGIC_supportedFields](#architecture-cmagic_supportedfields)
4. [Implémentation getSupportedFields](#implémentation-getsupportedfields)
5. [Intégration avec CREST](#intégration-avec-crest)
6. [Logique de Filtrage](#logique-de-filtrage)
7. [Logique de Tri](#logique-de-tri)
8. [Types de Données](#types-de-données)
9. [Exemples Réels](#exemples-réels)
10. [Best Practices](#best-practices)

---

## Vue d'Ensemble

### Qu'est-ce que le Mapping API ↔ SQL ?

Le **mapping API ↔ SQL** est la configuration qui permet de traduire les noms de champs exposés dans l'API REST vers les noms de colonnes réels dans la base de données SQL.

**Exemple** :
```
API REST          →    Base de Données SQL
─────────────          ────────────────────
nom               →    lastname
prenom            →    firstname
service           →    workdept
salaire           →    salary
```

### Pourquoi Mapper ?

**Sans Mapping** (Direct SQL) :
```http
GET /api/employees?lastname_like=Smith
```
❌ Expose structure interne base de données  
❌ Difficile de renommer colonnes DB sans casser API  
❌ Noms colonnes pas toujours user-friendly

**Avec Mapping** (API Abstraite) :
```http
GET /api/employees?nom_like=Smith
```
✅ API découplée de la structure DB  
✅ Noms français/user-friendly exposés  
✅ Possibilité de renommer colonnes DB sans impact API  
✅ Validation types automatique (char vs numeric)

---

## Problématique

### Filtres et Tri Dynamiques

**Requête REST Standard** :
```http
GET /api/employees?nom_like=Smith&service=D11&salaire_gte=50000&_sort=nom&_order=ASC
```

**Défis** :
1. **Validation** : `nom`, `service`, `salaire` sont-ils des champs valides ?
2. **Traduction** : `nom` → `lastname`, `service` → `workdept` en SQL
3. **Type** : `salaire` est numérique → pas de quotes dans WHERE
4. **Opérateurs** : `_like`, `_gte` → `LIKE`, `>=` en SQL
5. **Tri** : `_sort=nom` → `ORDER BY lastname`

### Solution CMAGIC

**CMAGIC_supportedFields** :
- Structure de configuration déclarant tous les champs exposés
- Mapping nom API → nom SQL
- Type de données (char, numeric, date)
- Utilisée par CREST pour validation + construction requêtes SQL

---

## Architecture CMAGIC_supportedFields

### Structures de Données

**Fichier** : `includes/cmagic.rpgleinc`

```rpgle
// Constante : Nombre maximum de champs supportés
dcl-c CMAGIC_MAX_SUPPORTED_FIELDS 50;

// Énumération des types de données
dcl-enum typeChamp qualified;
  CHARACTER 'C';
  NUMERIC 'N';
  DATE 'D';
end-enum;

// Structure d'un champ supporté
dcl-ds CMAGIC_supportedField template qualified;
  name char(32);      // Nom du champ exposé dans l'API REST
  sqlField char(32);  // Nom de la colonne SQL correspondante
  dataType char(1);   // Type: 'C' (character), 'N' (numeric), 'D' (date)
end-ds;

// Structure contenant tous les champs supportés
dcl-ds CMAGIC_supportedFields template qualified;
  dcl-ds supportedFields likeDS(CMAGIC_supportedField) dim(CMAGIC_MAX_SUPPORTED_FIELDS);
end-ds;
```

### Composants

**1. CMAGIC_supportedField** (Champ Individuel) :

| Propriété  | Type      | Description                          | Exemple                |
|------------|-----------|--------------------------------------|------------------------|
| `name`     | char(32)  | Nom champ API REST                   | `'nom'`                |
| `sqlField` | char(32)  | Nom colonne SQL                      | `'lastname'`           |
| `dataType` | char(1)   | Type données (C/N/D)                 | `'C'` (character)      |

**2. CMAGIC_supportedFields** (Collection) :

| Propriété         | Type                                    | Description                     |
|-------------------|-----------------------------------------|---------------------------------|
| `supportedFields` | Array de CMAGIC_supportedField (dim 50) | Tous les champs de la ressource |

### Exemple Configuration Employee

```rpgle
dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;

// Champ 1: nom → lastname (character)
lSupportedFields.supportedFields(1).name = 'nom';
lSupportedFields.supportedFields(1).sqlField = 'lastname';
lSupportedFields.supportedFields(1).dataType = 'C';

// Champ 2: prenom → firstname (character)
lSupportedFields.supportedFields(2).name = 'prenom';
lSupportedFields.supportedFields(2).sqlField = 'firstname';
lSupportedFields.supportedFields(2).dataType = 'C';

// Champ 5: salaire → salary (numeric)
lSupportedFields.supportedFields(5).name = 'salaire';
lSupportedFields.supportedFields(5).sqlField = 'salary';
lSupportedFields.supportedFields(5).dataType = 'N';
```

---

## Implémentation getSupportedFields

### Signature Procédure

**Fichier** : `includes/employee.rpgleinc`

```rpgle
///
// Get Employee supported fields configuration
//
// Returns supported fields configuration for Employee entity.
// Used by REST services for filtering, sorting and validation.
//
// @param **out** supportedFields  Supported fields configuration
// @param **out** errors           List of errors if initialization fails
// @return *ON if successful, *OFF if error
// @tag Employee
// @tag REST
// @tag Configuration
///
dcl-pr employee_getSupportedFields ind extproc(*dclcase);
  supportedFields likeds(CMAGIC_supportedFields);
  errors likeDS(GLOBAL_listError);
end-pr;
```

### Implémentation Complète

**Fichier** : `src/employee/employee.sqlrpgle`

```rpgle
dcl-proc employee_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeds(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-s ErrorHappened ind;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;

  // 1. Initialisation
  clear pErrors;
  clear pSupportedFields;
  clear lSupportedFields;
  
  // 2. Configuration des champs Employee pour filtres REST
  
  // Champ API "nom" → SQL "lastname" (character)
  lSupportedFields.supportedFields(1).name = 'nom';
  lSupportedFields.supportedFields(1).sqlField = 'lastname';
  lSupportedFields.supportedFields(1).dataType = 'C';
  
  // Champ API "prenom" → SQL "firstname" (character)
  lSupportedFields.supportedFields(2).name = 'prenom';
  lSupportedFields.supportedFields(2).sqlField = 'firstname';
  lSupportedFields.supportedFields(2).dataType = 'C';
  
  // Champ API "initiale" → SQL "midinit" (character)
  lSupportedFields.supportedFields(3).name = 'initiale';
  lSupportedFields.supportedFields(3).sqlField = 'midinit';
  lSupportedFields.supportedFields(3).dataType = 'C';
  
  // Champ API "service" → SQL "workdept" (character)
  lSupportedFields.supportedFields(4).name = 'service';
  lSupportedFields.supportedFields(4).sqlField = 'workdept';
  lSupportedFields.supportedFields(4).dataType = 'C';
  
  // Champ API "salaire" → SQL "salary" (numeric)
  lSupportedFields.supportedFields(5).name = 'salaire';
  lSupportedFields.supportedFields(5).sqlField = 'salary';
  lSupportedFields.supportedFields(5).dataType = 'N';
  
  // Champ API "id" → SQL "empno" (numeric)
  lSupportedFields.supportedFields(6).name = 'id';
  lSupportedFields.supportedFields(6).sqlField = 'empno';
  lSupportedFields.supportedFields(6).dataType = 'N';
  
  // Champ API "dateEmbauche" → SQL "hiredate" (date)
  lSupportedFields.supportedFields(7).name = 'dateEmbauche';
  lSupportedFields.supportedFields(7).sqlField = 'hiredate';
  lSupportedFields.supportedFields(7).dataType = 'D';
  
  // Champ API "dateNaissance" → SQL "birthdate" (date)
  lSupportedFields.supportedFields(8).name = 'dateNaissance';
  lSupportedFields.supportedFields(8).sqlField = 'birthdate';
  lSupportedFields.supportedFields(8).dataType = 'D';
  
  // Champ API "genre" → SQL "sex" (character)
  lSupportedFields.supportedFields(9).name = 'genre';
  lSupportedFields.supportedFields(9).sqlField = 'sex';
  lSupportedFields.supportedFields(9).dataType = 'C';
  
  // 3. Tri par nom (DESC) pour éviter conflits lookup
  // Exemple: "nom" doit être trouvé avant "nom_like" lors du parsing
  SORTA(D) lSupportedFields.supportedFields(*).name;
  
  // 4. Finalisation
  pSupportedFields = lSupportedFields;
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
```

### Points Clés Implémentation

**1. Ordre Index** :
```rpgle
// Index 1 = premier champ
lSupportedFields.supportedFields(1).name = 'nom';

// Index 2 = deuxième champ
lSupportedFields.supportedFields(2).name = 'prenom';
```

**2. Tri SORTA(D)** (Descending) :
```rpgle
// ⚠️ CRITIQUE pour éviter conflits parsing
SORTA(D) lSupportedFields.supportedFields(*).name;
```

**Raison** : Lors du parsing, CREST cherche d'abord les champs longs.  
Sans tri DESC, `nom` pourrait matcher avant `nom_like`, causant erreurs.

**Après Tri** :
```
service          (7 chars)
salaire          (7 chars)
prenom           (6 chars)
nom              (3 chars)
initiale         (8 chars)
id               (2 chars)
genre            (5 chars)
dateNaissance    (13 chars)
dateEmbauche     (12 chars)
```

**3. Type de Données** :
```rpgle
// Character : Quotes SQL + UPPER() pour recherche insensible casse
lSupportedFields.supportedFields(1).dataType = 'C';

// Numeric : Pas de quotes SQL
lSupportedFields.supportedFields(5).dataType = 'N';

// Date : Traitement spécifique (format ISO, etc.)
lSupportedFields.supportedFields(7).dataType = 'D';
```

---

## Intégration avec CREST

### Workflow Complet

**1. Handler REST Récupère Configuration** :

```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lContext likeds(CMAGIC_context) inz;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields);
  dcl-ds lErrors likeds(GLOBAL_listError);
  
  // ⚡ Récupération configuration champs supportés
  clear lSupportedFields;
  clear lErrors;
  if not employee_getSupportedFields(lSupportedFields : lErrors);
    // Gestion erreur configuration (rare)
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Configuration error"}');
    return;
  endif;
  
  // ⚡ Initialisation CREST avec supportedFields
  if not CREST_initRestRequest(request : lSupportedFields : response : lContext);
    return; // Erreur validation déjà gérée par CREST
  endif;
  
  // Suite traitement...
end-proc;
```

**2. CREST Utilise Configuration pour Parsing** :

**Fichier** : `src/crest/crest.sqlrpgle`

```rpgle
dcl-proc setupFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-s filterIndex int(5) inz(1);
  dcl-s filterValue varchar(100);
  dcl-s baseField varchar(32);
  dcl-ds lSupportedField likeDS(CMAGIC_supportedField) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  
  clear context.filter;
  lSupportedFields = supportedFields;
  
  // ⚡ Tri DESC pour éviter conflits
  SORTA(D) lSupportedFields.supportedFields(*).name;
  
  // ⚡ Parcours tous les champs supportés
  for-each lSupportedField in lSupportedFields.supportedFields;
    if %len(%trim(lSupportedField.name)) = *zeros;
      leave;
    endif;
    
    baseField = %trim(lSupportedField.name);
    
    // Test filtre simple : ?nom=Smith
    filterValue = il_getQueryParameter(request : baseField : '');
    if (%len(%trim(filterValue)) > 0);
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '=';
      context.filter(filterIndex).value = %trim(filterValue);
      filterIndex += 1;
    endif;
    
    // Test filtre LIKE : ?nom_like=Smith
    filterValue = il_getQueryParameter(request : baseField + '_like' : '');
    if (%len(%trim(filterValue)) > 0);
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = 'LIKE';
      context.filter(filterIndex).value = '%' + %trim(filterValue) + '%';
      filterIndex += 1;
    endif;
    
    // ... autres opérateurs (_gte, _lte, etc.)
  endfor;
end-proc;
```

**3. Métier Utilise Context pour Requête SQL** :

```rpgle
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields);
  dcl-s lWhere varchar(2000);
  dcl-s dbFieldName varchar(32);
  dcl-s lIt int(5);
  
  // Récupération configuration pour mapping
  employee_getSupportedFields(lSupportedFields : lErrors);
  
  // Construction WHERE depuis context.filter
  for-each lItemFiltre in pContext.filter;
    // ⚡ Lookup nom champ API dans supportedFields
    lIt = %lookup(%trim(lItemFiltre.field) 
                  : lSupportedFields.supportedFields(*).name);
    
    if lIt > 0;
      // ⚡ Récupération nom SQL correspondant
      dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
      
      // Construction clause WHERE avec nom SQL
      lWhere += ' AND ' + %trim(dbFieldName) + ' ' 
                + %trim(lItemFiltre.operator) + ' '
                + %trim(lItemFiltre.value);
    endif;
  endfor;
  
  // Exécution requête SQL avec WHERE construit
end-proc;
```

---

## Logique de Filtrage

### Construction WHERE Dynamique

**Requête REST** :
```http
GET /api/employees?nom_like=Smith&service=D11&salaire_gte=50000
```

**Parsing CREST** → **Context** :
```rpgle
context.filter(1).field = 'nom';
context.filter(1).operator = 'LIKE';
context.filter(1).value = '%Smith%';

context.filter(2).field = 'service';
context.filter(2).operator = '=';
context.filter(2).value = 'D11';

context.filter(3).field = 'salaire';
context.filter(3).operator = '>=';
context.filter(3).value = '50000';
```

**Mapping + Construction SQL** :

```rpgle
// Filtre 1: nom (character)
lIt = %lookup('nom' : lSupportedFields.supportedFields(*).name);
// → lIt = index du champ "nom"
dbFieldName = lSupportedFields.supportedFields(lIt).sqlField; // 'lastname'
dataType = lSupportedFields.supportedFields(lIt).dataType;    // 'C'

// Character → UPPER() + quotes
lWhere += ' AND UPPER(lastname) LIKE UPPER('%Smith%')';

// Filtre 2: service (character)
dbFieldName = 'workdept';  // Mapping depuis supportedFields
lWhere += ' AND UPPER(workdept) = UPPER('D11')';

// Filtre 3: salaire (numeric)
dbFieldName = 'salary';    // Mapping depuis supportedFields
dataType = 'N';            // Numeric
// Numeric → Pas de quotes, pas d'UPPER()
lWhere += ' AND salary >= 50000';
```

**SQL Final** :
```sql
SELECT empno, firstname, lastname, workdept, salary
FROM employee
WHERE UPPER(lastname) LIKE UPPER('%Smith%')
  AND UPPER(workdept) = UPPER('D11')
  AND salary >= 50000
```

### Gestion Types Données

**Character (C)** :
```rpgle
if lSupportedFields.supportedFields(lIt).dataType = typeChamp.CHARACTER;
  // UPPER() pour recherche insensible à la casse
  lWhere += ' UPPER(' + %trim(dbFieldName) + ')';
  
  // Quotes autour de la valeur
  lValue = GLOBAL_QUOTE + %trim(%upper(lValue)) + GLOBAL_QUOTE;
endif;
```

**SQL Généré** :
```sql
UPPER(lastname) = UPPER('SMITH')
```

**Numeric (N)** :
```rpgle
if lSupportedFields.supportedFields(lIt).dataType = typeChamp.NUMERIC;
  // Pas d'UPPER(), pas de quotes
  lWhere += ' ' + %trim(dbFieldName);
  
  // Valeur brute
  lValue = %trim(lValue);
endif;
```

**SQL Généré** :
```sql
salary >= 50000
```

**Date (D)** :
```rpgle
if lSupportedFields.supportedFields(lIt).dataType = typeChamp.DATE;
  // Format ISO attendu
  lWhere += ' ' + %trim(dbFieldName);
  
  // Quotes + format ISO
  lValue = GLOBAL_QUOTE + %trim(lValue) + GLOBAL_QUOTE;
endif;
```

**SQL Généré** :
```sql
hiredate >= '2020-01-01'
```

### Opérateurs Supportés

| Suffixe URL | Opérateur SQL | Exemple URL                    | SQL Généré                      |
|-------------|---------------|--------------------------------|---------------------------------|
| *(aucun)*   | `=`           | `?nom=Smith`                   | `lastname = 'SMITH'`            |
| `_like`     | `LIKE`        | `?nom_like=Sm`                 | `lastname LIKE '%SM%'`          |
| `_gte`      | `>=`          | `?salaire_gte=50000`           | `salary >= 50000`               |
| `_lte`      | `<=`          | `?salaire_lte=100000`          | `salary <= 100000`              |
| `_gt`       | `>`           | `?salaire_gt=50000`            | `salary > 50000`                |
| `_lt`       | `<`           | `?salaire_lt=100000`           | `salary < 100000`               |
| `_ne`       | `<>`          | `?service_ne=D11`              | `workdept <> 'D11'`             |

---

## Logique de Tri

### Construction ORDER BY Dynamique

**Requête REST** :
```http
GET /api/employees?_sort=nom&_order=ASC
```

**Parsing CREST** → **Context** :
```rpgle
context.sort(1).field = 'nom';
context.sort(1).order = 'ASC';
```

**Mapping + Construction SQL** :

```rpgle
// Lookup nom champ API
lIt = %lookup('nom' : lSupportedFields.supportedFields(*).name);

if lIt > 0;
  // Récupération nom SQL
  dbFieldName = lSupportedFields.supportedFields(lIt).sqlField; // 'lastname'
  
  // Construction ORDER BY
  lOrderBy = 'ORDER BY ' + %trim(dbFieldName) + ' ' + %trim(context.sort(1).order);
endif;
```

**SQL Final** :
```sql
SELECT empno, firstname, lastname, workdept
FROM employee
ORDER BY lastname ASC
```

### Multi-Tri

**Requête REST** :
```http
GET /api/employees?sort=service&order=ASC&sort1=nom&order1=DESC
```

**Parsing CREST** :
```rpgle
context.sort(1).field = 'service';
context.sort(1).order = 'ASC';

context.sort(2).field = 'nom';
context.sort(2).order = 'DESC';
```

**SQL Généré** :
```sql
ORDER BY workdept ASC, lastname DESC
```

### Tri avec Validation

```rpgle
for-each lItemSort in pContext.sort;
  if %len(%trim(lItemSort.field)) = *zeros;
    leave;
  endif;
  
  // ⚡ Validation champ supporté
  clear lIt;
  lIt = %lookup(%trim(lItemSort.field)
                : lSupportedFields.supportedFields(*).name);
  
  if lIt > 0;
    // ⚡ Mapping vers nom SQL
    dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
    
    // Ajout à ORDER BY
    if lFirst;
      lOrderBy = 'ORDER BY';
      lFirst = *off;
    else;
      lOrderBy = %trim(lOrderBy) + ' ,';
    endif;
    
    lOrderBy += ' ' + %trim(dbFieldName) + ' ' + %trim(lItemSort.order);
  else;
    // Champ non supporté → ignoré (pas d'erreur, juste skip)
    iter;
  endif;
endfor;
```

---

## Types de Données

### CHARACTER ('C')

**Caractéristiques** :
- Recherche **insensible à la casse** via `UPPER()`
- Quotes autour des valeurs
- Opérateur LIKE supporte wildcards `%`

**Exemple** :
```rpgle
lSupportedFields.supportedFields(1).name = 'nom';
lSupportedFields.supportedFields(1).sqlField = 'lastname';
lSupportedFields.supportedFields(1).dataType = 'C';
```

**SQL Généré** :
```sql
-- Filtre égalité
UPPER(lastname) = UPPER('SMITH')

-- Filtre LIKE
UPPER(lastname) LIKE UPPER('%SMITH%')

-- Filtre différent
UPPER(lastname) <> UPPER('JOHNSON')
```

---

### NUMERIC ('N')

**Caractéristiques** :
- **Pas** d'UPPER()
- **Pas** de quotes autour valeurs
- Opérateurs comparaison : `=`, `<>`, `<`, `<=`, `>`, `>=`

**Exemple** :
```rpgle
lSupportedFields.supportedFields(5).name = 'salaire';
lSupportedFields.supportedFields(5).sqlField = 'salary';
lSupportedFields.supportedFields(5).dataType = 'N';
```

**SQL Généré** :
```sql
-- Filtre égalité
salary = 50000

-- Filtre supérieur ou égal
salary >= 50000

-- Filtre inférieur
salary < 100000
```

**⚠️ LIKE Non Supporté** :
```rpg
// ❌ LIKE sur numeric → ignoré ou erreur SQL
?salaire_like=5000  // Ne devrait pas être utilisé
```

---

### DATE ('D')

**Caractéristiques** :
- Format **ISO** attendu : `YYYY-MM-DD`
- Quotes autour valeurs
- Comparaison chronologique : `<`, `<=`, `>`, `>=`

**Exemple** :
```rpgle
lSupportedFields.supportedFields(7).name = 'dateEmbauche';
lSupportedFields.supportedFields(7).sqlField = 'hiredate';
lSupportedFields.supportedFields(7).dataType = 'D';
```

**SQL Généré** :
```sql
-- Filtre égalité
hiredate = '2020-01-15'

-- Filtre après ou égal
hiredate >= '2020-01-01'

-- Filtre avant
hiredate < '2023-12-31'
```

**Requêtes REST** :
```http
GET /api/employees?dateEmbauche_gte=2020-01-01
GET /api/employees?dateEmbauche_lte=2023-12-31
GET /api/employees?dateEmbauche=2020-01-15
```

---

## Exemples Réels

### Exemple 1: Configuration Employee Complète

**Fichier** : `src/employee/employee.sqlrpgle`

```rpgle
dcl-proc employee_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeds(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-s ErrorHappened ind;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  
  clear pErrors;
  clear pSupportedFields;
  clear lSupportedFields;
  
  // Configuration 9 champs Employee
  
  // 1. nom (character)
  lSupportedFields.supportedFields(1).name = 'nom';
  lSupportedFields.supportedFields(1).sqlField = 'lastname';
  lSupportedFields.supportedFields(1).dataType = 'C';
  
  // 2. prenom (character)
  lSupportedFields.supportedFields(2).name = 'prenom';
  lSupportedFields.supportedFields(2).sqlField = 'firstname';
  lSupportedFields.supportedFields(2).dataType = 'C';
  
  // 3. initiale (character)
  lSupportedFields.supportedFields(3).name = 'initiale';
  lSupportedFields.supportedFields(3).sqlField = 'midinit';
  lSupportedFields.supportedFields(3).dataType = 'C';
  
  // 4. service (character)
  lSupportedFields.supportedFields(4).name = 'service';
  lSupportedFields.supportedFields(4).sqlField = 'workdept';
  lSupportedFields.supportedFields(4).dataType = 'C';
  
  // 5. salaire (numeric)
  lSupportedFields.supportedFields(5).name = 'salaire';
  lSupportedFields.supportedFields(5).sqlField = 'salary';
  lSupportedFields.supportedFields(5).dataType = 'N';
  
  // 6. id (numeric)
  lSupportedFields.supportedFields(6).name = 'id';
  lSupportedFields.supportedFields(6).sqlField = 'empno';
  lSupportedFields.supportedFields(6).dataType = 'N';
  
  // 7. dateEmbauche (date)
  lSupportedFields.supportedFields(7).name = 'dateEmbauche';
  lSupportedFields.supportedFields(7).sqlField = 'hiredate';
  lSupportedFields.supportedFields(7).dataType = 'D';
  
  // 8. dateNaissance (date)
  lSupportedFields.supportedFields(8).name = 'dateNaissance';
  lSupportedFields.supportedFields(8).sqlField = 'birthdate';
  lSupportedFields.supportedFields(8).dataType = 'D';
  
  // 9. genre (character)
  lSupportedFields.supportedFields(9).name = 'genre';
  lSupportedFields.supportedFields(9).sqlField = 'sex';
  lSupportedFields.supportedFields(9).dataType = 'C';
  
  // Tri DESC pour parsing CREST
  SORTA(D) lSupportedFields.supportedFields(*).name;
  
  pSupportedFields = lSupportedFields;
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
```

---

### Exemple 2: Utilisation dans Handler REST

**Fichier** : `src/employee/employee.rest.sqlrpgle`

```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lContext likeds(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields);
  dcl-ds lErrors likeds(GLOBAL_listError);
  
  // ⚡ 1. Récupération configuration champs supportés
  clear lSupportedFields;
  clear lErrors;
  if not employee_getSupportedFields(lSupportedFields : lErrors);
    // Configuration invalide (rare)
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Configuration error"}');
    return;
  endif;
  
  // ⚡ 2. CREST parse requête avec supportedFields
  if not CREST_initRestRequest(request : lSupportedFields : response : lContext);
    return; // Erreur validation (400/406)
  endif;
  
  // 3. Appel métier avec context rempli
  monitor;
    if employee_search(lContext : lTotalCount : lItems : lErrors);
      response.status = IL_HTTP_OK;
      CREST_addHeaders(response : lTotalCount);
      il_responseWrite(response : employeesToJson(lItems : lTotalCount));
    else;
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Internal server error"}');
  endmon;
  
  on-exit;
    if (lItems <> *null);
      list_dispose(lItems);
    endif;
end-proc;
```

---

### Exemple 3: Construction WHERE avec Mapping

**Fichier** : `src/employee/employee.sqlrpgle` (employee_search)

```rpgle
// Récupération configuration
employee_getSupportedFields(lSupportedFields : lErrors);

// Construction WHERE dynamique
clear lWhere;
lFirst = *on;
SORTA(D) lContext.filter(*).field;

for-each lItemFiltre in lContext.filter;
  if %len(%trim(lItemFiltre.field)) = *zeros;
    leave;
  endif;
  
  // Préfixe WHERE
  if lFirst;
    lWhere = 'WHERE';
    lFirst = *off;
  else;
    lWhere = %trim(lWhere) + ' AND';
  endif;
  
  // Traitement recherche générale 'q'
  if %trim(lItemFiltre.field) = 'q';
    lWhere += ' (';
    lWhere += 'UPPER(lastname) LIKE UPPER(' + GLOBAL_QUOTE + '%' 
              + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
    lWhere += ' OR UPPER(firstname) LIKE UPPER(' + GLOBAL_QUOTE + '%' 
              + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
    lWhere += ' OR UPPER(workdept) LIKE UPPER(' + GLOBAL_QUOTE + '%' 
              + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
    lWhere += ')';
  else;
    // ⚡ Lookup nom champ API → SQL
    clear lString;
    lString = %trim(lItemFiltre.value);
    isNumericField = *off;
    
    SORTA(D) lSupportedFields.supportedFields(*).name;
    clear lIt;
    lIt = %lookup(%trim(lItemFiltre.field)
                  : lSupportedFields.supportedFields(*).name);
    
    if lIt > 0;
      // ⚡ Vérification type données
      if lSupportedFields.supportedFields(lIt).dataType = typeChamp.NUMERIC;
        isNumericField = *on;
      endif;
      
      // ⚡ Mapping nom SQL
      clear dbFieldName;
      dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
    else;
      // Champ non supporté → skip
      iter;
    endif;
    
    // Construction clause selon type
    if not (%trim(lItemFiltre.operator) = CMAGIC_OP_LIKE);
      if not isNumericField;
        lWhere += ' UPPER(' + %trim(dbFieldName) + ')';
        lString = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
      else;
        lWhere += ' ' + %trim(dbFieldName);
      endif;
    else;
      lWhere += ' UPPER(' + %trim(dbFieldName) + ')';
    endif;
    
    // Opérateur
    select;
      when %trim(lItemFiltre.operator) = CMAGIC_OP_LIKE;
        lWhere += ' LIKE ';
        if %scan('%' : %trim(lString)) = 0;
          lString = '%' + %trim(lString) + '%';
        endif;
        lWhere += ' UPPER(' + GLOBAL_QUOTE + %upper(%trim(lString)) + GLOBAL_QUOTE + ')';
      when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER_EQUAL;
        lWhere += ' >= ' + %trim(lString);
      when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS_EQUAL;
        lWhere += ' <= ' + %trim(lString);
      when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER;
        lWhere += ' > ' + %trim(lString);
      when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS;
        lWhere += ' < ' + %trim(lString);
      when %trim(lItemFiltre.operator) = CMAGIC_OP_NOT_EQUAL;
        lWhere += ' <> ' + %trim(lString);
      other; // CMAGIC_OP_EQUAL
        lWhere += ' = ' + %trim(lString);
    endsl;
  endif;
endfor;

// Ajout WHERE à SELECT
if lWhere <> *blanks;
  lSelect = %trim(lSelect) + ' ' + %trim(lWhere);
endif;
```

---

### Exemple 4: Requête REST Complète

**Requête** :
```http
GET /api/employees?nom_like=Smith&service=D11&salaire_gte=50000&_sort=nom&_order=ASC&_page=2&_limit=5
```

**Parsing CREST** :
```rpgle
// Pagination
context.pagination.numPage = 2;
context.pagination.perPage = 5;

// Filtres
context.filter(1).field = 'nom';
context.filter(1).operator = 'LIKE';
context.filter(1).value = '%Smith%';

context.filter(2).field = 'service';
context.filter(2).operator = '=';
context.filter(2).value = 'D11';

context.filter(3).field = 'salaire';
context.filter(3).operator = '>=';
context.filter(3).value = '50000';

// Tri
context.sort(1).field = 'nom';
context.sort(1).order = 'ASC';
```

**SQL Généré** :
```sql
SELECT empno, firstname, lastname, midinit, workdept
FROM employee
WHERE UPPER(lastname) LIKE UPPER('%Smith%')
  AND UPPER(workdept) = UPPER('D11')
  AND salary >= 50000
ORDER BY lastname ASC
LIMIT 5 OFFSET 5
```

**Résultat** :
```json
[
  {
    "id": "000010",
    "prenom": "CHRISTINE",
    "nom": "SMITH",
    "service": "D11",
    "salaire": 52750.00
  },
  {
    "id": "000020",
    "prenom": "MICHAEL",
    "nom": "SMITHSON",
    "service": "D11",
    "salaire": 61250.00
  }
]
```

**Headers** :
```http
X-Total-Count: 23
Access-Control-Expose-Headers: X-Total-Count
```

---

## Best Practices

### ✅ Configuration Centralisée

```rpgle
// ✅ BON : Procédure dédiée getSupportedFields
dcl-proc employee_getSupportedFields export;
  // Configuration unique, réutilisable
end-proc;

// ❌ MAUVAIS : Configuration inline dans handlers
dcl-proc employee_getlist_rest export;
  lSupportedFields.supportedFields(1).name = 'nom';
  lSupportedFields.supportedFields(1).sqlField = 'lastname';
  // ... duplication code
end-proc;
```

### ✅ Toujours Trier SORTA(D)

```rpgle
// ✅ BON : Tri DESC pour éviter conflits parsing
SORTA(D) lSupportedFields.supportedFields(*).name;

// ❌ MAUVAIS : Sans tri, risque de conflits
// "nom" pourrait être trouvé avant "nom_like"
```

### ✅ Validation Champ Avant Utilisation

```rpgle
// ✅ BON : Vérifier champ existe dans supportedFields
lIt = %lookup(%trim(lItemFiltre.field)
              : lSupportedFields.supportedFields(*).name);

if lIt > 0;
  dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
  // Utiliser dbFieldName
else;
  // Champ non supporté → ignorer
  iter;
endif;

// ❌ MAUVAIS : Utiliser directement sans validation
dbFieldName = lItemFiltre.field; // Peut être injection SQL !
```

### ✅ Type Données Correct

```rpgle
// ✅ BON : Character avec UPPER() + quotes
if dataType = typeChamp.CHARACTER;
  lWhere += ' UPPER(' + %trim(dbFieldName) + ')';
  lValue = GLOBAL_QUOTE + %trim(%upper(lValue)) + GLOBAL_QUOTE;
endif;

// ✅ BON : Numeric sans quotes
if dataType = typeChamp.NUMERIC;
  lWhere += ' ' + %trim(dbFieldName);
  lValue = %trim(lValue); // Pas de quotes
endif;

// ❌ MAUVAIS : Quotes sur numeric
lValue = GLOBAL_QUOTE + %trim(lValue) + GLOBAL_QUOTE; // Erreur SQL !
```

### ✅ Noms API User-Friendly

```rpgle
// ✅ BON : Noms français clairs
lSupportedFields.supportedFields(1).name = 'nom';
lSupportedFields.supportedFields(2).name = 'prenom';
lSupportedFields.supportedFields(4).name = 'service';

// ❌ MOINS BON : Noms techniques DB exposés
lSupportedFields.supportedFields(1).name = 'lastname';
lSupportedFields.supportedFields(2).name = 'firstnme'; // Abréviation DB
lSupportedFields.supportedFields(4).name = 'workdept'; // Code DB
```

### ✅ Documenter Configuration

```rpgle
///
// Get Employee supported fields configuration
//
// Configuration mapping between REST API field names and SQL columns:
// - nom → lastname (character)
// - prenom → firstname (character)
// - service → workdept (character)
// - salaire → salary (numeric)
// - id → empno (numeric)
// - dateEmbauche → hiredate (date)
// - dateNaissance → birthdate (date)
// - genre → sex (character)
//
// @param **out** supportedFields  Supported fields configuration
// @param **out** errors           List of errors if initialization fails
// @return *ON if successful, *OFF if error
///
dcl-proc employee_getSupportedFields export;
  // ...
end-proc;
```

### ✅ Gestion Erreurs Configuration

```rpgle
// ✅ BON : Vérifier retour getSupportedFields
if not employee_getSupportedFields(lSupportedFields : lErrors);
  response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
  il_responseWrite(response : '{"error":"Configuration error"}');
  return;
endif;

// ❌ MAUVAIS : Ignorer erreur
employee_getSupportedFields(lSupportedFields : lErrors);
// Continuer sans vérifier → peut causer erreurs SQL
```

### ✅ Limite Champs Supportés

```rpgle
// ✅ BON : Exposer champs pertinents seulement
// Pas de champs sensibles (password, salt, etc.)
// Pas de champs techniques internes (timestamps audit, etc.)

lSupportedFields.supportedFields(1).name = 'nom';
lSupportedFields.supportedFields(2).name = 'prenom';
// ... champs business seulement

// ❌ MAUVAIS : Exposer tout
lSupportedFields.supportedFields(10).name = 'password_hash'; // INTERDIT
lSupportedFields.supportedFields(11).name = 'created_by';    // Technique
```

### ✅ Tester avec Curl

```bash
# Test filtre character
curl "http://server:44000/api/employees?nom_like=Smith"

# Test filtre numeric
curl "http://server:44000/api/employees?salaire_gte=50000"

# Test multi-filtres
curl "http://server:44000/api/employees?nom_like=Smith&service=D11&salaire_gte=50000"

# Test tri
curl "http://server:44000/api/employees?_sort=nom&_order=ASC"

# Test complet
curl "http://server:44000/api/employees?nom_like=Smith&_sort=salaire&_order=DESC&_page=1&_limit=10"
```

---

## Checklist Implémentation

### ✅ Création getSupportedFields

- [ ] Créer procédure `[resource]_getSupportedFields` exportée
- [ ] Déclarer paramètres OUT : `supportedFields`, `errors`
- [ ] Retourner `*ON/*OFF` selon succès
- [ ] Initialiser structure locale `lSupportedFields`

### ✅ Configuration Champs

- [ ] Lister tous champs exposés dans API REST
- [ ] Pour chaque champ :
  - [ ] Définir `name` (nom API user-friendly)
  - [ ] Définir `sqlField` (nom colonne SQL)
  - [ ] Définir `dataType` (C/N/D)
- [ ] Vérifier pas de champs sensibles exposés
- [ ] Ajouter `SORTA(D)` après configuration

### ✅ Intégration Handler REST

- [ ] Déclarer variable `lSupportedFields`
- [ ] Appeler `[resource]_getSupportedFields()` avant CREST
- [ ] Vérifier retour, gérer erreur si `*OFF`
- [ ] Passer `lSupportedFields` à `CREST_initRestRequest()`

### ✅ Logique Métier Search

- [ ] Récupérer `supportedFields` dans procédure search
- [ ] Pour chaque filtre `context.filter` :
  - [ ] Lookup `field` dans `supportedFields.supportedFields(*).name`
  - [ ] Si trouvé, récupérer `sqlField` et `dataType`
  - [ ] Construire clause WHERE selon type
- [ ] Pour chaque tri `context.sort` :
  - [ ] Lookup `field` dans `supportedFields`
  - [ ] Si trouvé, récupérer `sqlField`
  - [ ] Construire ORDER BY

### ✅ Tests

- [ ] Tester filtre égalité : `?nom=Smith`
- [ ] Tester filtre LIKE : `?nom_like=Sm`
- [ ] Tester filtre numeric : `?salaire_gte=50000`
- [ ] Tester multi-filtres combinés
- [ ] Tester tri simple : `?_sort=nom&_order=ASC`
- [ ] Tester tri multiple
- [ ] Tester champ non supporté (doit être ignoré)
- [ ] Vérifier SQL généré via logs

### ✅ Documentation

- [ ] Documenter procédure `getSupportedFields` avec `///`
- [ ] Lister tous les mappings dans commentaire
- [ ] Documenter types données de chaque champ
- [ ] Ajouter exemples requêtes REST

---

## Références

### Fichiers Source

- **Configuration** : `src/employee/employee.sqlrpgle` (employee_getSupportedFields)
- **Structures** : `includes/cmagic.rpgleinc` (CMAGIC_supportedFields)
- **Prototype** : `includes/employee.rpgleinc`
- **Utilisation REST** : `src/employee/employee.rest.sqlrpgle`
- **Parsing CREST** : `src/crest/crest.sqlrpgle` (setupFilters, setupSorting)

### Documents Liés

- **Guide CREST** : `ressources/docs/guides/GUIDE_FRAMEWORK_CREST.md`
- **Guide llist** : `ressources/docs/guides/GUIDE_LISTE_CHAINEE_LLIST.md`
- **Guide Versioning** : `ressources/docs/guides/GUIDE_VERSIONING_SERVICE_PROGRAMS.md`
- **Conventions** : `ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md`

### Concepts Clés

- **CMAGIC** : Framework contexte REST (pagination/tri/filtres)
- **CREST** : Framework centralisation logique REST + ILEastic
- **supportedFields** : Configuration mapping API ↔ SQL
- **Dynamic SQL** : Construction requêtes SQL dynamiques sécurisées

---

**📌 Règle d'Or** : Mapping API ↔ SQL = Sécurité + Flexibilité. Toujours valider champs via `supportedFields` avant construction SQL.

**🎯 Conclusion** : Les 4 guides techniques sont maintenant complets ! Documentation exhaustive des patterns ArchiAPI : CREST (REST), llist (collections), versioning (service programs), et mapping (API ↔ SQL).
