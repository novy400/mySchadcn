# How-to: ajouter une ressource de projection (xxx_summary)

Ce guide explique comment ajouter une vue enrichie de type `xxx_summary` dans l'architecture actuelle.

Exemple utilise: `deals_summary`.

## Quand utiliser une projection

Utilise une projection quand une liste doit afficher des donnees agregees provenant de plusieurs collections (ex: compteur, dernier evenement, statut calcule).

## 1. Etendre les types dans le pipeline de donnees

Dans `src/data/projections/buildSummaries.ts`:

1. Ajouter le type source manquant (si besoin), par exemple `Deal`.
2. Ajouter la collection source dans `BaseData`.
3. Calculer `deals_summary` dans `buildSummaries`.
4. Retourner la projection dans l'objet final.

Exemple simplifie:

```ts
type Deal = {
  id: number;
  contact_id: number;
  titre: string;
  status: 'OPEN' | 'WON' | 'LOST';
};

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

## 2. Alimenter les donnees brutes

Dans `src/data/raw/baseData.ts`, ajouter la collection source (`deals`) avec des donnees de test.

Exemple:

```ts
deals: [
  { id: 1, contact_id: 1, titre: 'Migration IBM i', status: 'OPEN' },
  { id: 2, contact_id: 3, titre: 'Refonte front', status: 'WON' },
],
```

## 3. Creer le module de projection

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

## 4. Brancher la ressource dans App

Dans `src/app/App.tsx`:

- importer `dealsSummary`
- ajouter `<Resource {...dealsSummary} />`

## 5. Verifier

```bash
npm run dev
```

Verifier:

- la vue apparait dans la navigation
- la liste charge les champs enrichis
- la projection se recalcule via `buildSummaries`

## Checklist

- type source ajoute dans `buildSummaries.ts`
- `BaseData` etendu
- source ajoutee dans `baseData.ts`
- projection `xxx_summary` calculee et retournee
- module `*-summary` cree
- ressource branchee dans `App.tsx`
