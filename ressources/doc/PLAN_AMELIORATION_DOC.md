# Plan d'amélioration documentaire

_Branche de travail : `codex/docs-restructuration`_  
_Dernière mise à jour : 2026-07-22_

## Objectif

Rendre la documentation cohérente avec le dépôt, séparer l'existant de la cible et
préparer les décisions d'implémentation sans modifier prématurément l'application.

## Suivi

| Lot | Contenu | État |
| --- | --- | --- |
| 1 | Index, plan, état réel et architecture actuelle | Terminé |
| 2 | Politique unique de synchronisation avec upstream | Terminé |
| 3 | Restructuration du référentiel CMagic | Terminé |
| 4 | Mise à jour des guides et de la recette | Terminé |
| 5 | Renommage des documents/images et contrôle des liens | Terminé |
| 6 | Validation finale : liens, lint, tests et build | Terminé |

## Décisions

- `etat-du-projet.md` devient la photographie factuelle du dépôt.
- `architecture-actuelle.md` devient la référence sur l'organisation technique.
- Les documents de vision doivent être identifiés comme tels et ne pas déclarer une
  fonctionnalité comme implémentée sans preuve dans le code.
- Les notes de conversation ou de génération sont conservées en archive ou transformées
  en documents normatifs avant d'être présentées comme référence.
- Les changements applicatifs seront traités après validation de la documentation.

## Critères de fin

- aucune ressource active n'est absente de l'état du projet ;
- les commandes et chemins documentés existent ;
- une seule stratégie upstream est déclarée comme active ;
- les concepts CMagic distinguent clairement prototype, cible et exemples ;
- les liens relatifs sont valides ;
- `npm run lint`, `npm run test` et `npm run build` restent verts.

## Journal

### 2026-07-22

- audit complet de `ressources/` ;
- création de la branche documentaire ;
- création de l'index et du présent suivi ;
- actualisation de l'état et de l'architecture ;
- unification de la politique de synchronisation upstream.
- ajout d'un index CMagic distinguant références et matériaux de travail ;
- formalisation des concepts Catalogue, Processus, Action métier et Saga.
- ajout des exigences de tests et de validation aux guides ;
- actualisation des filtres de tâches et de la recette fonctionnelle.
- contrôle des liens relatifs : réussi ;
- `npm run lint` : réussi ;
- `npm run test` : 23 fichiers et 26 tests réussis ;
- `npm run build` : réussi, avec l'avertissement existant sur la taille du bundle.
- consolidation de l'architecture et de la synthèse CMagic ;
- transformation de la note `orders` en état du prototype et questions métier ;
- actualisation des tutoriels de starter et du guide de migration IBM i ;
- correction du nom du guide de filtres et renommage de ses captures référencées.
- renommage des captures de commandes référencées ;
- contrôle des liens relatifs : réussi après renommage ;
- contrôle des liens externes structurants Marmelab/GitHub : réussi ;
- validation finale : lint réussi, 23 fichiers/26 tests réussis, build réussi ;
- avertissements non bloquants conservés : parsing CSS sous jsdom et bundle principal
  supérieur à 500 kB.

## Résultat

Les six lots documentaires sont terminés. La documentation distingue désormais :

- l'état réel du prototype ;
- l'architecture actuelle ;
- les guides opératoires ;
- la cible IBM i/CMagic ;
- les matériaux exploratoires qui ne font pas foi.

La prochaine phase peut porter sur la priorisation des changements applicatifs révélés
par cette documentation, notamment les tests manquants, le modèle métier des commandes et
le contrat du futur DataProvider IBM i.
