# AGENTS.md

Ce fichier decrit les regles et le contexte de travail pour les agents qui interviennent sur ce projet.

## 1. But du projet

`mySchadcn` est un **mini CRM d'administration** construit avec :

- Vite
- React 19
- TypeScript 5
- `ra-core`
- `ra-data-fakerest`
- Tailwind CSS 4

Le projet sert a :

- prototyper rapidement des ecrans CRUD metier
- travailler avec un jeu de donnees local sans backend HTTP reel
- organiser le code par domaines CRM
- preparer une future migration vers un vrai data provider

## 2. Etat actuel attendu

A la date actuelle, les commandes suivantes doivent rester operationnelles :

```bash
npm run dev
npm run lint
npm run test
npm run build
```

Un changement qui casse l'une de ces commandes doit etre corrige ou explicite avant d'etre considere comme termine.

## 3. Architecture fonctionnelle

### Point d'entree
- `src/main.tsx`
- `src/app/App.tsx`

### Provider de donnees
- `src/app/providers/dataProvider.ts`

### Pipeline de donnees
- `src/data/raw/baseData.ts` : donnees brutes
- `src/data/projections/buildSummaries.ts` : projections enrichies
- `src/data/fakerestData.ts` : dataset final

### Modules CRM
- `src/modules/crm/clients`
- `src/modules/crm/contacts`
- `src/modules/crm/tasks`
- `src/modules/crm/notes`
- `src/modules/crm/contacts-summary`
- `src/modules/crm/customers`
- `src/modules/crm/dashboard`

### Composants partages
- `src/components/admin` : composants admin reutilisables
- `src/components/ui` : primitives UI
- `src/components/rich-text-input` : zone technique plus sensible, a modifier avec prudence

## 4. Ressources actuellement exposees

Dans `src/app/App.tsx`, l'admin utilise actuellement :

- `clients`
- `contacts`
- `tasks`
- `notes`
- `contacts_summary`
- `customers`
- `customerSignalietiques`
- `customerRisques`

## 5. Regles de modification

### 5.1 Regles generales
- Faire des changements **cibles et minimaux**.
- Preserver le style et l'organisation existants.
- Ne pas introduire de refactor massif sans demande explicite.
- Si une modification touche l'architecture, documenter l'impact.

### 5.2 Donnees et logique metier
- Toute nouvelle vue de synthese doit preferablement passer par `src/data/projections`.
- Eviter de melanger logique de projection et logique de rendu.
- Si une nouvelle ressource CRM est ajoutee, garder la structure modulaire :
  - types
  - composant list
  - composant create/edit/show si necessaire
  - resource exportee par le module

### 5.3 Composants admin / ui
- Ne pas reecrire largement `src/components/admin` ou `src/components/ui` sans besoin clair.
- Si un correctif local suffit, preferer un correctif local.
- `src/components/rich-text-input` contient des zones plus fragiles : eviter d'y intervenir sauf besoin reel.

### 5.4 Tests et qualite
Apres une modification significative, verifier au minimum :

```bash
npm run lint
npm run test
npm run build
```

Pour un changement purement UI mineur, `lint` peut suffire pendant l'iteration, mais avant finalisation il faut viser les 3 commandes.

## 6. Strategie de test actuelle

Le projet dispose d'un setup Vitest minimal.

### Tests actifs
- `src/data/projections/buildSummaries.test.ts`
- `src/modules/crm/dashboard/Dashboard.test.tsx`

### Convention actuelle
- Les tests actifs utilisent `*.test.ts` et `*.test.tsx`
- Les anciens `*.spec.ts(x)` ne font pas partie de la suite active pour l'instant

### Pourquoi
Les anciens `*.spec.ts(x)` reposent sur un outillage incomplet ou non installe :
- stories manquantes
- dependances de test specifiques
- dependances rich-text / Tiptap non completes

Ne pas rebrancher ces anciens tests sans remettre en place leur stack complete.

## 7. Documentation utile

A consulter avant toute evolution structurante :

- `README.md`
- `ressources/doc/etat-du-projet.md`
- `ressources/doc/recette-fonctionnelle.md`
- `ressources/doc/0_cadrage.md`
- `ressources/doc/tutoriel-vite-react-admin-fakerest-modulaire.md`
- `ressources/doc/howto-ajouter-ressource-module.md`
- `ressources/doc/howto-ajouter-ressource-projection-summary.md`
- `ressources/doc/howto-migrer-fakerest-vers-rest-ibmi.md`

## 8. Workflow recommande pour une nouvelle fonctionnalite

### Ajouter une nouvelle ressource CRUD
1. Ajouter les types du domaine si necessaire
2. Ajouter les composants `List`, `Create`, `Edit`, `Show` selon le besoin
3. Exporter la resource depuis le module
4. Brancher la resource dans `src/app/App.tsx`
5. Ajouter les donnees dans `baseData.ts` si FakeRest est utilise
6. Ajouter ou adapter une projection si la vue l'exige
7. Ajouter au moins un test si la logique n'est pas triviale
8. Verifier `lint`, `test`, `build`

### Ajouter une projection
1. Ajouter ou modifier la logique dans `src/data/projections`
2. Garder la fonction pure et testable
3. Ajouter un test Vitest cible
4. Verifier que `fakerestData.ts` expose bien le resultat

## 9. Regles pour shadcn / registry

### Toujours verifier le registry avant de creer un composant custom
- utiliser la recherche semantique du registry d'abord
- consulter le detail des composants
- regarder les exemples d'usage
- recuperer la commande d'installation adaptee

### Installation de composants
- utiliser les commandes fournies par le registry
- ne pas installer directement les composants `example-*` comme composants finaux
- s'en servir comme reference seulement
- ne pas ecraser les composants `ui` ou `registry/ui` sauf demande explicite

## 10. Regles pour shadcn-admin-kit

### A propos du registry
- le registry `shadcn-admin-kit` tourne autour du bloc `admin`
- il fournit surtout l'UI admin
- la logique applicative repose sur `ra-core`

### Configuration TypeScript obligatoire
Le projet doit conserver :

```json
{
  "compilerOptions": {
    "verbatimModuleSyntax": false
  }
}
```

### Utilisation de `<Admin>`
- `<Admin>` est un composant client-side
- dans ce projet Vite SPA, il est utilise comme racine de l'admin
- les ressources sont declarees via `<Resource>` de `ra-core`

## 11. Bonnes pratiques de livraison

Quand une tache est terminee, l'agent doit idealement indiquer :

- les fichiers modifies
- ce qui a ete change
- les commandes de verification executees
- les limites eventuelles ou suites recommandees

## 12. A eviter

- casser le pipeline FakeRest sans le remplacer proprement
- modifier lourdement `src/components/admin` pour regler un besoin metier local
- reintroduire les anciens tests `*.spec.ts(x)` sans outillage adapte
- faire des changements non testes sur les projections de donnees
- ignorer une regression `lint`, `test` ou `build`

## 13. Commandes de reference

```bash
npm install
npm run dev
npm run lint
npm run test
npm run test:watch
npm run build
npm run preview
```
