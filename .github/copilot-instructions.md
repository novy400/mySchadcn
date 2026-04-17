# mySchadcn - AI Agent Instructions

This is a modular CRM prototype built with Vite + React 19 + TypeScript, using `ra-core` with custom `shadcn-admin-kit` components and `ra-data-fakerest` for local data simulation. The codebase is structured for IBM i migration readiness.

## Architecture Overview

### Data Pipeline (Critical Pattern)
1. **Raw Data**: `src/data/raw/baseData.ts` - Define typed base entities
2. **Projections**: `src/data/projections/buildSummaries.ts` - Calculate enriched views (e.g., `contacts_summary`)
3. **FakeRest**: `src/data/fakerestData.ts` - Expose final dataset to data provider
4. **Provider**: `src/app/providers/dataProvider.ts` - Bridge to react-admin

### Module Structure (src/modules/crm/)
Each business domain follows this exact pattern:
```
contacts/
├── contact.types.ts       # Type definitions (ALWAYS required)
├── ContactList.tsx        # List view with DataTable
├── ContactEdit.tsx        # Edit form 
├── ContactCreate.tsx      # Create form
├── contact.resource.tsx   # ResourceProps configuration
└── index.ts              # Export resource config
```

### Component Integration
- Use `@/components/admin` imports (shadcn-admin-kit components)
- `<DataTable>` with `<DataTable.Col>` for lists
- `<TextField>`, `<EmailField>`, `<NumberField>` for display
- `<Form>` with shadcn inputs for edit/create

## Critical Configuration Requirements

### TypeScript Config
**REQUIRED**: Set `"verbatimModuleSyntax": false` in `tsconfig.app.json` for shadcn-admin-kit compatibility.

### Import Aliases
- `@/*` maps to `src/*` 
- Always use `@/components/admin` for admin components
- Use `@/components/ui` for basic shadcn/ui components

## Development Workflows

### Adding New Resources (Follow ressources/doc/howto-ajouter-ressource-module.md)
1. Create module folder: `src/modules/crm/{resource}/`
2. **Create `{resource}.types.ts`** with `type` + `Pick<RaRecord, 'id'>` (see TypeScript Conventions below)
3. Add List/Edit/Create components using admin components
4. Create `{resource}.resource.tsx` with `ResourceProps`
5. Import the type in `buildSummaries.ts` (never redeclare locally) and extend `BaseData`
6. Add raw data to `baseData.ts`
7. Register in `src/app/App.tsx` with `<Resource {...resourceConfig} />`

### Build Commands
- `npm run dev` - Development server
- `npm run build` - TypeScript check + Vite build
- `npm run lint` - ESLint check

## TypeScript Conventions

### Type Definitions (Critical)
- **Always `type`, never `interface`** for entity types
- **Always `Pick<RaRecord, 'id'>`** instead of `id: number` — aligns with react-admin's `Identifier`
- **Extract union types** as named exports (e.g. `ClientStatut`)
- Each module owns its `*.types.ts`; `buildSummaries.ts` **imports** from modules, never redeclares locally

```ts
// src/modules/crm/clients/client.types.ts
import type { RaRecord } from 'ra-core';

export type ClientStatut = 'ACTIF' | 'PROSPECT' | 'SUSPENDU';

export type Client = {
  code: string;
  nom: string;
  ville: string;
  statut: ClientStatut;
} & Pick<RaRecord, 'id'>;
```

```ts
// src/data/projections/buildSummaries.ts — import, don't redeclare
import type { Client } from '@/modules/crm/clients/client.types';
import type { Contact } from '@/modules/crm/contacts/contact.types';
import type { Task } from '@/modules/crm/tasks/task.types';
import type { Note } from '@/modules/crm/notes/note.types';
```

## React-Admin Integration Patterns

### Resource Declaration
```tsx
export const contacts: ResourceProps = {
  name: "contacts",
  list: ContactList,
  edit: ContactEdit, 
  create: ContactCreate,
  recordRepresentation: (record) => `${record.prenom} ${record.nom}`,
  icon: User,
};
```

### Data Table Pattern
```tsx
export const ContactList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="field">
        <TextField source="field" />
      </DataTable.Col>
    </DataTable>
  </List>
);
```

### Cross-Resource Navigation
For summary views, use custom rowClick: `rowClick={(_, __, record) => \`/contacts/${record.id}\`}`

## Key Dependencies

- `ra-core` - Headless react-admin logic
- `ra-data-fakerest` - Local data simulation  
- `shadcn-admin-kit` - Custom admin UI components
- Components are client-side only (use `"use client"` in Next.js)

## Project-Specific Conventions

- French business terminology (clients, contacts, tâches, notes)
- Resource icons from `lucide-react`
- All admin screens use local `@/components/admin` components
- Data enrichment via projection pattern for summary views
- Module export pattern: `index.ts` exports resource config only
- snake_case for all relational fields: `client_id`, `contact_id`

Refer to `ressources/doc/` for detailed how-to guides and IBM i migration patterns.