---

### **Product Requirements Document (PRD) - CMagic v1.0**

**Titre du Projet :** CMagic - Un DSL pour l'Architecture Applicative sur IBM i

**Version :** 1.0

---

### 1. Genèse et Philosophie du Projet

**1.1. La Genèse**
Le développement sur IBM i (AS/400) a été historiquement guidé par des principes d'architecture robustes et centrés sur l'utilisateur, comme le **CUA (Common User Access)**. L'OS lui-même est orienté "objet", où chaque ressource (`*FILE`, `*PGM`, `*USRPRF`) est une entité manipulée par un ensemble de commandes standardisées (Verbe-Nom : `CRT`, `CHG`, `DSP`, `WRK`). Les applications métier suivent souvent ce paradigme, avec des **processus** pilotés par des **statuts** qui dictent le cycle de vie des données.

Cependant, avec le temps, ces patterns architecturaux clairs ont souvent été masqués par la complexité du code legacy. **CMagic** est né de la volonté de **redécouvrir et de formaliser ces patterns éprouvés dans un DSL moderne**. L'objectif n'est pas de rompre avec le passé, mais de distiller l'essence de l'architecture IBM i pour construire des applications futures de manière plus rapide, plus propre et plus maintenable.

**1.2. Philosophie**
CMagic traite une **`entity`** non pas comme une simple table, mais comme un **concept métier central**. Sa représentation physique (persistance) est un détail d'implémentation. Le DSL se concentre sur la description de l'**entité**, de ses **DTOs (vues)**, de son **comportement (opérations)** et de son **cycle de vie (workflow)**, indépendamment de la manière dont les données sont stockées ou récupérées.

---
### 2. Reflexion sur les patterns.
Le projet CMagic s'inspire des concepts fondamentaux d'IBM i pour créer un DSL qui permet de modéliser les applications de manière cohérente et moderne. Voici quelques patterns clés extraits de l'architecture IBM i, avec des propositions de syntaxe pour le DSL :
1.  **L'Entité en tant qu'Objet IBM i** : Chaque entité métier correspond à un objet de l'OS/400, enrichi par des métadonnées.
2.  **Le Service comme un Ensemble de Commandes CUA** : Les opérations standardisées (`CREATE`, `CHANGE`, `DELETE`, `DISPLAY`, `WORK_WITH`) sont modélisées comme des stéréotypes d'opérations.
3.  **Le Workflow par Statuts** : La logique métier est pilotée par des statuts et des transitions, formalisés dans un bloc de définition de workflow.
4.  **L'OS orienté Objet** : Chaque ressource est un objet avec un type et un sous-type, influençant la manière dont les entités sont définies.
5.  **La CLI et ses conventions** : Les commandes basées sur un paradigme Verbe-Nom sont intégrées dans le DSL pour représenter les opérations sur les objets.
6.  **Le Modèle de Persistance** : La séparation entre la définition de l'entité et sa persistance physique est essentielle, permettant une flexibilité dans l'implémentation.
7.  **Le Cycle de Vie des Objets** : La gestion des statuts et des transitions est essentielle pour modéliser le comportement des entités dans le temps.
8.  **L'Intégration des Sources de Données Hétérogènes**
    : Le DSL permet de décrire des entités qui peuvent provenir de différentes sources (Db2, API, legacy), tout en gardant une abstraction claire.
9.  **La Séparation des Préoccupations** : Le DSL permet de séparer la logique métier de la persistance, facilitant ainsi la maintenance et l'évolution des applications.
10.  **L'Extensibilité et la Personnalisation** : Le DSL permet aux développeurs d'ajouter des extensions personnalisées pour gérer des cas spécifiques, tout en respectant les standards de l'entreprise.

L'idée de distiller ces concepts en patterns pour un DSL basé sur JHipster JDL / Langium est brillante. Cela permettrait de modéliser la logique métier d'une application IBM i de manière très expressive et de générer ensuite un code moderne (Java/Spring, Angular/React...) qui en respecte l'esprit.

Voici plusieurs patterns que l'on peut extraire, avec des propositions de syntaxe pour votre DSL.

---

### Pattern 1: L'Entité en tant qu'Objet IBM i (Entity as an IBM i Object)

Ce pattern capture l'idée que chaque entité métier principale correspond à un "objet" au sens de l'OS/400.

*   **Principe** : Une entité dans le DSL n'est pas juste une table de base de données, elle représente un concept métier qui aurait été un objet sur IBM i. On enrichit la définition de l'entité JDL standard avec cette métadonnée.
*   **Mapping IBM i -> DSL** : Le type d'objet (`*USRPRF`, `*FILE` de type `PF`, etc.) devient une annotation sur l'entité.
*   **Exemple de Syntaxe DSL (JDL/Langium)** :

```jdl
/**
 * Le profil utilisateur système.
 * @objectType '*USRPRF'
 */
entity UserProfile {
    userName String required,
    password String, // Le mot de passe serait géré autrement en réalité
    userClass String,
    initialProgram String,
    status String // *ENABLED, *DISABLED
}

/**
 * Le fichier des commandes clients.
 * @objectType '*FILE'
 * @objectSubType 'PF'
 */
entity CustomerOrder {
    orderNumber Long required,
    orderDate LocalDate,
    customerNumber String required,
    totalAmount BigDecimal
}
```

*   **Ce que cela implique** : Votre générateur de code, en voyant `@objectType`, pourrait :
    *   Adapter la nomenclature des services générés.
    *   Savoir que cette entité est un "pilier" de l'application.
    *   Pré-configurer des logs ou des audits spécifiques à cet "objet".

---

### Pattern 2: Le Service comme un Ensemble de Commandes CUA (Service as CUA Commands)

Ce pattern formalise le cycle de vie de l'objet via des opérations standardisées, inspirées des commandes IBM i. C'est bien plus riche qu'un simple CRUD.

*   **Principe** : Au lieu de définir des méthodes de service une par une, on déclare que l'entité supporte un ensemble d'opérations standards (`CREATE`, `CHANGE`, `DELETE`, `DISPLAY`, `WORK_WITH`). `WORK_WITH` (`WRK...`) est la plus importante : elle représente l'écran de liste/recherche (le "subfile" en 5250) à partir duquel les autres actions sont déclenchées.
*   **Mapping IBM i -> DSL** : Les commandes `CRTxxx`, `CHGxxx`, `DLTxxx`, `DSPxxx`, `WRKxxx` sont modélisées comme des stéréotypes d'opérations.
*   **Exemple de Syntaxe DSL (JDL/Langium)** :

On introduit un nouveau mot-clé `operations` pour lier un ensemble d'opérations standards à une entité.

```jdl
// On reprend l'entité CustomerOrder
entity CustomerOrder { ... }

// On définit les opérations standardisées pour cette entité
operations for CustomerOrder {
    // Génère un formulaire de création (CRTORD)
    CREATE, 
    
    // Génère un formulaire d'édition (CHGORD)
    CHANGE, 
    
    // Génère une fonction de suppression (DLTORD)
    DELETE, 
    
    // Génère un écran de consultation non-modifiable (DSPORD)
    DISPLAY,
    
    // C'est le pattern clé : génère un écran de liste/recherche (WRKORD)
    // avec des actions sur chaque ligne.
    WORK_WITH {
        // Champs à afficher dans la liste (le subfile)
        list_columns(orderNumber, orderDate, customerNumber),
        // Actions possibles depuis une ligne de la liste
        row_actions(CHANGE, DELETE, DISPLAY),
        // Champs sur lesquels on peut filtrer
        filters(orderDate, customerNumber)
    }
}
```

*   **Ce que cela implique** :
    *   Le générateur sait qu'il doit créer une API REST avec les endpoints correspondants (`POST /orders`, `PUT /orders/{id}`, `GET /orders/{id}`, `DELETE /orders/{id}`).
    *   Surtout, pour `WORK_WITH`, il génère :
        *   Un endpoint `GET /orders` avec des capacités de pagination et de filtrage.
        *   Une interface utilisateur (UI) complète : une page avec un tableau, des filtres, et pour chaque ligne, des boutons "Modifier", "Supprimer", "Afficher". C'est l'équivalent moderne du `WRK...` avec les options 2, 4, 5.

---

### Pattern 3: Le Workflow par Statuts (Status-Driven Workflow)

C'est le pattern de la machine à états (State Machine) qui régit le cycle de vie de l'objet.

*   **Principe** : On définit formellement les différents statuts d'une entité et les transitions autorisées entre ces statuts. Une transition est déclenchée par une "action".
*   **Mapping IBM i -> DSL** : Le champ "statut" et la logique applicative (souvent codée en dur dans les programmes RPG) sont extraits dans un bloc de définition de workflow.
*   **Exemple de Syntaxe DSL (JDL/Langium)** :

D'abord, on définit les statuts avec un `enum` JDL.

```jdl
enum OrderStatus {
    NEW, // Nouvelle
    VALIDATED, // Validée
    IN_PREPARATION, // En préparation
    SHIPPED, // Expédiée
    CLOSED, // Clôturée
    CANCELLED // Annulée
}

entity CustomerOrder {
    ...
    status OrderStatus required
}
```

Ensuite, on définit le workflow avec un nouveau mot-clé `workflow`.

```jdl
workflow OrderLifecycle for CustomerOrder {
    // Le champ qui porte le statut
    status_field status,
    
    // Le statut initial à la création
    initial NEW,
    
    // Définition des transitions
    transition 'validate' from NEW to VALIDATED,
    transition 'prepare' from VALIDATED to IN_PREPARATION,
    transition 'ship' from IN_PREPARATION to SHIPPED,
    
    // Une action peut mener à un même état depuis plusieurs états sources
    transition 'cancel' from (NEW, VALIDATED, IN_PREPARATION) to CANCELLED,
    
    // Une transition peut être conditionnelle (logique plus avancée)
    // transition 'close' from SHIPPED to CLOSED when (payment.isReceived == true) 
}
```

*   **Ce que cela implique** :
    *   **Backend** : Le générateur peut créer la logique de validation dans la couche service. Par exemple, l'API pour l'action `ship` refusera d'exécuter une commande si son statut n'est pas `IN_PREPARATION`.
    *   **Frontend** : L'UI peut être dynamique. Si une commande est `SHIPPED`, le bouton "Expédier" sera désactivé et le bouton "Annuler" sera masqué.
    *   Cela documente de manière claire et formelle le cycle de vie métier.

---

### Implémentation avec Langium

Langium est l'outil parfait pour réaliser cela :

1.  **Grammaire** : Vous étendriez la grammaire JDL existante pour y ajouter vos nouveaux mots-clés : `@objectType`, `operations`, `WORK_WITH`, `workflow`, `transition`, etc.
2.  **Validation** : Le service de validation de Langium vous permettrait de définir des règles sémantiques.
    *   Vérifier qu'un `workflow` est défini pour une entité qui a un champ de type `enum`.
    *   S'assurer que les actions dans `row_actions` d'un `WORK_WITH` (`CHANGE`, `DELETE`...) sont bien définies dans le bloc `operations`.
    *   Valider que les états (`from`, `to`) dans une `transition` existent bien dans l'énumération de statuts.
3.  **Générateur de Code** : Le cœur de votre projet. Le parseur Langium crée un Arbre Syntaxique Abstrait (AST) de votre modèle. Votre générateur parcourt cet AST pour produire :
    *   Les entités JPA (pour le `@objectType`).
    *   Les `RestController` Spring Boot avec les endpoints (`/orders`, `/orders/{id}`).
    *   Les méthodes de `Service` qui implémentent la logique de transition du `workflow` (la machine à états).
    *   Les composants Angular/React/Vue pour les écrans `WORK_WITH` (tableaux, filtres) et les formulaires `CREATE`/`CHANGE`.

En combinant ces patterns, vous créez un DSL de très haut niveau, parfaitement adapté pour décrire la logique d'une application de gestion type IBM i et la transposer dans un monde technologique moderne de manière structurée et cohérente.
### 3. Personas et Scénarios Développeur

**3.1. Persona 1 : "Laurent", Architecte / Développeur Senior IBM i**
*   **Contexte :** Maîtrise RPG, Db2. Doit intégrer de nouvelles fonctionnalités dans un SI complexe mêlant legacy et nouvelles technologies.
*   **Besoin :** Standardiser l'architecture, accélérer les développements, et garantir que les nouvelles applications peuvent interagir avec des sources de données hétérogènes.

*   **Chemin Développeur (Scénario : Créer une vue unifiée du "Client")**
    1.  **Le besoin métier :** L'écran "Client" doit afficher des informations provenant de la table `CLIENTP` (Db2) et le "statut de crédit" provenant d'un service web externe.
    2.  **Modélisation dans `customer.cmagic` :** Laurent définit l'**entité métier** `Customer` avec tous les champs, qu'ils soient locaux ou distants. Il utilise des annotations pour spécifier l'origine des données.
        ```jdl
        entity Customer {
            id: Int required, // @source(db: 'CUSTOMERP.CUSID')
            name: String(80), // @source(db: 'CUSTOMERP.CUSNAM')
            creditStatus: String(20) // @source(api: 'CreditCheckService.getStatus')
        }
        ```
    3.  **Il définit les opérations :** `operations for Customer { DISPLAY, WORK_WITH ... }`
    4.  **Génération :** CMagic génère le `SRVPGM` `_CUSTOMER_S` avec les procédures `_getByID` et `_search`. Ces procédures sont des **squelettes vides** car le générateur ne sait pas comment appeler une API.
    5.  **Implémentation manuelle :** Laurent ouvre le fichier d'extension `CUSTOMER_X_S.sqlrpgle` et implémente la logique :
        *   Dans `Customer_X_getByID`, il code la requête SQL pour récupérer les données de `CUSTOMERP`.
        *   Puis, il utilise `HTTPAPI` (ou un autre outil) pour appeler le service web de crédit.
        *   Enfin, il fusionne les deux résultats dans la `dcl-ds Customer_detail_t` et la retourne.
    6.  **Résultat :** En quelques heures, Laurent a une couche de service propre et standardisée qui abstrait complètement la complexité de la source de données.

**2.2. Persona 2 : "Sophie", Développeur Junior**
*   **Contexte :** Connaît les concepts de programmation modernes (API, JSON, DTO) mais est nouvelle sur IBM i.
*   **Besoin :** Être productive rapidement sans avoir à connaître toutes les subtilités du RPG legacy ou des opcodes natifs.

*   **Chemin Développeur (Scénario : Ajouter une nouvelle fonctionnalité de commande)**
    1.  **Le besoin métier :** Créer une nouvelle gestion de commandes.
    2.  **Modélisation dans `customerorder.cmagic` :** Sophie utilise le DSL pour décrire la commande. Elle n'a pas besoin de savoir si la table existe déjà.
        ```jdl
        entity CustomerOrder {
            orderId: Int required,
            customer: Customer, // Référence l'entité définie par Laurent
            status: OrderStatus required default(DRAFT)
            // ...
        }
        workflow OrderLifecycle { ... }
        ```
    3.  **Génération :** Sophie lance CMagic. Le générateur produit :
        *   La table `ORDERP` avec la clé étrangère vers `CUSTOMERP`.
        *   Le `SRVPGM` `CUSTOMERORDER_S` avec tout le boilerplate pour le `WORK_WITH` et la gestion du workflow (vérification des statuts avant transition).
        *   Des procédures `*_local` avec des squelettes pour les actions métier personnalisables.
    4.  **Implémentation :** Guidée par les squelettes générés, Sophie n'a qu'à remplir la logique métier spécifique dans les procédures `*_local`, sans se soucier de la plomberie.
    5.  **Résultat :** Sophie a développé une fonctionnalité complète, robuste et conforme aux standards de l'entreprise en une fraction du temps, en se concentrant uniquement sur la logique métier.

---

### 3. Impact sur le DSL et le Générateur (PRD Technique)

**3.1. Le DSL doit abstraire la persistance**
*   L'**`entity`** est la description canonique du concept métier.
*   Des **annotations `@source` optionnelles** peuvent être utilisées pour documenter/piloter l'origine des données, mais le générateur ne les utilise que pour des optimisations. Par défaut, il suppose une implémentation manuelle.
    *   `@source(db: 'TABLE.COLUMN')` : Le champ vient d'une table Db2. Le générateur *peut* s'en servir pour pré-remplir la logique SQL.
    *   `@source(api: 'ServiceName.method')` : Le champ vient d'un service. Le générateur produit un squelette vide.
    *   `@source(legacy: 'PGMNAME')` : Le champ est récupéré via un appel à un programme legacy.
*   Si aucune annotation `@source` n'est présente, le générateur part du principe que l'entité est entièrement persistée dans une table Db2 qui porte son nom (`CUSTOMER` -> `CUSTOMERP`). C'est le cas par défaut pour le MVP.

**3.2. Le Générateur produit des "Hooks" (points d'accroche)**
*   Le pattern "Généré (`_`) vs Manuel (`_X`)" devient encore plus central.
*   Le code généré dans les fichiers `_` **orchestre** le processus.
*   Il appelle systématiquement des procédures dans les fichiers `_X` pour la logique de **persistance** et la logique **métier**.

**Exemple pour `_getByID` :**
```rpgle
// Dans _CUSTOMER_S.sqlrpgle (généré)
P _getByID B EXPORT
D _getByID PI LIKEDS(Customer_detail_t)
D  id ...
  
  DCL-DS dataL LIKEDS(Customer_detail_t);
  
  // Le code généré ne fait qu'une chose : appeler la procédure d'extension
  // qui est responsable de la récupération des données.
  dataL = Customer_X_loadByID(id);
  
  RETURN dataL;
P _getByID E
```
Le développeur est maintenant **obligé** d'implémenter `Customer_X_loadByID` dans le fichier `CUSTOMER_X_S.sqlrpgle`, que ce soit avec du SQL, un appel API, ou les deux.

---
### 4. Conclusion et Prochaines Étapes
CMagic est un DSL ambitieux qui vise à moderniser le développement sur IBM i en s'appuyant sur des concepts éprouvés tout en intégrant les meilleures pratiques modernes. Le MVP se concentre sur la gestion de deux entités clés, `Customer` et `CustomerOrder`, en prouvant la viabilité du concept à travers la génération d'artefacts essentiels.
Les prochaines étapes incluent :
*   Finaliser la grammaire du DSL et les templates de génération.
*   Développer le générateur de code Langium pour produire les artefacts cibles.
*   Mettre en place des tests unitaires et d'intégration pour valider le fonctionnement du générateur.
*   Documenter le processus de développement et les bonnes pratiques pour les développeurs IBM i.
*   Préparer une démonstration du MVP pour recueillir des retours et ajuster la feuille de route du projet.
---

## 📊 **ÉVOLUTION STRATÉGIQUE - SEPT 2024**

### 🎯 **Repositionnement Validé**
Suite à l'analyse du 30/09/2025, le projet adopte une **approche hybride** optimisée :

#### **Phase 1 : API REST Standard (Immédiat)**
- ✅ **Implémentation** selon `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- ✅ **Compatible universel** : React-Admin, Appsmith, Retool
- ✅ **ROI immédiat** sans lock-in technologique
- ✅ **Patterns validés** pour future génération

#### **Phase 2 : Générateur CMagic (Futur)**
- 🔄 **DSL CMagic** génère automatiquement les APIs REST
- 🔄 **Templates basés** sur patterns Phase 1 validés
- 🔄 **Backward compatible** avec APIs manuelles existantes

### 📈 **Métriques de Succès Ajustées**
| Métrique | Phase 1 (API) | Phase 2 (DSL) |
|----------|---------------|---------------|
| **Adoption** | 3 APIs créées manuellement | 10+ APIs générées |
| **Délai création** | 2 jours/API | 30 min/API |
| **Maintenance** | Manuelle | Régénération auto |

### 🎯 **Justification Stratégique**
**Référence :** `ressources/docs/strategique/analyse_repositionnement_sept2024.md`

Cette approche hybride permet de :
- **Dérisquer** le projet avec des technologies éprouvées
- **Livrer de la valeur immédiate** aux utilisateurs
- **Préparer l'avenir** avec des patterns validés pour le générateur
- **Capitaliser** sur l'excellente documentation `ibmi_rest_api_instructions.md`

**L'approche "API REST d'abord, générateur ensuite" respecte la philosophie IBM i d'évolution progressive plutôt que de révolution.**

---
### 5. le MVP : Contexte et Objectifs du Projet
Le projet CMagic vise à créer un DSL (Domain-Specific Language) pour modéliser des applications sur IBM i, en s'inspirant des concepts d'architecture éprouvés de l'OS/400. L'objectif est de permettre aux développeurs de décrire des entités métier, leurs relations, et leur cycle de vie de manière déclarative, tout en générant automatiquement les artefacts nécessaires à leur implémentation.

**Note stratégique (Sept 2024) :** Le périmètre initial est maintenant divisé en deux phases - d'abord valider les patterns avec des APIs REST manuelles, puis automatiser la génération avec le DSL CMagic.

Le périmètre du MVP est de prouver la viabilité du concept en générant l'ensemble des artefacts nécessaires pour la gestion de deux entités liées : une entité "maître" simple (`Customer`) et une entité "transactionnelle" avec un cycle de vie (`CustomerOrder`).
