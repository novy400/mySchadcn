# Mini tutoriel : starter modulaire Vite + React-Admin + FakeRest + TypeScript

Ce document propose un squelette minimal mais propre pour démarrer un mini CRM modulaire avec `clients` et `contacts`, en utilisant Vite, React-Admin, TypeScript et `ra-data-fakerest`.[cite:25][cite:17] L'idée est de séparer l'assemblage global de l'application, les modules métier et le faux jeu de données, afin de pouvoir ensuite remplacer FakeRest par une vraie API IBM i sans refaire toute l'interface.[cite:64][cite:72][cite:3]

## 1. Création du projet

Créer le projet avec le template React + TypeScript de Vite, puis installer React-Admin et FakeRest.[cite:39][cite:25][cite:17]

```bash
npm create vite@latest ibmi-admin-proto -- --template react-ts
cd ibmi-admin-proto
npm install
npm install react-admin ra-data-fakerest
npm run dev
```

Le serveur Vite démarre ensuite en local, généralement sur `http://localhost:5173/`.[cite:43][cite:51]

## 2. Arborescence cible

Cette structure reste simple tout en étant déjà modulaire, avec une organisation par features métier autour des `Resource` React-Admin.[cite:64][cite:72]

```text
src/
├─ app/
│  ├─ App.tsx
│  └─ providers/
│     └─ dataProvider.ts
├─ modules/
│  └─ crm/
│     ├─ clients/
│     │  ├─ ClientList.tsx
│     │  ├─ ClientEdit.tsx
│     │  ├─ ClientCreate.tsx
│     │  ├─ client.types.ts
│     │  └─ client.resource.tsx
│     └─ contacts/
│        ├─ ContactList.tsx
│        ├─ ContactEdit.tsx
│        ├─ ContactCreate.tsx
│        ├─ contact.types.ts
│        └─ contact.resource.tsx
├─ data/
│  └─ fakerestData.ts
└─ main.tsx
```

## 3. Fichiers à créer

### `src/main.tsx`

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './app/App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

### `src/data/fakerestData.ts`

`ra-data-fakerest` utilise un simple objet JSON en mémoire comme source de données locale.[cite:17]

```ts
const fakerestData = {
  clients: [
    { id: 1, code: 'C001', nom: 'Dupont SA', ville: 'Paris', statut: 'ACTIF' },
    { id: 2, code: 'C002', nom: 'Martin SARL', ville: 'Lyon', statut: 'PROSPECT' },
  ],
  contacts: [
    { id: 1, clientId: 1, prenom: 'Jean', nom: 'Dupont', email: 'jean@dupontsa.fr', telephone: '0102030405' },
    { id: 2, clientId: 2, prenom: 'Sophie', nom: 'Martin', email: 'sophie@martinsarl.fr', telephone: '0607080910' },
  ],
};

export default fakerestData;
```

### `src/app/providers/dataProvider.ts`

```ts
import fakeDataProvider from 'ra-data-fakerest';
import fakerestData from '../../data/fakerestData';

const dataProvider = fakeDataProvider(fakerestData);

export default dataProvider;
```

### `src/modules/crm/clients/client.types.ts`

```ts
export interface Client {
  id: number;
  code: string;
  nom: string;
  ville: string;
  statut: 'ACTIF' | 'PROSPECT' | 'SUSPENDU';
}
```

### `src/modules/crm/contacts/contact.types.ts`

```ts
export interface Contact {
  id: number;
  clientId: number;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
}
```

### `src/modules/crm/clients/ClientList.tsx`

```tsx
import { List, Datagrid, TextField } from 'react-admin';

export const ClientList = () => (
  <List>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <TextField source="code" />
      <TextField source="nom" />
      <TextField source="ville" />
      <TextField source="statut" />
    </Datagrid>
  </List>
);
```

### `src/modules/crm/clients/ClientEdit.tsx`

```tsx
import { Edit, SimpleForm, TextInput } from 'react-admin';

export const ClientEdit = () => (
  <Edit>
    <SimpleForm>
      <TextInput source="code" />
      <TextInput source="nom" />
      <TextInput source="ville" />
      <TextInput source="statut" />
    </SimpleForm>
  </Edit>
);
```

### `src/modules/crm/clients/ClientCreate.tsx`

```tsx
import { Create, SimpleForm, TextInput } from 'react-admin';

export const ClientCreate = () => (
  <Create>
    <SimpleForm>
      <TextInput source="code" />
      <TextInput source="nom" />
      <TextInput source="ville" />
      <TextInput source="statut" />
    </SimpleForm>
  </Create>
);
```

### `src/modules/crm/clients/client.resource.tsx`

Une `Resource` déclare les routes CRUD et encapsule les écrans d'une entité donnée dans React-Admin.[cite:72][cite:74]

```tsx
import { Resource } from 'react-admin';
import { ClientList } from './ClientList';
import { ClientEdit } from './ClientEdit';
import { ClientCreate } from './ClientCreate';

export const ClientResource = (
  <Resource
    name="clients"
    list={ClientList}
    edit={ClientEdit}
    create={ClientCreate}
    recordRepresentation="nom"
  />
);
```

### `src/modules/crm/contacts/ContactList.tsx`

```tsx
import { List, Datagrid, TextField, EmailField, NumberField } from 'react-admin';

export const ContactList = () => (
  <List>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <NumberField source="clientId" />
      <TextField source="prenom" />
      <TextField source="nom" />
      <EmailField source="email" />
      <TextField source="telephone" />
    </Datagrid>
  </List>
);
```

### `src/modules/crm/contacts/ContactEdit.tsx`

```tsx
import { Edit, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const ContactEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="clientId" />
      <TextInput source="prenom" />
      <TextInput source="nom" />
      <TextInput source="email" />
      <TextInput source="telephone" />
    </SimpleForm>
  </Edit>
);
```

### `src/modules/crm/contacts/ContactCreate.tsx`

```tsx
import { Create, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const ContactCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="clientId" />
      <TextInput source="prenom" />
      <TextInput source="nom" />
      <TextInput source="email" />
      <TextInput source="telephone" />
    </SimpleForm>
  </Create>
);
```

### `src/modules/crm/contacts/contact.resource.tsx`

```tsx
import { Resource } from 'react-admin';
import { ContactList } from './ContactList';
import { ContactEdit } from './ContactEdit';
import { ContactCreate } from './ContactCreate';

export const ContactResource = (
  <Resource
    name="contacts"
    list={ContactList}
    edit={ContactEdit}
    create={ContactCreate}
    recordRepresentation="nom"
  />
);
```

### `src/app/App.tsx`

Le composant `<Admin>` est le conteneur principal, et les modules métier y sont assemblés via leurs `Resource` respectives.[cite:64][cite:75]

```tsx
import { Admin } from 'react-admin';
import dataProvider from './providers/dataProvider';
import { ClientResource } from '../modules/crm/clients/client.resource';
import { ContactResource } from '../modules/crm/contacts/contact.resource';

export default function App() {
  return (
    <Admin dataProvider={dataProvider}>
      {ClientResource}
      {ContactResource}
    </Admin>
  );
}
```

## 4. Ordre de création recommandé

Pour éviter les erreurs, créer les fichiers dans cet ordre :

1. `main.tsx`
2. `fakerestData.ts`
3. `dataProvider.ts`
4. les types (`client.types.ts`, `contact.types.ts`)
5. les écrans CRUD de `clients`
6. `client.resource.tsx`
7. les écrans CRUD de `contacts`
8. `contact.resource.tsx`
9. `App.tsx`

Cet ordre fonctionne bien parce qu'il met d'abord en place l'infrastructure, puis les modules métier, puis l'assemblage final.[cite:57][cite:64]

## 5. Comment lancer

Une fois tous les fichiers créés :

```bash
npm run dev
```

Vite démarre alors le serveur de développement et fournit l'URL locale à ouvrir dans le navigateur.[cite:43][cite:51]

## 6. Évolution naturelle du starter

Ce starter peut ensuite évoluer de manière pragmatique :

- Ajouter un module `opportunities` ou `activities` pour élargir le CRM.[cite:57][cite:62]
- Introduire des composants réutilisables dans `shared/ui` pour éviter les duplications.[cite:62]
- Remplacer FakeRest par un vrai data provider REST lorsque les APIs IBM i seront prêtes.[cite:17][cite:3]
- Garder la structure par domaines métier, qui est généralement plus durable qu'un découpage purement visuel en atoms/molecules/organisms pour une application de gestion.[cite:62][cite:57]
