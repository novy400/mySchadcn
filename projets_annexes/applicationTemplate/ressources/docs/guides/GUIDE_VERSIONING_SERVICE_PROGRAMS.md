# Guide Versioning Service Programs
## Stratégie de Versioning et Compatibilité Arrière IBM i

**Version:** 1.0  
**Date:** Janvier 2025  
**Auteur:** Équipe ArchiAPI  
**Source:** Conventions extraites des binding sources réels (`employee.bnd`, `crest.bnd`, `hellosrv.bnd`)

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Concepts Fondamentaux](#concepts-fondamentaux)
3. [Anatomie d'un Binding Source](#anatomie-dun-binding-source)
4. [Stratégies de Versioning](#stratégies-de-versioning)
5. [PGMLVL : Current vs Previous](#pgmlvl--current-vs-previous)
6. [SIGNATURE : Semantic Versioning](#signature--semantic-versioning)
7. [Évolution d'un Service Program](#évolution-dun-service-program)
8. [Patterns de Compatibilité](#patterns-de-compatibilité)
9. [Exemples Réels](#exemples-réels)
10. [Best Practices](#best-practices)

---

## Vue d'Ensemble

### Qu'est-ce qu'un Service Program ?

Un **Service Program** (SRVPGM) sur IBM i est l'équivalent d'une **bibliothèque partagée** (DLL Windows, .so Linux). Il contient des procédures réutilisables par plusieurs programmes.

**Avantages** :
- ✅ **Réutilisation** : Code partagé entre programmes
- ✅ **Maintenance** : Mise à jour centralisée
- ✅ **Performance** : Pas de duplication code
- ✅ **Versioning** : Compatibilité arrière contrôlée

### Problématique du Versioning

**Scenario** :
1. Programme A utilise `employee_search()` du service program EMPLOYEE v1
2. Vous modifiez EMPLOYEE pour ajouter `employee_create()`
3. **Question** : Programme A doit-il être recompilé ?

**Réponse** : **Non**, grâce au **Binding Source** et au **PGMLVL**.

### Le Binding Source (.bnd)

Fichier texte décrivant :
- Quelles procédures sont **exportées** (visibles)
- Quelle **signature** identifie la version
- Quels **niveaux précédents** sont supportés (compatibilité)

---

## Concepts Fondamentaux

### Service Program Lifecycle

```
┌─────────────┐
│ Module RPG  │ (.rpgle)
│ employee    │
└──────┬──────┘
       │ CRTRPGMOD
       ▼
┌─────────────┐
│ Module OBJ  │ (*MODULE)
│ EMPLOYEE    │
└──────┬──────┘
       │ CRTSRVPGM + Binding Source
       ▼
┌─────────────┐
│ Service Prg │ (*SRVPGM)
│ EMPLOYEE    │ SIGNATURE('EMPLOYEE.0.0.1')
└──────┬──────┘
       │ Utilisé par
       ▼
┌─────────────┐
│ Programme   │ (*PGM)
│ EMPREST     │ Bind to EMPLOYEE
└─────────────┘
```

### Deux Types de Liaison

**1. Bind by Reference (Défaut)** :
```
CRTPGM PGM(EMPREST) MODULE(EMPREST) BNDSRVPGM(EMPLOYEE)
```
- Programme enregistre la **SIGNATURE** nécessaire
- Au runtime, OS charge service program avec signature compatible
- **Avantage** : Pas de recompilation si signature compatible

**2. Bind by Copy** :
```
CRTPGM PGM(EMPREST) MODULE(EMPREST) BNDSRVPGM((EMPLOYEE *BINDCPY))
```
- Code copié dans le programme
- **Désavantage** : Pas de mise à jour sans recompilation
- ⚠️ **Rarement utilisé** dans ArchiAPI

### Composants du Versioning

| Composant   | Rôle                                    | Exemple                  |
|-------------|-----------------------------------------|--------------------------|
| **PGMLVL**  | Niveau de version exportée              | `*CURRENT`, `*PRV`       |
| **SIGNATURE** | Identifiant unique version            | `'EMPLOYEE.0.0.3'`       |
| **EXPORT**  | Liste procédures exportées              | `SYMBOL('employee_search')` |

---

## Anatomie d'un Binding Source

### Structure Minimale

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.1')
  EXPORT SYMBOL('procedure1')
  EXPORT SYMBOL('procedure2')
ENDPGMEXP
```

**Explications** :
- `STRPGMEXP` : Début bloc export
- `PGMLVL(*CURRENT)` : Niveau actuel
- `SIGNATURE('MODULE.0.0.1')` : Identifiant version
- `EXPORT SYMBOL('...')` : Procédure exportée
- `ENDPGMEXP` : Fin bloc export

### Structure avec Compatibilité

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.2')
  EXPORT SYMBOL('procedure1')
  EXPORT SYMBOL('procedure2')
  EXPORT SYMBOL('procedure3')  // Nouvelle
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.1')
  EXPORT SYMBOL('procedure1')
  EXPORT SYMBOL('procedure2')
ENDPGMEXP
```

**Explications** :
- **PGMLVL(\*CURRENT)** : Version actuelle (0.0.2) avec 3 procédures
- **PGMLVL(\*PRV)** : Version précédente (0.0.1) avec 2 procédures
- Programmes liés à 0.0.1 fonctionnent toujours !

---

## Stratégies de Versioning

### Stratégie 1: Semantic Versioning (Recommandé ArchiAPI)

**Format** : `MODULE.MAJOR.MINOR.PATCH`

**Règles** :
- **MAJOR** : Breaking changes (incompatible)
- **MINOR** : Nouvelles fonctionnalités (compatible)
- **PATCH** : Corrections bugs (compatible)

**Exemples** :
```bnd
SIGNATURE('EMPLOYEE.0.0.1')  // Version initiale
SIGNATURE('EMPLOYEE.0.0.2')  // + employee_getByID (compatible)
SIGNATURE('EMPLOYEE.0.0.3')  // + employee_create (compatible)
SIGNATURE('EMPLOYEE.0.1.0')  // + nouvelles fonctionnalités majeures
SIGNATURE('EMPLOYEE.1.0.0')  // Refonte complète (incompatible)
```

### Stratégie 2: Date-Based Versioning

**Format** : `MODULE.YYYYMMDD.HH`

**Exemple** :
```bnd
SIGNATURE('EMPLOYEE.20250115.01')
SIGNATURE('EMPLOYEE.20250115.02')
```

**⚠️ Moins Lisible** : Difficile de savoir ce qui change.

### Stratégie 3: Simple Increment

**Format** : `MODULE_VERSION`

**Exemple** :
```bnd
SIGNATURE('HELLO_0.0.1')
SIGNATURE('HELLO_0.0.2')
```

**⚠️ Limitation** : Pas de distinction MAJOR/MINOR/PATCH.

---

## PGMLVL : Current vs Previous

### PGMLVL(\*CURRENT)

**Définition** : Niveau de version **actuel** du service program.

**Utilisation** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_display')
  EXPORT SYMBOL('employee_isValid')
ENDPGMEXP
```

**Comportement** :
- Nouveau programme compile → lie vers signature **0.0.3**
- Exécution → charge service program avec signature **0.0.3**

### PGMLVL(\*PRV)

**Définition** : Niveau de version **précédent** supporté (compatibilité arrière).

**Utilisation** :
```bnd
STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.2')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Comportement** :
- Ancien programme lié à **0.0.1** → charge service program, utilise exports **0.0.1**
- Ancien programme lié à **0.0.2** → charge service program, utilise exports **0.0.2**
- **Aucune recompilation nécessaire !**

### Règles PGMLVL

**1. Un seul \*CURRENT** :
```bnd
// ✅ BON : Un seul *CURRENT
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('V3')
  ...
ENDPGMEXP
STRPGMEXP PGMLVL(*PRV) SIGNATURE('V2')
  ...
ENDPGMEXP
```

**2. Ordre Chronologique** :
```bnd
// ✅ BON : *CURRENT d'abord, puis *PRV par ordre décroissant
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('0.0.3')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('0.0.2')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('0.0.1')
```

**3. Exports Cumulatifs** :
```bnd
// ✅ BON : *CURRENT contient TOUS les exports
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('0.0.2')
  EXPORT SYMBOL('func1')
  EXPORT SYMBOL('func2')  // Nouveau
ENDPGMEXP
STRPGMEXP PGMLVL(*PRV) SIGNATURE('0.0.1')
  EXPORT SYMBOL('func1')  // Ancien subset
ENDPGMEXP
```

---

## SIGNATURE : Semantic Versioning

### Format Standard ArchiAPI

**Pattern** : `'RESOURCENAME.MAJOR.MINOR.PATCH'`

**Exemples Réels** :
```bnd
SIGNATURE('EMPLOYEE.0.0.3')  // Service program Employee v0.0.3
SIGNATURE('CREST.0.0.1')     // Service program CREST v0.0.1
SIGNATURE('EMPREST.0.0.1')   // Service program Employee REST v0.0.1
SIGNATURE('EMPROUTE.0.0.1')  // Service program Employee Route v0.0.1
```

### Quand Incrémenter ?

**PATCH (0.0.X)** :
- ✅ Correction bug sans changer interface
- ✅ Optimisation performance
- ✅ Refactoring interne
- ❌ **Aucune** modification signature/exports

**Exemple** :
```rpg
// 0.0.1 → 0.0.2 : Correction bug
dcl-proc employee_search export;
  // Bug fix : Mauvaise gestion offset pagination
  lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
  // Avant : lOffset = pContext.pagination.numPage * pContext.pagination.perPage; (BUG)
end-proc;
```

**MINOR (0.X.0)** :
- ✅ Ajout nouvelle procédure exportée
- ✅ Ajout paramètre optionnel existant
- ✅ Extension fonctionnalité sans casser ancien code
- ❌ Modification signature procédure existante

**Exemple** :
```bnd
// 0.0.2 → 0.1.0 : Ajout procedures
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.1.0')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_create')    // NOUVEAU
  EXPORT SYMBOL('employee_update')    // NOUVEAU
  EXPORT SYMBOL('employee_delete')    // NOUVEAU
ENDPGMEXP
```

**MAJOR (X.0.0)** :
- ✅ Suppression procédure exportée
- ✅ Modification signature procédure existante
- ✅ Changement comportement breaking
- ⚠️ **BREAKING CHANGE** : Recompilation clients obligatoire

**Exemple** :
```rpg
// 0.X.Y → 1.0.0 : Breaking change
// Avant (0.X.Y)
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount int(10);  // Paramètre simple
  end-pi;
end-proc;

// Après (1.0.0) : Changement type paramètre
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount likeds(CMAGIC_totalCount);  // Nouveau type !
  end-pi;
end-proc;
```

### Quotes vs No Quotes

**Avec Quotes (Recommandé)** :
```bnd
SIGNATURE('EMPLOYEE.0.0.3')  // String littéral
```

**Sans Quotes (Ancien Style)** :
```bnd
SIGNATURE(EMPLOYEE.0.0.3)    // Identifiant, limité à 30 chars
```

**⚠️ Recommandation** : Toujours utiliser **quotes** pour flexibilité.

---

## Évolution d'un Service Program

### Exemple Réel : Employee Service Program

**Version 0.0.1** (Initial) :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Fonctionnalité** : Recherche seulement.

---

**Version 0.0.2** (+ Read by ID) :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.2')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')  // AJOUT
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Changement** :
- ✅ Ajout `employee_getByID()` → compatible
- ✅ PATCH increment (0.0.1 → 0.0.2)
- ✅ Ancien bloc \*PRV pour compatibilité 0.0.1

**Programmes Existants** :
- Programme lié à 0.0.1 → fonctionne toujours (utilise seulement `employee_search`)
- Nouveau programme → peut utiliser `employee_getByID`

---

**Version 0.0.3** (+ CRUD Complet) :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_update')    // AJOUT
  EXPORT SYMBOL('employee_delete')    // AJOUT
  EXPORT SYMBOL('employee_create')    // AJOUT
  EXPORT SYMBOL('employee_display')   // AJOUT
  EXPORT SYMBOL('employee_isValid')   // AJOUT
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.2')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Changement** :
- ✅ Ajout 5 procédures CRUD → compatible
- ✅ PATCH increment (0.0.2 → 0.0.3)
- ✅ Deux blocs \*PRV pour compatibilité 0.0.2 et 0.0.1

**Programmes Existants** :
- Programme lié à 0.0.1 → fonctionne (utilise `employee_search`)
- Programme lié à 0.0.2 → fonctionne (utilise `employee_search` + `employee_getByID`)
- Nouveau programme → accès complet CRUD

---

### Timeline Évolution

```
Version 0.0.1        Version 0.0.2              Version 0.0.3
─────────────        ─────────────              ─────────────
┌─────────┐          ┌─────────┐                ┌─────────┐
│ search  │    →     │ search  │         →      │ search  │
└─────────┘          │ getByID │                │ getByID │
                     └─────────┘                │ create  │
                                                │ update  │
                                                │ delete  │
                                                │ display │
                                                │ isValid │
                                                └─────────┘

Programs liés 0.0.1: ✅ Fonctionnent toujours
Programs liés 0.0.2: ✅ Fonctionnent toujours
New programs:        ✅ Utilisent 0.0.3
```

---

## Patterns de Compatibilité

### Pattern 1: Ajout Procédure (Compatible)

**Scenario** : Ajouter `employee_archive()` à EMPLOYEE v0.0.3.

**Binding Source** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.4')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_display')
  EXPORT SYMBOL('employee_isValid')
  EXPORT SYMBOL('employee_archive')  // NOUVEAU
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_display')
  EXPORT SYMBOL('employee_isValid')
ENDPGMEXP

// Versions 0.0.2 et 0.0.1 omises pour lisibilité
```

**Impact** :
- ✅ Programmes existants fonctionnent sans recompilation
- ✅ Incrément PATCH (0.0.3 → 0.0.4)

---

### Pattern 2: Ajout Paramètre Optionnel (Compatible)

**Scenario** : Ajouter paramètre `options(*nopass)` à `employee_search()`.

**Code** :
```rpg
// Avant (0.0.3)
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
end-proc;

// Après (0.0.4) : Ajout paramètre optionnel
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pOptions likeds(search_options_t) const options(*nopass);  // NOUVEAU
  end-pi;
  
  // Gestion paramètre optionnel
  if (%parms() >= 3);
    // Utiliser pOptions
  endif;
end-proc;
```

**Binding Source** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.4')
  EXPORT SYMBOL('employee_search')  // Même nom, signature étendue
  // ... autres exports
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')  // Ancienne signature
  // ... autres exports
ENDPGMEXP
```

**Impact** :
- ✅ Programmes existants appellent avec 2 paramètres → fonctionnent
- ✅ Nouveaux programmes peuvent passer 3 paramètres
- ✅ Incrément PATCH (0.0.3 → 0.0.4)

**⚠️ Important** : Paramètre DOIT être `options(*nopass)`.

---

### Pattern 3: Modification Signature (Breaking)

**Scenario** : Changer type retour `employee_search()` de `pointer` à `likeds(result_t)`.

**Code** :
```rpg
// Avant (0.0.3)
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  // ...
  return lList;
end-proc;

// Après (1.0.0) : Changement type retour
dcl-proc employee_search export;
  dcl-pi *n likeds(search_result_t);  // BREAKING CHANGE
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  // ...
  return lResult;
end-proc;
```

**Binding Source** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.1.0.0')
  EXPORT SYMBOL('employee_search')  // Nouvelle signature incompatible
  EXPORT SYMBOL('employee_getByID')
  // ... autres exports
ENDPGMEXP

// ⚠️ PAS de PGMLVL(*PRV) pour 0.X.Y
// Compatibilité cassée volontairement
```

**Impact** :
- ❌ Programmes existants doivent être **recompilés**
- ✅ Incrément MAJOR (0.X.Y → 1.0.0)
- ⚠️ Communication aux utilisateurs nécessaire

**Alternative Compatible** :
```rpg
// Garder ancienne procédure + nouvelle
dcl-proc employee_search export;
  dcl-pi *n pointer;
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  // Wrapper vers nouvelle implémentation
  return employee_searchV2(pContext : pTotalCount).list;
end-proc;

dcl-proc employee_searchV2 export;  // Nouvelle API
  dcl-pi *n likeds(search_result_t);
    pContext likeds(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
  end-pi;
  // Nouvelle implémentation
end-proc;
```

**Binding Source Compatible** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.1.0')
  EXPORT SYMBOL('employee_search')     // Ancienne API (wrapper)
  EXPORT SYMBOL('employee_searchV2')   // Nouvelle API
  // ... autres exports
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  // ... autres exports
ENDPGMEXP
```

---

### Pattern 4: Suppression Procédure (Breaking)

**Scenario** : Retirer `employee_display()` devenue obsolète.

**Binding Source** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.1.0.0')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  // ⚠️ employee_display supprimée
  EXPORT SYMBOL('employee_isValid')
ENDPGMEXP

// PAS de PGMLVL(*PRV) incluant employee_display
```

**Impact** :
- ❌ Programmes utilisant `employee_display()` → erreur au chargement
- ✅ Incrément MAJOR (0.X.Y → 1.0.0)

**Alternative Deprecation** :
```rpg
// Version 0.1.0 : Marquer deprecated
dcl-proc employee_display export;
  dcl-pi *n;
    // ...
  end-pi;
  
  CKOOL_logWarning('employee_display is DEPRECATED, use employee_getByID');
  // Implémentation minimaliste ou wrapper
end-proc;

// Version 1.0.0 : Suppression effective
// (après période transition)
```

---

## Exemples Réels

### Exemple 1: CREST Framework (Single Version)

**Fichier** : `src/crest/crest.bnd`

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE(CREST.0.0.1)
  EXPORT SYMBOL(CREST_addHeaders)
  EXPORT SYMBOL(CREST_initRestRequest)
  EXPORT SYMBOL(CREST_initSimpleRestRequest)
  EXPORT SYMBOL(CREST_initWriteRestRequest)
  EXPORT SYMBOL(CREST_errorsToJson)
  EXPORT SYMBOL(CREST_simpleError)
ENDPGMEXP
```

**Analyse** :
- ✅ Version initiale stable
- ✅ Pas de \*PRV (première version)
- ✅ 6 procédures exportées
- ⚠️ **Prochaine version** devra ajouter \*PRV pour compatibilité

**Évolution Possible** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE(CREST.0.0.2)
  EXPORT SYMBOL(CREST_addHeaders)
  EXPORT SYMBOL(CREST_initRestRequest)
  EXPORT SYMBOL(CREST_initSimpleRestRequest)
  EXPORT SYMBOL(CREST_initWriteRestRequest)
  EXPORT SYMBOL(CREST_errorsToJson)
  EXPORT SYMBOL(CREST_simpleError)
  EXPORT SYMBOL(CREST_parseJsonInput)  // NOUVEAU
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE(CREST.0.0.1)
  EXPORT SYMBOL(CREST_addHeaders)
  EXPORT SYMBOL(CREST_initRestRequest)
  EXPORT SYMBOL(CREST_initSimpleRestRequest)
  EXPORT SYMBOL(CREST_initWriteRestRequest)
  EXPORT SYMBOL(CREST_errorsToJson)
  EXPORT SYMBOL(CREST_simpleError)
ENDPGMEXP
```

---

### Exemple 2: Employee (Three Versions)

**Fichier** : `src/employee/employee.bnd`

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_update')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_display')
  EXPORT SYMBOL('employee_isValid')
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.2')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_getByID')
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.1')
  EXPORT SYMBOL('employee_search')
ENDPGMEXP
```

**Analyse** :
- ✅ Trois niveaux de compatibilité
- ✅ Évolution progressive : 1 → 2 → 7 procédures
- ✅ Incrément PATCH à chaque ajout (compatible)

**Timeline** :
- **0.0.1** : Recherche seulement
- **0.0.2** : + Lecture par ID
- **0.0.3** : + CRUD complet (Create/Update/Delete/Display/Validate)

**Programmes Compatibles** :
```
Programme A compilé avec 0.0.1 → ✅ Fonctionne avec 0.0.3
Programme B compilé avec 0.0.2 → ✅ Fonctionne avec 0.0.3
Programme C compilé avec 0.0.3 → ✅ Fonctionne avec 0.0.3
```

---

### Exemple 3: Hello Service (Two Versions)

**Fichier** : `src/qsrvsrc/hellosrv.bnd`

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('HELLO_0.0.2')
  EXPORT SYMBOL('HELLO_proc2')
  EXPORT SYMBOL('HELLO_proc1')
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('HELLO_0.0.1')
  EXPORT SYMBOL('HELLO_proc1')
ENDPGMEXP
```

**Analyse** :
- ✅ Deux niveaux : 0.0.1 (1 proc) → 0.0.2 (2 procs)
- ⚠️ **Ordre exports** : proc2 avant proc1 (pas critique mais inhabituel)
- ✅ Compatibilité 0.0.1 préservée

**Convention Recommandée** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('HELLO_0.0.2')
  EXPORT SYMBOL('HELLO_proc1')  // Ordre chronologique d'ajout
  EXPORT SYMBOL('HELLO_proc2')
ENDPGMEXP
```

---

### Exemple 4: Employee REST (Single Version)

**Fichier** : `src/employee/employee.rest.bnd`

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPREST.0.0.1')
  EXPORT SYMBOL('employee_getlist_rest')
  EXPORT SYMBOL('employee_getone_rest')
  EXPORT SYMBOL('employee_create_rest')
  EXPORT SYMBOL('employee_update_rest')
  EXPORT SYMBOL('employee_delete_rest')
ENDPGMEXP
```

**Analyse** :
- ✅ Version initiale complète (5 handlers REST)
- ✅ Pas de \*PRV (première version)
- ✅ Naming cohérent : `_rest` suffix pour handlers HTTP

**Évolution Future** :
```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPREST.0.0.2')
  EXPORT SYMBOL('employee_getlist_rest')
  EXPORT SYMBOL('employee_getone_rest')
  EXPORT SYMBOL('employee_create_rest')
  EXPORT SYMBOL('employee_update_rest')
  EXPORT SYMBOL('employee_delete_rest')
  EXPORT SYMBOL('employee_archive_rest')  // NOUVEAU
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPREST.0.0.1')
  EXPORT SYMBOL('employee_getlist_rest')
  EXPORT SYMBOL('employee_getone_rest')
  EXPORT SYMBOL('employee_create_rest')
  EXPORT SYMBOL('employee_update_rest')
  EXPORT SYMBOL('employee_delete_rest')
ENDPGMEXP
```

---

### Exemple 5: Employee Route (Single Version)

**Fichier** : `src/employee/employee.route.bnd`

```bnd
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPROUTE.0.0.1')
  EXPORT SYMBOL('employee_setupRoutes')
  EXPORT SYMBOL('employee_registerAPI')
ENDPGMEXP
```

**Analyse** :
- ✅ Deux procédures setup/register
- ✅ Pas de \*PRV (première version)
- ⚠️ **Stabilité attendue** : Setup routes change rarement

**Évolution Rare** :
```bnd
// Hypothétique 0.0.2 : Ajout configuration avancée
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPROUTE.0.0.2')
  EXPORT SYMBOL('employee_setupRoutes')
  EXPORT SYMBOL('employee_registerAPI')
  EXPORT SYMBOL('employee_configureMiddleware')  // NOUVEAU
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPROUTE.0.0.1')
  EXPORT SYMBOL('employee_setupRoutes')
  EXPORT SYMBOL('employee_registerAPI')
ENDPGMEXP
```

---

## Best Practices

### ✅ Toujours Ajouter PGMLVL(\*PRV) à partir de v2

```bnd
// ❌ MAUVAIS : Version 0.0.2 sans *PRV
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.2')
  EXPORT SYMBOL('func1')
  EXPORT SYMBOL('func2')
ENDPGMEXP

// ✅ BON : Compatibilité 0.0.1 préservée
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.2')
  EXPORT SYMBOL('func1')
  EXPORT SYMBOL('func2')
ENDPGMEXP
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.1')
  EXPORT SYMBOL('func1')
ENDPGMEXP
```

### ✅ Semantic Versioning Strict

```bnd
// ✅ BON : Incrément cohérent
0.0.1 → 0.0.2  // Ajout procédure compatible
0.0.2 → 0.0.3  // Ajout procédures compatible
0.0.3 → 0.1.0  // Ajout feature majeure compatible
0.1.0 → 1.0.0  // Breaking change

// ❌ MAUVAIS : Incréments incohérents
0.0.1 → 0.0.5  // Pourquoi sauter 2, 3, 4 ?
0.0.5 → 1.0.0  // Breaking sans 0.1.0 ?
```

### ✅ Documenter Breaking Changes

**Dans Code** :
```rpg
///
// employee_search - Search employees
//
// @version 1.0.0
// @breaking Changed return type from pointer to search_result_t
// @since 0.0.1
///
dcl-proc employee_search export;
  // ...
end-proc;
```

**Dans CHANGELOG.md** :
```markdown
# Changelog

## [1.0.0] - 2025-01-15
### Breaking Changes
- `employee_search()`: Changed return type from `pointer` to `search_result_t`
- Programs using this procedure MUST be recompiled

## [0.0.3] - 2025-01-10
### Added
- `employee_create()`: Create new employee
- `employee_update()`: Update existing employee
- `employee_delete()`: Delete employee
```

### ✅ Limiter Nombre de \*PRV

```bnd
// ❌ MAUVAIS : Trop de versions maintenues
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.10')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.9')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.8')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.7')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.6')
// ... maintenance cauchemar

// ✅ BON : 2-3 versions précédentes maximum
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.10')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.9')
STRPGMEXP PGMLVL(*PRV) SIGNATURE('MODULE.0.0.8')
// Versions < 0.0.8 nécessitent recompilation
```

**Règle** : Maximum 2-3 \*PRV, forcer recompilation après.

### ✅ Ordre Exports Chronologique

```bnd
// ✅ BON : Ordre d'ajout historique
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')    // v0.0.1
  EXPORT SYMBOL('employee_getByID')   // v0.0.2
  EXPORT SYMBOL('employee_create')    // v0.0.3
  EXPORT SYMBOL('employee_update')    // v0.0.3
  EXPORT SYMBOL('employee_delete')    // v0.0.3
ENDPGMEXP

// ❌ MOINS BON : Ordre alphabétique (perd historique)
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_create')
  EXPORT SYMBOL('employee_delete')
  EXPORT SYMBOL('employee_getByID')
  EXPORT SYMBOL('employee_search')
  EXPORT SYMBOL('employee_update')
ENDPGMEXP
```

**Avantage** : Facilite compréhension évolution.

### ✅ Tester Compatibilité Avant Release

**Script Test** :
```bash
# Compiler programme avec ancienne version
CRTSRVPGM SRVPGM(EMPLOYEE) SRCFILE(QSRVSRC) SRCMBR(EMPLOYEE) BNDDIR(MYBNDDIR)

# Compiler programme test avec ancienne signature
CRTPGM PGM(TESTV1) MODULE(TESTV1) BNDSRVPGM((EMPLOYEE *IMMED))

# Recréer service program avec nouvelle version
CRTSRVPGM SRVPGM(EMPLOYEE) SRCFILE(QSRVSRC) SRCMBR(EMPLOYEE) BNDDIR(MYBNDDIR) REPLACE(*YES)

# Tester programme ancien avec nouveau service program
CALL TESTV1
# → Doit fonctionner si compatibilité préservée
```

### ✅ Convention Naming Signature

**Pattern ArchiAPI** :
```bnd
// ✅ BON : Préfixe module uppercase + version
SIGNATURE('EMPLOYEE.0.0.3')
SIGNATURE('CREST.0.0.1')
SIGNATURE('EMPREST.0.0.1')

// ❌ INCONSISTENT
SIGNATURE('employee_0.0.3')  // Lowercase
SIGNATURE('EMP.v3')          // Format différent
SIGNATURE('20250115_EMP')    // Date-based
```

**Règle** : `'MODULENAME.MAJOR.MINOR.PATCH'`

### ✅ Ne Jamais Réutiliser Signature

```bnd
// ❌ INTERDIT : Réutiliser 0.0.2 après modification
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.2')
  EXPORT SYMBOL('func1')
  EXPORT SYMBOL('func2')
  EXPORT SYMBOL('func3')  // AJOUT mais signature inchangée !
ENDPGMEXP

// ✅ BON : Nouvelle signature pour changement
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('MODULE.0.0.3')
  EXPORT SYMBOL('func1')
  EXPORT SYMBOL('func2')
  EXPORT SYMBOL('func3')  // Nouvelle version = nouvelle signature
ENDPGMEXP
```

**Danger** : Cache IBM i peut garder ancienne version en mémoire.

---

## Workflow Pratique

### Étape 1: Planifier Changement

**Questions** :
1. Ajout procédure ? → PATCH increment
2. Modification signature ? → MAJOR increment
3. Suppression procédure ? → MAJOR increment
4. Bug fix interne ? → PATCH increment (sans changer .bnd)

### Étape 2: Modifier Code RPG

```rpg
// Ajouter nouvelle procédure
dcl-proc employee_archive export;
  dcl-pi *n ind;
    pId likeds(employee_detail_t.id) const;
  end-pi;
  // Implémentation
end-proc;
```

### Étape 3: Mettre à Jour Binding Source

```bnd
// Avant
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  // ... autres exports
ENDPGMEXP

// Après
STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('EMPLOYEE.0.0.4')
  EXPORT SYMBOL('employee_search')
  // ... autres exports
  EXPORT SYMBOL('employee_archive')  // NOUVEAU
ENDPGMEXP

STRPGMEXP PGMLVL(*PRV) SIGNATURE('EMPLOYEE.0.0.3')
  EXPORT SYMBOL('employee_search')
  // ... autres exports (sans employee_archive)
ENDPGMEXP
```

### Étape 4: Mettre à Jour Prototype (.rpgleinc)

```rpg
// includes/employee.rpgleinc

///
// Archive employee by ID
//
// @param id Employee ID to archive
// @return *ON if archived successfully, *OFF otherwise
// @since 0.0.4
///
dcl-pr employee_archive ind extproc(*dclcase);
  id likeds(employee_detail_t.id) const;
end-pr;
```

### Étape 5: Compiler

```bash
# Avec makei (BOB)
makei build -l src/employee

# Ou manuel
CRTRPGMOD MODULE(EMPLOYEE) SRCFILE(QRPGLESRC) SRCMBR(EMPLOYEE)
CRTSRVPGM SRVPGM(EMPLOYEE) MODULE(EMPLOYEE) SRCFILE(QSRVSRC) SRCMBR(EMPLOYEE)
```

### Étape 6: Tester Compatibilité

```bash
# Programme ancien (lié à 0.0.3)
CALL OLDPROGRAM
# → Doit fonctionner sans modification

# Programme nouveau (lié à 0.0.4)
CALL NEWPROGRAM
# → Peut utiliser employee_archive()
```

### Étape 7: Documenter

**CHANGELOG.md** :
```markdown
## [0.0.4] - 2025-01-15
### Added
- `employee_archive()`: Archive employee by ID

### Compatible
- Programs compiled with 0.0.3 remain compatible
```

---

## Checklist Versioning

### ✅ Avant Modification

- [ ] Identifier type changement (PATCH/MINOR/MAJOR)
- [ ] Vérifier impact compatibilité
- [ ] Planifier incrément version
- [ ] Documenter changement prévu

### ✅ Modification Binding Source

- [ ] Incrémenter SIGNATURE selon semantic versioning
- [ ] Ajouter PGMLVL(\*PRV) avec ancienne version
- [ ] Copier exports ancienne version dans \*PRV
- [ ] Ajouter nouveaux exports dans \*CURRENT uniquement
- [ ] Vérifier ordre chronologique exports

### ✅ Modification Code

- [ ] Ajouter procédure dans .sqlrpgle
- [ ] Ajouter prototype dans .rpgleinc
- [ ] Documenter `@since` version
- [ ] Marquer `@deprecated` si obsolète

### ✅ Compilation

- [ ] Compiler module RPG
- [ ] Créer service program avec binding source
- [ ] Vérifier pas d'erreurs
- [ ] Tester chargement service program

### ✅ Tests Compatibilité

- [ ] Compiler programme test avec ancienne signature
- [ ] Exécuter programme test avec nouveau service program
- [ ] Vérifier comportement attendu
- [ ] Tester nouveau code avec nouvelle signature

### ✅ Documentation

- [ ] Mettre à jour CHANGELOG.md
- [ ] Documenter breaking changes si MAJOR
- [ ] Mettre à jour README si API change
- [ ] Notifier utilisateurs si breaking

---

## Références

### Fichiers Source

- **Employee** : `src/employee/employee.bnd` (3 versions)
- **CREST** : `src/crest/crest.bnd` (1 version)
- **Employee REST** : `src/employee/employee.rest.bnd` (1 version)
- **Employee Route** : `src/employee/employee.route.bnd` (1 version)
- **Hello** : `src/qsrvsrc/hellosrv.bnd` (2 versions)

### Documents Liés

- **Guide CREST** : `ressources/docs/guides/GUIDE_FRAMEWORK_CREST.md`
- **Guide llist** : `ressources/docs/guides/GUIDE_LISTE_CHAINEE_LLIST.md`
- **Conventions** : `ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md`

### Documentation IBM i

- **CRTSRVPGM** : Create Service Program Command
- **Binding Source** : ILE Concepts Manual
- **Program Versioning** : ILE RPG Programmer's Guide

---

**📌 Règle d'Or** : Compatibilité arrière = PGMLVL(\*PRV) + SIGNATURE correcte. Ne jamais casser ancien code sans incrément MAJOR.

**🎯 Prochaine Étape** : Consulter le **Guide Mapping API ↔ SQL** pour comprendre la configuration des champs supportés (filtres/tri dynamiques).
