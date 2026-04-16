# Mini tutoriel : Vite + Admin modulaire + FakeRest (version a jour)

Ce tutoriel resume la facon dont le projet est actuellement structure dans ce repo.

## 1) Installation

```bash
npm install
npm run dev
```

## 2) Points d'entree

- `src/main.tsx` monte l'application React.
- `src/app/App.tsx` assemble l'admin, le dashboard et les ressources.
- `src/app/providers/dataProvider.ts` branche FakeRest.

## 3) Pipeline de donnees

```text
src/data/raw/baseData.ts
  -> src/data/projections/buildSummaries.ts
  -> src/data/fakerestData.ts
  -> src/app/providers/dataProvider.ts
```

Le dataset final contient des collections CRUD (`clients`, `contacts`, `tasks`, `notes`) et une projection de lecture (`contacts_summary`).

## 4) Ressources CRM en place

- `clients`
- `contacts`
- `tasks`
- `notes`
- `contacts_summary`

## 5) Exemple de data provider

```ts
import fakeDataProvider from 'ra-data-fakerest';
import fakerestData from '../../data/fakerestData';

const dataProvider = fakeDataProvider(fakerestData);

export default dataProvider;
```

## 6) Exemple de composition App

```tsx
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

## 7) Exemple de vue de synthese

`contacts_summary` sert de liste enrichie et redirige vers l'edition de `contacts`.

```tsx
import { DataTable, EmailField, List, NumberField, TextField } from '@/components/admin';

export const ContactSummaryList = () => (
  <List resource="contacts_summary">
    <DataTable rowClick={(_, __, record) => `/contacts/${record.id}`}>
      <DataTable.Col source="id">
        <TextField source="id" />
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
      <DataTable.Col source="client_name" label="Client">
        <TextField source="client_name" />
      </DataTable.Col>
      <DataTable.Col source="open_tasks" label="Taches ouvertes">
        <NumberField source="open_tasks" />
      </DataTable.Col>
      <DataTable.Col source="last_note_date" label="Derniere note">
        <TextField source="last_note_date" />
      </DataTable.Col>
    </DataTable>
  </List>
);
```

## 8) Convention utile

- Import UI/admin: `@/components/admin`
- Definition des ressources: `ResourceProps` depuis `ra-core`
- Mapping des champs relationnels: `client_id`, `contact_id` (snake_case)

## 9) Etape suivante IBM i

Remplacer `ra-data-fakerest` par un data provider REST reel en conservant:

- les composants de listes/formulaires
- les objets de ressources
- les routes implicites de l'admin