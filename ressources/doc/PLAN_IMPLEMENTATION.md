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
| 2 | Formaliser et tester le modèle métier des commandes | À cadrer |
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

## Prochaine décision

La tranche 2 nécessite des choix métier avant de modifier `orders` : transitions de
statut, calcul des montants, représentation des retours, historique et idempotence. Les
questions sont recensées dans [Commandes et statuts](./cmagic/ordres_status.md).
