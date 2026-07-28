# CMagic Catalogue v0

## But de la tranche

Cette première tranche transforme une entité catalogue décrite en CMagic en un contrat
indépendant des générateurs RPG historiques :

```text
source .cmagic -> CatalogSpec validé -> OpenAPI + ResourceContract TypeScript + module RPG
```

`CatalogSpec` est la frontière stable. Le générateur RPG le consomme déjà ; les futurs
générateurs ILEastic et IWS feront de même au lieu de relire directement l'AST Langium.

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
- tous les champs de la vue existent dans l'entité ;
- l'opérateur `LIKE` est réservé aux chaînes ;
- le tri par défaut est déterministe et utilise l'identifiant en ordre ascendant.

## Contrat HTTP généré

Le contrat est aligné sur le DataProvider IBM i de `mySchadcn` :

- `GET /api/services?page=1&perPage=25&sort=nom&order=ASC&q=paris` renvoie
  `{ "data": [...], "total": n }` ;
- `GET /api/services/{id}` renvoie `{ "data": {...} }` ;
- les filtres et tris autorisés viennent exclusivement du `CatalogSpec` ;
- la recherche `q` porte sur les champs textuels marqués `searchable` ;
- l'identifiant public reste `id`, même si la colonne Db2 s'appelle `DEPTNO`.

## Module RPG de lecture généré

Le quatrième artefact implémente directement les capacités de lecture déclarées :

- une procédure publique `{entity}_list` si `LIST` est présent ;
- une procédure publique `{entity}_get` si `GET` est présent ;
- aucune procédure parallèle suffixée `_local` ;
- des structures RPG dérivées des champs de liste et de détail ;
- une pagination et un total cohérents au moyen de `COUNT(*) OVER()`.

Les noms de table et de colonnes proviennent exclusivement du `CatalogSpec` validé.
Filtres et tris sont compilés sous forme de branches statiques limitées aux champs
autorisés. Les valeurs, l'identifiant, l'offset et la taille de page sont transmis à
Db2 par variables hôtes : le générateur n'émet ni `PREPARE`, ni interpolation de
valeurs dans le SQL.

La recherche libre `q` est acceptée seulement lorsqu'au moins un champ de la liste est
marqué `searchable`. Elle est transportée par le contexte CMagic comme un filtre
réservé, puis appliquée aux seules colonnes de recherche déclarées.

## Hors périmètre de la tranche

- publication ILEastic et wrapper IWS ;
- mutations `CREATE`, `UPDATE` et `DELETE` ;
- authentification, autorisations et concurrence optimiste ;
- exécution de SQL dynamique ;
- compilation et exécution du module généré sur un IBM i réel.

La tranche suivante pourra publier ce module derrière ILEastic ou IWS et vérifier le
contrat HTTP de bout en bout depuis le DataProvider de `mySchadcn`.
