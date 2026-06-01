# AGENTS.md

Guide court pour les agents IA travaillant sur ce repo.

## Mission

Maintenir et faire evoluer `mySchadcn`, un mini CRM admin en :

- Vite
- React 19
- TypeScript
- `ra-core`
- `ra-data-fakerest`
- Tailwind CSS

Le projet est un **prototype fonctionnel** base sur un dataset local et des projections.

## Etat cible a preserver

Ces commandes doivent rester vertes apres toute modification significative :

```bash
npm run lint
npm run test
npm run build
```

L'app doit aussi demarrer avec :

```bash
npm run dev
```

## Architecture a connaitre

### Entree app
- `src/main.tsx`
- `src/app/App.tsx`

### Donnees
- `src/data/raw/baseData.ts` : donnees brutes
- `src/data/projections/buildSummaries.ts` : projections
- `src/data/fakerestData.ts` : dataset final
- `src/app/providers/dataProvider.ts` : branchement FakeRest

### Modules CRM
- `src/modules/crm/clients`
- `src/modules/crm/contacts`
- `src/modules/crm/tasks`
- `src/modules/crm/notes`
- `src/modules/crm/contacts-summary`
- `src/modules/crm/customers`
- `src/modules/crm/dashboard`

### Composants partages
- `src/components/admin`
- `src/components/ui`
- `src/components/rich-text-input` ← zone plus fragile, modifier avec prudence

## Ressources actuelles

- `clients`
- `contacts`
- `tasks`
- `notes`
- `contacts_summary`
- `customers`
- `customerSignalietiques`
- `customerRisques`

## Regles de travail

### Do
- Faire des changements **petits, cibles, explicables**
- Preserver la structure modulaire du projet
- Mettre la logique de transformation de donnees dans `src/data/projections`
- Ajouter un test si la logique ajoutee n'est pas triviale
- Mettre a jour la doc si l'architecture ou le workflow change

### Don't
- Ne pas faire de refactor massif sans demande explicite
- Ne pas casser `lint`, `test` ou `build`
- Ne pas melanger logique metier et logique de rendu si une projection convient mieux
- Ne pas rebrancher les anciens `*.spec.ts(x)` sans remettre leur outillage complet
- Ne pas modifier lourdement `src/components/rich-text-input` sauf besoin clair

## Regles de tests

### Suite active
- `*.test.ts`
- `*.test.tsx`
- Vitest + Testing Library

### Tests existants utiles
- `src/data/projections/buildSummaries.test.ts`
- `src/modules/crm/dashboard/Dashboard.test.tsx`

### Important
Les anciens `*.spec.ts(x)` sont exclus de la suite active. Ils dependent d'outils incomplets ou non installes.

## Workflow recommande

### Ajouter une ressource CRM
1. Creer ou ajuster les types
2. Creer les composants `List` / `Create` / `Edit` / `Show` si necessaire
3. Exporter la resource depuis le module
4. Declarer la resource dans `src/app/App.tsx`
5. Ajouter les donnees dans `baseData.ts` si besoin
6. Ajouter un test si logique non triviale
7. Verifier `lint`, `test`, `build`

### Ajouter une projection
1. Modifier `src/data/projections/*`
2. Garder la fonction pure
3. Ajouter un test cible
4. Verifier l'exposition via `fakerestData.ts`

## Shadcn / admin-kit

### Avant de creer un composant custom
Verifier d'abord le registry / MCP shadcn.

### Regles importantes
- ne pas installer directement les composants `example-*` comme composants finaux
- ne pas ecraser les composants `ui` sauf demande explicite
- conserver `verbatimModuleSyntax: false` dans `tsconfig.app.json`
- `<Admin>` est utilise comme racine de l'application admin

## Checklist avant de terminer

- [ ] changement limite au besoin
- [ ] fichiers modifies identifies
- [ ] `npm run lint`
- [ ] `npm run test`
- [ ] `npm run build`
- [ ] doc mise a jour si necessaire

## Docs utiles

- `README.md`
- `ressources/doc/etat-du-projet.md`
- `ressources/doc/recette-fonctionnelle.md`
- `ressources/doc/howto-ajouter-ressource-module.md`
- `ressources/doc/howto-ajouter-ressource-projection-summary.md`
- `ressources/doc/howto-migrer-fakerest-vers-rest-ibmi.md`
