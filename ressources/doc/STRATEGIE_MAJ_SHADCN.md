# Stratégie de mise à jour Shadcn Admin Kit

Ce document décrit la stratégie retenue pour ce projet :
- continuer à travailler sur la version actuelle de la base shadcn-admin-kit ;
- prévoir un futur redémarrage propre à partir d'une version plus récente, avec réintégration sélective des personnalisations.

## Phase 1 : continuer avec la base actuelle

Objectif : rester productif maintenant, sans complexifier le Git ni casser le socle existant.

### Décisions

- On considère la version actuelle du projet comme **base de référence** pour ce POC.
- On ne tente plus de merge global avec `upstream/main` (surtout avec `--allow-unrelated-histories`).
- Les mises à jour upstream éventuelles se feront au cas par cas (fichier ou composant précis), pas par gros merge.

### Actions à effectuer

1. **Annuler tout merge en cours** (si nécessaire) :
   ```bash
   git merge --abort
   git status
   ```

2. **Nettoyer l'état local** :
   - vérifier qu'il n'y a plus de marqueurs de conflit (`<<<<<<<`, `=======`, `>>>>>>>`) dans les fichiers ;
   - lancer un `npm run dev` pour confirmer que le projet démarre correctement.

3. **Continuer le développement sur cette base** :
   - évoluer surtout dans `src/modules/` pour le métier ;
   - mettre les variantes d'UI dans `src/components/custom/` ;
   - éviter autant que possible de modifier directement les composants "de base" importés de shadcn-admin-kit.

## Phase 2 : redémarrage propre plus tard

Objectif : quand ce sera pertinent, repartir sur une version récente de shadcn-admin-kit et y réinjecter seulement les éléments utiles.

### Principe

- Créer un **nouveau repo** ou une **nouvelle branche** basée directement sur la dernière version de `marmelab/shadcn-admin-kit`.
- Réimporter progressivement les éléments suivants depuis ce projet :
  - `src/modules/` (logique métier, écrans spécifiques) ;
  - `src/components/custom/` (wrappers, composants personnalisés) ;
  - les éventuels helpers dans `src/lib/` utiles pour le métier ;
  - la documentation (SKILL, docs internes).

### Étapes possibles

1. **Récupérer la dernière version upstream** dans un nouveau dossier :
   ```bash
   git clone https://github.com/marmelab/shadcn-admin-kit nouvelle-base-shadcn
   ```

2. **Copier les pièces sélectionnées du projet actuel** vers cette nouvelle base :
   - modules métier (`src/modules/...`) ;
   - composants custom (`src/components/custom/...`) ;
   - styles et thèmes utiles.

3. **Adapter les imports et chemins** pour coller à la structure du nouveau repo.

4. **Tester et documenter** :
   - vérifier que les modules métier fonctionnent avec la nouvelle base ;
   - mettre à jour la doc SKILL pour refléter les nouveaux patterns ou composants.

## Règles d'architecture pour limiter les problèmes futurs

- `src/components/ui/` : zone la plus proche de l'upstream, à modifier le moins possible.
- `src/components/custom/` : toutes les adaptations UI spécifiques au projet.
- `src/modules/` : logique métier, écrans, routing métier.

Idée clé :
> plus la logique métier et les personnalisations sont concentrées dans `modules` et `custom`, plus il sera facile de changer de base (ou de mettre à jour) sans conflit massif.

## Résumé

- **Maintenant** : on avance avec la version actuelle, sans merge global upstream.
- **Plus tard** : on repartira d'une base shadcn-admin-kit récente, puis on réinjectera les morceaux utiles de ce projet (modules, custom, doc).
- **But** : rester simple et pragmatique, éviter de passer plus de temps à gérer Git qu'à faire avancer le métier.
