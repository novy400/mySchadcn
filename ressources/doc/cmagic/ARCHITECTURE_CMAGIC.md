# Référentiel d'architecture CMagic

_Statut : architecture cible. Les écarts avec le prototype sont signalés explicitement._

## Contexte

CMagic accompagne la modernisation d'applications IBM i historiques, notamment le cas
d'étude Flight400. L'objectif est de remplacer progressivement les écrans 5250
monolithiques par une interface Web modulaire, une API explicite et des services métier
maintenus sur IBM i.

Le prototype [mySchadcn](../architecture-actuelle.md) sert à valider les ressources, les
écrans et les contrats de données avant la réalisation du backend.

## Classification métier

Chaque capacité est classée selon son comportement :

1. **Catalogue** : donnée stable gérée principalement en CRUD.
2. **Processus** : dossier avec états, transitions et actions métier.
3. **Saga** : coordination d'une action répartie sur plusieurs systèmes, avec reprise et
   compensations.

Une action métier relie le processus à son exécution. Le vocabulaire détaillé se trouve
dans [Concepts CMagic](./concepts-cmagic.md).

## Architecture cible

```text
┌─────────────────────────────────────────────────────────────┐
│ Frontend                                                    │
│ mySchadcn · React 19 · ra-core · shadcn-admin-kit local     │
│ Ressources, listes, formulaires, actions et suivi d'état     │
└─────────────────────────────┬───────────────────────────────┘
                              │ DataProvider / HTTP
┌─────────────────────────────▼───────────────────────────────┐
│ API                                                         │
│ Contrats CRUD · recherches · actions métier · erreurs        │
│ Authentification · autorisations · idempotence · observabilité│
└─────────────────────────────┬───────────────────────────────┘
                              │ services et données
┌─────────────────────────────▼───────────────────────────────┐
│ IBM i                                                       │
│ Db2 for i · RPG ILE Full-Free · services métier             │
│ Vues de lecture · transactions locales · orchestrations      │
└─────────────────────────────────────────────────────────────┘
```

## Architecture du prototype

Le prototype ne contient pas de `data.json`. Ses données passent par :

```text
baseData.ts → buildSummaries.ts → fakerestData.ts → DataProvider FakeRest
```

Cette couche locale simule :

- les collections CRUD ;
- des vues enrichies comme `contacts_summary` ;
- la navigation et les formulaires ;
- certains états simples, par exemple ceux des commandes.

Elle ne simule pas encore :

- un contrat HTTP ;
- une authentification ;
- des transitions métier sécurisées ;
- une exécution asynchrone ;
- une Saga ou ses compensations ;
- la génération à partir d'un DSL `.cmagic`.

## Responsabilités

### Frontend

- présenter les données et actions autorisées ;
- envoyer des intentions explicites ;
- empêcher les doubles soumissions évidentes ;
- afficher l'état courant et les erreurs métier ;
- ne pas décider seul de la validité d'une transition.

### API

- normaliser les contrats React Admin ;
- appliquer authentification et autorisations ;
- valider les commandes ;
- assurer l'idempotence des actions sensibles ;
- exposer un suivi pour les opérations asynchrones.

### IBM i et services métier

- porter les invariants métier ;
- exécuter les transactions locales ;
- produire les vues ou agrégats nécessaires aux écrans ;
- participer aux étapes et compensations d'une Saga ;
- conserver une traçabilité exploitable.

## Règle d'évolution

Une fonctionnalité est d'abord validée dans le prototype. Son contrat et ses invariants
sont ensuite documentés. Elle n'est qualifiée de « processus » ou de « Saga implémentée »
qu'après réalisation et test des garanties correspondantes côté backend.
