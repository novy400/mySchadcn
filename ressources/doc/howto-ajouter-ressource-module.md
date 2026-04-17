# How-to: ajouter une nouvelle ressource dans un module

Ce guide explique comment ajouter une nouvelle ressource CRM dans l'architecture actuelle du projet.

Exemple utilise: `deals`.

## 1. Creer le dossier du module

Creer un dossier:

```text
src/modules/crm/deals/
```

## 2. Creer le fichier de types du module

Chaque module possede son propre fichier `*.types.ts`. Les types utilisent `type` (pas `interface`) et `Pick<RaRecord, 'id'>` pour l'identifiant, conformement aux conventions react-admin.

Creer `src/modules/crm/deals/deal.types.ts`:

```ts
import type { RaRecord } from 'ra-core';

export type DealStatus = 'OPEN' | 'WON' | 'LOST';

export type Deal = {
  titre: string;
  status: DealStatus;
  contact_id: number;
} & Pick<RaRecord, 'id'>;
```

> **Pourquoi `Pick<RaRecord, 'id'>` ?** Cela aligne le type sur le contrat react-admin (`Identifier`) plutot que de fixer `id: number` en dur, ce qui facilite la migration vers un backend IBM i.

## 3. Creer les ecrans CRUD du module

Ajouter les fichiers:

- `DealList.tsx`
- `DealEdit.tsx`
- `DealCreate.tsx`
- `deal.resource.tsx`
- `index.ts`

Exemple minimal pour la liste:

```tsx
import { DataTable, List, NumberField, TextField } from '@/components/admin';

export const DealList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <NumberField source="id" />
      </DataTable.Col>
      <DataTable.Col source="titre">
        <TextField source="titre" />
      </DataTable.Col>
      <DataTable.Col source="status">
        <TextField source="status" />
      </DataTable.Col>
    </DataTable>
  </List>
);
```

Exemple minimal pour la ressource:

```tsx
import { ResourceProps } from 'ra-core';
import { Handshake } from 'lucide-react';
import { DealList } from './DealList';
import { DealEdit } from './DealEdit';
import { DealCreate } from './DealCreate';

export const deals: ResourceProps = {
  name: 'deals',
  list: DealList,
  edit: DealEdit,
  create: DealCreate,
  recordRepresentation: 'titre',
  icon: Handshake,
};
```

Exemple `index.ts`:

```ts
export { deals } from './deal.resource';
```

## 3. Declarer la collection dans les donnees FakeRest

Ajouter `deals` dans:

- `src/modules/crm/deals/deal.types.ts` (deja fait a l'etape 2)
- `src/data/projections/buildSummaries.ts` (import du type + ajout dans `BaseData`)
- `src/data/raw/baseData.ts` (dataset initial)

Dans `buildSummaries.ts`, importer le type depuis le module (ne pas redeclarer localement):

```ts
import type { Deal } from '@/modules/crm/deals/deal.types';

export type BaseData = {
  clients: Client[];
  contacts: Contact[];
  tasks: Task[];
  notes: Note[];
  deals: Deal[];
};
```

Et ajouter des donnees dans `baseData.ts`:

```ts
deals: [
  { id: 1, contact_id: 1, titre: 'Migration IBM i', status: 'OPEN' },
],
```

## 4. Brancher la ressource dans App

Dans `src/app/App.tsx`:

1. Importer la ressource du module.
2. Ajouter `<Resource {...deals} />` dans le composant `Admin`.

Exemple:

```tsx
import { deals } from '../modules/crm/deals';

// ...

<Resource {...deals} />
```

## 5. Verifier le comportement

Lancer:

```bash
npm run dev
```

Verifier:

- la ressource apparait dans la navigation
- la liste charge sans erreur
- create et edit fonctionnent

## 6. Checklist rapide

- dossier module cree
- `*.types.ts` cree avec `type` + `Pick<RaRecord, 'id'>` (pas `interface`, pas `id: number`)
- fichiers `List`, `Edit`, `Create` crees
- `*.resource.tsx` exporte un `ResourceProps`
- `index.ts` exporte la ressource
- type importe dans `buildSummaries.ts` (pas redeclare localement)
- `BaseData` mis a jour
- collection ajoutee dans `baseData.ts`
- ressource ajoutee dans `src/app/App.tsx`

## 7. Cas particulier: ressource de projection

Si tu ajoutes une vue enrichie (type `xxx_summary`):

- calcule la vue dans `buildSummaries.ts`
- expose-la dans le dataset final
- cree une ressource avec `list` seulement si c'est une vue de lecture

Exemple dans ce projet: `contacts_summary`.