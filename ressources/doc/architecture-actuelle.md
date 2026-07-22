# Architecture actuelle

_État constaté le 2026-07-22._

## Finalité

`mySchadcn` est un prototype de CRM d'administration. Il valide les écrans, les
ressources et les contrats de données avant le branchement d'une API réelle, notamment
sur IBM i.

## Stack

- Vite 8
- React 19
- TypeScript 5
- `ra-core` 5
- `ra-data-fakerest` 5
- Tailwind CSS 4
- Vitest et Testing Library

Les composants d'administration sont maintenus localement dans
`src/components/admin`. Les primitives visuelles sont dans `src/components/ui`.

## Entrées principales

```text
src/main.tsx
└─ src/app/App.tsx
   ├─ src/app/providers/dataProvider.ts
   ├─ src/modules/crm/dashboard/Dashboard.tsx
   └─ ressources déclarées avec <Resource>
```

`src/app/App.tsx` est la composition centrale. Chaque module exporte un objet
`ResourceProps`, puis l'application l'enregistre avec `<Resource {...resource} />`.

## Modules métier

```text
src/modules/crm/
├─ clients/
├─ contacts/
├─ contacts-summary/
├─ customers/
├─ dashboard/
├─ fournisseurs/
├─ notes/
├─ orders/
└─ tasks/
```

Les modules contiennent les écrans et types propres à leur ressource. La logique de
projection transverse reste dans `src/data/projections`.

## Ressources actives

| Ressource | Nature | Écrans principaux |
| --- | --- | --- |
| `clients` | Donnée brute | liste, création, édition |
| `contacts` | Donnée brute | liste, création, édition |
| `tasks_with_client` | Projection enrichie des tâches | liste, création et édition routées vers `tasks` |
| `notes` | Donnée brute | liste, création, édition |
| `contacts_summary` | Projection en lecture | liste |
| `fournisseurs` | Donnée brute | liste, création, édition |
| `orders` | Donnée brute | liste par statut, édition |
| `customers` | Donnée brute | liste, fiche avec onglets |
| `customerSignalietiques` | Détail technique | utilisé par la fiche client |
| `customerRisques` | Détail technique | utilisé par la fiche client |

## Pipeline de données

```text
src/data/raw/baseData.ts
        │ données brutes typées
        ▼
src/data/projections/buildSummaries.ts
        │ contacts_summary + tasks_with_client
        ▼
src/data/fakerestData.ts
        │ dataset final
        ▼
src/app/providers/dataProvider.ts
        │ contrat DataProvider
        ▼
écrans d'administration
```

`buildSummaries` est une fonction pure. Les projections sont construites lors de la
création du dataset FakeRest. Elles ne constituent pas une synchronisation automatique
après chaque mutation effectuée pendant une session.

## Frontière avec le futur backend

La frontière principale est le `DataProvider`. Une migration vers IBM i devra préserver
les noms de ressources et les champs attendus par les écrans, ou les normaliser dans le
provider.

Les projections telles que `contacts_summary` et `tasks_with_client` sont des contrats
d'écran. En production, elles pourront être alimentées par des vues Db2, des services RPG
ou des endpoints d'agrégation.

## Contraintes connues

- les données FakeRest ne persistent pas après un rechargement complet ;
- les projections locales peuvent devenir obsolètes après une mutation de leurs sources ;
- les ressources de détail `customerSignalietiques` et `customerRisques` utilisent le même
  identifiant que leur `customer` plutôt qu'une relation explicite ;
- le panier d'une commande référence des produits qui ne sont pas encore exposés comme
  ressource ;
- `src/components/rich-text-input` reste une zone sensible à modifier avec prudence.

## Vérifications obligatoires

Après toute évolution significative :

```bash
npm run lint
npm run test
npm run build
```
