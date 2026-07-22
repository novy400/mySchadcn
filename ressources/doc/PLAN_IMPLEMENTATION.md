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
| 4 | Ajouter authentification et autorisations | À cadrer |
| 5 | Traiter la synchronisation des projections après mutation | À cadrer |
| 6 | Réduire les avertissements CSS de test et la taille du bundle | À évaluer |

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

## Prochaine tranche

La tranche 4 doit cadrer l'authentification et les autorisations à partir du contrat
d'erreur désormais fixé (`401` et `403`).
