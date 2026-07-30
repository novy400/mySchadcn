# Starter variante 2 : mini CRM modulaire simple pour IBM i avec Vite, TypeScript, React-Admin et FakeRest

Ce tutoriel propose un starter complet et volontairement simple pour des développeurs IBM i souhaitant prototyper une application d'administration ou de CRM léger avec Vite, TypeScript, React-Admin et `ra-data-fakerest`.[cite:17][cite:138] Le choix de la variante 2 consiste à organiser l'application par domaines métier et par contexte d'usage des composants, ce qui est plus proche de l'esprit d'Atomic CRM et plus facile à faire évoluer qu'une architecture purement centrée sur l'atomic design.[cite:90][cite:116][cite:129]

## Pourquoi cette variante

React-Admin repose sur un composant `<Admin>` et sur des `<Resource>` qui définissent les routes CRUD, le contexte de ressource et les pages associées à chaque entité.[cite:72][cite:94][cite:114] `ra-data-fakerest` permet de brancher un simple objet JSON local comme source de données, sans backend ni requêtes HTTP, ce qui en fait une excellente base pour un prototype pédagogique ou métier.[cite:17][cite:12]

Pour un projet IBM i, cette combinaison permet de garder l'interface simple, de travailler avec un vocabulaire métier clair, puis de remplacer plus tard FakeRest par un vrai data provider sans reconstruire toute l'application.[cite:17][cite:129][cite:3]

## Principe d'architecture

L'architecture retenue repose sur trois axes complémentaires :

- `shared/ui` pour les composants visuels réutilisables, génériques et peu liés au métier.[cite:90][cite:116]
- `shared/admin` pour les composants transverses de l'interface d'administration, par exemple un header, une barre d'actions ou un bloc de statistiques.[cite:90][cite:129]
- `modules/crm/...` pour le métier, c'est-à-dire les resources, les écrans CRUD et les vues enrichies comme `contacts_summary`.[cite:72][cite:94]

Cette structure garde l'application lisible pour une équipe IBM i, tout en préparant une modularisation propre inspirée des approches de personnalisation mises en avant par Atomic CRM.[cite:116][cite:90]

## Arborescence cible

```text
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
│     └─ AdminToolbar.tsx
├─ modules/
│  └─ crm/
│     ├─ clients/
│     │  ├─ ClientList.tsx
│     │  ├─ ClientEdit.tsx
│     │  ├─ ClientCreate.tsx
│     │  └─ client.resource.tsx
│     ├─ contacts/
│     │  ├─ ContactList.tsx
│     │  ├─ ContactEdit.tsx
│     │  ├─ ContactCreate.tsx
│     │  └─ contact.resource.tsx
│     ├─ tasks/
│     │  ├─ TaskList.tsx
│     │  ├─ TaskEdit.tsx
│     │  ├─ TaskCreate.tsx
│     │  └─ task.resource.tsx
│     ├─ notes/
│     │  ├─ NoteList.tsx
│     │  ├─ NoteEdit.tsx
│     │  ├─ NoteCreate.tsx
│     │  └─ note.resource.tsx
│     ├─ contacts-summary/
│     │  ├─ ContactSummaryList.tsx
│     │  └─ contactSummary.resource.tsx
│     └─ dashboard/
│        └─ Dashboard.tsx
└─ main.tsx
```

## Étape 1 : créer le projet

Créer d'abord un projet Vite avec le template React + TypeScript, puis installer React-Admin et FakeRest.[cite:138][cite:17]

```bash
npm create vite@latest ibmi-admin-proto -- --template react-ts
cd ibmi-admin-proto
npm install
npm install react-admin ra-data-fakerest
npm run dev
```

Vite fournit ensuite une URL locale de développement, en général `http://localhost:5173/`.[cite:138]

## Étape 2 : définir les données brutes

Créer `src/data/raw/baseData.ts` avec un petit modèle CRM de démonstration. FakeRest fonctionne localement sur ce type d'objet JSON et accepte plusieurs collections représentant plusieurs ressources.[cite:17][cite:12]

```ts
const baseData = {
  clients: [
    { id: 1, code: 'CLI001', nom: 'Dupont SA', ville: 'Paris', statut: 'ACTIF' },
    { id: 2, code: 'CLI002', nom: 'Martin SARL', ville: 'Lyon', statut: 'PROSPECT' },
  ],
  contacts: [
    { id: 1, client_id: 1, prenom: 'Jean', nom: 'Dupont', email: 'jean@dupont.fr', telephone: '0102030405' },
    { id: 2, client_id: 1, prenom: 'Claire', nom: 'Bernard', email: 'claire@dupont.fr', telephone: '0102030406' },
    { id: 3, client_id: 2, prenom: 'Sophie', nom: 'Martin', email: 'sophie@martin.fr', telephone: '0607080910' },
  ],
  tasks: [
    { id: 1, contact_id: 1, titre: 'Rappeler après devis', status: 'OPEN', due_date: '2026-04-03' },
    { id: 2, contact_id: 1, titre: 'Envoyer documentation', status: 'DONE', due_date: '2026-03-28' },
    { id: 3, contact_id: 3, titre: 'Planifier démonstration', status: 'OPEN', due_date: '2026-04-05' },
  ],
  notes: [
    { id: 1, contact_id: 1, contenu: 'Intéressé par une refonte de l’application.', date: '2026-03-27' },
    { id: 2, contact_id: 3, contenu: 'Souhaite un rappel début avril.', date: '2026-03-29' },
  ],
};

export default baseData;
```

## Étape 3 : construire une projection `contacts_summary`

Une des bonnes idées d'Atomic CRM est d'exposer des vues enrichies pour simplifier les écrans qui combinent plusieurs sources de données.[cite:90][cite:129] Sans backend réel, cette logique peut être simulée côté frontend en calculant une collection dérivée avant d'initialiser FakeRest.[cite:17]

Créer `src/data/projections/buildSummaries.ts` :

```ts
type Client = {
  id: number;
  nom: string;
  ville: string;
  statut: string;
};

type Contact = {
  id: number;
  client_id: number;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
};

type Task = {
  id: number;
  contact_id: number;
  titre: string;
  status: 'OPEN' | 'DONE';
  due_date: string;
};

type Note = {
  id: number;
  contact_id: number;
  contenu: string;
  date: string;
};

type BaseData = {
  clients: Client[];
  contacts: Contact[];
  tasks: Task[];
  notes: Note[];
};

export const buildSummaries = (data: BaseData) => {
  const contacts_summary = data.contacts.map((contact) => {
    const client = data.clients.find(c => c.id === contact.client_id);
    const openTasks = data.tasks.filter(
      t => t.contact_id === contact.id && t.status === 'OPEN'
    ).length;

    const notes = data.notes
      .filter(n => n.contact_id === contact.id)
      .sort((a, b) => b.date.localeCompare(a.date));

    return {
      id: contact.id,
      prenom: contact.prenom,
      nom: contact.nom,
      email: contact.email,
      telephone: contact.telephone,
      client_id: contact.client_id,
      client_name: client?.nom ?? '',
      client_city: client?.ville ?? '',
      client_status: client?.statut ?? '',
      open_tasks: openTasks,
      last_note_date: notes[0]?.date ?? null,
    };
  });

  return {
    ...data,
    contacts_summary,
  };
};
```

## Étape 4 : préparer le dataset final pour FakeRest

Créer `src/data/fakerestData.ts` :

```ts
import baseData from './raw/baseData';
import { buildSummaries } from './projections/buildSummaries';

const fakerestData = buildSummaries(baseData);

export default fakerestData;
```

Puis créer `src/app/providers/dataProvider.ts` :

```ts
import fakeDataProvider from 'ra-data-fakerest';
import fakerestData from '../../data/fakerestData';

const dataProvider = fakeDataProvider(fakerestData);

export default dataProvider;
```

`ra-data-fakerest` crée ainsi un data provider local sans backend, sur la base d'un simple objet JSON.[cite:17][cite:12]

## Étape 5 : ajouter quelques composants `shared/ui`

L'objectif n'est pas ici de fabriquer un design system complet, mais d'introduire quelques composants réutilisables simples qui pourront être réemployés dans plusieurs écrans.[cite:116][cite:129]

### `src/shared/ui/StatusChip.tsx`

```tsx
import { Chip } from '@mui/material';

type Props = {
  value: string;
};

const colorMap: Record<string, 'default' | 'success' | 'warning' | 'info'> = {
  ACTIF: 'success',
  PROSPECT: 'warning',
  OPEN: 'info',
  DONE: 'success',
};

export const StatusChip = ({ value }: Props) => {
  return <Chip label={value} color={colorMap[value] ?? 'default'} size="small" />;
};
```

### `src/shared/ui/KpiCard.tsx`

```tsx
import { Card, CardContent, Typography } from '@mui/material';

type Props = {
  label: string;
  value: number | string;
};

export const KpiCard = ({ label, value }: Props) => (
  <Card>
    <CardContent>
      <Typography variant="body2" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="h5">
        {value}
      </Typography>
    </CardContent>
  </Card>
);
```

### `src/shared/ui/EmptyState.tsx`

```tsx
import { Box, Typography } from '@mui/material';

type Props = {
  title: string;
};

export const EmptyState = ({ title }: Props) => (
  <Box sx={{ p: 3 }}>
    <Typography variant="h6">{title}</Typography>
  </Box>
);
```

### `src/shared/ui/SectionTitle.tsx`

```tsx
import { Typography } from '@mui/material';

type Props = {
  children: React.ReactNode;
};

export const SectionTitle = ({ children }: Props) => (
  <Typography variant="h6" sx={{ mb: 2 }}>
    {children}
  </Typography>
);
```

## Étape 6 : ajouter quelques composants `shared/admin`

Ces composants restent transverses à l'administration et peuvent être réutilisés dans plusieurs pages ou dashboards.[cite:90][cite:129]

### `src/shared/admin/DashboardHeader.tsx`

```tsx
import { Box, Typography } from '@mui/material';

export const DashboardHeader = () => (
  <Box sx={{ mb: 3 }}>
    <Typography variant="h4">Mini CRM IBM i</Typography>
    <Typography variant="body1" color="text.secondary">
      Prototype React-Admin modulaire avec FakeRest
    </Typography>
  </Box>
);
```

### `src/shared/admin/QuickStats.tsx`

```tsx
import { Grid } from '@mui/material';
import { KpiCard } from '../ui/KpiCard';

type Props = {
  clients: number;
  contacts: number;
  openTasks: number;
};

export const QuickStats = ({ clients, contacts, openTasks }: Props) => (
  <Grid container spacing={2} sx={{ mb: 3 }}>
    <Grid item xs={12} md={4}><KpiCard label="Clients" value={clients} /></Grid>
    <Grid item xs={12} md={4}><KpiCard label="Contacts" value={contacts} /></Grid>
    <Grid item xs={12} md={4}><KpiCard label="Tâches ouvertes" value={openTasks} /></Grid>
  </Grid>
);
```

### `src/shared/admin/AdminToolbar.tsx`

```tsx
import { TopToolbar, CreateButton } from 'react-admin';

export const AdminToolbar = () => (
  <TopToolbar>
    <CreateButton />
  </TopToolbar>
);
```

## Étape 7 : créer les resources métier

Dans React-Admin, chaque `<Resource>` définit les routes CRUD et le contexte de ressource, ce qui en fait l'unité naturelle pour structurer ton métier.[cite:72][cite:94]

### Clients

#### `src/modules/crm/clients/ClientList.tsx`

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

#### `src/modules/crm/clients/ClientEdit.tsx`

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

#### `src/modules/crm/clients/ClientCreate.tsx`

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

#### `src/modules/crm/clients/client.resource.tsx`

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

### Contacts

#### `src/modules/crm/contacts/ContactList.tsx`

```tsx
import { List, Datagrid, TextField, EmailField, NumberField } from 'react-admin';

export const ContactList = () => (
  <List>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <NumberField source="client_id" />
      <TextField source="prenom" />
      <TextField source="nom" />
      <EmailField source="email" />
      <TextField source="telephone" />
    </Datagrid>
  </List>
);
```

#### `src/modules/crm/contacts/ContactEdit.tsx`

```tsx
import { Edit, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const ContactEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="client_id" />
      <TextInput source="prenom" />
      <TextInput source="nom" />
      <TextInput source="email" />
      <TextInput source="telephone" />
    </SimpleForm>
  </Edit>
);
```

#### `src/modules/crm/contacts/ContactCreate.tsx`

```tsx
import { Create, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const ContactCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="client_id" />
      <TextInput source="prenom" />
      <TextInput source="nom" />
      <TextInput source="email" />
      <TextInput source="telephone" />
    </SimpleForm>
  </Create>
);
```

#### `src/modules/crm/contacts/contact.resource.tsx`

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

### Tasks

#### `src/modules/crm/tasks/TaskList.tsx`

```tsx
import { List, Datagrid, TextField, NumberField } from 'react-admin';

export const TaskList = () => (
  <List>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <NumberField source="contact_id" />
      <TextField source="titre" />
      <TextField source="status" />
      <TextField source="due_date" />
    </Datagrid>
  </List>
);
```

#### `src/modules/crm/tasks/TaskEdit.tsx`

```tsx
import { Edit, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const TaskEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Edit>
);
```

#### `src/modules/crm/tasks/TaskCreate.tsx`

```tsx
import { Create, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const TaskCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Create>
);
```

#### `src/modules/crm/tasks/task.resource.tsx`

```tsx
import { Resource } from 'react-admin';
import { TaskList } from './TaskList';
import { TaskEdit } from './TaskEdit';
import { TaskCreate } from './TaskCreate';

export const TaskResource = (
  <Resource
    name="tasks"
    list={TaskList}
    edit={TaskEdit}
    create={TaskCreate}
    recordRepresentation="titre"
  />
);
```

### Notes

#### `src/modules/crm/notes/NoteList.tsx`

```tsx
import { List, Datagrid, TextField, NumberField } from 'react-admin';

export const NoteList = () => (
  <List>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <NumberField source="contact_id" />
      <TextField source="contenu" />
      <TextField source="date" />
    </Datagrid>
  </List>
);
```

#### `src/modules/crm/notes/NoteEdit.tsx`

```tsx
import { Edit, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const NoteEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="contenu" multiline />
      <TextInput source="date" />
    </SimpleForm>
  </Edit>
);
```

#### `src/modules/crm/notes/NoteCreate.tsx`

```tsx
import { Create, SimpleForm, NumberInput, TextInput } from 'react-admin';

export const NoteCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="contenu" multiline />
      <TextInput source="date" />
    </SimpleForm>
  </Create>
);
```

#### `src/modules/crm/notes/note.resource.tsx`

```tsx
import { Resource } from 'react-admin';
import { NoteList } from './NoteList';
import { NoteEdit } from './NoteEdit';
import { NoteCreate } from './NoteCreate';

export const NoteResource = (
  <Resource
    name="notes"
    list={NoteList}
    edit={NoteEdit}
    create={NoteCreate}
    recordRepresentation="contenu"
  />
);
```

### Contacts Summary

Cette ressource sert de vue enrichie de lecture, ce qui illustre bien la séparation entre tables de base et projection métier destinée à l'interface.[cite:90][cite:129]

#### `src/modules/crm/contacts-summary/ContactSummaryList.tsx`

```tsx
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

#### `src/modules/crm/contacts-summary/contactSummary.resource.tsx`

```tsx
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

## Étape 8 : créer un mini dashboard

Atomic CRM met en avant la possibilité d'ajouter des pages personnalisées et des composants remplaçables, ce qui se traduit bien ici par un petit dashboard maison.[cite:90][cite:129] Il ne s'agit pas de reproduire toute la solution, mais d'en reprendre l'idée de tableaux de bord simples, utiles et facilement adaptables.[cite:116]

### `src/modules/crm/dashboard/Dashboard.tsx`

```tsx
import { Card, CardContent, Grid, List, ListItem, ListItemText } from '@mui/material';
import fakerestData from '../../../data/fakerestData';
import { DashboardHeader } from '../../../shared/admin/DashboardHeader';
import { QuickStats } from '../../../shared/admin/QuickStats';
import { SectionTitle } from '../../../shared/ui/SectionTitle';

export const Dashboard = () => {
  const clients = fakerestData.clients.length;
  const contacts = fakerestData.contacts.length;
  const openTasks = fakerestData.tasks.filter(task => task.status === 'OPEN').length;

  const topContacts = fakerestData.contacts_summary
    .filter(contact => contact.open_tasks > 0)
    .slice(0, 5);

  return (
    <>
      <DashboardHeader />

      <QuickStats clients={clients} contacts={contacts} openTasks={openTasks} />

      <Grid container spacing={2}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <SectionTitle>Contacts à suivre</SectionTitle>
              <List>
                {topContacts.map((contact) => (
                  <ListItem key={contact.id} disablePadding>
                    <ListItemText
                      primary={`${contact.prenom} ${contact.nom}`}
                      secondary={`${contact.client_name} · ${contact.open_tasks} tâche(s) ouverte(s)`}
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </>
  );
};
```

## Étape 9 : assembler l'application

Créer `src/app/App.tsx` et brancher le dashboard ainsi que toutes les resources. `<Admin>` est le composant racine qui gère l'état, le routage et la logique de haut niveau de l'application React-Admin.[cite:114][cite:72]

```tsx
import { Admin, CustomRoutes } from 'react-admin';
import { Route } from 'react-router-dom';
import dataProvider from './providers/dataProvider';
import { Dashboard } from '../modules/crm/dashboard/Dashboard';
import { ClientResource } from '../modules/crm/clients/client.resource';
import { ContactResource } from '../modules/crm/contacts/contact.resource';
import { TaskResource } from '../modules/crm/tasks/task.resource';
import { NoteResource } from '../modules/crm/notes/note.resource';
import { ContactSummaryResource } from '../modules/crm/contacts-summary/contactSummary.resource';

export default function App() {
  return (
    <Admin dataProvider={dataProvider} dashboard={Dashboard}>
      <CustomRoutes>
        <Route path="/dashboard" element={<Dashboard />} />
      </CustomRoutes>
      {ClientResource}
      {ContactResource}
      {TaskResource}
      {NoteResource}
      {ContactSummaryResource}
    </Admin>
  );
}
```

Créer ensuite `src/main.tsx` :

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

## Étape 10 : ordre conseillé pour créer les fichiers

Voici l'ordre conseillé pour éviter de se perdre :

1. Créer le projet Vite et installer les dépendances.[cite:138][cite:17]
2. Créer `baseData.ts`.[cite:17]
3. Créer `buildSummaries.ts` puis `fakerestData.ts`.[cite:17]
4. Créer `dataProvider.ts`.[cite:17]
5. Créer `shared/ui`.[cite:116]
6. Créer `shared/admin`.[cite:116][cite:129]
7. Créer les modules `clients`, `contacts`, `tasks`, `notes`.[cite:72][cite:94]
8. Créer `contacts-summary`.[cite:90]
9. Créer le `Dashboard`.[cite:129]
10. Assembler dans `App.tsx` puis lancer `npm run dev`.[cite:138][cite:72]

## Pourquoi ce choix est bon pour des développeurs IBM i

Ce starter reste simple car il sépare bien les responsabilités sans imposer une architecture trop abstraite.[cite:90][cite:116] Les développeurs IBM i peuvent y retrouver une logique proche des sous-domaines métier, des vues enrichies comparables à des vues SQL, et une composition claire par ressources, ce qui facilite l'apprentissage et la future transition vers une API réelle.[cite:72][cite:129][cite:3]

La clé est de ne pas complexifier trop tôt : `shared/ui` pour le générique, `shared/admin` pour l'habillage, `modules/crm` pour le métier, et FakeRest pour garder un cycle de prototypage rapide.[cite:17][cite:90][cite:116]
