# Recette IBM i — fournisseurs IWS

Cette procédure permet à l'opérateur IBM i de créer la nouvelle table `FOURNIS`, compiler
les objets générés, publier le service REST `FOURIWS1` et valider LIST, GET, CREATE et
UPDATE. Elle ne prévoit aucune route DELETE.

Les sources à utiliser sont celles du dépôt, sans correction manuelle :

```text
projets_annexes/cmagic_perso/examples/generated-fournisseurs-iws/
```

La recette générique du runtime et du serveur IWS reste décrite dans
[`recette-ibmi-catalogue-iws.md`](./recette-ibmi-catalogue-iws.md). Le présent document ne
remplace que les noms, le DDL, les procédures et les scénarios propres à `fournisseurs`.

## 1. Valeurs à fixer avant de commencer

Noter ces valeurs dans le compte rendu de recette :

| Paramètre | Valeur attendue |
| --- | --- |
| Bibliothèque de recette | à choisir ; `CMAGICTST` convient si elle est toujours dédiée aux tests |
| Dossier IFS du projet | par exemple `src/cmagic-generated-fournisseurs-iws` |
| Objet de lecture | `FOURNIS` (`*MODULE`, `*SRVPGM`, `*BNDDIR`) |
| Objet de transport | `FOURIWS` (`*MODULE`, `*SRVPGM`, `*BNDDIR`) |
| Nom public IWS | `FOURIWS1` |
| URL publique | `/web/services/FOURIWS1` |
| Identifiant de recette | `T14REC001`, dix caractères maximum |

Arrêter la recette si la bibliothèque n'est pas explicitement confirmée ou si elle
contient déjà une table `FOURNIS` à conserver. Ne jamais lancer `CLRLIB` pour cette recette.

## 2. Transférer les sources générées

Transférer tout le dossier `generated-fournisseurs-iws`, en conservant les sous-dossiers
`fournisseurs` et `includes`, vers le projet BOB/TOBi sur l'IFS. Vérifier le transfert :

```bash
cd /chemin/du/projet/applicationTemplate
find src/cmagic-generated-fournisseurs-iws -maxdepth 2 -type f | sort
```

Le résultat doit contenir 21 fichiers. Dans `iproj.json`, ajouter sans supprimer les
chemins existants :

```json
{
  "includePath": [
    "includes",
    "src/cmagic-generated-fournisseurs-iws",
    "src/cmagic-generated-fournisseurs-iws/fournisseurs",
    "/usr/local/include"
  ]
}
```

Conserver les bibliothèques qui fournissent `CIWS`, `CKOOL`, `NOXDB` et CMagic. Vérifier
que `CURLIB` désigne bien la bibliothèque de recette choisie. Le runtime CMagic doit être
au moins en version `CMAGIC.0.0.2` : `cmagic_computeSqlClauses` y protège les colonnes SQL
nullables avec `IFNULL` pendant LIST.

## 3. Créer la table neuve `FOURNIS`

Le DDL de référence est
[`fournisseurs.ddl.sql`](../../../projets_annexes/cmagic_perso/examples/generated-fournisseurs-iws/fournisseurs/fournisseurs.ddl.sql).
Il crée les colonnes suivantes :

| Colonne | Type | Contrainte |
| --- | --- | --- |
| `ID` | `VARCHAR(10)` | clé primaire, non nul |
| `NOM` | `VARCHAR(100)` | non nul |
| `ADRESSE` | `VARCHAR(160)` | facultatif |
| `VILLE` | `VARCHAR(80)` | facultatif |
| `TELEPHONE` | `VARCHAR(20)` | facultatif |
| `EMAIL` | `VARCHAR(254)` | facultatif |

Dans ACS Run SQL Scripts, sélectionner la bibliothèque de recette comme schéma courant,
puis exécuter le DDL généré sans le modifier. Vérifier ensuite, en remplaçant
`<BIBLIOTHEQUE_RECETTE>` :

```sql
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM QSYS2.SYSTABLES
WHERE TABLE_SCHEMA = '<BIBLIOTHEQUE_RECETTE>'
  AND TABLE_NAME = 'FOURNIS';

SELECT COLUMN_NAME, DATA_TYPE, LENGTH, IS_NULLABLE
FROM QSYS2.SYSCOLUMNS
WHERE TABLE_SCHEMA = '<BIBLIOTHEQUE_RECETTE>'
  AND TABLE_NAME = 'FOURNIS'
ORDER BY ORDINAL_POSITION;
```

Attendu : une table, six colonnes et une clé primaire sur `ID`.

## 4. Compiler les objets générés

Depuis la racine du projet BOB/TOBi :

```bash
mkdir -p validation-fournisseurs-iws
makei build -v -l src/cmagic-generated-fournisseurs-iws/fournisseurs \
  > validation-fournisseurs-iws/build.log 2>&1
cmagic_fournisseurs_build_rc=$?
tail -n 120 validation-fournisseurs-iws/build.log
echo "BOB return code: $cmagic_fournisseurs_build_rc"
```

Le code retour attendu est `0`. Pour isoler une erreur, construire dans cet ordre :

```bash
makei build -v -t FOURNIS.MODULE
makei build -v -t FOURNIS.SRVPGM
makei build -v -t FOURNIS.BNDDIR
makei build -v -t FOURIWS.MODULE
makei build -v -t FOURIWS.SRVPGM
makei build -v -t FOURIWS.BNDDIR
```

Contrôler les six objets, en remplaçant la bibliothèque :

```cl
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURNIS) OBJTYPE(*MODULE)
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURNIS) OBJTYPE(*SRVPGM)
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURNIS) OBJTYPE(*BNDDIR)
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURIWS) OBJTYPE(*MODULE)
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURIWS) OBJTYPE(*SRVPGM)
DSPOBJD OBJ(<BIBLIOTHEQUE_RECETTE>/FOURIWS) OBJTYPE(*BNDDIR)

DSPBNDDIRE BNDDIR(<BIBLIOTHEQUE_RECETTE>/FOURNIS)
DSPBNDDIRE BNDDIR(<BIBLIOTHEQUE_RECETTE>/FOURIWS)
DSPSRVPGM SRVPGM(<BIBLIOTHEQUE_RECETTE>/FOURNIS) DETAIL(*PROCEXP)
DSPSRVPGM SRVPGM(<BIBLIOTHEQUE_RECETTE>/FOURIWS) DETAIL(*PROCEXP)
```

Exports attendus :

- `FOURNIS` : `fournis_search`, `fournis_getSupportedFields`, `fournis_get`,
  `fournis_create`, `fournis_isValid`, `fournis_update` ;
- `FOURIWS` : `fournis_getlist_iws`, `fournis_getone_iws`, `fournis_create_iws`,
  `fournis_update_iws`.

Il ne doit exister aucun export `delete`.

### 4.1 Compléter et exécuter RPGUnit

Les fichiers `fournis.test.sqlrpgle` et `fouriws.test.sqlrpgle` sont des enveloppes
générées : leurs zones manuelles doivent être complétées sur le projet IBM i avant le GO.
`testing.json` référence déjà `FOURNIS` et `FOURIWS`.

Couvrir au minimum :

- LIST sans paramètre avec application du tri par défaut `id ASC`, pagination et tri
  explicite `nom` ;
- rejet par le sanitizer CMagic d'un champ de tri ou de filtre inconnu ;
- recherche `q` et filtre `ville` ;
- LIST et GET d'une ligne dont les quatre champs facultatifs valent SQL NULL, restitués
  comme chaînes vides ;
- CREATE nominal, clé dupliquée et champs requis absents ;
- UPDATE nominal, clé absente et incohérence entre clé de chemin et corps ;
- absence de procédure DELETE.

Exécuter les deux suites avec l'intégration RPGUnit déjà utilisée par le projet et
conserver la capture ou le journal du nombre de cas/assertions. Un simple succès de
compilation des enveloppes sans cas manuel ne valide pas cette porte.

## 5. Publier `FOURIWS1` dans IBM Web Administration for i

Dans `Manage > Application Servers`, sélectionner le serveur IWS de recette puis installer
un nouveau service REST :

- bibliothèque : bibliothèque de recette choisie ;
- objet : `FOURIWS` ;
- type : `*SRVPGM` ;
- nom du service : `FOURIWS1` ;
- aucun chemin supplémentaire au niveau du service ;
- procédures sélectionnées : les quatre exports `fournis_*_iws` uniquement.

Activer la détection des champs de longueur. Configurer les paramètres communs
`errors_LENGTH`, `errors`, `httpStatus` et `httpHeaders` comme sorties ; associer
`httpStatus` au statut HTTP et `httpHeaders` aux en-têtes HTTP. Les champs `*_LENGTH`,
`httpStatus` et `httpHeaders` ne doivent pas apparaître dans le JSON public.

Configurer les méthodes ainsi :

| Procédure | HTTP et chemin | Entrées | Sorties enveloppées |
| --- | --- | --- | --- |
| `fournis_getlist_iws` | `GET`, chemin vide | aucune ; sélectionner `QUERY_STRING` dans les informations de transport | `items`, `totalCount`, `errors` |
| `fournis_getone_iws` | `GET /{id}` | `id` depuis le chemin | `item`, `errors` |
| `fournis_create_iws` | `POST`, chemin vide | `input` comme corps JSON non enveloppé | `item`, `errors` |
| `fournis_update_iws` | `PUT /{id}` | `id` depuis le chemin et `input` comme corps JSON non enveloppé | `item`, `errors` |

La liste de bibliothèques du service doit contenir la bibliothèque de recette et les
bibliothèques runtime déjà validées pour `CIWS`, `CKOOL` et `NOXDB`. Vérifier les droits du
profil d'exécution sur la table, les deux service programs et leurs dépendances.

Après activation, l'URL suivante ne doit plus répondre `404` :

```text
http://<hote>:<port>/web/services/FOURIWS1
```

## 6. Exécuter la recette HTTP

Depuis PowerShell, définir l'URL réelle sans enregistrer de secret dans le dépôt :

```powershell
$baseUrl = "http://<hote>:<port>/web/services/FOURIWS1"
$testId = "T14REC001"
```

### 6.1 LIST vide ou existante

```powershell
$list = Invoke-RestMethod "$baseUrl?page=1&perPage=5&sort=nom&order=ASC"
$list | ConvertTo-Json -Depth 6
```

Attendu : statut `200`, tableau `items`, entier `totalCount`, tableau `errors` vide et au
maximum cinq lignes. Chaque ligne possède les six champs publics.

### 6.2 CREATE puis GET

```powershell
$createBody = @{
  id = $testId
  nom = "Fournisseur recette tranche 14"
  adresse = "1 rue du Test"
  ville = "Lille"
  telephone = "0300000000"
  email = "recette14@example.test"
} | ConvertTo-Json

$createResponse = Invoke-WebRequest $baseUrl -Method Post -ContentType "application/json" -Body $createBody
$createResponse.StatusCode
$created = $createResponse.Content | ConvertFrom-Json
$created | ConvertTo-Json -Depth 6

$detail = Invoke-RestMethod "$baseUrl/$testId"
$detail | ConvertTo-Json -Depth 6
```

Attendu : CREATE répond `201`, GET répond `200`, `item.id` vaut `T14REC001` et les six
champs relus correspondent aux valeurs persistées.

### 6.3 Pagination, recherche, filtre et tri

```powershell
Invoke-RestMethod $baseUrl
Invoke-RestMethod "$baseUrl?page=1&perPage=5&sort=nom&order=DESC&q=recette"
Invoke-RestMethod "$baseUrl?page=1&perPage=5&sort=nom&order=ASC&ville=Lille"
```

Vérifier que l'appel sans paramètre réussit avec le tri par défaut `id ASC`, puis contrôler
le filtrage, l'ordre explicite par `nom` et la cohérence de `totalCount`. La préparation
de la requête reste déléguée aux procédures génériques `cmagic_sanitizeContext` et
`cmagic_computeSqlClauses`, comme pour `service_search`.

Créer ensuite une ligne dont les champs facultatifs sont vides afin de valider la lecture
des SQL NULL :

```powershell
$emptyId = "T14VIDE01"
$emptyBody = @{
  id = $emptyId
  nom = "Fournisseur sans coordonnées"
  adresse = ""
  ville = ""
  telephone = ""
  email = ""
} | ConvertTo-Json

$emptyResponse = Invoke-WebRequest $baseUrl -Method Post -ContentType "application/json" -Body $emptyBody
$emptyResponse.StatusCode
Invoke-RestMethod "$baseUrl/$emptyId" | ConvertTo-Json -Depth 6
```

Attendu : `201`, puis GET `200`; les quatre valeurs facultatives sont restituées comme
chaînes vides et LIST continue de répondre sans erreur SQL de valeur nulle.

### 6.4 UPDATE puis relecture

```powershell
$updateBody = @{
  id = $testId
  nom = "Fournisseur recette tranche 14 modifié"
  adresse = "2 rue du Test"
  ville = "Lille"
  telephone = "0300000001"
  email = "recette14@example.test"
} | ConvertTo-Json

$updateResponse = Invoke-WebRequest "$baseUrl/$testId" -Method Put -ContentType "application/json" -Body $updateBody
$updateResponse.StatusCode
$updated = $updateResponse.Content | ConvertFrom-Json
$updated | ConvertTo-Json -Depth 6
Invoke-RestMethod "$baseUrl/$testId" | ConvertTo-Json -Depth 6
```

Attendu : UPDATE répond `200`, conserve le même `id` et la relecture retourne les valeurs
modifiées.

### 6.5 Erreurs contractuelles

Utiliser `Invoke-WebRequest -SkipHttpErrorCheck` pour conserver le corps d'erreur :

```powershell
$duplicate = Invoke-WebRequest $baseUrl -Method Post -ContentType "application/json" -Body $createBody -SkipHttpErrorCheck
$duplicate.StatusCode
$duplicate.Content

$missing = Invoke-WebRequest "$baseUrl/T14ABSENT" -SkipHttpErrorCheck
$missing.StatusCode
$missing.Content

$badSort = Invoke-WebRequest "$baseUrl?sort=inconnu&order=ASC" -SkipHttpErrorCheck
$badSort.StatusCode
$badSort.Content
```

Attendu : doublon `409`, identifiant absent `404`, tri invalide `400`. Vérifier dans chaque
corps le tableau `errors` et, lorsqu'ils sont fournis, `code`, `nomZone` et `textUser`.

Ne pas créer de route DELETE pour faciliter le nettoyage.

## 7. Nettoyer la donnée de recette

Après les tests HTTP et UI, supprimer uniquement la clé isolée depuis ACS Run SQL Scripts :

```sql
DELETE FROM <BIBLIOTHEQUE_RECETTE>.FOURNIS
WHERE ID IN ('T14REC001', 'T14VIDE01');

SELECT COUNT(*) AS RESTANT
FROM <BIBLIOTHEQUE_RECETTE>.FOURNIS
WHERE ID IN ('T14REC001', 'T14VIDE01');
```

Attendu : `RESTANT = 0`. Ne pas supprimer la table tant que la recette applicative n'est
pas terminée.

## 8. Vérifier l'application via Vite

Dans `.env.local`, conserver la cible IBM i déjà utilisée par le proxy. `.env.example`
fournit l'URL cliente relative :

```text
VITE_IBM_I_FOURNISSEURS_API_URL=/web/services/FOURIWS1
```

Lancer `npm run dev`, puis vérifier :

- Lecteur : LIST uniquement, sans création, modification ni ligne cliquable ;
- Agent et Responsable : LIST, CREATE, ouverture d'une ligne vers EDIT et UPDATE ;
- recherche `q`, filtre `ville`, pagination et tri `nom` ;
- les six champs ;
- identifiant désactivé dans EDIT ;
- aucun bouton DELETE et aucune sélection groupée ;
- `services` toujours en lecture seule ;
- les autres ressources et les projections toujours sur FakeRest.

Ne déployer le commit applicatif qui ajoute `fournisseurs` au routage IWS qu'après la
réussite des sections 5 et 6. Le service `FOURIWS1` et cette bascule frontend forment une
mise en production atomique ; si le service répond encore `404`, conserver la version
applicative précédente.

## 9. Critères GO / NO GO

La recette est **GO** si les quatre méthodes répondent avec les statuts et enveloppes
attendus, si l'identifiant reste stable, si la recherche et la pagination sont cohérentes,
si les erreurs sont exploitables et si l'interface respecte les droits sans exposer de
suppression.

Elle est **NO GO** si le service répond `404`, si une procédure DELETE est publiée, si une
écriture est perdue après relecture, si la clé chemin/corps diverge, si les paramètres de
liste sont ignorés ou si une autre ressource quitte FakeRest.

Conserver avec le compte rendu : date, bibliothèque, version/port IWS, code retour BOB,
liste des objets, Swagger ou définition de service exportée, réponses HTTP expurgées et
résultat du nettoyage SQL. Ne jamais archiver d'hôte privé, de profil, de jeton ou de mot
de passe dans Git.

## Problème signalé pendant la recette

Le premier déploiement de `fournis_search` ajoutait deux boucles de prévalidation des tris
et filtres avant la copie du contexte. Contrairement à `service_search`, un appel LIST sans
paramètre échouait alors au lieu d'appliquer simplement le tri par défaut `id ASC`.

Les contrôles en cause étaient les boucles parcourant `pContext.sort` et
`pContext.filter`, avec un rejet spécifique des champs absents des listes du catalogue.
Le comportement de `service_search`, sans cette prévalidation spécifique, a été retenu
comme référence fonctionnelle.

### Résolution et validation du 11 août 2026

Le diagnostic a confirmé que ces deux boucles constituaient une prévalidation spécifique
à `fournis_search`, absente du chemin `service_search` déjà validé. Elles ont été retirées
du générateur CMagic, ainsi que le second tri forcé `ID ASC`. Le comportement conservé est :

- copie du contexte reçu ;
- ajout du tri par défaut `id ASC` uniquement lorsqu'aucun tri n'est fourni ;
- validation et construction SQL par les procédures génériques CMagic.

Après régénération, compilation et redéploiement sur IBM i, le propriétaire du projet
confirme que l'appel LIST sans paramètre fonctionne correctement. La correction et ce
scénario de recette sont validés. La tranche fournisseurs est **GO**.
