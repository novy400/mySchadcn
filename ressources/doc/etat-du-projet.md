# État du projet

_Date de vérification : 2026-07-22_

## Résumé exécutif

`mySchadcn` est un mini CRM d'administration fonctionnel basé sur Vite, React,
TypeScript, `ra-core` et `ra-data-fakerest`. Il sert à valider une architecture modulaire,
des écrans métier et des contrats de données avant une migration vers une API réelle.

Le dépôt contient aujourd'hui :

- un dashboard CRM ;
- six modules métier principaux : clients, contacts, tâches, notes, fournisseurs et
  commandes ;
- une fiche `customers` composée d'onglets ;
- deux projections locales : `contacts_summary` et `tasks_with_client` ;
- des composants admin et UI maintenus localement ;
- une authentification de démonstration et une politique d'accès à trois rôles ;
- une suite active de tests Vitest.

## Ressources enregistrées

| Ressource | Capacités |
| --- | --- |
| `clients` | liste, création, édition |
| `contacts` | liste, création, édition |
| `tasks_with_client` | liste enrichie ; création/édition sur les données `tasks` |
| `notes` | liste, création, édition |
| `contacts_summary` | liste de synthèse en lecture |
| `fournisseurs` | liste, création, édition |
| `orders` | liste filtrée par statut, édition |
| `customers` | liste, fiche détaillée avec onglets |
| `customerSignalietiques` | ressource technique de détail |
| `customerRisques` | ressource technique de détail |

La liste exacte est assemblée dans `src/app/App.tsx`.

## Fonctionnalités notables

### Accès

- connexion obligatoire avec adapter d'identité remplaçable ;
- rôles Lecteur, Agent et Responsable ;
- routes, menus, suppressions et actions de commande filtrés par la même politique ;
- distinction entre expiration de session (`401`) et refus d'accès (`403`).

### Dashboard

- indicateurs issus du dataset local ;
- contacts à suivre ;
- tests de rendu ciblés.

### Tâches

- recherche textuelle ;
- filtre par contact ;
- filtre par client grâce à la projection `tasks_with_client` ;
- filtre par statut ;
- tri par date d'échéance.

### Commandes

- onglets `ordered`, `delivered` et `canceled` ;
- compteur par statut ;
- filtre par client ;
- sélection des colonnes et export ;
- édition du client et de la date ;
- transitions contrôlées via les actions Livrer, Annuler et Signaler le retour ;
- restitution du panier et des totaux.

### Customers

- liste ;
- fiche de consultation ;
- onglets Général, Signalétique et Risque métier.

## Architecture et données

Le pipeline actuel est :

```text
baseData.ts
→ buildSummaries.ts
→ fakerestData.ts
→ dataProvider.ts
→ composants CRM
```

Voir [Architecture actuelle](./architecture-actuelle.md) pour le détail.

## Tests

La suite active sélectionne les fichiers `*.test.ts` et `*.test.tsx`. Elle couvre
notamment :

- les projections ;
- le dashboard ;
- les listes, créations et éditions des modules clients, contacts, tâches et notes ;
- plusieurs composants admin, dont `Admin`, `DataTable` et `ResourcePage` ;
- les principaux sous-composants de `DataTable` ;
- les variantes du rich-text input.
- la liste et le contrat de ressource `fournisseurs` ;
- les onglets de statut et le contrat de ressource `orders` ;
- le cycle de vie et les actions autorisées des commandes ;
- la liste `customers` et ses données Général, Signalétique et Risque.

Les anciens fichiers `*.spec.ts(x)` restent hors de la suite active et ne doivent pas
être présentés comme une couverture opérationnelle.

## Limites actuelles

- aucune persistance après rechargement complet ;
- projections FakeRest recalculées après création, modification ou modification en masse
  de leurs ressources sources ;
- authentification locale non adaptée à la production et autorisations non imposées par un backend ;
- absence de vrai contrat HTTP avec IBM i ;
- produits du panier de commande non modélisés comme ressource ;
- documentation CMagic encore composée en partie de notes exploratoires.

## Priorités

1. Stabiliser la documentation et distinguer état présent, décisions et cible.
2. Formaliser le contrat du futur DataProvider IBM i.
3. Préparer l'authentification et les autorisations avant toute utilisation réelle.
4. Remplacer le recalcul local des projections par des endpoints cohérents lors de la
   migration IBM i.
5. Étendre le modèle des commandes aux retours détaillés et à l'historique si nécessaire.

## Vérification

Les commandes de référence sont :

```bash
npm run lint
npm run test
npm run build
```

Le démarrage local utilise :

```bash
npm run dev
```

Les statuts « vert » de ces commandes doivent être confirmés par une exécution récente ;
ils ne sont pas supposés uniquement à partir de ce document.
