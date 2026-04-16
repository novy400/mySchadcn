# Starter variante 2 : mini CRM modulaire (etat reel du repo)

Ce document decrit la version actuellement implementee dans ce depot (avril 2026), et non plus un simple squelette theorique.

## Objectif

- Prototyper rapidement un CRM admin sans backend HTTP.
- Structurer le code par modules metier.
- Preparer une migration vers une API IBM i sans refaire les ecrans.

## Stack projet

- Vite + React + TypeScript
- `ra-core`
- composants admin locaux: `src/components/admin/*`
- `ra-data-fakerest`
- donnees brutes + projections (`contacts_summary`)

## Arborescence reelle

```text
src/
├─ app/
│  ├─ App.tsx
│  └─ providers/
│     └─ dataProvider.ts
├─ components/
│  ├─ admin/
│  └─ ui/
├─ data/
│  ├─ raw/
│  │  └─ baseData.ts
│  ├─ projections/
│  │  └─ buildSummaries.ts
│  └─ fakerestData.ts
├─ modules/
│  └─ crm/
│     ├─ dashboard/
│     ├─ clients/
│     ├─ contacts/
│     ├─ tasks/
│     ├─ notes/
│     └─ contacts-summary/
└─ main.tsx
```

## Donnees et provider

1. `src/data/raw/baseData.ts`: donnees metier brutes.
2. `src/data/projections/buildSummaries.ts`: calcul de `contacts_summary`.
3. `src/data/fakerestData.ts`: dataset final.
4. `src/app/providers/dataProvider.ts`: branchement FakeRest.

```ts
// src/app/providers/dataProvider.ts
import fakeDataProvider from 'ra-data-fakerest';
import fakerestData from '../../data/fakerestData';

const dataProvider = fakeDataProvider(fakerestData);

export default dataProvider;
```

## Ressources implementees

- `clients` (list, edit, create)
- `contacts` (list, edit, create)
- `tasks` (list, edit, create)
- `notes` (list, edit, create)
- `contacts_summary` (list seulement)

## Exemple de liste metier (pattern actuel)

Le projet utilise les composants de `src/components/admin`.

```tsx
// src/modules/crm/contacts/ContactList.tsx
import { DataTable, EmailField, List, NumberField, TextField } from '@/components/admin';

export const ContactList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="client_id">
        <NumberField source="client_id" />
      </DataTable.Col>
      <DataTable.Col source="prenom">
        <TextField source="prenom" />
      </DataTable.Col>
      <DataTable.Col source="nom">
        <TextField source="nom" />
      </DataTable.Col>
      <DataTable.Col source="email">
        <EmailField source="email" />
      </DataTable.Col>
      <DataTable.Col source="telephone">
        <TextField source="telephone" />
      </DataTable.Col>
    </DataTable>
  </List>
);
```

## Exemple de ressource (pattern actuel)

Les fichiers resource exportent un objet `ResourceProps` (et non un JSX `<Resource />` directement).

```tsx
// src/modules/crm/contacts/contact.resource.tsx
import { ResourceProps } from 'ra-core';
import { Users } from 'lucide-react';
import { ContactList } from './ContactList';
import { ContactEdit } from './ContactEdit';
import { ContactCreate } from './ContactCreate';

export const contacts: ResourceProps = {
  name: 'contacts',
  list: ContactList,
  edit: ContactEdit,
  create: ContactCreate,
  recordRepresentation: 'nom',
  icon: Users,
};
```

## Composition App actuelle

```tsx
// src/app/App.tsx
import { Admin } from '@/components/admin';
import { Resource } from 'ra-core';

import dataProvider from './providers/dataProvider';
import { Dashboard } from '../modules/crm/dashboard/Dashboard';
import { clients } from '../modules/crm/clients';
import { contacts } from '../modules/crm/contacts';
import { tasks } from '../modules/crm/tasks';
import { notes } from '../modules/crm/notes';
import { contactsSummary } from '../modules/crm/contacts-summary';

function App() {
  return (
    <Admin dataProvider={dataProvider} dashboard={Dashboard}>
      <Resource {...clients} />
      <Resource {...contacts} />
      <Resource {...tasks} />
      <Resource {...notes} />
      <Resource {...contactsSummary} />
    </Admin>
  );
}

export default App;
```

## Lancement

```bash
npm install
npm run dev
```

## Notes IBM i

- FakeRest permet de figer le contrat d'ecran sans dependre du backend.
- Le passage a IBM i se fera en remplaçant le data provider, en conservant les memes ressources et ecrans.
- Le pattern `contacts_summary` prepare bien des vues SQL DB2 ou des endpoints d'agregation.