# mySchadcn - Mini CRM Admin (Vite + React + ra-core + FakeRest)

Ce projet est un mini CRM d'administration construit avec Vite, React 19, TypeScript et les composants de shadcn-admin-kit.

L'application utilise `ra-data-fakerest` comme data provider local. Les donnees sont chargees depuis un jeu brut, puis enrichies via des projections (`contacts_summary`) avant d'etre exposees a l'admin.

## Objectif

- Prototyper rapidement des ecrans CRUD metier sans backend HTTP.
- Structurer le code par domaines (clients, contacts, taches, notes).
- Preparer une migration future vers un vrai data provider IBM i sans changer les ecrans.

## Stack

- Vite 8
- React 19
- TypeScript 5
- `ra-core` + composants admin locaux (`src/components/admin`)
- `ra-data-fakerest`
- Tailwind CSS 4

## Demarrage

Prerequis: Node.js 20+

```bash
npm install
npm run dev
```

Scripts utiles:

- `npm run dev`: lancement local
- `npm run build`: verifie TypeScript puis build Vite
- `npm run lint`: lint ESLint
- `npm run preview`: previsualisation du build

## Configuration TypeScript

Le projet est configure avec:

- alias `@/*` vers `src/*`
- `verbatimModuleSyntax: false` dans `tsconfig.app.json` (requis pour l'integration admin)

## Architecture actuelle

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

## Composition de l'application

Le point d'entree principal est `src/app/App.tsx`.

L'admin y declare:

- un `dataProvider` central (`src/app/providers/dataProvider.ts`)
- un `dashboard` CRM (`src/modules/crm/dashboard/Dashboard.tsx`)
- 5 ressources React-Admin:
  - `clients`
  - `contacts`
  - `tasks`
  - `notes`
  - `contacts_summary` (vue de synthese en lecture)

## Pipeline de donnees

1. Les donnees brutes sont definies dans `src/data/raw/baseData.ts`.
2. `src/data/projections/buildSummaries.ts` calcule la projection `contacts_summary`.
3. `src/data/fakerestData.ts` expose le dataset final.
4. `src/app/providers/dataProvider.ts` branche ce dataset sur `ra-data-fakerest`.

Ce pattern permet de separer:

- les entites metier CRUD
- les vues enrichies pour les ecrans de liste/dashboard

## Ressources CRM implementees

- `clients`: list, edit, create
- `contacts`: list, edit, create
- `tasks`: list, edit, create
- `notes`: list, edit, create
- `contacts_summary`: list uniquement (navigue vers l'edition de `contacts`)

## Documentation projet

Les documents de cadrage et tutoriels sont disponibles dans `ressources/doc`:

- `0_cadrage.md`
- `starter-variante-2-react-admin-fakerest-ibmi.md`
- `tutoriel-vite-react-admin-fakerest-modulaire.md`
- `howto-ajouter-ressource-module.md`
- `howto-ajouter-ressource-projection-summary.md`
- `howto-migrer-fakerest-vers-rest-ibmi.md`

Ils decrivent l'approche IBM i progressive (prototype local puis migration backend).

## Prochaines evolutions suggerees

- ajouter des guesser pour generer automatiquement les champs d'apres les donnees
- brancher un data provider REST reel a la place de FakeRest
- ajouter auth/roles
- ajouter tests d'integration par ressource