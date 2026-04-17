# How-to: ajouter une ressource de projection (xxx_summary)

Ce guide explique comment ajouter une vue enrichie de type `xxx_summary` dans l'architecture actuelle.

Exemple utilise: `deals_summary`.

## Quand utiliser une projection

Utilise une projection quand une liste doit afficher des donnees agregees provenant de plusieurs collections (ex: compteur, dernier evenement, statut calcule).

## 1. Creer le fichier de types du module source

Avant toute chose, le type de l'entite source doit etre declare dans son propre module, pas dans `buildSummaries.ts`.

Creer `src/modules/crm/deals/deal.types.ts`:

```ts
import type { RaRecord } from 'ra-core';

export type DealStatus = 'OPEN' | 'WON' | 'LOST';

export type Deal = {
  contact_id: number;
  titre: string;
  status: DealStatus;
} & Pick<RaRecord, 'id'>;
```

> **Regle** : chaque module possede son fichier `*.types.ts`. Les types utilisent `type` (pas `interface`) et `Pick<RaRecord, 'id'>` pour l'identifiant.

## 2. Etendre les types dans le pipeline de donnees

Dans `src/data/projections/buildSummaries.ts`, importer le type depuis le module (ne pas le redeclarer localement) :

```ts
import type { Client } from '@/modules/crm/clients/client.types';
import type { Contact } from '@/modules/crm/contacts/contact.types';
import type { Task } from '@/modules/crm/tasks/task.types';
import type { Note } from '@/modules/crm/notes/note.types';
import type { Deal } from '@/modules/crm/deals/deal.types';

export type BaseData = {
  clients: Client[];
  contacts: Contact[];
  tasks: Task[];
  notes: Note[];
  deals: Deal[];
};

export const buildSummaries = (data: BaseData) => {
  const deals_summary = data.deals.map((deal) => {
    const contact = data.contacts.find((c) => c.id === deal.contact_id);
    const client = data.clients.find((cl) => cl.id === contact?.client_id);

    return {
      id: deal.id,
      titre: deal.titre,
      status: deal.status,
      contact_name: contact ? `${contact.prenom} ${contact.nom}` : '',
      client_name: client?.nom ?? '',
    };
  });

  return {
    ...data,
    deals_summary,
  };
};
```

## 3. Alimenter les donnees brutes

Dans `src/data/raw/baseData.ts`, ajouter la collection source (`deals`) avec des donnees de test.

Exemple:

```ts
deals: [
  { id: 1, contact_id: 1, titre: 'Migration IBM i', status: 'OPEN' },
  { id: 2, contact_id: 3, titre: 'Refonte front', status: 'WON' },
],
```

## 4. Creer le module de projection

Creer `src/modules/crm/deals-summary/` avec:

- `DealSummaryList.tsx`
- `dealSummary.resource.tsx`
- `index.ts`

Exemple de liste (lecture seule):

```tsx
import { DataTable, List, TextField } from '@/components/admin';

export const DealSummaryList = () => (
  <List resource="deals_summary">
    <DataTable>
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="titre">
        <TextField source="titre" />
      </DataTable.Col>
      <DataTable.Col source="status">
        <TextField source="status" />
      </DataTable.Col>
      <DataTable.Col source="contact_name" label="Contact">
        <TextField source="contact_name" />
      </DataTable.Col>
      <DataTable.Col source="client_name" label="Client">
        <TextField source="client_name" />
      </DataTable.Col>
    </DataTable>
  </List>
);
```

Exemple de resource:

```tsx
import { ResourceProps } from 'ra-core';
import { Eye } from 'lucide-react';
import { DealSummaryList } from './DealSummaryList';

export const dealsSummary: ResourceProps = {
  name: 'deals_summary',
  list: DealSummaryList,
  options: { label: 'Vue deals' },
  icon: Eye,
};
```

Exemple `index.ts`:

```ts
export { dealsSummary } from './dealSummary.resource';
```

## 5. Brancher la ressource dans App

Dans `src/app/App.tsx`:

- importer `dealsSummary`
- ajouter `<Resource {...dealsSummary} />`

## 6. Verifier

```bash
npm run dev
```

Verifier:

- la vue apparait dans la navigation
- la liste charge les champs enrichis
- la projection se recalcule via `buildSummaries`

## Checklist

- `*.types.ts` cree dans le module source avec `type` + `Pick<RaRecord, 'id'>` (pas `interface`)
- type importe dans `buildSummaries.ts` depuis le module (pas redeclare localement)
- `BaseData` etendu
- source ajoutee dans `baseData.ts`
- projection `xxx_summary` calculee et retournee
- module `*-summary` cree
- ressource branchee dans `App.tsx`
