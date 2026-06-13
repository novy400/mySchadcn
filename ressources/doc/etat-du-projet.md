# Etat du projet

_Date : 2026-06-01_

## Resume executif

Le projet **mySchadcn** est aujourd'hui un **mini CRM d'administration fonctionnel** base sur **Vite + React + TypeScript + ra-core + FakeRest**.

Il permet de :

- lancer une application admin localement sans backend HTTP reel
- manipuler plusieurs ressources CRM en CRUD
- tester une structure modulaire orientee domaine
- preparer une migration progressive vers un vrai data provider

Le projet est dans un etat **propre pour le developpement local** :

- `npm run dev` fonctionne
- `npm run lint` fonctionne
- `npm run test` fonctionne
- `npm run build` fonctionne

---

## Objectif du projet

Le projet sert a prototyper rapidement une application d'administration CRM avec :

- des ecrans CRUD metier
- un dashboard
- une organisation modulaire par domaine
- un jeu de donnees local
- une couche de projection pour enrichir certaines vues

L'objectif n'est pas encore de fournir une application de production complete, mais une **base solide de prototype evolutif**.

---

## Stack technique

- **Vite 8**
- **React 19**
- **TypeScript 5**
- **ra-core**
- **ra-data-fakerest**
- **Tailwind CSS 4**
- composants admin locaux dans `src/components/admin`
- composants UI dans `src/components/ui`
- **Vitest** + **Testing Library** pour les tests minimaux

---

## Fonctionnalites presentes

### Dashboard CRM
- cartes de synthese
- liste des contacts a suivre
- statistiques calculees a partir du dataset local

### Ressources metier
- `clients`
  - list
  - create
  - edit
- `contacts`
  - list
  - create
  - edit
- `tasks`
  - list
  - create
  - edit
- `notes`
  - list
  - create
  - edit
- `contacts_summary`
  - list uniquement
  - projection enrichie en lecture
- `customers`
  - list
  - show avec onglets
- ressources techniques associees :
  - `customerSignalietiques`
  - `customerRisques`

---

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
│     ├─ contacts-summary/
│     └─ customers/
└─ test/
```

### Pipeline de donnees

1. Les donnees brutes sont definies dans `src/data/raw/baseData.ts`
2. Les projections sont calculees dans `src/data/projections/buildSummaries.ts`
3. Le dataset final est expose via `src/data/fakerestData.ts`
4. Le provider est branche dans `src/app/providers/dataProvider.ts`

Ce decoupage est un point fort du projet : il facilite l'evolution vers d'autres providers.

---

## Etat qualite / outillage

## Build
Le build de production est operationnel.

```bash
npm run build
```

## Lint
Le lint est au vert.

```bash
npm run lint
```

## Tests
Un socle de tests a ete mis en place avec Vitest.

Tests actifs actuellement :

- `src/data/projections/buildSummaries.test.ts`
- `src/modules/crm/dashboard/Dashboard.test.tsx`

Commande :

```bash
npm run test
```

Mode watch :

```bash
npm run test:watch
```

### Note sur les anciens tests `*.spec.ts(x)`
Le repo contient encore de nombreux fichiers `*.spec.ts(x)` herites ou incomplets.
Ils ne sont pas integres a la suite active pour l'instant car ils dependent d'un outillage non finalise :

- stories manquantes
- packages de test specifiques non installes
- dependances rich-text / tiptap non completes

Ils sont pour le moment exclus du flux principal pour garder un socle fiable.

---

## Ce qui fonctionne bien

- structure modulaire claire
- application demarrable localement tres vite
- separation nette entre donnees brutes et projections
- dashboard simple et utile
- base CRM cohérente pour du prototypage
- build / lint / tests de base operationnels
- documentation projet deja assez riche dans `ressources/doc`

---

## Limites actuelles

### Donnees non persistantes
Le projet utilise `ra-data-fakerest`.
Les donnees sont donc :

- chargees localement
- modifiables pendant la session
- reinitialisees au rechargement complet de la page

### Couverture de test encore faible
Le socle existe, mais la couverture est encore minimale.
Il manque notamment :

- tests CRUD par ressource
- tests sur la navigation
- tests du data provider
- tests sur les onglets `customers`

### Quelques zones techniques encore fragiles
Certaines parties de `src/components/admin` et `src/components/rich-text-input` ont ete stabilisees surtout par configuration ESLint ciblee, pas encore par refactoring complet.

Cela signifie que :

- le projet est exploitable
- mais certains composants utilitaires meriteront un nettoyage progressif

---

## Comment tester le projet

## Lancement local

```bash
npm install
npm run dev
```

## Verification complete

```bash
npm run lint
npm run test
npm run build
```

## Recette manuelle rapide

Verifier au minimum :

- dashboard visible
- listes `clients`, `contacts`, `tasks`, `notes`
- vue `contacts_summary`
- vue `customers` avec onglets
- creation / edition sur au moins une ressource CRUD

Voir aussi :

- `ressources/doc/recette-fonctionnelle.md`

---

## Priorites recommandees

### Priorite 1 - Renforcer la couverture de tests
**Objectif :** Etendre les tests existants pour couvrir toutes les ressources

**Actions :**
1. Ajouter des tests pour chaque module CRM (`clients`, `contacts`, `tasks`, `notes`)
2. Tester le `dataProvider` et la navigation
3. Ajouter des tests d'integration pour les onglets `customers`

### Priorite 2 - Refactor progressif des composants techniques
**Objectif :** Ameliorer la qualite et la maintenabilite des composants partages

**Actions :**
1. Nettoyer `src/components/admin` (composants personnalises)
   - Modulariser le composant `data-table` en sous-composants
   - Extraire `DataTableHead`, `DataTableBody`, `DataTableRow`, `DataTableCell`
   - Réduire la complexité du composant principal
   - Créer un composant de base commun `ResourcePage` pour `Edit` et `Create`
   - Réduire le code dupliqué entre `Edit` et `Create`
2. Reviser `src/components/rich-text-input` (zone fragile)
   - Créer une version simplifiée `SimpleRichTextInput`
   - Réduire les dépendances inutiles
   - Améliorer la documentation
3. Reduire les exceptions ESLint dans les composants UI

### Priorite 3 - Preparer la migration vers un backend reel
**Objectif :** Rendre l'application prete pour un vrai data provider REST

**Actions :**
1. Conserver les ecrans existants tout en remplacant FakeRest
2. Implementer un data provider REST compatible IBM i
3. Tester la connectivite avec un backend reel

### Priorite 4 - Ameliorations fonctionnelles
**Objectif :** Ajouter des fonctionnalites utiles pour l'experience utilisateur

**Actions :**
1. Ajouter des "guesser" pour generer automatiquement les champs
2. Mettre en place un systeme d'authentification/roles
3. Ajouter des filtres et tris avances sur les listes

---

## Conclusion

Le projet est dans un **bon etat de prototype avance**.

Il est maintenant :

- demarrable
- testable
- buildable
- lintable
- documente

La prochaine etape n'est plus de le "faire fonctionner", mais de **renforcer sa qualite fonctionnelle et son evolutivite** :

1. plus de tests
2. nettoyage progressif des composants techniques
3. preparation du vrai data provider
