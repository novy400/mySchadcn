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
Elle couvre désormais la lecture (`LIST` et `GET`) et les mutations verticales `CREATE`,
`UPDATE` et `DELETE` avec IWS.

## Génération

Depuis la racine du dépôt autonome [`cmagic_perso`](https://github.com/novy400/cmagic) :

```powershell
npm install
npm run build
node bin/cli.js generate-catalog examples/service-catalogue.cmagic `
  --destination examples/generated-catalog
```

L'include canonique du runtime est `cmagic/includes/cmagic.rpgleinc`, dans le dépôt
CMagic. Les copies actives de `cMagicIws`, `cMagicTest`, `applicationTemplate`, `client`
et `cmagic_perso/examples` doivent rester alignées sur ce fichier. Toute évolution de
`CMAGIC_supportedField`, comme l'ajout de `maxLength`, doit mettre à jour dans le même
changement l'include partagé et les artefacts qui renseignent cette métadonnée.

La commande écrit, dans un sous-dossier portant le nom de la ressource :

- `{resource}.catalog-spec.json` ;
- `{resource}.openapi.json` ;
- `{resource}.resource-contract.ts` ;
- `{resource}.read.rpgleinc` ;
- `{resource}.read.sqlrpgle` ;
- `{entity}.test.sqlrpgle`, enveloppe RPGUnit de lecture à compléter ;
- `testing.json`, configuration RPGUnit et couverture des modules générés ;
- `{resource}.ileastic.rpgleinc` ;
- `{resource}.ileastic.sqlrpgle` ;
- `{resource}.ddl.sql` ;
- `{resource}.bnd` ;
- `Rules.mk`.

Pour préserver la compatibilité du générateur historique, les sources ILEastic restent
toujours présentes. La propriété `ileasticObject` active leur cible de compilation BOB.
Le choix IWS ajoute sept artefacts :

- `iwsObject` génère `{resource}.iws.rpgleinc`, `{resource}.iws.sqlrpgle` et
  `{resource}.iws.bnd` ;
- `{resource}.read.bnddir` décrit le binding directory utilisé pour construire le
  wrapper ;
- `{resource}.iws.bnddir` décrit le binding directory utilisé par ses tests ;
- `includes/{resource}.iws.rpgleinc` adapte les chemins d'include aux tests ;
- `{iwsObject}.test.sqlrpgle` fournit l'enveloppe RPGUnit du transport IWS.

Les propriétés `ileasticObject` et `iwsObject` sont mutuellement exclusives : une seule
cible de transport est ajoutée à `Rules.mk`. Sans propriété de transport, les sources
ILEastic compatibles restent générées, mais aucune cible HTTP n'est créée.

La génération de projet écrit toujours un `Rules.mk` à la racine de la destination
pour que BOB/TOBi parcoure les dossiers des ressources. Lorsqu'un bloc `server` est
présent, elle ajoute aussi au projet généré :

- `{server}/{server}.main.sqlrpgle` ;
- `{server}/Rules.mk`.

Si le `Rules.mk` racine existe déjà, son contenu et ses sous-projets sont conservés.
CMagic ajoute uniquement les dossiers générés qui manquent avec une affectation
`SUBDIRS += ...`.

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

Pour publier `service_search` et la lecture par identifiant avec IBM Integrated Web
Services, le choix devient :

```cmagic
entity Service resource "services" table "DEPARTMENT" iwsObject "SERVIWS" {
    id: String(3) column "DEPTNO" key required searchable sortable filter(EQ, LIKE),
    nom: String(36) column "DEPTNAME" required searchable sortable filter(EQ, LIKE)
}

view list for Service {
    id, nom
}

operations for Service {
    LIST, GET, CREATE, UPDATE, DELETE
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

`CREATE`, `UPDATE` et `DELETE` sont compilés par le service RPG commun et exposés par
IWS. Une entité qui choisit `ileasticObject` ne peut pas encore déclarer ces mutations,
car le wrapper ILEastic reste en lecture seule. Avec `iwsObject`, `CREATE` exige `GET`
pour relire la donnée persistée avant de produire la réponse `201`. `UPDATE`/`CHANGE`
et `DELETE` exigent toujours `GET` afin de charger l'état précédent et vérifier
l'existence avant toute validation ou écriture.

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
- si `CREATE` est déclaré avec `iwsObject`, la capacité `GET` ou son alias `DISPLAY`
  est également obligatoire ;
- `UPDATE` ou `CHANGE` exige `GET`/`DISPLAY` et au moins un champ non-clé ;
- `DELETE` exige `GET`/`DISPLAY` pour charger l'état précédent et vérifier l'existence ;
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
- `POST /api/services` reçoit l'entité complète, identifiant naturel compris, et renvoie
  la donnée créée en `201` ; les erreurs fonctionnelles, conflits et erreurs techniques
  sont décrits par `400`, `409` et `500` ;
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
- l'enum `{entity}_listeAction`, le prototype `{entity}_isValid` et les prototypes
  `{entity}_create`/`{entity}_update` correspondant aux mutations déclarées ;
- les includes CMagic et Global nécessaires aux types des paramètres.

Le fichier possède un garde d'inclusion. Les types et noms de procédures sont issus du
même modèle de rendu que le module RPG et son binder ; les wrappers incluent donc ce
contrat sans recopier leurs signatures.

Le générateur conserve ce contrat dans le dossier de la ressource avec les includes
historiques `cmagic.rpgleinc` et `global.rpgleinc`. Il produit aussi une copie destinée
aux tests sous `<destination>/includes/{resource}.read.rpgleinc` ; seule cette copie
utilise les chemins `includes/cmagic.rpgleinc` et `includes/global.rpgleinc` attendus
par les tests RPGUnit exécutés depuis la racine du projet IBM i.

## Enveloppes RPGUnit générées

Le générateur crée systématiquement `{entity}.test.sqlrpgle` dans le dossier de la
ressource. Si `iwsObject` est déclaré, il crée aussi `{iwsObject}.test.sqlrpgle`. Ces
fichiers fournissent uniquement l'infrastructure technique : includes, binding
directories, procédures `setUpSuite`, `setUp`, `tearDown` et `tearDownSuite`, ainsi
que les utilitaires de chaîne de requête pour IWS. Ils ne contiennent ni identifiants
métier, ni hypothèse sur le contenu de la table, ni résultat attendu.

Le développeur ajoute les cas propres au projet entre les marqueurs suivants :

```rpgle
// [CMAGIC:MANUAL_START]
// tests RPGUnit spécifiques au projet
// [CMAGIC:MANUAL_END]
```

Le contenu situé entre ces deux marqueurs est conservé lors des générations
suivantes. Le reste de l'enveloppe demeure sous la responsabilité du générateur. Un
fichier de test déjà présent mais dépourvu de ces marqueurs est considéré comme
entièrement manuel et n'est jamais écrasé ; cela permet d'adopter le générateur dans
un projet qui possède déjà ses propres tests RPGUnit.

Le fichier `testing.json` placé dans le même dossier s'applique à toutes les suites
RPGUnit de la ressource. Il reprend les options `RUCRTRPG` validées sur IBM i et calcule
la couverture depuis les objets du catalogue : le module de lecture est toujours
présent et le service program IWS est ajouté lorsque `iwsObject` est déclaré. Aucun nom
comme `CLIENT` n'est figé dans le template.

Lors d'une régénération, les options locales déjà présentes (`incDir`, `rucalltst`,
champs spécifiques au projet, etc.) sont conservées. Les modules de couverture
existants sont également préservés et complétés par les modules issus du catalogue.

Les suites peuvent être compilées et exécutées depuis l'explorateur de tests de
l'extension IBM i Testing. Pour une exécution automatisée, la CLI `itest` utilise la
même configuration. Voir la
[configuration officielle](https://codefori.github.io/docs/developing/testing/configuring/)
et la [CLI IBM i Testing](https://codefori.github.io/docs/developing/testing/cli/).

## Module RPG de catalogue généré

Le module RPG généré implémente directement les capacités déclarées :

- une procédure publique `{entity}_search` si `LIST` est présent ;
- une procédure publique `{entity}_getSupportedFields` qui décrit la projection à
  CMagic ;
- une procédure publique `{entity}_get` si `GET` est présent ;
- une procédure publique `{entity}_isValid` dès qu'une mutation est présente, puis
  `{entity}_create` et/ou `{entity}_update` selon les capacités ;
- aucune procédure parallèle suffixée `_local` ;
- des structures RPG dérivées des champs de liste et de détail ;
- une requête de liste paginée et une requête de comptage préparées dynamiquement.

`{entity}_create` reçoit le détail complet et renvoie l'identifiant naturel. Il construit
les états `before`/`after`, appelle obligatoirement `{entity}_isValid`, puis seulement
après validation exécute l'`INSERT`. Les champs textuels facultatifs vides sont liés via
`NULLIF(..., '')` afin d'écrire `NULL` au lieu d'une chaîne vide. Le `SQLSTATE 23505`
devient une erreur `CAT1002` portant sur `conflict` ; les autres erreurs SQL portent sur
`sql`.

`{entity}_update` reçoit l'identifiant du chemin et le détail complet. Il charge d'abord
l'état `before` par `{entity}_get` : une entité absente est donc rejetée avant toute
écriture. L'état `after` passe ensuite par `{entity}_isValid` avec l'action
`modification`. L'identifiant est immuable (`CAT1005/id`) et l'`UPDATE` Db2 ne contient
que les colonnes non-clés. Les valeurs facultatives vides utilisent le même traitement
`NULLIF` que `CREATE`.

`{entity}_isValid` génère les contrôles basiques déductibles du DSL, notamment les
champs textuels `required` et les domaines booléens/enums, puis appelle
`{entity}_isValid_business`. Cette dernière
procédure se trouve entre les marqueurs `CMAGIC:MANUAL_START/END` : le développeur peut
y ajouter ses règles de gestion, avec déclarations locales si nécessaire. Cette zone
est conservée lors des régénérations, alors que les contrôles basiques qui l'entourent
continuent d'être régénérés.

La procédure contractuelle et exportée reste `{entity}_isValid`. Son hook interne
`{entity}_isValid_business` est défini directement dans le module, sans prototype
`dcl-pr` explicite. Cette forme a été compilée et validée sur IBM i ; l'appel et la zone
protégée restent présents dans chaque source générée.

Le squelette du module se trouve dans
`src/templates/catalog-read.sqlrpgle.hbs` et inclut le fichier
`{resource}.read.rpgleinc` généré. Le TypeScript ne porte que l'adaptation `CatalogSpec`
vers un modèle de rendu typé partagé : noms validés, types RPG, champs de projection et
métadonnées `CMAGIC_supportedFields`. Le rendu passe par le même moteur Handlebars que
les générateurs historiques de copybook, service et SQL.

Les noms historiques `catalog-read.*` et `{resource}.read.*` sont conservés pour ne pas
casser les projets IBM i existants. Malgré ce suffixe, ce module porte désormais le
service catalogue commun de lecture, création, modification et suppression.

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

Lorsque `GET` est déclaré, le même service program exporte également
`{entity}_getone_iws`. Sa signature PCML expose :

- `id` en entrée, avec le type RPG de l'identifiant du catalogue ;
- `item`, structure de détail contenant tous les champs de l'entité ;
- `errors_LENGTH` et `errors` ;
- `httpStatus` ;
- `httpHeaders`.

Le wrapper appelle la procédure de lecture commune `{entity}_get`, copie le détail
dans `item`, renvoie `HTTPREST_NOTFOUND` lorsque l'erreur porte sur `id` et
`HTTPREST_SERVERERROR` pour une erreur technique. Une terminaison RPG inattendue est
convertie en erreur `RNX9001`, comme pour la liste.

Lorsque `CREATE` est déclaré, le service program exporte aussi
`{entity}_create_iws`. Sa signature PCML reçoit `input` et renvoie `item`,
`errors_LENGTH`, `errors`, `httpStatus` et `httpHeaders`. Le wrapper :

1. adapte `input` vers le détail RPG commun ;
2. appelle `{entity}_create`, qui porte toute la validation et l'écriture Db2 ;
3. relit obligatoirement la donnée par `{entity}_get` ;
4. renvoie `201` et l'élément créé, `400` pour une validation fonctionnelle, `409`
   pour un conflit, ou `500` pour une erreur technique et une terminaison inattendue.

Lorsque `UPDATE` est déclaré, le service program exporte aussi
`{entity}_update_iws`. Sa signature PCML reçoit l'identifiant `id`, le corps `input` et
renvoie `item`, `errors_LENGTH`, `errors`, `httpStatus` et `httpHeaders`. Le wrapper :

1. adapte `input` vers le détail RPG commun ;
2. appelle `{entity}_update`, qui charge l'état précédent, valide puis écrit ;
3. relit la donnée persistée par `{entity}_get` ;
4. renvoie `200`, `400` pour une validation, `404` pour une entité absente, `409` pour
   un conflit, ou `500` pour une erreur SQL/RPG.

Lorsque `DELETE` est déclaré, le service program exporte aussi
`{entity}_delete_iws`. Sa signature PCML reçoit uniquement l'identifiant `id` avec les
sorties `errors_LENGTH`, `errors`, `httpStatus` et `httpHeaders`. Le wrapper :

1. appelle `{entity}_delete`, qui charge l'état précédent par `{entity}_get` ;
2. appelle `{entity}_isValid(suppression, before, after, errors)` avant le SQL ;
3. supprime uniquement la ligne portant l'identifiant demandé ;
4. renvoie `204`, `400` pour un refus métier, `404` pour une entité absente, `409` pour
   une contrainte référentielle, ou `500` pour une erreur SQL/RPG.

Le module contient `pgminfo(*pcml:*module:*dclcase)`. Après compilation, le déploiement
IWS doit publier le service program désigné par `iwsObject`, sélectionner séparément
`{entity}_getlist_iws`, `{entity}_getone_iws` et les mutations déclarées
`{entity}_create_iws`/`{entity}_update_iws`/`{entity}_delete_iws`, mapper `httpStatus` au code de réponse et
`httpHeaders` aux en-têtes sortants. Le chemin REST public de chaque procédure est
choisi lors du déploiement IWS ; il n'est donc pas codé dans le wrapper RPG.

Le projet IBM i cible doit déjà fournir `ciws.rpgleinc`, `httpRest.rpgleinc` et le
service program `CIWS`, comme `applicationTemplate` et le projet de référence
`projets_annexes/client`. Ces composants constituent le runtime partagé ; ils ne sont
pas recopiés pour chaque catalogue généré.

Le générateur produit deux binding directories applicatifs. Le fichier
`{resource}.read.bnddir` crée `{ENTITY}.BNDDIR` avec le seul service program de lecture
(`SERVICE` dans l'exemple), afin de construire le wrapper. Après cette construction,
`{resource}.iws.bnddir` crée `{IWSOBJECT}.BNDDIR` avec le service de lecture et le
wrapper (`SERVICE` et `SERVIWS`) pour les tests RPGUnit.

`CIWS` reste fourni par le binding directory partagé `CKOOL`, déjà déclaré dans le
`ctl-opt bnddir` du wrapper. Le graphe généré ne crée donc ni entrée applicative pour
`CIWS`, ni dépendance directe vers `CIWS.SRVPGM`.

Le contrat IWS couvre `LIST`/`SEARCH`, `GET`, `CREATE`, `UPDATE`/`CHANGE` et `DELETE`. Le
compilateur exige `LIST` lorsqu'une entité choisit `iwsObject`, puis `GET` pour toute
modification, suppression et pour une création IWS. Une exposition IWS limitée au seul `GET`, ou une
mutation sans les capacités requises, reste hors du contrat actuel.

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
- `CREATE` ajoute `{entity}_create` puis `{entity}_isValid` après les exports de lecture
  existants ;
- `UPDATE` ajoute `{entity}_update` après les exports déjà publiés. Sans `CREATE`, il
  exporte `{entity}_update` puis `{entity}_isValid`.
- `DELETE` ajoute `{entity}_delete` après les mutations déjà publiées. Lorsqu'il est la
  seule mutation, il exporte `{entity}_delete` puis `{entity}_isValid`.

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
SERVICE.BNDDIR: services.read.bnddir SERVICE.SRVPGM
SERVIWS.SRVPGM: services.iws.bnd SERVIWS.MODULE SERVICE.BNDDIR
SERVIWS.BNDDIR: services.iws.bnddir SERVIWS.SRVPGM
```

`services.read.bnddir` contient `SERVICE`. `services.iws.bnddir` contient `SERVICE` et
`SERVIWS`. Cette séparation garde le graphe acyclique et permet aux tests du transport
de résoudre les deux services programs sans modifier `CKOOL`.

Le binder IWS utilise la signature `SERVIWS.0.0.1`. Il conserve
`service_getlist_iws` comme premier export et ajoute `service_getone_iws` lorsque la
capacité `GET` est déclarée, `service_create_iws` lorsque `CREATE` est déclaré, puis
`service_update_iws` lorsque `UPDATE` est déclaré, puis `service_delete_iws` lorsque
`DELETE` est déclaré. Les ajouts sont placés en fin de
liste afin de préserver les exports existants. Les règles ILEastic et IWS ne sont
jamais produites ensemble pour une même entité.

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

- exposition IWS limitée au seul `GET`, `CREATE`, `UPDATE` ou `DELETE` ;
- configuration CORS, journalisation et arrêt contrôlé du serveur ILEastic ;
- authentification, autorisations et concurrence optimiste ;
- enrichissement de `CMAGIC_supportedField` avec les droits distincts de recherche,
  filtre et tri ;
- durcissement de `cmagic_computeSqlClauses` pour lier ou échapper les valeurs ;
- tests RPGUnit dédiés à `service_isValid`, `service_create` et
  `service_create_iws` ; les suites de lecture existantes et la recette HTTP de création
  sont déjà validées.

Le wrapper IWS couvrant `LIST`, `GET` et `CREATE` a été compilé, redéployé et accepté sur
IBM i le 6 août 2026. La recette a confirmé la création `201`, la relecture `200`, le
doublon `409/CAT1002`, la validation `400/CAT1001` et le nettoyage des données de test.
Les verticales `UPDATE` et `DELETE` sont maintenant implémentées, testées localement et
synchronisées vers `cMagicIws`. `UPDATE` est accepté sur IBM i ; la compilation, le
redéploiement et la recette IBM i de `DELETE` restent à exécuter avant le branchement
progressif du DataProvider.
