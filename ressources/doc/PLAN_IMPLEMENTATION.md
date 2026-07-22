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
| 3 | Stabiliser le contrat du futur DataProvider IBM i | À cadrer |
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

## Prochaine tranche

La tranche 3 doit stabiliser le contrat du futur DataProvider IBM i avant d'ajouter une
nouvelle logique métier dépendante de l'API.
