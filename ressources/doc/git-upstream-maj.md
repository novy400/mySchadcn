# Workflow de mise à jour depuis upstream

Ce document résume une méthode simple et sûre pour récupérer les mises à jour du projet source `marmelab/shadcn-admin-kit` dans ce dépôt.

## Préparation initiale

Si le remote `upstream` n'existe pas encore :

```bash
git remote add upstream https://github.com/marmelab/shadcn-admin-kit
```

Vérifier les remotes :

```bash
git remote -v
```

## Convention de branche principale

Le dépôt local peut utiliser `main` comme branche principale, ce qui est cohérent avec `upstream/main`.

Renommer la branche locale `master` en `main` :

```bash
git branch -m master main
git push -u origin main
```

Ensuite, changer la branche par défaut sur GitHub dans **Settings > Branches**, puis supprimer l'ancienne branche distante si nécessaire :

```bash
git push origin --delete master
```

## Routine de mise à jour

### 1. Récupérer les nouveautés upstream

```bash
git fetch upstream
```

Cette commande ne modifie pas le code local. Elle met seulement à jour les références distantes comme `upstream/main`.

### 2. Mesurer l'écart

```bash
git rev-list --left-right --count HEAD...upstream/main
```

Exemple de sortie :

```text
32    850
```

Lecture pratique :
- premier nombre : commits présents dans `upstream/main` et absents localement
- second nombre : commits présents localement et absents dans `upstream/main`

> Sous PowerShell, ne pas ajouter `\` en fin de ligne.

### 3. Voir les commits upstream à intégrer

```bash
git log --oneline --graph --decorate HEAD..upstream/main -20
```

### 4. Voir les fichiers touchés

```bash
git diff --stat HEAD..upstream/main
```

Pour inspecter un fichier précis :

```bash
git diff HEAD..upstream/main -- src/components/ui/data-table.tsx
```

## Trois stratégies d'intégration

### A. Merge complet recommandé dans une branche de test

À utiliser quand les changements semblent peu risqués.

```bash
git checkout main
git checkout -b merge/upstream-main
git merge upstream/main
```

Puis vérifier le projet :

```bash
npm install
npm run lint
npm run test
npm run dev
```

Si tout est correct :

```bash
git checkout main
git merge merge/upstream-main
```

### B. Cherry-pick d'un commit précis

À utiliser quand un commit upstream t'intéresse particulièrement.

```bash
git log --oneline upstream/main
git cherry-pick <sha_commit>
```

### C. Récupération sélective d'un fichier

À utiliser quand tu veux remettre un composant dans l'état upstream.

```bash
git checkout upstream/main -- src/components/ui/data-table.tsx
git commit -m "sync data-table depuis upstream"
```

## Règle d'architecture pour limiter les conflits

Pour garder les mises à jour simples :

- `src/components/ui/` → zone la plus proche d'upstream, à modifier le moins possible
- `src/components/custom/` → wrappers et personnalisations locales
- `src/modules/` → logique métier et écrans applicatifs

Principe recommandé :
- éviter de modifier directement les composants de base quand un wrapper suffit
- placer les adaptations métier dans `modules`
- placer les variantes d'UI dans `components/custom`

## Commandes utiles

Lister les branches locales :

```bash
git branch
```

Lister les branches distantes :

```bash
git branch -r
```

Voir les remotes :

```bash
git remote -v
```

Voir l'état courant :

```bash
git status
```

## Routine conseillée avant chaque mise à jour

```bash
git checkout main
git pull origin main
git fetch upstream
git rev-list --left-right --count HEAD...upstream/main
git log --oneline --graph --decorate HEAD..upstream/main -20
git diff --stat HEAD..upstream/main
```

Ensuite :
- si peu de changements et peu de risques → merge dans une branche de test
- si un seul correctif t'intéresse → cherry-pick
- si un seul composant t'intéresse → récupération sélective du fichier

## Conseil pratique

Sur ce projet, la meilleure stratégie est souvent :
1. `fetch upstream`
2. regarder l'écart
3. tester un merge complet dans une branche intermédiaire
4. valider avec lint/tests/dev
5. fusionner dans `main` seulement après validation
