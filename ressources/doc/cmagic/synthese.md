
---

# 🚀 Synthèse Globale CMagic : Modernisation IBM i & Roadmap Flight400

## 1. Vision et Philosophie

La méthodologie **CMagic** vise à extraire la valeur métier des applications legacy IBM i (AS/400) pour les porter vers des architectures Web modernes et découplées (API REST + React Admin). L'objectif est de standardiser le développement, de faciliter la communication avec les utilisateurs finaux et de tirer parti de l'IA (Copilot) comme assistant de codage, tout en conservant la robustesse du backend Db2/RPG.

---

## 2. Le Triptyque des Patterns Métier (Modélisation & DSL)

Toute application de gestion (ex: Flight400) est modélisée selon trois patterns fondamentaux pour faire le pont entre la base de données Db2 et l'UX moderne. Le code est rédigé grâce au DSL CMagic (`.cmagic`).

### A. L'Entité Catalogue (Données de Référence)

* **Rôle :** Master data, données de base stables sans cycle de vie complexe.
* **Cible React Admin :** Gestion de Ressources (CRUD). Utilisation des vues `<List>`, `<Edit>`, `<Create>` avec des grilles de données (Datagrid) et filtres.
* **Exemple DSL Flight400 (Aéroports) :**

```jdl
// airport.cmagic
// PATTERN CATALOGUE : Données de référence stables

entity Airport {
    id: Int required, // @autoIncrement
    codeOACI: String(4) required unique,
    name: String(80) required,
    city: String(50) required,
    country: String(3) default("FRA")
}

// Déclaration des opérations standards (CRUD + Recherche)
operations for Airport {
    CREATE, 
    CHANGE, 
    DELETE, 
    DISPLAY,
    // Génère l'écran de liste (WORK_WITH) et l'API de recherche
    WORK_WITH returns Airport {
        list_columns(codeOACI, name, city, country),
        filters(codeOACI, city)
    }
}
```

### B. L'Entité Processus (Dossier & Workflow)

* **Rôle :** Cas métier isolé évoluant dans le temps, régi par des statuts et des règles de transition.
* **Cible React Admin :** Pattern *Workflow & State*. Le statut est visuel (`<ChipField>`). Les transitions se font via des *Actions Métier* (boutons spécifiques, ex: "Confirmer") qui remplacent l'édition libre.
* **Exemple DSL Flight400 (Réservation) :**

```jdl
// booking.cmagic
// PATTERN PROCESSUS : Dossier avec cycle de vie et statuts

import './airport.cmagic'

enum BookingStatus {
    DRAFT, PAYMENT_PENDING, CONFIRMED, CANCELLED
}

entity Booking {
    bookingId: Int required, // @autoIncrement
    flightNumber: String(10) required,
    passengerName: String(80) required,
    status: BookingStatus required default(DRAFT)
}

// 1. Définition des Actions Métier explicites
action processPayment for Booking { in: { bookingId: Int } }
action issueTicket for Booking { in: { bookingId: Int } }
action cancelBooking for Booking { in: { bookingId: Int } }

// 2. Définition de la Machine à États (Workflow)
workflow BookingLifecycle for Booking {
    status_field status,
    initial DRAFT,

    // Les transitions sont contrôlées et déclenchent les actions métier
    transition 'pay' from DRAFT to PAYMENT_PENDING
        executes(processPayment(bookingId)),
      
    transition 'confirm' from PAYMENT_PENDING to CONFIRMED
        executes(issueTicket(bookingId)),
      
    transition 'cancel' from (DRAFT, PAYMENT_PENDING) to CANCELLED
        executes(cancelBooking(bookingId))
}

// 3. Opérations limitées (Pas de CREATE/CHANGE direct sur l'état)
operations for Booking {
    DISPLAY,
    WORK_WITH returns Booking {
        list_columns(bookingId, flightNumber, passengerName, status),
        filters(status)
    }
}
```

### C. L'Entité Saga (Orchestration Distribuée)

* **Rôle :** Coordination de transactions longues ou distribuées avec exécution de **compensations** automatiques en cas d'échec d'une étape.
* **Cible React Admin :** Gestion de l'asynchronisme. Utilisation d'indicateurs de progression et de composants *Timeline* pour afficher l'historique d'exécution et les compensations.
* **Exemple DSL Flight400 (Parcours d'Achat) :**

```jdl
// booking_saga.cmagic
// PATTERN SAGA : Orchestration distribuée et Compensations

import './booking.cmagic'

enum SagaStatus {
    PROCESSING, SUCCESS, FAILED, COMPENSATING, COMPENSATED
}

entity CompleteBookingSaga {
    sagaId: Int required,
    bookingId: Int required,
    status: SagaStatus required default(PROCESSING)
}

// 1. Actions "Aller" (Transactions locales/distribuées)
action reserveSeat for CompleteBookingSaga { ... }
action chargeStripePayment for CompleteBookingSaga { ... }

// 2. Actions de "Compensation" (Annulation en cas d'échec)
action releaseSeat for CompleteBookingSaga { ... } // Compense reserveSeat

// 3. Orchestration de la Saga
workflow BookingOrchestrator for CompleteBookingSaga {
    status_field status,
    initial PROCESSING,

    transition 'step1' from PROCESSING to PROCESSING
        executes(reserveSeat(bookingId)),
      
    transition 'step2' from PROCESSING to SUCCESS
        executes(chargeStripePayment(bookingId)),

    // Logique de Compensation (Échec au paiement -> Annulation du siège)
    transition 'fail_at_payment' from PROCESSING to COMPENSATING
        executes(releaseSeat(bookingId)), 

    transition 'finish_compensation' from COMPENSATING to COMPENSATED
}
```

---

## 3. Stratégie de Prototypage et Outillage (Starter `myschadcn`)

Avant d'écrire le code RPG backend, CMagic impose une phase de prototypage UX pour valider le langage ubiquitaire avec les métiers.

1. **Le Socle `myschadcn` :** Utilisation d'une architecture modulaire par domaine métier (DDD), mariant la logique de **React Admin** avec la modernité esthétique de **Tailwind CSS / shadcn/ui**.
2. **Simulation avec FakeRest :** Utilisation d'un fichier `data.json` centralisé qui simule instantanément une API REST complète. Cela permet de valider les IHM, les filtres et les boutons d'actions en conditions réelles, sans backend.
3. **L'Assistant IA (Copilot Agent Skill) :** Intégration d'un fichier `.github/skills/cmagic-react-admin/SKILL.md`. Grâce au *Few-Shot Prompting*, cette compétence oblige GitHub Copilot à générer du code React Admin et des données FakeRest en respectant strictement la ségrégation Catalogue/Processus/Saga.

---

## 4. Conventions Backend (IBM i / RPG)

Une fois l'UX validée, le code backend est généré via le DSL CMagic en respectant la philosophie IBM i :

* **Pattern du Fichier Unifié :** Le code RPG généré (API publique) et le code manuel (implémentation) cohabitent dans le même fichier source de service (`ENTITE_S.sqlrpgle`).
* **Convention `_local` :** Les API publiques exportées sont nommées `entite_action` (ex: `customer_getByID`). Les implémentations manuelles sont suffixées `_local` (ex: `customer_getByID_local`).
* **Zones Protégées :** Le code manuel du développeur RPG est impérativement encadré par des balises `[CMAGIC:MANUAL_START]` et `[CMAGIC:MANUAL_END]` pour garantir sa préservation lors des régénérations du DSL.

---

## 5. Roadmap de Mise en Œuvre : Projet Flight400

Plan d'action incrémental pour moderniser Flight400 en appliquant la méthode CMagic de bout en bout.

### 📍 Phase 1 : Prototypage UX & Validation Métier (Semaines 1-2)

* **Objectif :** Maquetter l'interface avec `myschadcn` et valider l'ergonomie avec les métiers avant le développement backend.
* **Actions :** Configurer `data.json` pour FakeRest (vols, réservations). Développer l'IHM React Admin. Coder les boutons d'Actions Métier pour simuler les changements d'état.
* **Livrable :** Prototype interactif validé par les utilisateurs finaux.

### 📍 Phase 2 : Modélisation DSL & Ingénierie des Données (Semaines 3-4)

* **Objectif :** Formaliser la structure de données, les relations et la machine à états métier.
* **Actions :** Rédiger les fichiers `.cmagic` (voir Section 2). Générer les scripts DDL SQL pour Db2 for i (Tables, Index, FK).
* **Livrable :** Schéma de base de données relationnel moderne déployé sur IBM i et spécification formelle du workflow.

### 📍 Phase 3 : Génération Backend & Logique RPG (Semaines 5-8)

* **Objectif :** Produire les services robustes et sécurisés sur IBM i.
* **Actions :** Générer les copybooks (`.rpgleinc`) et les modules de service (`SRVPGM`) unifiés. Implémenter la logique métier dans les zones `[CMAGIC:MANUAL_START]`.
* **Livrable :** Couche de services RPG (API) compilée, testée unitairement et prête à être exposée.

### 📍 Phase 4 : Orchestration de la Saga & Résilience (Semaines 9-12)

* **Objectif :** Gérer les parcours distribués complexes et l'intégration externe.
* **Actions :** Développer l'orchestrateur de la Saga. Coder les procédures de compensation en RPG (`releaseSeat`). Mettre à jour l'IHM React Admin avec un composant *Timeline* pour l'asynchronisme.
* **Livrable :** Application Flight400 modernisée de bout en bout, résiliente et prête pour la production.

---

Ce document complet vous servira de pilier central. Que diriez-vous de passer à la prochaine étape pratique, par exemple en demandant à Copilot de générer le code source React Admin pour l'entité *Booking* (Processus) basée sur ce nouveau document de référence ?
