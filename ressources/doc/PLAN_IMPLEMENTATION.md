# Plan d'implémentation

_Branche : `codex/docs-restructuration`_
_Dernière mise à jour : 2026-07-22_

## Objectif

Traiter progressivement les écarts techniques et fonctionnels identifiés pendant l'audit
documentaire, par tranches petites et vérifiables.

## Tranches

| Priorité | Tranche | État |
| --- | --- | --- |
| 1 | Couvrir `fournisseurs`, `orders` et les onglets `customers` | Terminé |
| 2 | Formaliser et tester le modèle métier des commandes | Terminé |
| 3 | Stabiliser le contrat du futur DataProvider IBM i | Terminé |
| 4 | Ajouter authentification et autorisations | Terminé |
| 5 | Traiter la synchronisation des projections après mutation | Terminé |
| 6 | Réduire les avertissements CSS de test et la taille du bundle | Terminé |

## Tranche 1 — Couverture des modules récents

### Réalisé

- tests de rendu et filtres pour `fournisseurs` ;
- test du contrat de ressource `fournisseurs` ;
- tests des onglets de statut et données de `orders` ;
- test du contrat de ressource `orders` ;
- test de la liste `customers` ;
- tests des données Général, Signalétique et Risque ;
- nettoyage automatique du DOM entre les tests Testing Library ;
- export nommé du DataProvider utilisé par `TestProvider` ;
- suppression des filtres UI vides avant délégation à FakeRest.

### Défaut fonctionnel corrigé

FakeRest traite `q: ""` comme une recherche active ne correspondant à aucune ligne. Les
listes munies d'une recherche permanente pouvaient donc afficher « No results found » au
chargement. Le DataProvider normalise désormais les filtres vides tout en conservant les
valeurs métier significatives telles que `false`, `0` et `null`.

### Validation

- `npm run lint` : réussi ;
- `npm run test` : 30 fichiers, 37 tests réussis ;
- `npm run build` : réussi.

## Tranche 2 — Cycle de vie des commandes

Le modèle validé est :

- une commande en cours peut être livrée ou annulée ;
- une commande livrée ne peut plus être annulée ;
- une commande annulée est terminale ;
- un retour ne peut être signalé que sur une commande livrée et une seule fois ;
- le retour reste temporairement représenté par un booléen.

Le vocabulaire canonique est enregistré dans [`CONTEXT.md`](../../CONTEXT.md).

### Réalisé

- règles de transition isolées dans une fonction pure ;
- erreur métier explicite pour toute transition interdite ;
- tests des transitions autorisées, terminales et du retour unique ;
- remplacement de l'édition libre de `status` et `returned` par les actions `Livrer`,
  `Annuler` et `Signaler le retour` ;
- confirmation avant annulation ;
- affichage des seules actions autorisées par l'état courant ;
- mise à jour de la recette et de la documentation CMagic.

### Validation

- tests ciblés du domaine et des actions : 11 tests réussis ;
- `npm run lint` : réussi ;
- `npm run test` : 32 fichiers, 48 tests réussis ;
- `npm run build` : réussi.

## Tranche 3 — Contrat du DataProvider IBM i

### Contrat retenu

- un registre typé unique décrit les onze ressources consommées par l'administration ;
- le registre fixe leurs champs, capacités, filtres, tris, relations et actions métier ;
- `tasks` fait partie du contrat même si seule sa projection `tasks_with_client` est
  enregistrée dans l'application ;
- les projections sont explicitement en lecture seule ;
- les commandes exposent des actions métier distinctes des opérations CRUD ;
- un provider composite permet une migration ressource par ressource sans modifier les écrans ;
- une ressource absente du registre provoque une erreur explicite au lieu d'être routée
  silencieusement vers FakeRest.

Le contrat de transport et d'erreur est documenté dans
[`contrat-data-provider-ibmi.md`](./contrat-data-provider-ibmi.md).

### Réalisé

- ajout du registre `resourceContracts` et de ses tests de contrat ;
- ajout de `createCompositeDataProvider` couvrant les neuf opérations standard React Admin ;
- conservation du signal d'annulation uniquement lorsque les deux adapters le supportent ;
- définition des formats de liste, d'écriture, de relation, de date, de montant et d'erreur ;
- définition des endpoints attendus pour les actions de commande ;
- mise à jour du guide de migration IBM i et de l'index documentaire.

### Validation

- tests ciblés du registre et du provider composite : 9 tests réussis ;
- `npm run lint` : réussi ;
- `npm run test` : 34 fichiers, 57 tests réussis ;
- `npm run build` : réussi ;
- revue standards et conformité au plan : terminée ; constats corrigés avant clôture.

## Tranche 4 — Authentification et autorisations

### Modèle retenu

- Lecteur : consultation uniquement ;
- Agent : gestion des clients, contacts, tâches, notes et fournisseurs ;
- Responsable : droits de l'Agent et pilotage du cycle de vie des commandes ;
- politique refusant par défaut toute ressource ou action inconnue ;
- AuthProvider indépendant de l'adapter d'identité ;
- adapter local public pour le prototype, remplaçable par un adapter REST IBM i ;
- identité publique conservée dans `sessionStorage`, sans mot de passe ni jeton ;
- autorisation de production obligatoirement contrôlée par le backend à chaque requête.

Le vocabulaire est enregistré dans [`CONTEXT.md`](../../CONTEXT.md) et le contrat détaillé
dans [`authentification-autorisations.md`](./authentification-autorisations.md).

### Réalisé

- politique d'accès typée et tests des trois rôles ;
- AuthProvider avec connexion, déconnexion, identité, permissions, `401`, `403` et `canAccess` ;
- trois comptes de démonstration clairement signalés comme publics ;
- application protégée par `requireAuth` avec page de connexion dédiée ;
- filtrage des routes, menus, suppressions génériques et actions métier des commandes ;
- filtrage des boutons de création et d'édition ainsi que des clics de ligne selon le rôle ;
- invalidation d'une ancienne session avant toute nouvelle tentative de connexion ;
- restauration et fermeture de session serveur via l'adapter d'identité injectable ;
- routage des mutations de `tasks_with_client` vers la ressource `tasks` ;
- documentation du futur contrat de session IBM i et des limites du prototype.

### Validation

- tests ciblés de l'authentification, des rôles, de l'application et des commandes :
  24 tests réussis ;
- `npm run lint` : réussi ;
- `npm run test` : 38 fichiers, 77 tests réussis ;
- `npm run build` : réussi ;
- revue standards et conformité au plan : terminée ; constats corrigés avant clôture.

## Tranche 5 — Synchronisation des projections

### Stratégie retenue

- conserver les transformations métier dans des fonctions pures de `src/data/projections` ;
- observer les mutations au seam public du DataProvider ;
- recalculer `contacts_summary` et `tasks_with_client` depuis les collections sources ;
- remplacer les collections projetées après `create`, `update` et `updateMany` sur
  `clients`, `contacts`, `tasks` ou `notes` ;
- réserver au futur backend IBM i la synchronisation adaptée aux volumes de production.

### Réalisé

- extraction des constructeurs purs des deux projections ;
- décorateur de DataProvider resynchronisant les projections dépendantes ;
- sérialisation des recalculs concurrents pour conserver l'état source le plus récent ;
- application du contrat de lecture seule au DataProvider FakeRest exporté ;
- couverture des créations et modifications de tâches ;
- couverture d'une modification en masse, d'un renommage client et d'une nouvelle note ;
- mise à jour de l'architecture, de l'état du projet et des guides concernés.

### Validation

- tests ciblés du DataProvider et des projections : 12 tests réussis ;
- `npm run lint` : réussi ;
- `npm run test` : 38 fichiers, 85 tests réussis ;
- `npm run build` : réussi ;
- revue standards et conformité au plan : terminée ; aucun constat restant.

## Tranche 6 — Tests CSS et découpage du bundle

### Diagnostic

- l'avertissement CSS est reproduit par les seuls tests du rich-text input ;
- les deux tests du rich-text input sont des smoke tests d'import et de définition ;
- les autres tests actifs vérifient le DOM et les interactions sans assertion visuelle ;
- jsdom échoue sur la feuille Tailwind moderne alors que le navigateur l'accepte ;
- le chunk unique d'environ 950 kB est dominé par React, React Admin, le routeur et les
  primitives UI nécessaires à l'administration ;
- un découpage uniquement fondé sur la taille génère trop de micro-chunks.

### Réalisé

- désactivation explicite de l'injection CSS dans jsdom ;
- conservation de la compilation CSS dans le build Vite ;
- quatre groupes fonctionnels de dépendances, produisant cinq chunks principaux tous
  inférieurs à 300 kB minifiés, plus le petit runtime Rolldown ;
- suppression des deux avertissements dans les commandes de référence ;
- smoke test du build : connexion Responsable, dashboard visible, console sans erreur ;
- publication du diagnostic dans
  [`diagnostic-tests-et-bundle.md`](./diagnostic-tests-et-bundle.md).

### Validation

- `npm run lint` : réussi ;
- `npm run test` : 38 fichiers, 85 tests réussis, sans avertissement CSS ;
- `npm run build` : réussi, sans avertissement de taille de chunk ;
- smoke test navigateur : réussi ;
- revue standards et conformité au plan : terminée ; aucun constat restant.

## Suite

Les six tranches du plan initial sont terminées. Les évolutions suivantes relèvent d'un
nouveau cadrage produit ou technique, notamment le branchement IBM i et l'enrichissement
du modèle des commandes.
