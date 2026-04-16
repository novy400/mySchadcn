#  IBM i, React-Admin + FakeRest

## objectif
Ce projet a pour objectif de fournir un exemple de base pour démarrer une application React-Admin avec une API FakeRest, le tout tournant sur un serveur IBM i. Il est conçu pour être simple et facile à comprendre, tout en démontrant les concepts clés de l'intégration entre React-Admin et une API REST.

L’idée est simple : React-Admin fournit l’interface CRUD, et ra-data-fakerest joue le rôle de faux backend en mémoire, à partir d’un objet JSON local, sans requêtes HTTP réelles.

Cette approche est particulièrement adaptée pour valider un modèle métier, tester les écrans, préparer les ressources, puis remplacer ensuite FakeRest par un vrai data provider REST connecté à IBM i.

## État actuel du code (avril 2026)

Le dépôt a déjà dépassé le simple squelette initial. Les éléments suivants sont en place:

- Dashboard CRM branché dans l'admin
- Ressources CRUD: `clients`, `contacts`, `tasks`, `notes`
- Ressource de projection: `contacts_summary` (liste de synthèse)
- Pipeline de données: `baseData` -> `buildSummaries` -> `fakerestData` -> `dataProvider`
- Architecture modulaire sous `src/modules/crm/*`

Référence à jour pour l'exécution et la structure: `README.md`.

## Installation et démarrage

[Voir le tutoriel détaillé pour créer ce projet étape par étape](./tutoriel-vite-react-admin-fakerest-modulaire.md)

[How-to: ajouter une nouvelle ressource dans un module](./howto-ajouter-ressource-module.md)

[How-to: ajouter une ressource de projection (xxx_summary)](./howto-ajouter-ressource-projection-summary.md)

[How-to: migrer FakeRest vers un data provider REST IBM i](./howto-migrer-fakerest-vers-rest-ibmi.md)


## Méthode IBM i

3 phases/couches pour construire ton application :

Couche 1 : prototype React-Admin avec noms métier lisibles.

Couche 2 : faux dataset inspiré des fichiers DB2/physiques IBM i, mais simplifié.

Couche 3 : futur data provider REST branché sur IBM i, sans changer les écrans React-Admin, seulement la source des données.

| Étape             | But                                     | Outil                                   |
| ----------------- | --------------------------------------- | --------------------------------------- |
| Prototype UI      | Valider navigation, listes, formulaires | React-Admin + FakeRest npmjs            |
| Simulation API    | Tester structure REST réaliste          | JSON Server ou FakeRest npmjs+1         |
| Industrialisation | Connecter IBM i réel                    | Data provider REST personnalisé npmjs+1 |

> séparer très tôt la conception de l’interface de la complexité d’exposition des données IBM i.

## Petit plan de cours
mini-cours en 5 séances :

1. Découvrir React-Admin : Admin, Resource, List, Edit, Create.

1. Prototyper sans backend avec ra-data-fakerest et un JSON local.

1. Structurer un domaine métier IBM i en ressources d’admin.

1. Remplacer les Guessers par de vrais écrans métier.

1. Préparer la migration vers JSON Server puis vers un backend IBM i réel.

## Idée d’architecture

Le bon principe est de combiner :

- une organisation par features ou domaines métier ;

- une petite couche de composants UI réutilisables ;

- des ressources React-Admin assemblées au niveau central.

## Pour IBM i
```
src/
├─ app/
│  ├─ App.tsx
│  ├─ providers/
│  │  └─ dataProvider.ts
│  └─ routes/
├─ modules/
│  ├─ crm/
│  │  ├─ clients/
│  │  │  ├─ ClientList.tsx
│  │  │  ├─ ClientEdit.tsx
│  │  │  ├─ ClientCreate.tsx
│  │  │  ├─ client.types.ts
│  │  │  ├─ client.data.ts
│  │  │  └─ client.resource.tsx
│  │  └─ contacts/
│  ├─ sales/
│  │  └─ opportunities/
│  └─ shared/
│     ├─ ui/
│     ├─ fields/
│     └─ forms/
├─ data/
│  └─ fakerestData.ts
└─ main.tsx

```
Cette approche sépare clairement :

- l’assemblage global de l’application ;

- les modules métier ;

- les briques réutilisables.

La logique est la suivante :

- app/ contient la composition globale de l’application.

- modules/ contient les features métier, ici crm/clients et crm/contacts.

- data/ contient le faux backend local branché sur ra-data-fakerest, qui travaille à partir d’un objet JSON sans serveur externe

Front de tes sous-domaines IBM i, par exemple :

- crm/clients

- crm/adresses

- sales/commandes

- stock/articles

- billing/factures

## Règles d’organisation

- Un module métier = un dossier = une ressource React-Admin.

- Chaque module expose ses écrans CRUD et son fichier *.resource.tsx.

- Le dataProvider est centralisé dans app/providers, ce qui facilitera plus tard le passage de FakeRest vers une API IBM i.

## Grands principes

- la logique de CRM par domaines métier, par exemple contacts, tâches, notes, deals et activités ;

- la composition modulaire autour d’un composant racine et de ressources spécialisées ;

- l’idée de préparer dès le début des vues ou agrégats pour simplifier le frontend.

## Vues et agrégats

Certaines pages ont besoin de données issues de plusieurs tables, et qu’il utilise pour cela des database views afin de réduire la complexité côté frontend et le nombre d’appels HTTP.

## Road map

| Niveau   | Objectif         | Ce que tu empruntes à Atomic CRM                                                 |
| -------- | ---------------- | -------------------------------------------------------------------------------- |
| Niveau 1 | Prototype propre | Modules métier, Resource séparées, types TS, composants réutilisables marmelab+1 |
| Niveau 2 | CRM crédible     | Ajout de tasks, notes, deals, vues *_summary simulées                            |
| Niveau 3 | Pré-prod         | Vrai data provider REST IBM i, agrégats côté backend, sécurité et workflows      |

- Garder ton starter Vite + React-Admin + FakeRest + TypeScript.

- intégrer schadcdn kit de composants UI réutilisables (StatusChip, KpiCard, EmptyState, etc.) pour éviter de repartir de zéro sur les éléments de base.
  - [github shadcn-admin-kit](https://github.com/marmelab/shadcn-admin-kit)
  - [Marmelab shadcn-admin-kit](https://marmelab.com/shadcn-admin-kit/)

- Étendre ton modèle vers companies, contacts, tasks, notes.

- Créer des vues simulées contacts_summary et companies_summary pour les listes.

- Introduire ensuite un vrai data provider IBM i en conservant les mêmes resources

### Le meilleur next step, sans quitter FakeRest, serait donc :

- ajouter tasks ;

- ajouter contacts_summary ;

- créer un mini dashboard basé sur ces projections ;

- conserver une architecture par modules métier.

## Pattern à copier
Le point le plus intelligent du dépôt, pour ton cas, est le pattern suivant : le frontend ne travaille pas toujours sur les tables brutes, mais sur des vues adaptées aux écrans.
Exemple : une liste de contacts peut afficher nom, société, nombre de tâches ouvertes, dernière interaction et statut commercial, même si ces données viennent de plusieurs sources.

Dans ton FakeRest, tu peux donc avoir à la fois :

- contacts

- tasks

- notes

- contacts_summary

Exemple de collection simulée :
```typescript
const fakerestData = {
  contacts: [
    { id: 1, companyId: 1, prenom: 'Jean', nom: 'Dupont', email: 'jean@dupont.fr' }
  ],
  tasks: [
    { id: 1, contactId: 1, title: 'Rappeler', status: 'OPEN' }
  ],
  contacts_summary: [
    {
      id: 1,
      prenom: 'Jean',
      nom: 'Dupont',
      email: 'jean@dupont.fr',
      openTasks: 1,
      lastInteraction: '2026-03-28',
      companyName: 'Dupont SA'
    }
  ]
};
```

Ce pattern te prépare très bien à une future implémentation IBM i, où ces vues pourraient venir d’une vue SQL DB2, d’un service RPG, ou d’une couche d’API d’agrégation.

> Créer des vues simulées contacts_summary et companies_summary pour les listes.

- des modules métier bien séparés ;

- des ressources React-Admin explicites ;

- des “views” ou collections enrichies simulées directement dans les données FakeRest.

## Evolution
```python
src/
├─ app/
│  ├─ App.tsx
│  └─ providers/
│     └─ dataProvider.ts
├─ data/
│  ├─ raw/
│  │  └─ baseData.ts
│  ├─ projections/
│  │  └─ buildSummaries.ts
│  └─ fakerestData.ts
├─ modules/
│  └─ crm/
│     ├─ clients/
│     ├─ contacts/
│     ├─ contacts-summary/
│     ├─ tasks/
│     └─ notes/
├─ shared/
│  ├─ ui/
│  └─ types/
└─ main.tsx
```
Cette organisation sépare bien :

- les données brutes ;

- les projections calculées ;

- les modules métier React-Admin.


Pourquoi data/projections ? Parce qu’au lieu d’écrire à la main toutes les vues enrichies, tu peux les calculer depuis les données brutes avant de les injecter dans FakeRest. 
Cela te prépare à une future couche d’agrégation côté backend IBM i, où tu pourrais faire la même chose pour construire des vues SQL ou des services d’agrégation.

## liste avec projections et crud avec une netité brute
### Resource contacts_summary
Je te conseille d’utiliser contacts_summary pour la liste principale, et contacts pour l’édition/création. C’est souvent le meilleur compromis entre lisibilité de l’UI et simplicité du modèle.

| Phase              | Où se trouve l’intelligence ?              | Pourquoi                                        |
| ------------------ | ------------------------------------------ | ----------------------------------------------- |
| Prototype FakeRest | buildSummaries() côté frontend             | Simule vite le futur backend github+1           |
| Préparation API    | contrat de données figé (contacts_summary) | Stabilise les écrans et les types linkedin      |
| Backend IBM i      | vues SQL / service RPG / API agrégée       | Simplifie le client et prépare la prod github+1 |


src/modules/crm/contacts-summary/ContactSummaryList.tsx
```typescript
import { List, Datagrid, TextField, EmailField, NumberField } from 'react-admin';

export const ContactSummaryList = () => (
  <List resource="contacts_summary">
    <Datagrid rowClick={(_, __, record) => `/contacts/${record.id}`}>
      <TextField source="id" />
      <TextField source="prenom" />
      <TextField source="nom" />
      <EmailField source="email" />
      <TextField source="client_name" label="Client" />
      <TextField source="client_city" label="Ville" />
      <NumberField source="open_tasks" label="Tâches ouvertes" />
      <TextField source="last_note_date" label="Dernière note" />
    </Datagrid>
  </List>
);
```

src/modules/crm/contacts-summary/contactSummary.resource.tsx
```typescript
import { Resource } from 'react-admin';
import { ContactSummaryList } from './ContactSummaryList';

export const ContactSummaryResource = (
  <Resource
    name="contacts_summary"
    list={ContactSummaryList}
    options={{ label: 'Vue contacts' }}
  />
);
```
## propsition d'archi modulaire
```python
src/
├─ app/
│  ├─ App.tsx
│  └─ providers/
│     └─ dataProvider.ts
├─ data/
│  ├─ raw/
│  │  └─ baseData.ts
│  ├─ projections/
│  │  └─ buildSummaries.ts
│  └─ fakerestData.ts
├─ shared/
│  ├─ ui/
│  │  ├─ StatusChip.tsx
│  │  ├─ KpiCard.tsx
│  │  ├─ EmptyState.tsx
│  │  └─ SectionTitle.tsx
│  └─ admin/
│     ├─ DashboardHeader.tsx
│     ├─ QuickStats.tsx
│     ├─ SidebarNav.tsx
│     └─ AdminToolbar.tsx
├─ modules/
│  └─ crm/
│     ├─ clients/
│     │  ├─ ClientList.tsx
│     │  ├─ ClientEdit.tsx
│     │  └─ client.resource.tsx
│     ├─ contacts/
│     ├─ contacts-summary/
│     ├─ tasks/
│     ├─ notes/
│     └─ dashboard/
└─ main.tsx
```
- shared/ui contient seulement les briques UI génériques ;

- shared/admin contient les composants transverses liés à l’interface d’administration ;

- modules/crm/... contient le vrai métier.

| Point               | Version pédagogique                                     | Version proche d’Atomic CRM                                 |
| ------------------- | ------------------------------------------------------- | ----------------------------------------------------------- |
| Question principale | “Quel est le niveau du composant ?” youtube             | “À quoi sert ce composant et dans quel contexte ?” marmelab |
| Organisation UI     | atoms / molecules / organisms feature-sliced            | ui / admin / modules métier marmelab+1                      |
| Avantage            | Très claire pour apprendre la composition UI youtube    | Plus pratique pour une vraie app CRM dev+1                  |
| Risque              | Trop théorique si tu l’appliques partout feature-sliced | Moins “académique”, mais souvent plus concret dev           |

en priorité la réutilisation de :

- composants de présentation génériques dans shared/ui ;

- composants de shell ou de mise en page admin dans shared/admin ;

- conventions d’organisation par entité dans modules/crm.

➡️ [variante2 : organisation par type de composant](./starter-variante-2-react-admin-fakerest-ibmi.md)

