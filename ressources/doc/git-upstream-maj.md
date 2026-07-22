# Mise à jour depuis shadcn-admin-kit

_Politique active depuis le 2026-07-22._

## Décision

Le dépôt actuel a divergé de `marmelab/shadcn-admin-kit`. La politique retenue est donc :

- ne pas fusionner globalement `upstream/main` dans la branche principale ;
- inspecter les changements upstream ;
- reprendre sélectivement un correctif ou un composant dans une branche dédiée ;
- conserver les adaptations métier dans `src/modules` ;
- valider systématiquement lint, tests et build.

Un redémarrage complet depuis une nouvelle version upstream constitue un projet de
migration distinct. Il ne doit pas être confondu avec la maintenance courante.

## Configuration initiale

```bash
git remote add upstream https://github.com/marmelab/shadcn-admin-kit
git remote -v
```

Si le remote existe déjà, ne pas l'ajouter une seconde fois.

## Inspecter l'écart

```bash
git fetch upstream
git rev-list --left-right --count HEAD...upstream/main
git log --oneline --graph --decorate HEAD..upstream/main -20
git diff --stat HEAD..upstream/main
```

Pour `git rev-list --left-right --count HEAD...upstream/main` :

- le premier nombre compte les commits propres à `HEAD` ;
- le second compte les commits propres à `upstream/main`.

## Reprise recommandée d'un changement

### 1. Créer une branche dédiée

```bash
git switch main
git pull --ff-only origin main
git switch -c sync/upstream-composant
```

### 2. Examiner le changement

```bash
git diff HEAD..upstream/main -- chemin/du/fichier.tsx
```

Le chemin doit correspondre à l'arborescence réelle de l'upstream. Il ne faut pas
supposer qu'un composant se trouve dans `components/ui` sans le vérifier.

### 3. Choisir la méthode

Pour un commit autonome et compris :

```bash
git cherry-pick <sha>
```

Pour reprendre la version upstream d'un fichier puis l'adapter :

```bash
git restore --source upstream/main -- chemin/du/fichier.tsx
```

La reprise d'un fichier entier est à éviter si elle écrase des adaptations locales. Dans
ce cas, appliquer manuellement les différences utiles.

### 4. Valider

```bash
npm install
npm run lint
npm run test
npm run build
```

Effectuer ensuite une recette manuelle ciblée sur le composant repris.

## Répartition des responsabilités

- `src/components/ui` : primitives proches de shadcn/ui ; changements locaux prudents ;
- `src/components/admin` : implémentation admin locale issue du kit et adaptée au dépôt ;
- `src/modules` : écrans et logique de présentation métier ;
- `src/data/projections` : transformations et projections locales.

Le dossier `src/components/custom` mentionné dans d'anciens documents n'existe pas dans
l'architecture actuelle. Il ne constitue donc pas une convention active.

## Opérations interdites dans le flux courant

- merge global avec `--allow-unrelated-histories` ;
- remplacement massif de `src/components/admin` ou `src/components/ui` ;
- reprise d'un exemple `example-*` comme composant final sans adaptation ;
- intégration sans exécuter la suite de validation.

## Migration complète vers une nouvelle base

Si le coût des reprises sélectives devient trop élevé, créer un nouveau dépôt ou une
branche de migration à partir d'une version précise du kit, puis réintégrer progressivement :

1. les modules métier ;
2. le pipeline de données ;
3. les composants locaux indispensables ;
4. les tests ;
5. la documentation.

Cette décision doit faire l'objet d'un cadrage et d'une recette propres.
