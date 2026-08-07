# Plan d'implémentation

_Branche : `codex/docs-restructuration`_
_Dernière mise à jour : 2026-08-07_

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
| 7 | Ajouter `GET` par identifiant au transport IWS CMagic | Terminé |
| 8 | Ajouter `CREATE` avec validation métier au transport IWS CMagic | Terminé |
| 9 | Ajouter `UPDATE` avec validation préalable au transport IWS CMagic | Terminé |
| 10 | Ajouter `DELETE` avec validation préalable au transport IWS CMagic | Terminé |
| 11 | Migrer le moteur CMagic de Langium 3.5 à Langium 4.3.1 | Terminé |
| 12 | Brancher une première ressource en lecture sur le DataProvider IBM i | Terminé |

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

## Tranche 7 — `GET` par identifiant avec IWS

### Contrat retenu

- une entité avec `iwsObject` conserve la capacité `LIST` obligatoire et peut déclarer
  `GET` en complément ;
- `service_getlist_iws` reste le premier export du service program ;
- `service_getone_iws` reçoit l'identifiant typé par PCML et renvoie `item`, `errors`,
  `httpStatus` et `httpHeaders` ;
- la procédure de lecture commune `{entity}_get` reste l'unique accès Db2 ;
- une ressource absente produit `404`, une erreur technique `500` et une terminaison
  RPG inattendue `RNX9001` ;
- IWS publie le détail comme sous-ressource `GET /{id}` de la même ressource REST.

### Réalisé localement

- extension du modèle de rendu et des templates IWS pour la structure de détail et la
  procédure `GET` ;
- export conditionnel de `service_getone_iws` dans le binder, après l'export `LIST`
  existant ;
- conservation exacte du contrat généré pour un catalogue limité à `LIST` ;
- passage de l'exemple IWS à `operations { LIST, GET }` et régénération de ses vingt et un
  artefacts ;
- génération de deux binding directories applicatifs : `SERVICE.BNDDIR` pour construire
  le wrapper, puis `SERVIWS.BNDDIR` pour ses tests, sans dépendance directe à `CIWS` ;
- tests du compilateur, de l'interface PCML, du wrapper, du binder et de la
  compatibilité `LIST` seule ;
- archivage du [Swagger IWS 2.6](./cmagic/swagger.json) et du
  [PCML SERVIWS3](./cmagic/SERVIWS3.pcml), puis fermeture de la réserve documentaire
  de la session précédente ;
- mise à jour du contrat Catalogue et de la recette de redéploiement IWS.

### Validation locale

- suite CMagic : 18 fichiers, 120 tests réussis ;
- lint CMagic : réussi ;
- build CMagic : réussi ;
- génération répétée : vingt et un artefacts strictement identiques ;
- `npm run check` à la racine : lint réussi, 38 fichiers et 85 tests réussis, build
  réussi ;
- revue Standards : aucun constat ;
- revue Spec : deux constats corrigés dans la recette HTTP et la couverture des erreurs
  `500`/`RNX9001`, puis suites CMagic et racine réexécutées avec succès.

### Validation IBM i du 6 août 2026

- `SERVICE` et `SERVIWS` reconstruits après correction manuelle des binding
  directories ; cette correction est maintenant intégrée au générateur ;
- suites RPGUnit existantes réussies : 6 tests/14 assertions pour le service et
  4 tests/24 assertions pour le transport IWS ;
- `SERVIWS3` redéployé avec `service_getlist_iws` sur `/` et `service_getone_iws` sur
  `/{id}` ;
- [Swagger IWS 2.6](./cmagic/swagger.json) et [PCML](./cmagic/SERVIWS3.pcml) actualisés
  avec les deux procédures ;
- [export curl](./cmagic/testCurl.html) archivé : le corps nominal de `GET /A00`
  contient `item.id = A00` et aucune erreur, `/XXX` produit `CAT0001` sur `id`, et les
  statuts capturés séparément sont `200` pour `/A00` et `404` pour `/ZZZ` ;
- [capture HTTP finale](./cmagic/image/recette-ibmi-catalogue-iws/http-get-200-404-success.png)
  archivée avec ces trois observations.

### Décision de validation

- le 6 août 2026, le propriétaire du projet accepte la validation fonctionnelle sur la
  base des observations archivées : `/A00 → 200`, `/ZZZ → 404` et
  `/XXX → CAT0001/id` ;
- le statut et le corps d'erreur proviennent de deux identifiants absents distincts ;
  cette limite de preuve est connue et acceptée pour clôturer la tranche.

### Suivi non bloquant

- ajouter une couverture RPGUnit IBM i dédiée à `service_get` et
  `service_getone_iws` lors d'une prochaine évolution du générateur de tests.

## Tranche 8 — `CREATE` avec validation métier et IWS

### Contrat retenu

- `service_create(pDetail, pId, pErrors)` orchestre la création et n'exécute aucun SQL
  avant la validation ;
- `service_isValid(action, before, after, errors)` constitue la frontière de validation
  de toutes les mutations présentes et futures ;
- le générateur produit les contrôles basiques déductibles du DSL, puis appelle
  `service_isValid_business` dans une zone manuelle préservée pour les règles du projet ;
- l'identifiant naturel `DEPTNO` est fourni par le client ;
- les champs facultatifs textuels vides sont écrits comme `NULL` ;
- `service_create_iws` renvoie l'élément créé avec `201`, une validation avec `400`, un
  conflit Db2 `23505` avec `409`, et une erreur technique avec `500` ;
- une exposition IWS avec `CREATE` exige aussi `GET`, afin que la réponse `201` restitue
  systématiquement la donnée réellement persistée ;
- à l'issue de cette tranche, `UPDATE` et `DELETE` restaient refusés par le compilateur ;
- le transport ILEastic reste en lecture seule et refuse donc une entité déclarant
  simultanément `ileasticObject` et `CREATE`.

### Réalisé localement

- activation de `CREATE` dans `CatalogSpec` et maintien du refus de `UPDATE`/`DELETE` ;
- génération des prototypes, procédures RPG, binder et contrôles `required` ;
- insertion Db2 après validation, gestion du conflit et conversion des chaînes vides
  facultatives avec `NULLIF` ;
- préservation à la régénération de la procédure métier
  `service_isValid_business` ;
- génération de l'interface PCML, du wrapper et de l'export
  `service_create_iws` après les exports `LIST` et `GET` ;
- relecture par `service_get` afin de restituer la donnée réellement persistée ;
- ajout de `POST` et de la capacité `create` aux contrats OpenAPI et frontend ;
- passage de l'exemple IWS à `operations { LIST, GET, CREATE }` et régénération des
  artefacts de référence ;
- couverture TDD du compilateur, du service RPG, de la zone protégée, des interfaces,
  des binders, du wrapper IWS et des contrats.

### Validation locale

- suite CMagic : 18 fichiers, 128 tests réussis ;
- lint CMagic : réussi ;
- build CMagic : réussi ;
- génération répétée : vingt et un artefacts strictement identiques.

### Validation IBM i du 6 août 2026

- reconstruction réussie de `SERVICE`, `SERVICE.BNDDIR`, `SERVIWS` et
  `SERVIWS.BNDDIR` ; la procédure contractuelle reste `service_isValid`. Le prototype
  explicite de son hook interne `service_isValid_business`, inutile et incompatible
  avec cette compilation IBM i, a été retiré du générateur tandis que le hook protégé
  reste présent ;
- suites RPGUnit existantes réussies : 2 fichiers, 10 cas, 38 assertions et aucun
  échec ;
- redéploiement de `SERVIWS3` avec `service_create_iws` comme `POST /` ;
- création de `ZC4` avec `201`, relecture avec `200`, doublon avec `409/CAT1002`,
  identifiant invalide avec `400/CAT1001`, seconde création de `ZC5` avec `201`, puis
  suppression des seules lignes `ZC%` et contrôle d'une liste finale vide ;
- Swagger, PCML, export curl et capture RPGUnit archivés ;
- le Swagger et l'attribut PCML statique annoncent encore un succès `200`, mais le
  paramètre de réponse dynamique `httpStatus` produit bien le `201` observé. Cette
  limite documentaire d'IWS 2.6 est acceptée pour la v0.

## Tranche 9 — `UPDATE` avec validation préalable et IWS

### Contrat retenu

- `UPDATE` exige `GET` pour charger l'état `before` et confirmer l'existence de
  l'entité avant toute validation ou écriture ;
- `service_update(pId, pDetail, pErrors)` appelle
  `service_isValid(modification, before, after, errors)` avant tout SQL ;
- l'identifiant naturel est immuable : une différence entre le chemin et le corps
  produit `CAT1005/id` ;
- les contrôles `required`, booléens et enums sont communs à `CREATE` et `UPDATE`, puis
  le hook interne protégé applique les règles métier spécifiques ;
- l'instruction Db2 modifie uniquement les colonnes non-clés et convertit les valeurs
  facultatives vides en `NULL` ;
- `service_update_iws` reçoit `id` depuis le chemin et `input` depuis le corps, relit la
  donnée persistée et renvoie `200`, `400`, `404`, `409` ou `500` ;
- OpenAPI publie `PUT /api/{resource}/{id}` et le contrat frontend ajoute la capacité
  `update` ;
- ILEastic reste en lecture seule et `DELETE` reste refusé par le compilateur.

### Réalisé localement

- activation de `UPDATE`/`CHANGE` dans le compilateur avec diagnostics lorsque `GET`
  ou un champ non-clé manque ;
- génération des prototypes, procédures, actions, binders et exports
  `service_update`/`service_update_iws` sans déplacer les exports déjà publiés ;
- chargement de l'état précédent, validation de l'identifiant immuable, écriture des
  seuls champs non-clés et gestion des erreurs Db2 ;
- mapping IWS de l'absence vers `404`, de la validation vers `400`, du conflit vers
  `409` et des erreurs SQL/RPG vers `500` ;
- ajout de `PUT`, des réponses et de la capacité `update` aux contrats générés ;
- passage de l'exemple IWS à `operations { LIST, GET, CREATE, UPDATE }` ;
- régénération déterministe des vingt et un artefacts et synchronisation des onze
  fichiers affectés vers `cMagicIws` ;
- couverture TDD du compilateur, du service RPG, des interfaces, des binders, du
  wrapper IWS et des contrats.

### Validation locale

- suite CMagic : 18 fichiers, 135 tests réussis ;
- lint CMagic : réussi ;
- build CMagic : réussi ;
- génération répétée : vingt et un artefacts strictement identiques ;
- comparaison des onze artefacts synchronisés avec `cMagicIws` : identiques ;
- `npm run check` à la racine : lint réussi, 38 fichiers et 85 tests réussis, build
  réussi ;
- revue Standards : aucune violation ; une duplication interne mineure a été
  simplifiée en partageant une seule expression d'écriture SQL ;
- revue Spec : aucun constat.

### Validation IBM i

- `SERVICE`, `SERVICE.BNDDIR`, `SERVIWS` et `SERVIWS.BNDDIR` ont été reconstruits sans
  modification manuelle des sources générées ;
- les deux suites RPGUnit compilent et exécutent 10 cas et 38 assertions sans échec ;
- le Swagger et le PCML archivés exposent `service_update_iws` comme `PUT /{id}` ;
- la séquence nominale confirmée pendant la recette est `GET /ZC5 → 200`,
  `PUT /ZC5 → 200`, puis `GET /ZC5 → 200` avec le nom modifié persisté ;
- le dernier export du notebook a été produit après `clrlib TESTBIN` et conserve donc
  des réponses techniques `500` attendues après nettoyage ; il n'est pas utilisé comme
  preuve nominale de l'UPDATE ;
- le propriétaire du projet accepte cette limite de preuve et déclare la tranche 9
  **GO** le 6 août 2026.

## Tranche 10 — `DELETE` avec validation préalable et IWS

### Contrat retenu

- `DELETE` exige `GET` pour charger l'état `before` et confirmer l'existence de
  l'entité avant toute validation ou suppression ;
- `service_delete(pId, pErrors)` appelle
  `service_isValid(suppression, before, after, errors)` avant tout SQL ;
- l'état `after` est vide et le hook métier protégé peut refuser la suppression avec
  une erreur fonctionnelle ;
- une contrainte référentielle Db2 (`SQLSTATE 23504`) devient
  `409/CAT1002/conflict` ;
- `service_delete_iws` renvoie `204`, `400`, `404`, `409` ou `500` sans structure
  `item` dans sa signature ;
- OpenAPI publie `DELETE /api/{resource}/{id}` et le contrat frontend ajoute la
  capacité `delete` ;
- ILEastic reste en lecture seule.

### Réalisé localement

- activation de `DELETE` dans le compilateur avec diagnostics lorsque `GET` manque ou
  que la mutation est demandée avec ILEastic ;
- génération de l'action `suppression`, des prototypes, de `service_delete`, de
  `service_delete_iws` et de leurs exports en fin des binders existants ;
- lecture préalable, validation par `service_isValid`, suppression Db2 et adaptation
  des erreurs fonctionnelles, référentielles et techniques ;
- ajout du `DELETE`, des réponses HTTP et de la capacité `delete` aux contrats
  générés ;
- passage de l'exemple IWS à
  `operations { LIST, GET, CREATE, UPDATE, DELETE }` ;
- régénération des vingt et un artefacts et synchronisation des onze fichiers affectés
  vers `cMagicIws` ;
- cycle TDD observé : 25 échecs initiaux sur les seams manquants, puis 62 tests ciblés
  réussis.

### Validation locale

- suite CMagic : 18 fichiers, 141 tests réussis ;
- lint CMagic : réussi ;
- build CMagic : réussi ;
- génération répétée : vingt et un artefacts strictement identiques ;
- comparaison des onze artefacts synchronisés avec `cMagicIws` : identiques ;
- `npm run check` à la racine : lint réussi, 38 fichiers et 85 tests réussis, build
  réussi ;
- revue Standards : aucune violation d'`AGENTS.md` ; le nom ambigu `hasWrite` a été
  corrigé en `hasCreateOrUpdate`. Deux refactorings internes mineurs restent hors de
  cette tranche ciblée (politique des mutations et mapping d'erreurs IWS) ;
- revue Spec : aucun constat.

### Validation IBM i du 6 août 2026

- le propriétaire du projet confirme que `clrlib TESTBIN` a été exécuté au début de la
  séance, avant la reconstruction des objets et les appels curl de validation ;
- `SERVICE`, les binding directories, `SERVIWS` et le service `SERVIWS3` ont ensuite été
  reconstruits et la verticale `DELETE` a été testée puis acceptée sur IBM i ;
- l'ordre des cellules dans [l'export curl](./cmagic/testCurl.html) ne représente pas leur
  ordre d'exécution. L'export mélange des réponses nominales obtenues après reconstruction
  et d'anciennes sorties `500` de cellules non rejouées après l'absence de
  `TESTBIN/SERVIWS.SRVPGM` ;
- l'export ne constitue donc pas, à lui seul, une preuve autonome du scénario
  `DELETE → 204`, puis `GET → 404`. Cette limite documentaire est connue et acceptée par
  le propriétaire du projet, qui déclare la tranche 10 **GO**.

## Tranche 11 — Migration du moteur CMagic vers Langium 4.3.1

### Périmètre retenu

- Node 24 LTS, TypeScript 5.9, Langium 4.3.1 et `langium-cli` 4.3.0 ;
- famille LSP 10 / protocole 3.18 pour le serveur et l'extension VS Code ;
- adaptation limitée à la génération Langium, au CLI, à l'extension et au Web Worker ;
- aucun changement de grammaire, de générateur métier, de DataProvider IBM i ou de pile
  Monaco du lot B.

### Réalisé

- mise à jour ciblée des dépendances et du lockfile, avec Volta sur Node 24.18.0 ;
- alignement du moteur VS Code minimal sur 1.91, exigé par le client LSP 10 ;
- adaptation des sous-chemins d'import LSP et des descripteurs AST `Model.$type` ;
- audit du diff généré Langium 3.5.2 vers 4.3.0 ;
- correction du workflow `vscode:prepublish`, qui reconstruit désormais la grammaire,
  l'extension et le serveur réellement empaquetés ;
- livraison et installation locale de l'extension CMagic `0.0.3`, avec un test LSP exécuté
  depuis le VSIX ;
- mise à jour et suivi de
  [`etude-langium-4.3.1-et-playground.md`](./cmagic/etude-langium-4.3.1-et-playground.md).

### Validation locale

- génération Langium sans avertissement ;
- suite CMagic : 18 fichiers et 141 tests réussis, lint et build réussis ;
- CLI, prépublication de l'extension, packaging du VSIX et build du Web Worker réussis ;
- `cmagic-0.0.3.vsix` vérifié avec Langium 4.3.1, famille LSP 10 et zéro diagnostic sur le
  modèle valide `service-catalogue-iws.cmagic` ; le bundle serveur installé est identique à
  celui du VSIX ;
- smoke test LSP sur le serveur compilé : modèle valide sans diagnostic, modèle invalide
  avec erreurs de syntaxe et métier, complétion, définition et survol fonctionnels ;
- deux régénérations des vingt et un artefacts catalogue/IWS : hashes identiques entre les
  exécutions et au point fixe `f35429f` ;
- `npm run check` à la racine : lint réussi, 38 fichiers et 85 tests réussis, build réussi ;
- revue Standards : aucune violation dure ; deux duplications mineures restent hors de cette
  tranche ciblée (helper de test préexistant et scripts npm explicites) ;
- revue Spec : plan et preuve LSP complétés pendant la revue finale ; la vérification
  graphique de la fenêtre VS Code reste à confirmer après `Developer: Reload Window`.

## Tranche 12 — Première verticale du DataProvider IBM i

### Contrat retenu

- FakeRest reste le provider par défaut de l'administration et de ses projections ;
- la ressource technique `services` correspond exactement à l'entité CMagic `Service`
  adossée à `DB2SAMPLE.DEPARTMENT` et exposée par IWS sous `SERVIWS3` ;
- seule cette ressource est routée vers IBM i ; `clients` n'est pas artificiellement
  associé à un domaine différent ;
- la tranche expose uniquement `getList` et `getOne`, sans écran CRM ni mutation ;
- l'URL publique provient de `VITE_IBM_I_API_URL`, sans secret dans le bundle.

### Réalisé

- adapter IWS convertissant la pagination, le tri, la recherche et les filtres React Admin ;
- adaptation des enveloppes `{ items, totalCount, errors }` et `{ item, errors }` ;
- validation de la présence et de la cohérence de l'identifiant naturel ;
- conversion déterministe des statuts `400`, `401`, `403`, `404`, `409` et `500`, y
  compris lorsque le corps IWS est vide ;
- conservation des erreurs IWS, des erreurs de champ et de l'identifiant de corrélation ;
- transfert de l'`AbortSignal` par l'adapter ;
- provider composite configuré avec `services` comme unique ressource migrée ;
- contrat d'opérations limitant explicitement `services` à `getList` et `getOne` ;
- annonce de l'annulation au seam composite puis transfert du signal jusqu'au `fetch` IWS ;
- test d'une ressource non migrée contre le vrai provider FakeRest ;
- documentation de l'URL IWS et du principe de proxy intranet à partir de l'exemple
  ILEastic fonctionnel.

### Validation

- tests ciblés des providers et du registre : 4 fichiers, 37 tests réussis ;
- `npm run check` : lint réussi, 39 fichiers et 103 tests réussis, build réussi ;
- revue Standards depuis `82b0b9baf9aedf7d51107be580bd6fcc28b892a2` : les deux
  jugements initiaux sur l'interface partielle et la duplication des filtres ont été
  corrigés ; aucun constat actionnable restant ;
- revue Spec depuis le même point fixe : les deux constats initiaux sur les opérations de
  lecture et l'annulation au seam composite ont été corrigés ; aucun constat actionnable
  restant.

## Suite

Les douze tranches sont terminées. La prochaine verticale IBM i devra être choisie
uniquement lorsqu'un endpoint correspondra à une ressource CRM existante. L'enrichissement
du modèle des commandes demeure une évolution séparée.
