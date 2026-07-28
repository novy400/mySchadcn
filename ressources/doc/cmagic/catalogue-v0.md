# CMagic Catalogue v0

## But de la tranche

Cette première tranche transforme une entité catalogue décrite en CMagic en un contrat
indépendant des générateurs RPG historiques :

```text
source .cmagic -> CatalogSpec validé -> modèles de rendu -> templates Handlebars -> artefacts
```

`CatalogSpec` est la frontière stable. Le générateur adapte ce contrat en modèles de
rendu, puis Handlebars produit les artefacts dans leur langage natif. Les futurs
générateurs DDL, `Rules.mk`, ILEastic et IWS feront de même au lieu de relire directement
l'AST Langium ou d'assembler du code ligne par ligne en TypeScript.

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
- `{resource}.read.sqlrpgle`.

Sans `--destination`, la CLI écrit dans `generated-catalog` à côté du fichier source.

## Syntaxe v0

```cmagic
entity Service resource "services" table "DEPARTMENT" {
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
```

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
- exactement un champ porte le marqueur `key` et ce champ public s'appelle `id` ;
- chaque champ possède un mapping `column` ;
- une capacité de liste exige une vue `list` non vide ;
- la vue `list` expose obligatoirement l'identifiant public `id` ;
- tous les champs de la vue existent dans l'entité ;
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

## Module RPG de lecture généré

Le quatrième artefact implémente directement les capacités de lecture déclarées :

- une procédure publique `{entity}_search` si `LIST` est présent ;
- une procédure publique `{entity}_getSupportedFields` qui décrit la projection à
  CMagic ;
- une procédure publique `{entity}_get` si `GET` est présent ;
- aucune procédure parallèle suffixée `_local` ;
- des structures RPG dérivées des champs de liste et de détail ;
- une requête de liste paginée et une requête de comptage préparées dynamiquement.

Le squelette du module se trouve dans
`src/templates/catalog-read.sqlrpgle.hbs`. Le TypeScript ne porte que l'adaptation
`CatalogSpec` vers un modèle de rendu typé : noms validés, types RPG, champs de
projection et métadonnées `CMAGIC_supportedFields`. Le rendu passe par le même moteur
Handlebars que les générateurs historiques de copybook, service et SQL.

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

## Hors périmètre de la tranche

- publication ILEastic et wrapper IWS ;
- mutations `CREATE`, `UPDATE` et `DELETE` ;
- authentification, autorisations et concurrence optimiste ;
- enrichissement de `CMAGIC_supportedField` avec les droits distincts de recherche,
  filtre et tri ;
- durcissement de `cmagic_computeSqlClauses` pour lier ou échapper les valeurs ;
- compilation et exécution du module généré sur un IBM i réel.

Les prochains artefacts seront ajoutés comme templates autonomes, notamment le DDL et
les fichiers `Rules.mk`, avant la publication ILEastic ou IWS et la vérification du
contrat HTTP de bout en bout depuis le DataProvider de `mySchadcn`.
