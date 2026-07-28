

### **Product Requirements Document (PRD) - CMagic MVP**

**Titre du Projet :** CMagic - Générateur d'Applications Modernes pour IBM i

**Version :** 1.0 (MVP)

**Projet Fil Rouge :** Gestion des Clients et des Commandes

---

### 1. Vision & Scope

**1.1. Vision**
Fournir un outil de développement (DSL + Générateur) qui permet de décrire une application de gestion en termes métier de haut niveau et de générer un socle applicatif robuste, standardisé et maintenable en RPG ILE moderne sur IBM i.

**1.2. Scope du MVP**
Le périmètre du MVP est de prouver la viabilité du concept en générant l'ensemble des artefacts nécessaires pour la gestion de deux entités liées : une entité "maître" simple (`Customer`) et une entité "transactionnelle" avec un cycle de vie (`CustomerOrder`).

**1.3. Objectifs Mesurables du MVP (Recentrés)**
- ✅ Parser correctement la syntaxe DSL CMagic (.cmagic files)
- ✅ Générer les structures de données RPG (copybooks .rpgleinc)
- ✅ Générer les définitions de tables SQL (DDL)
- ✅ Générer les modules de service (SRVPGM) avec pattern généré simple
- ✅ Supporter les relations entre entités (clés étrangères)
- ✅ Implémenter les opérations CRUD de base
- ✅ Générer les écrans de travail (Dspf et WORK_WITH pattern)
- ✅ Supporter un workflow simple avec machine à états
- ✅ Fournir un CLI basique pour la génération

**1.4. Non-Scope du MVP (Étendu)**
- Interface utilisateur web/moderne (focus sur RPG/IBM i natif)
- Intégration avec des APIs externes
- Gestion avancée des droits et sécurité
- Performance optimization
- Migration de données existantes
- **Git-Based Extensibility avec merge intelligent** (reporté v2.0)
- **Annotations CMAGIC avancées** (reporté v2.0)
- **Interface de résolution de conflits** (reporté v2.0)

---

### 2. Concepts Clés et Syntaxe du DSL CMagic

Le DSL permet de décrire une application de manière déclarative. Voici les concepts clés retenus :

**2.1. Concepts Fondamentaux**
Le DSL doit abstraire la persistance**
*   L'**`entity`** est la description canonique du concept métier.
*   Des **annotations `@source` optionnelles** peuvent être utilisées pour documenter/piloter l'origine des données, mais le générateur ne les utilise que pour des optimisations. Par défaut, il suppose une implémentation manuelle.
    *   `@source(db: 'TABLE.COLUMN')` : Le champ vient d'une table Db2. Le générateur *peut* s'en servir pour pré-remplir la logique SQL.
    *   `@source(api: 'ServiceName.method')` : Le champ vient d'un service. Le générateur produit un squelette vide.
    *   `@source(legacy: 'PGMNAME')` : Le champ est récupéré via un appel à un programme legacy.
*   Si aucune annotation `@source` n'est présente, le générateur part du principe que l'entité est entièrement persistée dans une table Db2 qui porte son nom (`CUSTOMER` -> `CUSTOMER`). C'est le cas par défaut pour le MVP.

**2.2. Stratégie d'Extensibilité Moderne**

Pour le MVP, nous adoptons directement l'approche la plus élégante et maintenable :

**MVP (v1.0)** : Fichier unifié avec zones protégées et convention _local  
**v2.0** : Git-based avec annotations CMAGIC avancées et merge intelligent

### **Approche MVP : Fichier Unifié avec Convention _local**

Notre stratégie principale qui combine le meilleur des deux mondes :

*   **Fichier service unifié** (`ENTITY_S.sqlrpgle`) : Code généré + local dans le même fichier
*   **Convention _local** : `entity_*` (API publique) vs `entity_*_local` (implémentation locale)
*   **Zones protégées** : Délimitation claire entre code généré et local
*   **Contrôle d'exposition** : Granularité fine des procédures exportées

**Exemple avec fichier unifié :**
```rpgle
**FREE
// CUSTOMER_S.sqlrpgle - Service unifié

/copy CUSTOMER_H

// ========================================
// API PUBLIQUE - PROCÉDURES EXPORTÉES
// ========================================

// Convention entity_* pour les APIs publiques
DCL-PROC customer_getByID EXPORT;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  // Validation générée
  IF id <= 0;
    RETURN *NULL;
  ENDIF;
  
  // Délégation vers l'implémentation locale
  RETURN customer_getByID_local(id);
END-PROC;

// ========================================
// ZONE MANUELLE - PRÉSERVÉE
// ========================================
// [CMAGIC:MANUAL_START]

// Convention entity_*_local pour les implémentations locales (non exportées)
DCL-PROC customer_getByID_local;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(Customer_detail_t);
  
  // Implémentation manuelle du développeur
  EXEC SQL 
    SELECT ID, NAME, ADDR_LIGNE1, ADDR_VILLE
    INTO :result.id, :result.name, :result.address.ligne1, :result.address.ville
    FROM CUSTOMERP 
    WHERE ID = :id;
  
  RETURN result;
END-PROC;

// [CMAGIC:MANUAL_END]
```

**Avantages de l'approche unifiée :**
- ✅ **Namespace RPG** : Respect des conventions `Entity_*` (public) vs `Entity_*_local` (interne)
- ✅ **Cohésion** : Un seul fichier par entité à maintenir
- ✅ **Contrôle d'exposition** : Granularité fine des procédures exportées
- ✅ **Zones protégées** : Délimitation claire du code manuel
- ✅ **Migration facile** : Évolution naturelle depuis le pattern double couche

**Note pour la roadmap :** Cette approche moderne du MVP prépare directement l'évolution vers le Git-Based Extensibility v2.0, sans étape intermédiaire.
**2.1. Syntaxe du DSL CMagic**
Le DSL CMagic est conçu pour être simple et intuitif. Voici les principales constructions syntaxiques
*   **`import` : Gestion des Dépendances**
    *   **Rôle :** Permet à un fichier de réutiliser les définitions (`Entity`, `Struct`, `Enum`) d'un autre fichier.
    *   **Syntaxe :** `import './chemin/vers/autre_fichier.cmagic'`
    *   **Exemple :** `import './commons.cmagic'`

*   **`entity` : Le Modèle Métier**
    *   **Rôle :** Décrit la structure du concept métier. 
    *   **Syntaxe :** `entity Nom { champ: Type(args) modifiers... }`
    *   **Annotations supportées :**
        -   `@source pour spécifier la provenance d'un champ d'une entité.
    ```jdl
    entity Customer {
        id: Int required, // @source(db: 'CUSTOMERP.CUSID')
        name: String(80), // @source(db: 'CUSTOMERP.CUSNAM')
        creditStatus: String(20) // @source(api: 'CreditCheckService.getStatus')
    }
    ```



*   **`struct` : Le Type de Données Composite**
    *   **Rôle :** Regroupe des champs pour créer un type réutilisable (ex: clé composite, adresse).
    *   **Syntaxe :** `struct Nom { champ: Type... }`
    *   **Utilisation :** Peut être utilisé comme type de champ dans une entity
    ```jdl
    struct Address {
        ligne1: String(50),
        codePostal: String(10),
        ville: String(50)
    }
    entity Customer {
    ...
    address: Address,
    creationDate: Date
    }
    ```


*   **`enum` : La Liste de Valeurs**
    *   **Rôle :** Définit un ensemble de valeurs constantes nommées (ex: statuts, catégories).
    *   **Syntaxe :** `enum Nom { VALEUR1, VALEUR2 }`
    *   **Génération :** Produit des constantes RPG et des contraintes SQL CHECK
    ```jdl
    enum OrderStatus {
        DRAFT, VALIDATED, SHIPPED, CANCELLED
    }
    entity CustomerOrder {
        ...,
        status: OrderStatus required default(DRAFT)
    }
    ```



*   **`view` : Le Data Transfer Object (DTO)**
    *   **Rôle :** Définit une projection spécifique d'une `entity` pour un cas d'usage (API, écran). Assure la séparation des préoccupations et la sécurité des données.
    *   **Syntaxe :** `view NomVue for NomEntite { champ1, champ2 }`
    *   **Fonctionnalités :** Support des champs imbriqués (ex: `address.ville`)
    ```jdl
    // Vue pour la liste des commandes
    view OrderListItem for CustomerOrder {
    orderId,
    orderDate,
    customer.name, // On peut "aplatir" la relation dans le DTO
    status,
    totalAmount
    }
      ```
*   **`operations` : Le Comportement Standard (CRUD)**
    *   **Rôle :** Déclare les opérations standard (CRUD) et l'écran de travail (`WORK_WITH`) pour une entité.
    *   **Syntaxe :** `operations for NomEntite { CREATE, CHANGE, DELETE, DISPLAY, WORK_WITH { ... } }`
    *   **Génération :** Produit les procédures de service et les écrans associés
    ```jdl
    operations for Customer {
        CREATE, CHANGE, DELETE, DISPLAY,
        WORK_WITH returns CustomerListItem {
            filters(name, address.ville)
        }
    }
    ```

*   **`action` et `workflow` : La Logique Métier**
    *   **Rôle :** Décrit les actions métier spécifiques et le cycle de vie (machine à états) d'une entité.
    *   **Syntaxe :** `action nomAction for Entity { ... }`, `workflow nomWorkflow for Entity { ... }`
    *   **Validation :** Le générateur valide la cohérence des transitions d'états
    ```jdl
    action validateOrder for CustomerOrder {
        in: { orderId: Int }
    }
    workflow OrderLifecycle for CustomerOrder {
        status_field status,
        initial DRAFT,

        transition 'validate' from DRAFT to VALIDATED
            executes(validateOrder(orderId))
    }
    ```

**2.2. Types de Données Supportés**

| Type DSL | Type RPG Moderne | Type SQL | Description |
|----------|------------------|----------|-------------|
| `Int` | `INT(10)` | `INTEGER` | Entier 32 bits |
| `Long` | `INT(20)` | `BIGINT` | Entier 64 bits |
| `String(n)` | `CHAR(n)` ou `VARCHAR(n)` | `VARCHAR(n)` | Chaîne de caractères |
| `Date` | `DATE` | `DATE` | Date |
| `Decimal(p,s)` | `PACKED(p:s)` | `DECIMAL(p,s)` | Nombre décimal |
| `Boolean` | `IND` | `CHAR(1) CHECK(...)` | Booléen |

**2.3. Modificateurs de Champs**

- `required` : Champ obligatoire (NOT NULL)
- `default(valeur)` : Valeur par défaut
- `unique` : Contrainte d'unicité
- Relations : `Entity` référence une autre entité (clé étrangère)

**2.4. Gestion des ids**
- Les entités doivent avoir un champ `id` de type `Int` ou `Long` avec le modificateur `required`.
- Le générateur crée automatiquement un champ `ID` avec une contrainte d'unicité et une séquence pour l'auto-incrémentation si il n'est pas défini ou annoté @autoIncrement.
- l'id peut-etre simple ou issu d'une structure composite.
- Les ids peuvent être issus d'une structure dans le cas de champs composés par exemple code établissement, n° de facture comme id de l'entité facture.
- Exemple :
```jdl  
// id simple   
entity Customer {
    id: Int required,
    name: String(80) required,
    address: Address,
    creationDate: Date
}
// id simple auto-incrément  
entity Customer {
    id: Int required, // @autoIncrement
    name: String(80) required,
    address: Address,
    creationDate: Date
}
// 1. Définir la structure de la clé composite
struct EmployeeId {
    code: String(6) required,
    departement: String(3) required  
}
// 2. Utiliser cette structure comme type dans l'entité
entity Employee {
    id: EmployeeId,
    ...// autres champs 
}
```
mais les ids peuvent etre issus d'une structure dans le cas de champs composés par exemple code établissement, n° de facture comme id de l'entité facture.


---
### 4. Roadmap de Développement MVP

**⚠️ Important :** Les exemples détaillés de la section précédente représentent la vision complète du DSL CMagic, mais sont trop ambitieux pour le MVP. La réalisation se fera par sprints incrémentaux.

#### **🎯 MVP Focus : Customer + CustomerOrder Fonctionnels**

Le MVP se concentre sur la validation du concept avec deux entités liées :
- **Customer** : Entité maître simple avec CRUD complet
- **CustomerOrder** : Entité avec relation et workflow basique

#### **📋 Découpage en 6 Sprints**

| Sprint | Focus | Durée | Livrables Clés |
|--------|-------|-------|----------------|
| **Sprint 1** | Fondations + Entity | 2 sem | Parser DSL, DDL, Copybooks |
| **Sprint 2** | Services CRUD | 2 sem | Services RPG, Pattern unifié |
| **Sprint 3** | Écrans DSPF | 2 sem | WORK_WITH, Maintenance UI |
| **Sprint 4** | Relations | 2 sem | FK, Jointures, Master-Detail |
| **Sprint 5** | Workflow Simple | 2 sem | Actions, Machine à états |
| **Sprint 6** | Tests + Doc | 1-2 sem | Polish, Documentation |

#### **📚 Documentation Détaillée**

Chaque sprint dispose de son PRD détaillé :
- 📄 **[Roadmap Complète](./roadmap.md)** - Vue d'ensemble et planning
- 📄 **[Sprint 1 - Fondations](./prdSprint01.md)** - Parser + DDL + Copybooks
- 📄 **[Sprint 2 - Services CRUD](./prdSprint02.md)** - Services RPG + Pattern unifié
- 📄 **[Sprint 3 - Écrans DSPF](./prdSprint03.md)** - Interface utilisateur native
- 📄 **[Sprint 4 - Relations](./prdSprint04.md)** - Customer/Order avec FK
- 📄 **[Sprint 5 - Workflow](./prdSprint05.md)** - Machine à états simple
- 📄 **[Sprint 6 - Finalisation](./prdSprint06.md)** - Tests, doc, polish

#### **🔮 Patterns Avancés → v2.0**

Les patterns complexes illustrés précédemment (sources hétérogènes, validation avancée, etc.) sont reportés en v2.0 pour maintenir un MVP réaliste et livrable.

#### **✅ Avantages de cette Approche**
- ✅ **MVP réaliste** en 12 semaines
- ✅ **Livrables fonctionnels** à chaque sprint
- ✅ **Risques maîtrisés** avec complexité progressive
- ✅ **Feedback précoce** pour ajustements
- ✅ **Base solide** pour extension v2.0

---
### 5. Architecture et Stratégie de Génération

**3.1. Stack Technique (Simplifié MVP)**
*   **DSL/Générateur :** Langium, TypeScript, Node.js, Handlebars.js (templating), Vitest (tests).
*   **CLI Interface :** Commander.js pour l'interface en ligne de commande basique
*   **Cible IBM i :** RPG ILE (Full Free format), SQL DDL, SRVPGM, DSPF.
*   **Build :** `make` (via `gmake`) ou IBM i `Bob`.

**Technologies reportées en v2.0 :**
- Simple-git pour la gestion des branches et merges
- Moteur intelligent de résolution de conflits avec annotations

**3.2. Architecture du Générateur (MVP Simplifié)**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Fichiers      │    │   Parseur        │    │   Générateur    │
│   .cmagic       │───▶│   Langium        │───▶│   Templates     │
│                 │    │                  │    │   Handlebars    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                        ┌─────────────────────────────────────────┐
                        │         Artefacts Générés               │
                        │  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
                        │  │   SQL   │ │   RPG   │ │  DSPF   │   │
                        │  │   DDL   │ │ Double  │ │ Écrans  │   │
                        │  │         │ │ Couche  │ │         │   │
                        │  └─────────┘ └─────────┘ └─────────┘   │
                        └─────────────────────────────────────────┘
```

**Architecture simplifiée :**
- Pas de moteur de merge complexe
- Pas de gestion Git intégrée
- Focus sur la génération de code robuste
- Pattern double couche éprouvé

**3.3. Convention de Fichiers et Organisation**
*   **Structure des sources :** Un fichier `.cmagic` par entité principale
    - `customer.cmagic` : Contient tout ce qui concerne `Customer`
    - `customerorder.cmagic` : Contient tout ce qui concerne `CustomerOrder`
    - `commons.cmagic` : Définitions partagées (structs, enums communs)

**3.3.1. Principe d'Organisation par Entité**

L'arborescence suit le principe de **cohésion métier** : tous les artefacts d'une même entité sont regroupés dans un dossier dédié. Cette approche offre plusieurs avantages :

| Avantage | Description | Impact |
|----------|-------------|---------|
| **Cohésion** | Tous les artefacts d'une entité au même endroit | Navigation intuitive |
| **Maintenance** | Modification d'une entité = un seul dossier | Moins d'erreurs |
| **Scalabilité** | Ajout d'entité = nouveau dossier autonome | Croissance maîtrisée |
| **Compréhension** | Structure reflète le modèle métier | Onboarding facilité |
| **Modularité** | Entités indépendantes physiquement | Déploiement sélectif |

**3.3.2. Gestion des Dépendances entre Entités**

```json
// .cmagic/entity-dependencies.json
{
  "dependencies": {
    "CustomerOrder": ["Customer"],
    "Customer": []
  },
  "generation_order": ["Customer", "CustomerOrder"],
  "impact_analysis": {
    "Customer": {
      "affects": ["CustomerOrder"],
      "critical_fields": ["id", "name"]
    }
  }
}
```

*   **Arborescence de sortie générée (MVP - Fichier Unifié) :**
```
src/
│
├── shared/
│   ├── includes/
│   │   ├── COMMONS_H.rpgleinc    # Structures communes (Address, etc.)
│   │   └── TYPES_H.rpgleinc      # Types partagés et énumérations
│   └── utils/
│       └── ErrorHandling.rpgleinc # Utilitaires partagés
│
├── customer/
│   ├── Customer_H.rpgleinc       # Structures de données Customer
│   ├── Customer_PR.rpgleinc      # Prototypes publics (généré)
│   ├── Customer_S.sqlrpgle       # Service unifié (généré + manuel)
│   ├── CUSTOMERP.sql            # DDL table Customer
│   ├── CustomerWrk.dspf         # Écran WORK_WITH
│   ├── CustomerWrk.rpgle        # Programme WORK_WITH
│   ├── CustomerMnt.dspf         # Écran maintenance (CREATE/CHANGE)
│   ├── CustomerMnt.rpgle        # Programme maintenance
│   └── tests/
│       └── Customer_T.sqlrpgle   # Tests unitaires
│
├── customerorder/
│   ├── CustomerOrder_H.rpgleinc  # Structures de données CustomerOrder
│   ├── CustomerOrder_PR.rpgleinc # Prototypes publics (généré)
│   ├── CustomerOrder_S.sqlrpgle  # Service unifié (généré + manuel)
│   ├── CUSTOMERORDERP.sql       # DDL table CustomerOrder
│   ├── OrderWrk.dspf            # Écran WORK_WITH commandes
│   ├── OrderWrk.rpgle           # Programme WORK_WITH commandes
│   ├── OrderMnt.dspf            # Écran maintenance commande
│   ├── OrderMnt.rpgle           # Programme maintenance commande
│   ├── OrderValidate.rpgle      # Actions métier (validate, ship, etc.)
│   └── tests/
│       └── CustomerOrder_T.sqlrpgle # Tests unitaires
│
└── .cmagic/
    ├── generation.history       # Historique des générations
    ├── templates.version        # Version des templates utilisés
    └── entity-dependencies.json # Graphe des dépendances entre entités
```

**Avantages du fichier unifié pour le MVP :**
- ✅ **Fichier unifié** : Un seul fichier service par entité
- ✅ **Namespace RPG** : Respect des conventions IBM i
- ✅ **Zones protégées** : Code manuel préservé automatiquement
- ✅ **Contrôle d'exposition** : API publique/interne bien séparée
- ✅ **Simplicité** : Pas de synchronisation entre fichiers
- ✅ **Maintenabilité** : Architecture claire et moderne

**3.4. Approche Fichier Unifié avec Zones Protégées (MVP)**

Le générateur implémente directement l'approche moderne qui unifie génération et code manuel dans un seul fichier :

| Concept | Description | Avantages |
|---------|-------------|-----------|
| **API Publique** | Procédures `_Entity_*` exportées | Interface standardisée |
| **Implémentation Interne** | Procédures `Entity_*` non exportées | Encapsulation |
| **Zones Protégées** | Délimiteurs `[CMAGIC:MANUAL_START/END]` | Code manuel préservé |
| **Namespace Implicite** | Convention RPG respectée | Intégration naturelle |

**Workflow de Génération Intelligent :**
```bash
# Génération classique
cmagic generate customer.cmagic

# Génération avec validation
cmagic generate --validate *.cmagic

# Génération d'une entité spécifique
cmagic generate --entity=customer
```

**Exemple de Délégation dans le Code Unifié :**
```rpgle
**FREE
// Dans Customer_S.sqlrpgle (fichier unifié)

/copy CUSTOMER_H

// ========================================
// API PUBLIQUE - PROCÉDURES EXPORTÉES  
// ========================================

DCL-PROC customer_getByID EXPORT;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  // Validation des paramètres (généré)
  IF id <= 0;
    RETURN *NULL;
  ENDIF;
  
  // Délégation à l'implémentation locale
  RETURN customer_getByID_local(id);
END-PROC;

// ========================================
// ZONE MANUELLE - PRÉSERVÉE
// ========================================
// [CMAGIC:MANUAL_START]

DCL-PROC customer_getByID_local;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(Customer_detail_t);
  
  // Implémentation manuelle du développeur
  EXEC SQL 
    SELECT ID, NAME, ADDR_LIGNE1, ADDR_VILLE
    INTO :result.id, :result.name, :result.address.ligne1, :result.address.ville
    FROM CUSTOMERP 
    WHERE ID = :id;
  
  RETURN result;
END-PROC;

// [CMAGIC:MANUAL_END]
```

**3.5. Interface CLI CMagic (MVP Simplifié)**

Le générateur fournit une interface en ligne de commande basique mais efficace :

```bash
# Commandes principales
cmagic generate [options] <files...>    # Génération des artefacts
cmagic validate <files...>              # Validation des fichiers DSL
cmagic status                           # État des fichiers générés
cmagic entity list                      # Liste des entités du projet
cmagic entity dependency <name>         # Analyse des dépendances d'une entité

# Options de génération
--validate                              # Validation avant génération
--entity=<name>                        # Génération d'une entité spécifique
--force                                # Force la régénération même si à jour
--dry-run                              # Simulation sans modification des fichiers

# Exemples d'utilisation
cmagic generate customer.cmagic
cmagic generate --entity=customer --validate
cmagic generate --force *.cmagic
cmagic entity dependency customerorder  # Affiche: Customer
```

**Interface moderne (avec zones protégées) :**
```bash
$ cmagic generate customer.cmagic

🔄 Génération de l'entité Customer en cours...
📁 Dossier: src/customer/

✅ Customer_S.sqlrpgle généré (zones manuelles préservées)
✅ Customer_H.rpgleinc généré
✅ Customer_PR.rpgleinc généré
✅ CUSTOMERP.sql généré

📊 Résumé:
   • 4 fichiers générés/mis à jour
   • Zone manuelle préservée dans Customer_S.sqlrpgle
   • 0 erreur

🎯 Prochaines étapes:
   1. Compiler les sources RPG
   2. Implémenter la logique métier dans [CMAGIC:MANUAL_START/END]
   3. Tester les fonctionnalités
```

**3.6. Processus de Build et Intégration (MVP)**

1. **Développement :** Le développeur écrit/modifie les fichiers `.cmagic`
2. **Génération :** `cmagic generate *.cmagic` produit les artefacts avec zones protégées
3. **Implémentation :** Le développeur complète la logique dans `[CMAGIC:MANUAL_START/END]`
4. **Compilation :** `make` ou `Bob` compile les sources RPG
5. **Déploiement :** Les objets sont créés sur IBM i via QSYS

**Intégration CI/CD Simplifiée :**
```yaml
# .github/workflows/cmagic-build.yml
name: CMagic Build
on: [push, pull_request]

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install CMagic
        run: npm install -g @cmagic/cli
      
      - name: Generate artifacts
        run: cmagic generate --validate src/*.cmagic
      
      - name: Validate RPG syntax
        run: make validate-rpg
```

**3.7. Gestion des Dépendances et Relations**

Le générateur analyse les relations entre entités pour :
- Générer les contraintes de clés étrangères dans le SQL
- Créer les procédures de jointure nécessaires dans les zones protégées
- Valider la cohérence référentielle dans les workflows
- Optimiser l'ordre de génération des artefacts
- Préserver les relations personnalisées lors du merge

**Métadonnées de Génération Simplifiées (.cmagic/generation-metadata.json) :**
```json
{
  "entities": {
    "Customer": {
      "folder": "src/customer/",
      "files": {
        "Customer_S.sqlrpgle": {
          "type": "unified",
          "last_generation": "2024-12-20T10:30:00Z",
          "template_version": "1.0",
          "manual_zone_preserved": true
        },
        "Customer_H.rpgleinc": {
          "type": "generated",
          "last_generation": "2024-12-20T10:30:00Z"
        },
        "CUSTOMERP.sql": {
          "type": "generated",
          "last_generation": "2024-12-20T10:30:00Z"
        }
      }
    },
    "CustomerOrder": {
      "folder": "src/customerorder/",
      "dependencies": ["Customer"],
      "files": {
        "CustomerOrder_S.sqlrpgle": {
          "type": "unified",
          "last_generation": "2024-12-20T11:15:00Z",
          "manual_zone_preserved": true
        }
      }
    }
  },
  "generation_history": [
    {
      "timestamp": "2024-12-20T10:30:00Z",
      "entities_generated": ["Customer"],
      "template_version": "1.0",
      "files_created": 4,
      "manual_zones_preserved": 1
    }
  ]
}
```

---

### 4. Exemple Fil Rouge Complet

#### **Fichier 1 : `commons.cmagic`**
```jdl
// Fichier partagé pour les structures communes

struct Address {
    ligne1: String(50),
    codePostal: String(10),
    ville: String(50)
}
```

#### **Fichier 2 : `customer.cmagic`**
```jdl
// Définition de l'entité maître simple
import './commons.cmagic'

/** @pf 'CUSTOMERP' */
entity Customer {
    id: Int required,
    name: String(80) required,
    address: Address,
    creationDate: Date
}

// Vue pour la liste
view CustomerListItem for Customer {
    id,
    name,
    address.ville // On peut même accéder aux champs d'une struct
}

// Opérations de base
operations for Customer {
    CREATE, CHANGE, DELETE, DISPLAY,
    WORK_WITH returns CustomerListItem {
        filters(name, address.ville)
    }
}
```

#### **Fichier 3 : `customerorder.cmagic`**
```jdl
// Définition de l'entité transactionnelle avec workflow et relation
import './customer.cmagic'

/** @pf 'ORDERP' */
entity CustomerOrder {
    orderId: Int required,
    orderDate: Date required,
    customer: Customer required, // <-- LA RELATION
    totalAmount: Decimal(15, 2),
    status: OrderStatus required default(DRAFT)
}

enum OrderStatus {
    DRAFT, VALIDATED, SHIPPED, CANCELLED
}

// Vue pour la liste des commandes
view OrderListItem for CustomerOrder {
    orderId,
    orderDate,
    customer.name, // On peut "aplatir" la relation dans le DTO
    status,
    totalAmount
}

operations for CustomerOrder {
    DISPLAY,
    WORK_WITH returns OrderListItem {
        filters(customer, status)
    }
}

// Action métier pour valider la commande
action validateOrder for CustomerOrder {
    in: { orderId: Int }
}

// Workflow du cycle de vie
workflow OrderLifecycle for CustomerOrder {
    status_field status,
    initial DRAFT,

    transition 'validate' from DRAFT to VALIDATED
        executes(validateOrder(orderId))
}
```

---

Ce récapitulatif consolide toutes nos décisions. Il vous donne un plan d'attaque clair pour commencer à coder le "Sprint Zéro" et les suivants, avec une vision précise de la cible à atteindre pour le MVP. C'est un excellent document de référence pour vous guider.

---

### 5. Artefacts Générés Détaillés

**5.1. Structures de Données RPG (.rpgleinc)**

Pour chaque entité, le générateur produit un copybook avec :
- Structure de données de base (`Entity_t`)
- Structure détaillée avec relations (`Entity_detail_t`)
- Templates pour les vues (`EntityView_t`)

**Exemple généré pour Customer :**
```rpgle
**FREE
// CUSTOMER_H.rpgleinc
/if not defined(CUSTOMER_H)
/define CUSTOMER_H

// Structure de base
DCL-DS Customer_t QUALIFIED TEMPLATE;
  id INT(10);
  name CHAR(80);
  address LIKEDS(Address_t);
  creationDate DATE;
END-DS;

// Structure détaillée (avec relations)
DCL-DS Customer_detail_t QUALIFIED TEMPLATE;
  id INT(10);
  name CHAR(80);
  address LIKEDS(Address_t);
  creationDate DATE;
  // Métadonnées
  created_at TIMESTAMP;
  updated_at TIMESTAMP;
END-DS;

// Vue pour liste
DCL-DS CustomerListItem_t QUALIFIED TEMPLATE;
  id INT(10);
  name CHAR(80);
  ville CHAR(50); // address.ville aplati
END-DS;

/endif
```

**5.2. Définitions SQL (DDL)**

```sql
-- CUSTOMERP.sql
CREATE TABLE CUSTOMERP (
    ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    NAME VARCHAR(80) NOT NULL,
    ADDR_LIGNE1 VARCHAR(50),
    ADDR_CODEPOSTAL VARCHAR(10),
    ADDR_VILLE VARCHAR(50),
    CREATIONDATE DATE,
    CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

-- Index pour les recherches fréquentes
CREATE INDEX CUSTOMERP_NAME_IDX ON CUSTOMERP (NAME);

-- Trigger pour updated_at
CREATE TRIGGER CUSTOMERP_UPD_TRG
    BEFORE UPDATE ON CUSTOMERP
    FOR EACH ROW
    SET NEW.UPDATED_AT = CURRENT_TIMESTAMP;
```

**5.3. Services RPG Unifiés (SRVPGM)**

Avec la nouvelle approche Git-based, le générateur produit un seul fichier unifié par entité avec annotations CMAGIC :

**Fichier unifié (`Customer.sqlrpgle`) :**
```rpgle
**FREE
// Service Customer - Code unifié (généré + local)

/copy CUSTOMER_H

// === CMAGIC_GENERATED_START:prototypes ===
// Opérations CRUD de base - Prototypes générés
DCL-PR customer_create EXPORT LIKEDS(Customer_detail_t);
  customer LIKEDS(Customer_t) CONST;
END-PR;

DCL-PR customer_getByID EXPORT LIKEDS(Customer_detail_t);
  id INT(10) CONST;
END-PR;

DCL-PR customer_update EXPORT LIKEDS(Customer_detail_t);
  id INT(10) CONST;
  customer LIKEDS(Customer_t) CONST;
END-PR;

DCL-PR customer_delete EXPORT IND;
  id INT(10) CONST;
END-PR;
// === CMAGIC_GENERATED_END:prototypes ===

// === CMAGIC_GENERATED_START:getByID ===
DCL-PROC customer_getByID EXPORT;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  // Validation générée
  IF id <= 0;
    RETURN *NULL;
  ENDIF;
  
  // Délégation vers l'implémentation locale
  RETURN customer_getByID_local(id);
END-PROC;
// === CMAGIC_GENERATED_END:getByID ===

// === CMAGIC_GENERATED_START:create ===
DCL-PROC customer_create EXPORT;
  DCL-PI *N LIKEDS(Customer_detail_t);
    customer LIKEDS(Customer_t) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(Customer_detail_t);
  
  DCL-PI *N LIKEDS(Customer_detail_t);
    customer LIKEDS(Customer_t) CONST;
  END-PI;
  
  // Délégation vers l'implémentation locale
  RETURN customer_create_local(customer);
END-PROC;
// === CMAGIC_GENERATED_END:create ===

// ========================================
// ZONE MANUELLE - PRÉSERVÉE
// ========================================
// [CMAGIC:MANUAL_START]

DCL-PROC customer_getByID_local;
  DCL-PI *N LIKEDS(Customer_detail_t);
    id INT(10) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(Customer_detail_t);
  
  // Implémentation locale - Zone personnalisable
  EXEC SQL 
    SELECT CUSID, CUSNAM, ADDR1, CITY, POSTAL
    INTO :result.id, :result.name, :result.address.ligne1, 
         :result.address.ville, :result.address.codePostal
    FROM CUSTOMERP 
    WHERE CUSID = :id;
  
  // Validation métier personnalisée
  IF result.id = 0;
    // Gestion d'erreur personnalisée
    result.name = 'Client non trouvé';
  ENDIF;
  
  // Enrichissement avec données externes (exemple)
  // result.creditStatus = getCreditFromAPI(id);
  
  RETURN result;
END-PROC;

DCL-PROC customer_create_local;
  DCL-PI *N LIKEDS(Customer_detail_t);
    customer LIKEDS(Customer_t) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(Customer_detail_t);
  
  // Validation métier personnalisée
  IF customer.name = '';
    // Logique d'erreur
    RETURN result;
  ENDIF;
  
  // Logique de persistance personnalisée
  EXEC SQL 
    INSERT INTO CUSTOMERP (CUSNAM, ADDR1, CITY, POSTAL)
    VALUES (:customer.name, :customer.address.ligne1,
            :customer.address.ville, :customer.address.codePostal);
  
  // Récupération de l'ID auto-généré
  EXEC SQL VALUES(IDENTITY_VAL_LOCAL()) INTO :result.id;
  
  RETURN result;
END-PROC;

// [CMAGIC:MANUAL_END]
```

**Avantages de cette approche :**
- **Code unifié** : Plus de synchronisation entre fichiers
- **Zones protégées** : Le code local est préservé avec `[CMAGIC:MANUAL_START/END]`
- **Convention _local** : Claire distinction entre API publique et implémentation locale
- **Évolution continue** : Les templates peuvent évoluer sans casser le code local
- **Historique Git** : Traçabilité complète des modifications

---

### 6. Implémentation du MVP - Plan de Développement

**6.1. Sprint 0 : Infrastructure (Simplifié)**
- ✅ Setup du projet Langium
- ✅ Configuration TypeScript/Node.js
- ✅ Setup des tests avec Vitest
- ✅ Configuration des templates Handlebars
- ✅ CLI basique avec Commander.js
- ✅ CI/CD basique

**6.2. Sprint 1 : Grammaire et Parser**
- ✅ Définition de la grammaire DSL (.langium)
- ✅ Génération du parser
- ✅ Tests de parsing des fichiers exemples
- ✅ Validation syntaxique de base

**6.3. Sprint 2 : Génération des Structures**
- ✅ Templates pour les copybooks RPG (.rpgleinc)
- ✅ Génération des structures de données
- ✅ Support des types de base et struct imbriquées
- ✅ Tests de génération

**6.4. Sprint 3 : Génération SQL et DDL**
- ✅ Templates DDL pour les tables
- ✅ Gestion des contraintes et index
- ✅ Support des relations (clés étrangères)
- ✅ Génération des triggers

**6.5. Sprint 4 : Services RPG (Pattern Double Couche)**
- ✅ Templates pour les SRVPGM générés (`_ENTITY_S`)
- ✅ Templates pour les extensions (`ENTITY_X_S`)
- ✅ Opérations CRUD de base avec délégation
- ✅ Gestion des erreurs

**6.6. Sprint 5 : Relations et Vues**
- ✅ Support des relations entre entités
- ✅ Génération des vues (DTOs)
- ✅ Jointures dans les requêtes (dans les extensions)
- ✅ Aplatissement des structures

**6.7. Sprint 6 : Workflows et Actions**
- ✅ Parser pour les workflows
- ✅ Génération de la machine à états (dans les extensions)
- ✅ Validation des transitions
- ✅ Intégration avec les services

**6.8. Sprint 7 : Écrans de Travail et Interface**
- ✅ Templates DSPF basiques
- ✅ Écrans WORK_WITH avec subfiles
- ✅ Filtres et recherche
- ✅ Actions sur les lignes

**6.9. Sprint 8 : Intégration et Tests Finaux**
- ✅ Tests end-to-end complets
- ✅ Exemple Customer/CustomerOrder fonctionnel
- ✅ Tests de régression et de performance
- ✅ Documentation utilisateur complète
- ✅ CLI packaging et distribution

---

### 7. Critères d'Acceptation du MVP (Recentrés)

**7.1. Fonctionnels**
- ✅ Le parseur valide correctement la syntaxe des fichiers exemple
- ✅ La génération produit des artefacts RPG compilables avec fichier unifié
- ✅ Les zones protégées `[CMAGIC:MANUAL_START/END]` préservent le code manuel
- ✅ Le namespace RPG (`_Entity_*` vs `Entity_*`) est respecté dès le MVP
- ✅ Les relations entre Customer et CustomerOrder fonctionnent avec l'organisation par entité
- ✅ Le workflow OrderLifecycle génère les squelettes appropriés
- ✅ Les écrans WORK_WITH sont générés et fonctionnels
- ✅ Les opérations CRUD de base fonctionnent avec le pattern de délégation unifié
- ✅ Le CLI CMagic gère correctement la génération par entité
- ✅ La génération sélective par entité fonctionne correctement
- ✅ L'analyse des dépendances entre entités est opérationnelle
- ✅ Le contrôle d'exposition des procédures (EXPORT) fonctionne correctement

**7.2. Techniques**
- ✅ Couverture de tests > 80%
- ✅ Performance : génération complète < 10 secondes
- ✅ Aucune régression sur les zones manuelles lors des régénérations
- ✅ Gestion d'erreurs claire et informative
- ✅ Documentation technique et guide utilisateur complets
- ✅ Extraction et préservation intelligente des zones manuelles

**7.3. Métier et Adoption**
- ✅ Un développeur IBM i peut utiliser l'outil sans formation extensive
- ✅ Le code généré respecte les standards de l'entreprise
- ✅ La séparation généré/manuel est claire et sûre (zones protégées)
- ✅ L'organisation par entité facilite la compréhension du modèle métier
- ✅ La navigation dans le code est intuitive (une entité = un dossier, un fichier service)
- ✅ La maintenance est simplifiée (modification localisée par entité)
- ✅ Réduction mesurable du temps de développement (> 30%)
- ✅ Réduction du temps de localisation du code (> 50%)
- ✅ Réduction du nombre de fichiers à maintenir (> 50%)

### 8. Risques et Mitigation (Simplifiés)

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Complexité de la grammaire Langium | Élevé | Moyen | Prototypage rapide, validation précoce |
| Performance de génération | Moyen | Faible | Benchmarks, optimisation templates |
| Adoption par les développeurs | Élevé | Moyen | Formation, documentation, exemples |
| Maintenance du code généré | Moyen | Faible | Tests automatisés, pattern éprouvé |
| Complexité organisation par entité | Faible | Faible | Structure intuitive, documentation |

---

### 9. Livrables du MVP (Simplifiés)

**9.1. Code Source**
- Générateur CMagic avec approche fichier unifié moderne (TypeScript/Langium)
- Templates de génération avec zones protégées intelligentes (Handlebars)
- Parser de zones manuelles avec regex robuste
- CLI CMagic avec support complet du namespace RPG
- Suite de tests complète couvrant les zones protégées
- Scripts de build et déploiement

**9.2. Documentation**
- Guide utilisateur du DSL
- Documentation d'architecture du générateur
- Exemples complets (Customer/CustomerOrder)
- Guide de développement
- Standards de codage

**9.3. Démonstration**
- Application exemple fonctionnelle
- Présentation du processus de développement
- Métriques de productivité comparatives
- Guide d'adoption pour les équipes

---

### 10. Roadmap Post-MVP

**10.1. Version 2.0 - Git-Based Extensibility**
- Évolution des délimiteurs `[CMAGIC:MANUAL_START/END]` vers annotations CMAGIC avancées
- Merge intelligent avec historique Git
- Interface de résolution de conflits avancée
- Traçabilité complète des modifications manuelles
- Support de hooks Git pour génération automatique

**10.2. Version 2.1 - Intégrations Avancées**
- Intégration avec des APIs externes
- Gestion avancée des droits et sécurité
- Performance optimization et génération incrémentale
- Migration de données existantes
- Support multi-environnement (DEV/TEST/PROD)

**10.3. Version 3.0 - Modernisation**
- Interface utilisateur web moderne
- Support multi-plateforme (AS/400, Linux, Cloud)
- Écosystème de plugins et extensions
- Intelligence artificielle pour la génération et l'optimisation

---

### 11. Conclusion

Cette version **modernisée du PRD MVP** adopte directement l'approche la plus élégante et efficace pour prouver la viabilité du DSL CMagic. 

**Les bénéfices attendus avec l'approche moderne dès le MVP :**
- **Validation du concept** : DSL expressif pour IBM i
- **Organisation métier** : Structure reflétant le modèle de domaine  
- **Architecture moderne** : Fichier unifié avec zones protégées dès le MVP
- **Namespace RPG natif** : Respect des conventions IBM i (`_Entity_*` vs `Entity_*)
- **Zones protégées robustes** : Code manuel préservé automatiquement avec délimiteurs intelligents
- **Contrôle d'exposition avancé** : API publique/interne parfaitement séparée
- **Productivité maximale** : Génération automatique sans compromis sur la flexibilité
- **Maintenance optimale** : Un seul fichier par entité, architecture claire
- **Évolutivité directe** : Base parfaite pour les innovations Git-based v2.0

Le MVP moderne établit **d'emblée les meilleures pratiques** de CMagic avec une architecture définitive, évitant toute étape intermédiaire et préparant directement le terrain pour les fonctionnalités révolutionnaires des versions futures. 

**Pourquoi cette approche est supérieure :**
- ✅ **Pas de dette technique** : Solution optimale dès le départ
- ✅ **Adoption facilitée** : Développeurs habitués à une seule approche
- ✅ **Moins de complexité** : Pas de migration à gérer
- ✅ **Feedback utilisateur** direct sur l'approche finale