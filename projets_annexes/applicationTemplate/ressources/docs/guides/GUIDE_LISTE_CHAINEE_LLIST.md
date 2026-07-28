# Guide Liste Chaînée llist
## Linked List Implementation pour IBM i RPG

**Version:** 1.0  
**Date:** Janvier 2025  
**Auteur:** Mihael Schmidt (bibliothèque), Équipe ArchiAPI (guide)  
**Source:** Conventions extraites du code réel `src/employee/employee.sqlrpgle` et `employee.rest.sqlrpgle`

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Concepts Fondamentaux](#concepts-fondamentaux)
3. [API Principale](#api-principale)
4. [Patterns d'Utilisation](#patterns-dutilisation)
5. [Performance et Mémoire](#performance-et-mémoire)
6. [Comparaison Array vs List](#comparaison-array-vs-list)
7. [Exemples Réels](#exemples-réels)
8. [Best Practices](#best-practices)

---

## Vue d'Ensemble

### Qu'est-ce que llist ?

**llist** est une implémentation de **liste doublement chaînée** (Doubly-Linked List) pour IBM i RPG ILE, développée par Mihael Schmidt. Elle utilise l'allocation mémoire dynamique et est particulièrement adaptée aux collections de taille variable.

**Caractéristiques** :
- ✅ **Doubly-Linked** : Navigation avant/arrière
- ✅ **Allocation Dynamique** : Pas de limite fixe
- ✅ **Générique** : Fonctionne avec tout type de données (char, structures)
- ✅ **Zero-Based Index** : Index commence à 0
- ⚠️ **Non Thread-Safe** : Utilisation mono-thread uniquement

### Pourquoi Utiliser llist ?

**Avantages** :
1. **Taille Variable** : Pas besoin de connaître la taille à l'avance
2. **Insertion/Suppression Rapide** : O(1) en début/fin de liste
3. **Pas de Réallocation** : Contrairement aux arrays dynamiques
4. **Itération Simple** : API d'itération intégrée

**Cas d'Usage dans ArchiAPI** :
- ✅ **Collections SQL** : Résultats de recherche avec pagination
- ✅ **API REST** : Retour collections JSON
- ✅ **Traitement Batch** : Accumulation d'éléments avant traitement

---

## Concepts Fondamentaux

### Structure de Données

**Liste Doublement Chaînée** :
```
┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐
│ H   │───▶│ N1  │───▶│ N2  │───▶│ N3  │
│ E   │    │ ◀───│────│ ◀───│────│     │
│ A   │    │ Data│    │ Data│    │ Data│
│ D   │    └─────┘    └─────┘    └─────┘
└─────┘
```

**Header (HEAD)** :
- Contient métadonnées (taille, pointeur premier/dernier nœud)
- Retourné par `list_create()`

**Nœud (Node)** :
- Contient données + pointeur suivant + pointeur précédent
- Alloué dynamiquement par `list_add()`

### Pointeurs

**Trois Types de Pointeurs** :

1. **Pointeur Liste** (Header) :
```rpgle
dcl-s lList pointer;
lList = list_create(); // Pointe vers header
```

2. **Pointeur Élément** (Node) :
```rpgle
dcl-s ptr pointer;
ptr = list_iterate(lList); // Pointe vers données du nœud
```

3. **Based Variable** (Accès Données) :
```rpgle
dcl-ds lItem likeds(employee_item_t) based(ptr);
// ptr utilisé comme base pour accéder à lItem
```

### Cycle de Vie

```rpgle
// 1. Création
lList = list_create();

// 2. Ajout d'éléments
list_add(lList : %addr(lItem) : %size(lItem));

// 3. Utilisation/Itération
ptr = list_iterate(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_iterate(lList);
enddo;

// 4. Nettoyage (OBLIGATOIRE)
list_dispose(lList); // ou list_clear(lList)
```

---

## API Principale

### 1. list_create

**Objectif** : Créer une nouvelle liste vide.

**Prototype** :
```rpgle
dcl-pr list_create pointer extproc('list_create') end-pr;
```

**Retour** :
- Pointeur vers header de la liste
- **Jamais *null** (lance exception si échec allocation)

**Utilisation** :
```rpgle
dcl-s lList pointer;

lList = list_create();

// ⚠️ OBLIGATION : Toujours disposer après usage
on-exit;
  if (lList <> *null);
    list_dispose(lList);
  endif;
```

**Mémoire Allouée** :
- Header structure (metadata)
- Heap utilisateur géré par la bibliothèque

**⚠️ Important** : Toujours vérifier `<> *null` avant `list_dispose()` dans `on-exit`.

---

### 2. list_add

**Objectif** : Ajouter un élément à la liste.

**Prototype** :
```rpgle
dcl-pr list_add ind extproc('list_add');
  list pointer const;
  value pointer const;
  length uns(10) const;
  position uns(10) const options(*nopass);
end-pr;
```

**Paramètres** :
- `list` : Pointeur liste créée par `list_create()`
- `value` : Pointeur vers données à ajouter
- `length` : Taille en octets des données
- `position` : *(Optionnel)* Position d'insertion (0-based)

**Retour** :
- `*ON` : Élément ajouté avec succès
- `*OFF` : Erreur (position invalide)

**Comportement** :
- **Sans position** : Ajout en **fin de liste** (équivalent `list_addLast`)
- **Avec position** : Insertion à l'index spécifié (0 = début)

**Utilisation Typique** :
```rpgle
dcl-ds lItem likeds(employee_item_t);

// Ajout en fin (pattern le plus courant)
list_add(lList : %addr(lItem) : %size(lItem));

// Ajout au début
list_add(lList : %addr(lItem) : %size(lItem) : 0);

// Ajout à la position 5
list_add(lList : %addr(lItem) : %size(lItem) : 5);
```

**⚠️ CRITIQUE** : Les données sont **copiées** en mémoire. Modifier `lItem` après `list_add()` n'affecte PAS l'élément dans la liste.

**Exemple Réel** (Employee Search) :
```rpgle
// Dans employee_search
dow (sqlState = SQL_OK);
  clear lItemSQL;
  Exec SQL Fetch Next From cListe Into :lItemSQL;
  if (sqlState <> SQL_OK);
    leave;
  endif;
  
  // Copie SQL → Structure temporaire
  clear lItem;
  lItem = lItemSQL;
  
  // Ajout dans liste (copie données)
  list_add(lItems : %addr(lItem) : %size(lItem));
enddo;
```

---

### 3. list_dispose

**Objectif** : Détruire la liste et libérer toute la mémoire.

**Prototype** :
```rpgle
dcl-pr list_dispose extproc('list_dispose');
  list pointer;
end-pr;
```

**Paramètres** :
- `list` : Pointeur liste (sera mis à `*null` automatiquement)

**Comportement** :
1. Libère tous les nœuds (données)
2. Libère le header
3. Met `list` à `*null`

**Utilisation** :
```rpgle
dcl-s lList pointer;

lList = list_create();
// ... utilisation

// Nettoyage
list_dispose(lList);
// ⚡ lList est maintenant *null
```

**⚠️ OBLIGATOIRE** : Appeler dans `on-exit` pour éviter fuite mémoire.

**Pattern Standard** :
```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lList pointer;
  
  // Logique métier
  lList = employee_search(context : lTotalCount);
  
  // ... traitement JSON
  
  on-exit;
    // ⚡ Nettoyage automatique même en cas d'erreur
    if (lList <> *null);
      list_dispose(lList);
    endif;
end-proc;
```

**Différence avec list_clear** :
- `list_dispose()` : Détruit liste ET header → pointeur = *null
- `list_clear()` : Vide liste MAIS garde header → réutilisable

---

### 4. list_clear

**Objectif** : Vider la liste en conservant le header.

**Prototype** :
```rpgle
dcl-pr list_clear ind extproc('list_clear');
  list pointer const;
end-pr;
```

**Paramètres** :
- `list` : Pointeur liste

**Retour** :
- `*ON` : Liste vidée
- `*OFF` : Erreur

**Comportement** :
1. Libère tous les nœuds (données)
2. **Conserve** le header
3. Liste devient vide mais réutilisable

**Utilisation** :
```rpgle
// Réutilisation de liste dans boucle
lList = list_create();

for i = 1 to 10;
  // Remplissage
  list_add(lList : %addr(lItem) : %size(lItem));
  
  // Traitement
  processItems(lList);
  
  // Nettoyage pour réutilisation
  list_clear(lList);
endfor;

// Destruction finale
list_dispose(lList);
```

**⚠️ Quand Utiliser** :
- ✅ **list_clear** : Réutilisation de la liste dans boucle
- ✅ **list_dispose** : Fin de vie définitive de la liste

---

### 5. list_iterate

**Objectif** : Itérer sur la liste (API moderne).

**Prototype** :
```rpgle
dcl-pr list_iterate pointer extproc('list_iterate');
  list pointer const;
  offset uns(10) const options(*nopass);
end-pr;
```

**Paramètres** :
- `list` : Pointeur liste
- `offset` : *(Optionnel)* Position de départ (0-based)

**Retour** :
- Pointeur vers données du nœud suivant
- `*null` si fin de liste

**Comportement** :
1. **Premier appel** : Retourne premier élément
2. **Appels suivants** : Retourne éléments suivants
3. **Fin de liste** : Retourne `*null`
4. **Automatique** : Réinitialise après `*null` pour nouvelle itération

**Utilisation Standard** :
```rpgle
dcl-ds lItem likeds(employee_item_t) based(ptr);
dcl-s ptr pointer;

// Itération complète
ptr = list_iterate(lList);
dow (ptr <> *null);
  // Accès à lItem via based variable
  CKOOL_logMessage('Employee: ' + %trim(lItem.lastname));
  
  ptr = list_iterate(lList);
enddo;
```

**Avec Offset** :
```rpgle
// Commencer à l'élément 5
ptr = list_iterate(lList : 5);
dow (ptr <> *null);
  // Traitement à partir de l'élément 5
  ptr = list_iterate(lList);
enddo;
```

**⚠️ Important** :
- Appel **sans offset** après premier appel avec offset
- Itération automatiquement réinitialisée après fin
- **Ne pas** modifier liste pendant itération (résultat indéterminé)

---

### 6. list_getFirst / list_getNext (Deprecated)

**Objectif** : Itérer sur la liste (ancienne API).

**Prototypes** :
```rpgle
dcl-pr list_getFirst pointer extproc('list_getFirst');
  list pointer const;
end-pr;

dcl-pr list_getNext pointer extproc('list_getNext');
  list pointer const;
end-pr;
```

**⚠️ DEPRECATED** : Utiliser `list_iterate()` à la place.

**Pattern Ancien** (encore présent dans code legacy) :
```rpgle
ptr = list_getFirst(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_getNext(lList);
enddo;
```

**Pattern Moderne** (recommandé) :
```rpgle
ptr = list_iterate(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_iterate(lList);
enddo;
```

**Différence** :
- `list_getFirst/getNext` : Deux appels différents
- `list_iterate` : Un seul appel unifié

---

### 7. list_size

**Objectif** : Obtenir le nombre d'éléments dans la liste.

**Prototype** :
```rpgle
dcl-pr list_size uns(10) extproc('list_size');
  list pointer const;
end-pr;
```

**Retour** :
- Nombre d'éléments (unsigned)
- `-1` si erreur (cast en unsigned = très grand nombre)

**Utilisation** :
```rpgle
dcl-s lSize uns(10);

lSize = list_size(lList);
CKOOL_logMessage('List contains ' + %char(lSize) + ' elements');

// Vérification liste vide
if (list_size(lList) = 0);
  CKOOL_logMessage('List is empty');
endif;
```

**⚠️ Performance** : O(1) - taille stockée dans header, pas de parcours.

---

### 8. list_isEmpty

**Objectif** : Vérifier si la liste est vide.

**Prototype** :
```rpgle
dcl-pr list_isEmpty ind extproc('list_isEmpty');
  list pointer const;
end-pr;
```

**Retour** :
- `*ON` : Liste vide
- `*OFF` : Liste contient éléments

**Utilisation** :
```rpgle
if (list_isEmpty(lList));
  CKOOL_logMessage('No results found');
  return *OFF;
endif;
```

**Équivalent** :
```rpgle
// Avec list_size
if (list_size(lList) = 0);
  // ...
endif;

// Avec list_isEmpty (plus lisible)
if (list_isEmpty(lList));
  // ...
endif;
```

**⚠️ Recommandation** : Préférer `list_isEmpty()` pour clarté du code.

---

## Patterns d'Utilisation

### Pattern 1: Accumulation SQL → Liste

**Cas d'Usage** : Requête SQL avec pagination, résultats accumulés dans liste.

**Code** (Employee Search) :
```rpgle
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  
  dcl-s lItems pointer;
  dcl-ds lItem likeds(employee_item_t);
  dcl-ds lItemSQL likeds(employee_item_t);
  dcl-s lLimit int(10);
  dcl-s lOffset int(10);
  
  // 1. Création liste
  lItems = list_create();
  
  // 2. Calcul pagination
  lLimit = pContext.pagination.perPage;
  lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
  
  // 3. Requête SQL avec filtres/tri/pagination
  lSelect = 'SELECT empno, firstnme, lastname, workdept FROM employee';
  // ... construction WHERE, ORDER BY, LIMIT, OFFSET
  
  Exec SQL PREPARE SqlStmt FROM :lSelect;
  Exec SQL DECLARE cListe CURSOR FOR SqlStmt;
  Exec SQL OPEN cListe;
  
  // 4. Accumulation résultats dans liste
  dow (sqlState = SQL_OK);
    clear lItemSQL;
    Exec SQL FETCH NEXT FROM cListe INTO :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    
    // Copie SQL → Structure temporaire
    clear lItem;
    lItem = lItemSQL;
    
    // ⚡ Ajout dans liste (copie données)
    list_add(lItems : %addr(lItem) : %size(lItem));
  enddo;
  
  // 5. Count total (sans pagination)
  lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelect) + ') a';
  // ... exécution count
  
  // 6. Retour pointeur liste
  pTotalCount = lCount;
  return lItems;
  
  on-exit ErrorHappened;
    Exec SQL CLOSE cListe;
    if ErrorHappened;
      list_dispose(lItems);
      return *null;
    endif;
end-proc;
```

**Points Clés** :
- ✅ Liste créée au début
- ✅ Accumulation progressive dans boucle SQL
- ✅ `list_dispose()` en cas d'erreur
- ✅ Retour pointeur liste au succès
- ⚠️ Appelant responsable du `list_dispose()` final

---

### Pattern 2: Liste → JSON Streaming

**Cas d'Usage** : Conversion liste en JSON pour réponse REST.

**Code** (Employee REST Handler) :
```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s lList pointer;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-ds context likeds(CMAGIC_context) inz;
  dcl-ds supportedFields likeds(CMAGIC_supportedFields) inz;
  
  // 1. Initialisation CREST
  supportedFields = employee_getSupportedFields();
  if not CREST_initRestRequest(request : supportedFields : response : context);
    return;
  endif;
  
  // 2. Recherche métier → liste
  lList = employee_search(context : lTotalCount);
  
  // 3. Headers REST
  response.status = IL_HTTP_OK;
  CREST_addHeaders(response : lTotalCount);
  
  // 4. Conversion liste → JSON
  il_responseWrite(response : employeesToJson(lList : lTotalCount));
  
  on-exit;
    // ⚡ Nettoyage automatique
    if (lList <> *null);
      list_dispose(lList);
    endif;
end-proc;
```

**Fonction Conversion** :
```rpgle
dcl-proc employeesToJson;
  dcl-pi *n varchar(1048576);
    employees pointer const;
    totalCount like(CMAGIC_totalCount) const;
  end-pi;
  
  dcl-s json varchar(1048576);
  dcl-s first ind inz(*on);
  dcl-ds employee likeds(employee_item_t) based(ptr);
  dcl-s ptr pointer;
  
  // 1. Ouverture tableau JSON
  json = '[';
  
  // 2. Itération liste avec list_iterate
  ptr = list_iterate(employees);
  dow (ptr <> *null);
    // Virgule entre éléments
    if (not first);
      json += ',';
    endif;
    
    // Conversion item → JSON
    json += employeeItemToJson(employee);
    
    first = *off;
    ptr = list_iterate(employees);
  enddo;
  
  // 3. Fermeture tableau
  json += ']';
  
  return json;
end-proc;
```

**Points Clés** :
- ✅ `based(ptr)` pour accès direct structure
- ✅ `list_iterate()` pour parcours moderne
- ✅ Gestion virgules avec flag `first`
- ✅ `list_dispose()` dans `on-exit` du handler REST

---

### Pattern 3: Réutilisation Liste (list_clear)

**Cas d'Usage** : Traitement batch avec réutilisation de liste.

**Code** :
```rpgle
dcl-proc processBatchFiles export;
  dcl-pi *n ind;
    fileList varchar(1000) dim(100) const;
  end-pi;
  
  dcl-s lRecords pointer;
  dcl-s i int(10);
  dcl-ds lRecord likeds(record_t);
  
  // Création liste unique pour tous fichiers
  lRecords = list_create();
  
  // Traitement de chaque fichier
  for i = 1 to %elem(fileList);
    if (%len(%trim(fileList(i))) = 0);
      leave;
    endif;
    
    // 1. Lecture fichier → accumulation dans liste
    readFileToList(fileList(i) : lRecords);
    
    // 2. Traitement des enregistrements
    processRecords(lRecords);
    
    // 3. Nettoyage pour réutilisation
    list_clear(lRecords);
  endfor;
  
  // Destruction finale
  list_dispose(lRecords);
  
  return *ON;
end-proc;
```

**Points Clés** :
- ✅ `list_clear()` libère nœuds mais garde header
- ✅ Pas de réallocation à chaque itération
- ✅ `list_dispose()` final pour destruction complète
- ⚠️ Économie mémoire significative sur gros volumes

---

### Pattern 4: Liste avec Offset (Pagination Manuelle)

**Cas d'Usage** : Pagination côté application (rare, mais possible).

**Code** :
```rpgle
dcl-proc getPaginatedResults export;
  dcl-pi *n varchar(10000);
    lList pointer const;
    pageNum int(10) const;
    pageSize int(10) const;
  end-pi;
  
  dcl-s json varchar(10000);
  dcl-s offset int(10);
  dcl-s count int(10);
  dcl-ds lItem likeds(employee_item_t) based(ptr);
  dcl-s ptr pointer;
  
  // Calcul offset
  offset = (pageNum - 1) * pageSize;
  
  json = '[';
  
  // ⚡ Démarrage itération à offset
  ptr = list_iterate(lList : offset);
  count = 0;
  
  dow (ptr <> *null and count < pageSize);
    if (count > 0);
      json += ',';
    endif;
    
    json += itemToJson(lItem);
    
    count += 1;
    ptr = list_iterate(lList);
  enddo;
  
  json += ']';
  
  return json;
end-proc;
```

**Points Clés** :
- ✅ `list_iterate(lList : offset)` pour démarrage à position
- ✅ Compteur manuel pour limitation `pageSize`
- ⚠️ Préférer pagination SQL quand possible (plus performant)

---

## Performance et Mémoire

### Complexité Algorithmique

| Opération                  | Complexité | Note                                      |
|----------------------------|------------|-------------------------------------------|
| `list_create()`            | O(1)       | Allocation header uniquement              |
| `list_add()` (fin)         | O(1)       | Ajout direct en fin via pointeur tail     |
| `list_add()` (début)       | O(1)       | Ajout direct en début via pointeur head   |
| `list_add(position)`       | O(n)       | Parcours jusqu'à position                 |
| `list_get(index)`          | O(n/2)     | Parcours depuis extrémité la plus proche  |
| `list_iterate()`           | O(1)       | Accès direct pointeur interne             |
| `list_size()`              | O(1)       | Taille stockée dans header                |
| `list_clear()`             | O(n)       | Libération de chaque nœud                 |
| `list_dispose()`           | O(n)       | Libération nœuds + header                 |

### Mémoire

**Overhead par Élément** :
```
Taille Totale Nœud = sizeof(Données) + Overhead Liste
Overhead ≈ 32 octets (pointeurs next/prev + métadonnées)
```

**Exemple Employee Item** :
```rpgle
dcl-ds employee_item_t qualified template;
  empno char(6);      // 6 octets
  firstname char(30); // 30 octets
  lastname char(30);  // 30 octets
  workdept char(3);   // 3 octets
  // Total données = 69 octets
end-ds;

// Mémoire réelle par élément ≈ 69 + 32 = 101 octets
```

**Calcul Collection** :
```
1000 employés × 101 octets ≈ 101 KB
10000 employés × 101 octets ≈ 1 MB
```

**⚠️ Fragmentation** :
- Liste allouée nœud par nœud → fragmentation mémoire
- Array continu → meilleure localité cache CPU
- **Trade-off** : Flexibilité vs Performance

### Optimisations

**1. Réutiliser Liste avec list_clear()** :
```rpgle
// ❌ Mauvais : Réallocation constante
for i = 1 to 1000;
  lList = list_create();
  // ... traitement
  list_dispose(lList);
endfor;

// ✅ Bon : Réutilisation header
lList = list_create();
for i = 1 to 1000;
  // ... traitement
  list_clear(lList);
endfor;
list_dispose(lList);
```

**2. Éviter list_add() avec Position** :
```rpgle
// ❌ Lent : O(n) à chaque insertion
for i = 1 to 1000;
  list_add(lList : %addr(lItem) : %size(lItem) : 0); // Toujours au début
endfor;

// ✅ Rapide : O(1) par insertion
for i = 1 to 1000;
  list_add(lList : %addr(lItem) : %size(lItem)); // Fin de liste
endfor;
```

**3. Préférer list_iterate() à list_get()** :
```rpgle
// ❌ Lent : O(n²) - parcours complet à chaque get
for i = 0 to list_size(lList) - 1;
  ptr = list_get(lList : i);
  // Traitement
endfor;

// ✅ Rapide : O(n) - itération séquentielle
ptr = list_iterate(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_iterate(lList);
enddo;
```

---

## Comparaison Array vs List

### Quand Utiliser Array ?

**✅ Utiliser Array Si** :
- Taille connue à l'avance
- Accès aléatoire fréquent (index direct)
- Performance critique (localité cache)
- Données fixes (pas d'insertion/suppression)

**Exemple** :
```rpgle
// Array pour paramètres fixes
dcl-s lMonths char(10) dim(12) inz;
lMonths(1) = 'Janvier';
// ...

// Array pour résultat SQL avec FETCH ALL
dcl-ds lEmployees likeds(employee_t) dim(1000);
Exec SQL FETCH ALL FROM cListe INTO :lEmployees;
```

### Quand Utiliser Liste ?

**✅ Utiliser Liste Si** :
- Taille inconnue ou variable
- Accumulation progressive (loop SQL)
- Insertion/suppression fréquentes
- Pas d'accès aléatoire nécessaire

**Exemple** :
```rpgle
// Liste pour résultats SQL progressifs
lList = list_create();
dow (sqlState = SQL_OK);
  Exec SQL FETCH NEXT FROM cListe INTO :lItem;
  if (sqlState <> SQL_OK);
    leave;
  endif;
  list_add(lList : %addr(lItem) : %size(lItem));
enddo;
```

### Tableau Comparatif

| Critère                   | Array                    | Liste                    |
|---------------------------|--------------------------|--------------------------|
| **Taille**                | Fixe ou dim(MAX)         | Dynamique illimitée      |
| **Mémoire**               | Allouée d'avance         | Allouée à la demande     |
| **Accès Index**           | O(1)                     | O(n)                     |
| **Insertion Fin**         | O(1) si espace           | O(1)                     |
| **Insertion Milieu**      | O(n) (décalage)          | O(n) (parcours)          |
| **Itération**             | O(n)                     | O(n)                     |
| **Cache CPU**             | ✅ Excellent              | ⚠️ Moyen                  |
| **Fragmentation**         | ✅ Aucune                 | ⚠️ Possible               |
| **Flexibilité**           | ⚠️ Limitée                | ✅ Excellente             |
| **Cleanup**               | Automatique              | Manuel (dispose)         |

### Cas d'Usage ArchiAPI

| Scenario                          | Recommandation | Justification                                  |
|-----------------------------------|----------------|------------------------------------------------|
| Résultats SQL paginated           | **Liste**      | Taille variable, accumulation progressive      |
| Configuration fields mapping      | **Array**      | Taille fixe, accès fréquent                    |
| Accumulation erreurs validation   | **Array**      | Max ~10 erreurs, structure fixe                |
| Résultats recherche REST          | **Liste**      | Taille inconnue, retour JSON direct            |
| Constantes (mois, codes)          | **Array**      | Données fixes, accès direct                    |

---

## Exemples Réels

### Exemple 1: Employee Search Complet

**Fichier** : `src/employee/employee.sqlrpgle`

```rpgle
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  
  dcl-s lItems pointer;
  dcl-ds lItem likeds(employee_item_t);
  dcl-ds lItemSQL likeds(employee_item_t);
  dcl-s lLimit int(10);
  dcl-s lOffset int(10);
  dcl-s lSelect varchar(5000);
  dcl-s lSelCount varchar(5000);
  dcl-s lWhere varchar(2000);
  dcl-s lOrderBy varchar(500);
  dcl-s lCount int(10);
  
  // 1. Initialisation
  clear lItems;
  lItems = list_create();
  
  // 2. Pagination
  lLimit = pContext.pagination.perPage;
  lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
  if lLimit < 1;
    lLimit = CMAGIC_DEFAULT_LIMIT;
  endif;
  
  // 3. Construction requête SQL
  lSelect = 'SELECT empno, firstnme, lastname, midinit, workdept FROM employee';
  
  // ... construction WHERE (filtres)
  // ... construction ORDER BY (tri)
  
  lSelect = %trim(lSelect) + ' LIMIT ' + %char(lLimit) 
                            + ' OFFSET ' + %char(lOffset);
  
  // 4. Exécution requête
  Exec SQL PREPARE SqlStmt FROM :lSelect;
  Exec SQL DECLARE cListe CURSOR FOR SqlStmt;
  Exec SQL OPEN cListe;
  
  if (sqlState <> SQL_OK);
    clear lError;
    lError.code = %trim(sqlState);
    CKOOL_ThrowError(lError);
  endif;
  
  // 5. ⚡ Accumulation dans liste
  dow (sqlState = SQL_OK);
    clear lItemSQL;
    Exec SQL FETCH NEXT FROM cListe INTO :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    
    // Copie SQL → Structure
    clear lItem;
    lItem = lItemSQL;
    
    // Ajout dans liste
    list_add(lItems : %addr(lItem) : %size(lItem));
  enddo;
  
  // 6. Count total (sans pagination)
  lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelect) + ') a';
  Exec SQL PREPARE SqlStmt2 FROM :lSelCount;
  Exec SQL DECLARE cCountListe CURSOR FOR SqlStmt2;
  Exec SQL OPEN cCountListe;
  Exec SQL FETCH cCountListe INTO :lCount;
  
  // 7. Retour
  pTotalCount = lCount;
  return lItems;
  
  on-exit ErrorHappened;
    Exec SQL CLOSE cListe;
    Exec SQL CLOSE cCountListe;
    if ErrorHappened;
      list_dispose(lItems);
      return *null;
    endif;
end-proc;
```

**Points Clés** :
- ✅ `list_create()` au début
- ✅ `list_add()` dans loop SQL
- ✅ `list_dispose()` en cas d'erreur (on-exit)
- ✅ Retour pointeur pour traitement ultérieur
- ⚠️ Appelant responsable du cleanup final

---

### Exemple 2: Conversion Liste → JSON

**Fichier** : `src/employee/employee.rest.sqlrpgle`

```rpgle
dcl-proc employeesToJson;
  dcl-pi *n varchar(1048576);
    employees pointer const;
    totalCount like(CMAGIC_totalCount) const;
  end-pi;
  
  dcl-s json varchar(1048576);
  dcl-s first ind inz(*on);
  dcl-ds employee likeds(employee_item_t) based(ptr);
  dcl-s ptr pointer;
  
  // 1. Ouverture tableau JSON
  json = '[';
  
  // 2. ⚡ Itération avec list_iterate
  ptr = list_iterate(employees);
  dow (ptr <> *null);
    // Virgule entre éléments
    if (not first);
      json += ',';
    endif;
    
    // Conversion item → JSON
    json += employeeItemToJson(employee);
    
    first = *off;
    ptr = list_iterate(employees);
  enddo;
  
  // 3. Fermeture tableau
  json += ']';
  
  return json;
end-proc;

dcl-proc employeeItemToJson;
  dcl-pi *n varchar(500);
    employee likeds(employee_item_t) const;
  end-pi;
  
  dcl-s json varchar(500);
  
  json = '{';
  json += '"id":"' + %trim(employee.empno) + '",';
  json += '"firstname":"' + %trim(employee.firstname) + '",';
  json += '"lastname":"' + %trim(employee.lastname) + '",';
  json += '"workdept":"' + %trim(employee.workdept) + '"';
  json += '}';
  
  return json;
end-proc;
```

**Points Clés** :
- ✅ `based(ptr)` pour accès transparent structure
- ✅ `list_iterate()` moderne (pas `list_getFirst/getNext`)
- ✅ Flag `first` pour gestion virgules JSON
- ✅ Procédure dédiée conversion item simple

---

### Exemple 3: Handler REST avec Cleanup

**Fichier** : `src/employee/employee.rest.sqlrpgle`

```rpgle
dcl-proc employee_getlist_rest export;
  dcl-pi *n;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  dcl-ds supportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  
  monitor;
    // 1. CREST init
    supportedFields = employee_getSupportedFields();
    if not CREST_initRestRequest(request : supportedFields : response : context);
      return;
    endif;
    
    // 2. ⚡ Recherche → liste
    lItems = employee_search(context : lTotalCount);
    
    if (lItems <> *null);
      // 3. Réponse HTTP
      response.status = IL_HTTP_OK;
      CREST_addHeaders(response : lTotalCount);
      
      // 4. JSON
      il_responseWrite(response : employeesToJson(lItems : lTotalCount));
    else;
      CKOOL_logMessage('employee_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    CKOOL_logMessage('Exception: ' + %char(%error));
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Internal server error"}');
  endmon;
  
  on-exit;
    // ⚡ Cleanup automatique (même en cas d'erreur)
    if (lItems <> *null);
      list_dispose(lItems);
    endif;
end-proc;
```

**Points Clés** :
- ✅ `on-exit` garantit cleanup même en cas d'erreur
- ✅ `monitor/on-error` pour exceptions
- ✅ Test `<> *null` avant `list_dispose()`
- ✅ Aucune fuite mémoire possible

---

## Best Practices

### ✅ Toujours Disposer

```rpgle
// ❌ INTERDIT : Fuite mémoire
dcl-proc badExample;
  dcl-s lList pointer;
  lList = list_create();
  // ... utilisation
  // ⚠️ Pas de list_dispose() → FUITE MÉMOIRE
end-proc;

// ✅ BON : Cleanup garanti
dcl-proc goodExample;
  dcl-s lList pointer;
  lList = list_create();
  // ... utilisation
  on-exit;
    if (lList <> *null);
      list_dispose(lList);
    endif;
end-proc;
```

### ✅ Utiliser list_iterate() (Pas list_getFirst/getNext)

```rpgle
// ❌ Ancien : API deprecated
ptr = list_getFirst(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_getNext(lList);
enddo;

// ✅ Moderne : API unifiée
ptr = list_iterate(lList);
dow (ptr <> *null);
  // Traitement
  ptr = list_iterate(lList);
enddo;
```

### ✅ Based Variables pour Structures

```rpgle
// ❌ Copie manuelle
ptr = list_iterate(lList);
dow (ptr <> *null);
  %str(ptr : %size(employee_item_t) : lItem);
  CKOOL_logMessage(lItem.lastname);
  ptr = list_iterate(lList);
enddo;

// ✅ Based variable (transparent)
dcl-ds lItem likeds(employee_item_t) based(ptr);
ptr = list_iterate(lList);
dow (ptr <> *null);
  CKOOL_logMessage(lItem.lastname); // Accès direct
  ptr = list_iterate(lList);
enddo;
```

### ✅ Réutiliser avec list_clear()

```rpgle
// ❌ Réallocation constante
for i = 1 to 100;
  lList = list_create();
  // ... traitement
  list_dispose(lList);
endfor;

// ✅ Réutilisation header
lList = list_create();
for i = 1 to 100;
  // ... traitement
  list_clear(lList);
endfor;
list_dispose(lList);
```

### ✅ Ne Jamais Modifier Liste Pendant Itération

```rpgle
// ❌ DANGEREUX : Résultat indéterminé
ptr = list_iterate(lList);
dow (ptr <> *null);
  if (someCondition);
    list_remove(lList : currentIndex); // ⚠️ INTERDIT
  endif;
  ptr = list_iterate(lList);
enddo;

// ✅ Collecter indices puis supprimer après
dcl-s toDelete int(10) dim(1000);
dcl-s deleteCount int(10) inz(0);

ptr = list_iterate(lList);
index = 0;
dow (ptr <> *null);
  if (someCondition);
    deleteCount += 1;
    toDelete(deleteCount) = index;
  endif;
  ptr = list_iterate(lList);
  index += 1;
enddo;

// Suppression après itération (ordre inverse)
for i = deleteCount downto 1;
  list_remove(lList : toDelete(i));
endfor;
```

### ✅ Vérifier Retours

```rpgle
// ❌ Ignorer erreurs
list_add(lList : %addr(lItem) : %size(lItem));

// ✅ Vérifier succès
if not list_add(lList : %addr(lItem) : %size(lItem));
  CKOOL_logError('Failed to add item to list');
  return *OFF;
endif;
```

### ✅ Documenter Propriété Pointeur

```rpgle
///
// Search employees by filters
//
// Returns a linked list of employee items matching search criteria.
// **CALLER IS RESPONSIBLE** for calling list_dispose() on returned pointer.
//
// @param context  CMAGIC search context
// @param totalCount  OUT total number of matching employees
// @return pointer to linked list of employee_item_t (caller must dispose)
///
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  
  // ...
end-proc;
```

---

## Checklist Utilisation llist

### ✅ Création

- [ ] Appeler `list_create()` au début
- [ ] Stocker pointeur dans variable locale
- [ ] Tester `<> *null` avant utilisation (sécurité)

### ✅ Ajout

- [ ] Utiliser `list_add()` sans position (fin de liste) si possible
- [ ] Vérifier retour `*ON/*OFF` si critique
- [ ] Comprendre que données sont **copiées** (pas référencées)

### ✅ Itération

- [ ] Préférer `list_iterate()` à `list_getFirst/getNext`
- [ ] Utiliser `based(ptr)` pour accès structure
- [ ] **Ne jamais** modifier liste pendant itération
- [ ] Tester `ptr <> *null` pour fin de boucle

### ✅ Nettoyage

- [ ] Toujours appeler `list_dispose()` ou `list_clear()`
- [ ] Utiliser `on-exit` pour garantie cleanup
- [ ] Tester `<> *null` avant dispose
- [ ] Utiliser `list_clear()` pour réutilisation en boucle

### ✅ Performance

- [ ] Éviter `list_add()` avec position si possible
- [ ] Éviter `list_get(index)` dans loop (préférer iterate)
- [ ] Réutiliser liste avec `list_clear()` quand pertinent
- [ ] Préférer array si taille connue et accès aléatoire

### ✅ Documentation

- [ ] Documenter qui possède pointeur (caller/callee)
- [ ] Spécifier responsabilité cleanup
- [ ] Indiquer si procédure retourne liste nouvelle ou existante

---

## Références

### Fichiers Source

- **Bibliothèque** : `includes/llist/llist_h.rpgle`
- **Implémentation** : Service program `llist`
- **Exemple Réel** : `src/employee/employee.sqlrpgle` (lignes 76, 252, 276)
- **Exemple REST** : `src/employee/employee.rest.sqlrpgle` (lignes 280-295)

### Documents Liés

- **Guide CREST** : `ressources/docs/guides/GUIDE_FRAMEWORK_CREST.md`
- **Conventions Réelles** : `ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md`
- **Guide RPG** : `ressources/docs/guides/guide_rpg_bonnes_pratiques.md`

### Auteur Bibliothèque

- **Mihael Schmidt** : Auteur original llist
- **License** : MIT
- **Repository** : https://github.com/mihael-schmidt/llist (probablement)

---

**📌 Règle d'Or** : Liste = Allocation Dynamique. Toujours nettoyer avec `list_dispose()` dans `on-exit` pour éviter fuites mémoire.

**🎯 Prochaine Étape** : Consulter le **Guide Versioning Service Programs** pour comprendre la stratégie d'évolution des signatures d'export.
