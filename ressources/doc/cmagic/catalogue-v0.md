# CMagic Catalogue v0

## But de la tranche

Cette première tranche transforme une entité catalogue décrite en CMagic en un contrat
indépendant des générateurs RPG historiques :

```text
source .cmagic -> CatalogSpec validé -> modèles de rendu -> templates Handlebars -> artefacts
```

`CatalogSpec` est la frontière stable. Le générateur adapte ce contrat en modèles de
rendu, puis Handlebars produit les artefacts dans leur langage natif. Les générateurs
ILEastic et IWS font de même au lieu de relire directement l'AST Langium ou d'assembler
du code ligne par ligne en TypeScript.

La ressource pilote est `Service`, adossée à la table Db2 existante `DEPARTMENT`.
Elle est volontairement limitée à la lecture (`LIST` et `GET`) pour valider la chaîne
avant d'ajouter les mutations.

## Génération

Depuis `projets_annexes/cmagic_perso` :

```powershell
npm install
npm run build
node bin/cli.js generate-catalog examples/service-catalogue.cmagic `
  --destination examples/generated-catalog
```

La commande écrit, dans un sous-dossier portant le nom de la ressource :

- `{resource}.catalog-spec.json` ;
- `{resource}.openapi.json` ;
- `{resource}.resource-contract.ts` ;
- `{resource}.read.rpgleinc` ;
- `{resource}.read.sqlrpgle` ;
- `{resource}.ileastic.rpgleinc` ;
- `{resource}.ileastic.sqlrpgle` ;
- `{resource}.ddl.sql` ;
- `{resource}.bnd` ;
- `Rules.mk`.

Pour préserver la compatibilité du générateur historique, les sources ILEastic restent
toujours présentes. La propriété `ileasticObject` active leur cible de compilation BOB.
Le choix IWS ajoute quatre artefacts :

- `iwsObject` génère `{resource}.iws.rpgleinc`, `{resource}.iws.sqlrpgle` et
  `{resource}.iws.bnd` ;
- `{resource}.iws.bnddir` décrit le binding directory applicatif du wrapper.

Les propriétés `ileasticObject` et `iwsObject` sont mutuellement exclusives : une seule
cible de transport est ajoutée à `Rules.mk`. Sans propriété de transport, les sources
ILEastic compatibles restent générées, mais aucune cible HTTP n'est créée.

Lorsqu'un bloc `server` est présent, elle ajoute au projet généré :

- `Rules.mk` à la racine, avec les sous-projets BOB ;
- `{server}/{server}.main.sqlrpgle` ;
- `{server}/Rules.mk`.

Sans `--destination`, la CLI écrit dans `generated-catalog` à côté du fichier source.

## Syntaxe v0

```cmagic
entity Service resource "services" table "DEPARTMENT" ileasticObject "SERVREST" {
    id: String(3) column "DEPTNO" key required searchable sortable filter(EQ, LIKE),
    nom: String(36) column "DEPTNAME" required searchable sortable filter(EQ, LIKE),
    idManageur: String(6) column "MGRNO" filter(EQ),
    idServiceAdmin: String(3) column "ADMRDEPT" filter(EQ),
    site: String(16) column "LOCATION" searchable filter(EQ, LIKE)
}

view list for Service {
    id, nom, idManageur, idServiceAdmin, site
}

operations for Service {
    LIST, GET
}

server ServiceApi object "SERVAPI" port 44000 host "*ANY" {
    Service
}
```

Pour publier seulement `service_search` avec IBM Integrated Web Services, le choix
devient :

```cmagic
entity Service resource "services" table "DEPARTMENT" iwsObject "SERVIWS" {
    id: String(3) column "DEPTNO" key required searchable sortable filter(EQ, LIKE),
    nom: String(36) column "DEPTNAME" required searchable sortable filter(EQ, LIKE)
}

view list for Service {
    id, nom
}

operations for Service {
    LIST
}
```

L'exemple complet se trouve dans `examples/service-catalogue-iws.cmagic`. Un bloc
`server` n'est pas nécessaire pour IWS : l'écoute HTTP est fournie par le serveur IWS
IBM i, pas par un programme ILEastic généré.

Les mots-clés historiques restent acceptés. Pour une entité catalogue, les alias sont :

| Catalogue | Historique | Capacité sémantique |
| --- | --- | --- |
| `LIST` | `SEARCH` | liste paginée |
| `GET` | `DISPLAY` | lecture par identifiant |
| `UPDATE` | `CHANGE` | modification |
| `CREATE` | `CREATE` | création |
| `DELETE` | `DELETE` | suppression |

Les alias de mutation sont reconnus par la grammaire pour préserver la compatibilité,
mais Catalogue v0 refuse leur compilation tant que les générateurs de mutation ne sont
pas dans le périmètre.

## Règles de validation

Une entité est considérée comme une entité catalogue dès qu'elle déclare `resource` ou
`table`. Elle doit alors respecter les règles suivantes :

- `resource` et `table` sont tous deux obligatoires ;
- `ileasticObject` est facultatif ; lorsqu'il est présent, il contient un nom système
  IBM i de 1 à 10 caractères, normalisé en majuscules et distinct du module de lecture ;
- `iwsObject` suit les mêmes règles de nommage et désigne le service program publié
  par IBM Integrated Web Services ;
- une entité choisit au plus un transport avec `ileasticObject` ou `iwsObject` ;
- `iwsObject` exige la capacité `LIST` ou son alias `SEARCH` dans cette première
  version ;
- un serveur déclare un nom d'objet programme IBM i valide, un port entier compris
  entre 1 et 65 535 et au moins une entité catalogue ;
- chaque entité publiée par un serveur est unique dans ce serveur et déclare
  `ileasticObject` ;
- l'objet programme du serveur est distinct des modules de lecture et de transport
  qu'il lie ;
- exactement un champ porte le marqueur `key` et ce champ public s'appelle `id` ;
- chaque champ possède un mapping `column` ;
- une capacité de liste exige une vue `list` non vide ;
- la vue `list` expose obligatoirement l'identifiant public `id` ;
- tous les champs de la vue existent dans l'entité ;
- une longueur `String` explicite est un entier compris entre 1 et 32 739 ;
- une précision `Decimal` est un entier compris entre 1 et 63, avec une échelle
  entière comprise entre 0 et la précision ;
- un enum utilisé par une entité catalogue contient au moins une valeur ;
- l'opérateur `LIKE` est réservé aux chaînes ;
- le tri par défaut est déterministe et utilise l'identifiant en ordre ascendant.

## Contrat HTTP généré

Le contrat est aligné sur le DataProvider IBM i de `mySchadcn` :

- `GET /api/services?page=1&perPage=25&sort=nom&order=ASC&q=paris` renvoie
  `{ "data": [...], "total": n }` ;
- `GET /api/services/{id}` renvoie `{ "data": {...} }` ;
- le `CatalogSpec` décrit les filtres, tris et champs de recherche publiés dans le
  contrat HTTP ;
- le runtime RPG v0 applique la liste blanche plus large décrite ci-dessous ;
- l'identifiant public reste `id`, même si la colonne Db2 s'appelle `DEPTNO`.

## Interface RPG de lecture générée

Le quatrième artefact, produit par
`src/templates/catalog-read.rpgleinc.hbs`, est le contrat public partagé entre le module
catalogue et ses futurs adaptateurs de transport. Il contient :

- les structures template `{entity}_item_t` et `{entity}_detail_t` nécessaires aux
  capacités déclarées ;
- les prototypes `{entity}_search` et `{entity}_getSupportedFields` pour `LIST` ;
- le prototype `{entity}_get` pour `GET` ;
- les includes CMagic et Global nécessaires aux types des paramètres.

Le fichier possède un garde d'inclusion et ne déclare aucune procédure de mutation. Les
types et noms de procédures sont issus du même modèle de rendu que le module RPG et son
binder ; le wrapper ILEastic inclut donc ce contrat sans recopier leurs signatures.

Le générateur conserve ce contrat dans le dossier de la ressource avec les includes
historiques `cmagic.rpgleinc` et `global.rpgleinc`. Il produit aussi une copie destinée
aux tests sous `<destination>/includes/{resource}.read.rpgleinc` ; seule cette copie
utilise les chemins `includes/cmagic.rpgleinc` et `includes/global.rpgleinc` attendus
par les tests RPGUnit exécutés depuis la racine du projet IBM i.

## Module RPG de lecture généré

Le cinquième artefact implémente directement les capacités de lecture déclarées :

- une procédure publique `{entity}_search` si `LIST` est présent ;
- une procédure publique `{entity}_getSupportedFields` qui décrit la projection à
  CMagic ;
- une procédure publique `{entity}_get` si `GET` est présent ;
- aucune procédure parallèle suffixée `_local` ;
- des structures RPG dérivées des champs de liste et de détail ;
- une requête de liste paginée et une requête de comptage préparées dynamiquement.

Le squelette du module se trouve dans
`src/templates/catalog-read.sqlrpgle.hbs` et inclut le fichier
`{resource}.read.rpgleinc` généré. Le TypeScript ne porte que l'adaptation `CatalogSpec`
vers un modèle de rendu typé partagé : noms validés, types RPG, champs de projection et
métadonnées `CMAGIC_supportedFields`. Le rendu passe par le même moteur Handlebars que
les générateurs historiques de copybook, service et SQL.

Les noms de table et de colonnes proviennent exclusivement du `CatalogSpec` validé.
La procédure `{entity}_search` suit le contrat utilisé par `service_search` dans
`applicationTemplate` :

1. `{entity}_getSupportedFields` construit la configuration des champs ;
2. le tri par défaut du `CatalogSpec` est injecté, puis
   `cmagic_sanitizeContext` applique les autres valeurs par défaut et la liste blanche ;
3. `cmagic_computeSqlClauses` produit `SELECT`, `WHERE` et `ORDER BY` ;
4. le template ajoute la table, la pagination et prépare les curseurs de liste et de
   comptage.

Le contrat `CMAGIC_supportedField` actuel expose une liste unique utilisée à la fois
pour la projection, la recherche libre, les filtres et les tris. Catalogue v0 génère
donc cette liste à partir des champs de la vue `list`. Les distinctions plus fines du
DSL (`searchable`, `sortable`, opérateurs de filtre) restent présentes dans
`CatalogSpec` et dans le contrat HTTP, mais leur application exacte côté RPG nécessitera
d'enrichir `CMAGIC_supportedField` avec ces capacités.

`cmagic_computeSqlClauses` construit aujourd'hui du SQL dynamique à partir du contexte
nettoyé. Avant un usage en production, le runtime CMagic devra aussi garantir
l'échappement ou la liaison de toutes les valeurs de filtre ; cette responsabilité
n'appartient pas au template d'entité.

## Interface et wrapper ILEastic générés

Les sixième et septième artefacts publient les lectures du catalogue avec ILEastic :

- `{resource}.ileastic.rpgleinc` expose uniquement
  `{entity}_registerRoutes(IL_config)`, point d'entrée destiné au programme serveur ;
- `{resource}.ileastic.sqlrpgle` contient les handlers et l'enregistrement des routes
  `GET /api/{resource}` et `GET /api/{resource}/{id}` selon les capacités déclarées ;
- le handler `LIST` appelle successivement `{entity}_getSupportedFields`,
  `CREST_initRestRequest` puis `{entity}_search` ;
- le handler `GET` utilise `CREST_initSimpleRestRequest`, convertit l'identifiant vers
  son type RPG sans troncature silencieuse, valide les domaines booléen et enum, puis
  appelle `{entity}_get` ;
- `DATA-GEN` et noxDB sérialisent les structures déclarées dans
  `{resource}.read.rpgleinc` sans redéfinir une structure REST parallèle et en
  conservant la casse des noms de champs publics ; les valeurs RPG `Y/N` sont
  normalisées en booléens JSON `true/false` dans les nœuds noxDB ;
- la liste chaînée rendue par `{entity}_search` est libérée par le handler après
  sérialisation.

Le format de succès implémente directement le contrat HTTP généré :

```json
{ "data": [], "total": 0 }
```

pour `LIST`, et :

```json
{ "data": {} }
```

pour `GET`. Le wrapper historique d'`applicationTemplate`, qui renvoie un tableau brut
et place le total dans un en-tête, sert uniquement de référence pour les appels
ILEastic, CREST et CMagic ; son format de réponse n'est pas repris.

Les erreurs de validation sont produites par CREST. Une recherche rejetée renvoie une
erreur client, un identifiant absent renvoie `404`, et une erreur d'accès aux données ou
de sérialisation renvoie `500`. Aucune route de mutation ni route IWS n'est générée.

Lorsque l'entité déclare `ileasticObject`, le module de transport est également ajouté
à `Rules.mk` sous ce nom système explicite. Le générateur ne déduit, n'abrège et ne
tronque jamais ce second nom d'objet IBM i. Sans cette propriété, les sources ILEastic
restent générées pour compatibilité, mais aucune cible BOB de transport n'est créée.

## Interface, wrapper, binder et binding directory IWS générés

Le transport IWS reprend le patron validé dans `projets_annexes/client` :

1. `{entity}_getSupportedFields` fournit la liste blanche CMagic ;
2. `CIWS_initRestRequest` transforme `QUERY_STRING` en `CMAGIC_context` ;
3. `{entity}_search` exécute la recherche métier commune aux deux transports ;
4. le wrapper copie la liste chaînée dans un tableau PCML limité par
   `HTTPREST_MAX_ITEMS`, puis libère la liste ;
5. `CIWS_setErrors` adapte les erreurs métier au tableau PCML ;
6. `CIWS_addCollectionHeaders` produit `X-Total-Count` et
   `Access-Control-Expose-Headers` comme en-têtes IWS.

Le point d'entrée public est `{entity}_getlist_iws`. Sa signature PCML expose :

- `items_LENGTH` et `items` ;
- `totalCount` ;
- `errors_LENGTH` et `errors` ;
- `httpStatus` ;
- `httpHeaders`.

Le module contient `pgminfo(*pcml:*module:*dclcase)`. Après compilation, le déploiement
IWS doit publier le service program désigné par `iwsObject`, sélectionner
`{entity}_getlist_iws`, mapper `httpStatus` au code de réponse et `httpHeaders` aux
en-têtes sortants. Le chemin REST public est choisi lors du déploiement IWS ; il n'est
donc pas codé dans le wrapper RPG.

Le projet IBM i cible doit déjà fournir `ciws.rpgleinc`, `httpRest.rpgleinc` et le
service program `CIWS`, comme `applicationTemplate` et le projet de référence
`projets_annexes/client`. Ces composants constituent le runtime partagé ; ils ne sont
pas recopiés pour chaque catalogue généré.

Le générateur produit également `{resource}.iws.bnddir` et la cible
`{ENTITY}.BNDDIR`. Ce binding directory applicatif référence le service program de
lecture (`SERVICE` dans l'exemple) et `CIWS`, puis le wrapper le déclare dans
`ctl-opt bnddir`. La compilation ne demande donc plus d'ajouter manuellement les
services générés au binding directory partagé `CKOOL`.

Le contrat IWS v0 couvre uniquement `LIST`/`SEARCH`. `GET` par identifiant continue à
être disponible avec ILEastic lorsqu'il est déclaré, mais n'est pas encore généré pour
IWS.

## DDL Db2 généré

Le huitième artefact est produit par
`src/templates/catalog.ddl.sql.hbs`. Il génère un `CREATE TABLE` déterministe à partir
des mappings du `CatalogSpec` :

- nom de table éventuellement qualifié par un schéma et noms de colonnes simples
  validés ;
- `VARCHAR`, `INTEGER`, `DECIMAL`, `DATE`, booléens `CHAR(1)` en `Y/N` et stockage
  textuel des enums ;
- `NOT NULL` pour les champs `required` ;
- clé primaire issue du champ `key` ;
- contraintes `UNIQUE` et `CHECK` pour les booléens et les enums.

Le DDL v0 ne fait pas de `CREATE OR REPLACE`, afin de ne pas rendre l'artefact
destructif par défaut. Il ne tente pas non plus de reproduire les particularités du DDL
historique de `DEPARTMENT` qui ne figurent pas dans le DSL : schéma `DB2SAMPLE`,
colonnes `CHAR`, CCSID, clés étrangères, `RCDFMT` et autorisations. Ces informations
nécessiteront des concepts DSL explicites avant d'être générées.

La représentation `Y/N` est également utilisée dans les structures RPG de lecture et
déclarée comme caractère dans `CMAGIC_supportedFields`, afin que DDL et module RPG
restent cohérents sur IBM i 7.4.

## Binder du service program généré

Le neuvième artefact est produit par `src/templates/catalog.bnd.hbs`. Il crée une
signature courante `{OBJECT}.0.0.1` et n'exporte que les procédures réellement présentes
dans le module RPG :

- `LIST` exporte `{entity}_search` et `{entity}_getSupportedFields` ;
- `GET` exporte `{entity}_get` ;
- aucune procédure de mutation n'est ajoutée à Catalogue v0.

Le binder initial ne contient pas de niveau `PGMLVL(*PRV)`. Les signatures précédentes
devront être conservées lors d'une future évolution incompatible du contrat exporté ;
le générateur ne peut pas inventer un historique pour un service program qui n'a pas
encore été publié.

## Règle BOB générée

Le dixième artefact est produit par `src/templates/catalog.Rules.mk.hbs`. Il relie à BOB
le module de lecture et le binder réellement générés :

```make
SERVICE.MODULE: services.read.sqlrpgle
SERVICE.SRVPGM: services.bnd SERVICE.MODULE
SERVREST.MODULE: services.ileastic.sqlrpgle
```

Le nom d'objet est dérivé du nom de l'entité en majuscules. La génération échoue si ce
nom ne respecte pas le format IBM i d'un nom système de 1 à 10 caractères ; il n'est
jamais tronqué silencieusement.

La cible `SERVREST.MODULE` provient directement de
`ileasticObject "SERVREST"`. Elle est facultative et doit être distincte de
`SERVICE.MODULE`. Cette règle compile le transport et ne génère pas de binder pour ce
module.

Avec `iwsObject "SERVIWS"`, les règles de transport deviennent :

```make
SERVIWS.MODULE: services.iws.sqlrpgle
SERVICE.BNDDIR: services.iws.bnddir SERVICE.SRVPGM CIWS.SRVPGM
SERVIWS.SRVPGM: services.iws.bnd SERVIWS.MODULE SERVICE.BNDDIR
```

Le binder IWS utilise la signature `SERVIWS.0.0.1` et exporte uniquement
`service_getlist_iws`. Les règles ILEastic et IWS ne sont jamais produites ensemble
pour une même entité.

## Programme serveur ILEastic généré

Le bloc `server ServiceApi` produit un sous-projet applicatif séparé. Son source
`serviceapi.main.sqlrpgle`, rendu par
`src/templates/catalog-server.main.sqlrpgle.hbs` :

1. initialise `IL_config` avec le port `44000` et l'hôte `*ANY` ;
2. inclut les interfaces ILEastic publiques des catalogues référencés ;
3. appelle `service_registerRoutes(config)` ;
4. démarre l'écoute avec `il_listen(config)`.

Un même bloc peut référencer plusieurs entités : le modèle et le template ajoutent une
interface, un appel d'enregistrement et les dépendances BOB correspondantes pour
chacune. Le programme ne recopie ni signatures de procédures, ni routes, ni logique
métier.

La règle applicative lie explicitement le module du programme, le module de transport
et le service program de lecture :

```make
SERVAPI.MODULE: serviceapi.main.sqlrpgle
SERVAPI.PGM: SERVAPI.MODULE SERVREST.MODULE SERVICE.SRVPGM
```

Le `Rules.mk` racine, produit par
`src/templates/catalog-project.Rules.mk.hbs`, rend l'arborescence directement
parcourable par BOB :

```make
SUBDIRS = services serviceapi
```

Sans bloc `server`, ces trois artefacts applicatifs ne sont pas créés et la génération
historique des dix artefacts par catalogue reste inchangée.

## Hors périmètre de la tranche

- opération IWS `GET` par identifiant et mutations IWS ;
- configuration CORS, journalisation et arrêt contrôlé du serveur ILEastic ;
- mutations `CREATE`, `UPDATE` et `DELETE` ;
- authentification, autorisations et concurrence optimiste ;
- enrichissement de `CMAGIC_supportedField` avec les droits distincts de recherche,
  filtre et tri ;
- durcissement de `cmagic_computeSqlClauses` pour lier ou échapper les valeurs ;
- compilation et exécution du module généré sur un IBM i réel.

La prochaine verticale pourra valider la compilation des deux transports sur IBM i,
puis vérifier leurs contrats HTTP de bout en bout avant d'étendre IWS à `GET` ou
d'aborder les mutations.
