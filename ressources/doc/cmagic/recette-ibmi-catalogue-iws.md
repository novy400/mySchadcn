# Recette IBM i du catalogue CMagic avec IWS

Cette procédure permet de compiler, déployer et tester sur IBM i le catalogue
`Service` généré par CMagic pour **IBM Integrated Web Services (IWS)**.

Elle a été préparée pour la séance du **30 juillet 2026**, puis mise à jour le
**5 août 2026** après la validation fonctionnelle du service IWS. La correction
du wrapper IWS validée sur IBM i est incluse dans `6d7a41e`. Le générateur courant
(`3508c42`) ajoute aussi les enveloppes et la configuration RPGUnit/BOB, validées
localement.

La recette doit être exécutée dans une bibliothèque et sur un serveur IWS de test.
Elle ne remplace pas la
[recette ILEastic](./recette-ibmi-catalogue.md) : les deux transports doivent être
évalués séparément avant de décider des suites.

## 1. Objectif et limites de cette première recette

La recette doit établir que :

1. les sources IWS générées se compilent sans modification manuelle ;
2. `SERVICE.SRVPGM`, `SERVICE.BNDDIR` et `SERVIWS.SRVPGM` sont créés ;
3. `SERVIWS` exporte uniquement `service_getlist_iws` ;
4. le serveur IWS transmet `QUERY_STRING` au wrapper RPG ;
5. les recherches, filtres, tris et paginations utilisent le même
   `service_search` que le transport ILEastic ;
6. `httpStatus` pilote réellement le statut HTTP ;
7. `httpHeaders` produit notamment `X-Total-Count` ;
8. les erreurs de requête ne provoquent pas d'arrêt du service IWS.

Cette version est volontairement limitée à `LIST`/`SEARCH` :

- `GET /services/{id}` n'est pas encore publié par le wrapper IWS ;
- aucune mutation n'est générée ;
- la réponse IWS nominale est `{ items, totalCount, errors }`, et non l'enveloppe
  ILEastic `{ data, total }` ;
- `Access-Control-Expose-Headers` est produit, mais cela ne configure pas à lui seul
  une politique CORS complète.

Utiliser `curl` ou Bruno pour cette recette, pas directement le navigateur de
`mySchadcn`.

## 2. Valeurs à noter avant de commencer

| Paramètre | Exemple | Valeur du test |
| --- | --- | --- |
| Hôte IBM i | `cmspw7t` | `cmspw7t` |
| Utilisateur de déploiement | `GIYVOVIE` | |
| Racine du projet BOB/TOBi | `/home/user/projects/applicationTemplate` | |
| Bibliothèque de test | `CMAGICTST` | |
| Bibliothèque contenant `CIWS` | `CKOOLBIN` ou autre | |
| Nom du serveur IWS | `CMAGICIWS` | |
| Version IWS | `2.6` ou `3.0` | |
| Port HTTP du serveur IWS | `10074` | `10074` |
| Profil d'exécution du service | `QWSERVICE` ou profil dédié | |
| Nom public du service | `SERVICES` | `SERVIWS2` |
| Racine de contexte | `/web/services` | `/web/services` |
| Commit testé | `3508c42` | `6d7a41e` sur IBM i ; `3508c42` localement |
| Version IBM i | `7.4`, `7.5` ou `7.6` | |
| Version BOB/TOBi | sortie de `makei --version` | |

URL attendue si les exemples du tableau sont conservés :

```text
http://cmspw7t:10074/web/services/SERVIWS2
```

Ne pas réutiliser sans vérification un service IWS de production. Si `SERVICES`
existe déjà sur le serveur choisi, utiliser un autre nom, par exemple
`SERVTST`.

## 3. Porte 1 — Figer les artefacts locaux

Depuis PowerShell :

```powershell
cd C:\Users\giyvovie\Documents\mesProjets\mySchadcn\projets_annexes\cmagic_perso
npm.cmd test
npm.cmd run build
node bin/cli.js generate-catalog examples/service-catalogue-iws.cmagic `
  --destination examples/generated-catalog-iws
git -c safe.directory=C:/Users/giyvovie/Documents/mesProjets/mySchadcn `
  diff --exit-code -- examples/service-catalogue-iws.cmagic `
  examples/generated-catalog-iws
```

Résultat attendu :

- `118` tests CMagic réussis ;
- build réussi ;
- aucune différence après régénération ;
- présence des fichiers suivants :

```text
generated-catalog-iws/
├── Rules.mk
├── includes/
│   ├── services.read.rpgleinc
│   └── services.iws.rpgleinc
└── services/
    ├── Rules.mk
    ├── service.test.sqlrpgle
    ├── services.bnd
    ├── services.iws.bnd
    ├── services.iws.bnddir
    ├── services.read.rpgleinc
    ├── services.read.sqlrpgle
    ├── services.iws.rpgleinc
    ├── services.iws.sqlrpgle
    ├── serviws.test.sqlrpgle
    └── testing.json
```

Les fichiers `services.ileastic.*` sont encore générés pour compatibilité, mais
`Rules.mk` ne contient aucune cible `SERVREST` dans cet exemple IWS.

Les fichiers sous `services/` sont les sources de production. Les copies sous
`includes/` sont réservées aux tests : le générateur ne doit pas déplacer ni remplacer
`services/services.read.rpgleinc`. Les enveloppes `service.test.sqlrpgle` et
`serviws.test.sqlrpgle` sont volontairement minimales afin que le développeur complète
les cas propres à son catalogue. `testing.json` déclare les objets `SERVICE` et
`SERVIWS` à RPGUnit.

Arrêter la recette si la régénération produit une différence : les sources testées ne
correspondraient plus au commit annoncé.

## 4. Porte 2 — Installer les sources dans le projet BOB/TOBi

Transférer l'ensemble de :

```text
projets_annexes/cmagic_perso/examples/generated-catalog-iws/
```

vers un dossier dédié du projet IBM i, par exemple :

```text
<applicationTemplate>/src/cmagic-generated-iws/
```

Vérifier sur IBM i :

```bash
cd /home/user/projects/applicationTemplate
find src/cmagic-generated-iws -maxdepth 2 -type f | sort
```

Ajouter le dossier généré à `includePath` dans `iproj.json`, sans supprimer les
entrées existantes :

```json
{
  "includePath": [
    "includes",
    "src/cmagic-generated-iws",
    "src/cmagic-generated-iws/services",
    "/usr/local/include"
  ]
}
```

Conserver les bibliothèques runtime existantes et ajouter la bibliothèque contenant
`CIWS` si elle n'est pas déjà présente. Exemple :

```json
{
  "preUsrlibl": [
    "CKOOLBIN"
  ],
  "postUsrlibl": [
    "DB2SAMPLE",
    "ILEASTIC"
  ]
}
```

Vérifier le `.env` du projet :

```dotenv
CURLIB=CMAGICTST
```

Créer la bibliothèque uniquement si elle n'existe pas :

```cl
CRTLIB LIB(CMAGICTST) TEXT('Tests catalogue CMagic IWS')
```

## 5. Porte 3 — Vérifier les prérequis IBM i

### 5.1 Données de référence

Depuis ACS Run SQL Scripts :

```sql
SELECT COUNT(*) AS TOTAL
FROM DB2SAMPLE.DEPARTMENT;

SELECT DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION
FROM DB2SAMPLE.DEPARTMENT
ORDER BY DEPTNO
FETCH FIRST 10 ROWS ONLY;
```

Noter le nombre total et un identifiant existant, par exemple `A00`.

### 5.2 Runtime et includes

Depuis une session 5250 :

```cl
WRKOBJ OBJ(*ALL/CIWS) OBJTYPE(*SRVPGM)
WRKOBJ OBJ(*ALL/CKOOL) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(*ALL/NOXDB) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(DB2SAMPLE/DEPARTMENT) OBJTYPE(*FILE)
```

Le service program `CIWS` est un prérequis partagé. Les règles générées le référencent
mais ne le reconstruisent pas.

Depuis PASE :

```bash
for cmagic_iws_header in \
  includes/ciws.rpgleinc \
  includes/cmagic.rpgleinc \
  includes/global.rpgleinc \
  includes/httpRest.rpgleinc \
  /usr/local/include/sqlstates.rpginc \
  /usr/local/include/llist/llist_h.rpgle \
  /usr/local/include/ileastic/noxdb.rpgleinc
do
  test -f "$cmagic_iws_header" \
    && echo "OK      $cmagic_iws_header" \
    || echo "MISSING $cmagic_iws_header"
done
```

Adapter les chemins si le projet conserve ses includes ailleurs. Un fichier manquant
bloque la compilation.

### 5.3 Serveur IWS

Ouvrir IBM Web Administration for i :

```text
http://<hote>:2001/HTTPAdmin
```

ou, si l'administration SSL est configurée :

```text
https://<hote>:2010/HTTPAdmin
```

Dans `Manage > Application Servers`, sélectionner le serveur de test et noter :

- son état ;
- son type et sa version IWS ;
- son port HTTP ou HTTPS ;
- son profil d'exécution ;
- sa racine de contexte.

Le serveur doit être démarré avant le déploiement. Ne pas créer un nouveau serveur si
un serveur IWS de test adapté existe déjà.

## 6. Porte 4 — Compiler les cinq objets générés

Depuis la racine du projet BOB/TOBi :

```bash
mkdir -p validation-cmagic-iws-20260730
makei --version
makei list
makei build -v -l src/cmagic-generated-iws/services \
  > validation-cmagic-iws-20260730/build.log 2>&1
cmagic_iws_build_rc=$?
tail -n 120 validation-cmagic-iws-20260730/build.log
echo "BOB return code: $cmagic_iws_build_rc"
```

Le code retour attendu est `0`.

En cas d'échec global, construire les cibles dans cet ordre pour isoler la première
erreur :

```bash
makei build -v -t SERVICE.MODULE
makei build -v -t SERVICE.SRVPGM
makei build -v -t SERVIWS.MODULE
makei build -v -t SERVICE.BNDDIR
makei build -v -t SERVIWS.SRVPGM
```

Ne pas ajouter `SERVICE` ou `SERVIWS` au binding directory partagé `CKOOL`. Le fichier
généré `services.iws.bnddir` crée un binding directory applicatif `SERVICE` qui
référence :

- `SERVICE.SRVPGM` ;
- `CIWS.SRVPGM`.

Le wrapper `SERVIWS` se lie ensuite à ce binding directory applicatif.

### Objets attendus

```cl
DSPOBJD OBJ(CMAGICTST/SERVICE) OBJTYPE(*MODULE)
DSPOBJD OBJ(CMAGICTST/SERVICE) OBJTYPE(*SRVPGM)
DSPOBJD OBJ(CMAGICTST/SERVICE) OBJTYPE(*BNDDIR)
DSPOBJD OBJ(CMAGICTST/SERVIWS) OBJTYPE(*MODULE)
DSPOBJD OBJ(CMAGICTST/SERVIWS) OBJTYPE(*SRVPGM)
```

Contrôler ensuite les entrées et exports :

```cl
DSPBNDDIRE BNDDIR(CMAGICTST/SERVICE)
DSPSRVPGM SRVPGM(CMAGICTST/SERVICE) DETAIL(*PROCEXP)
DSPSRVPGM SRVPGM(CMAGICTST/SERVIWS) DETAIL(*PROCEXP)
```

Attendu :

- `SERVICE.BNDDIR` contient `SERVICE` et `CIWS` ;
- `SERVICE.SRVPGM` exporte `service_search` et
  `service_getSupportedFields` ;
- `SERVIWS.SRVPGM` exporte `service_getlist_iws`.

Si le build échoue, conserver le premier message complet et le log. Ne pas corriger
directement les sources générées : la correction devra être faite dans CMagic puis
régénérée.

## 7. Porte 5 — Déployer `SERVIWS` comme service REST

Les libellés exacts peuvent varier légèrement entre IWS 2.6 et IWS 3.0. Les valeurs
fonctionnelles à obtenir restent les mêmes.

Dans IBM Web Administration for i :

1. ouvrir `Manage > Application Servers` ;
2. sélectionner le serveur IWS de test ;
3. choisir `Install New Service` ou `Deploy New Service` ;
4. sélectionner le type **REST** ;
5. indiquer :
   - bibliothèque : `CMAGICTST` ;
   - objet : `SERVIWS` ;
   - type : `*SRVPGM` ;
6. utiliser le PCML stocké dans l'objet ; aucun fichier PCML IFS séparé ne devrait être
   demandé grâce à `pgminfo(*pcml:*module:*dclcase)` ;
7. nommer la ressource `SERVICES` ;
8. ne pas définir de chemin supplémentaire au niveau de la ressource ;
9. sélectionner uniquement la procédure `service_getlist_iws`.

### 7.1 Usage des paramètres

Configurer tous les paramètres comme sorties :

| Paramètre | Usage | Traitement IWS |
| --- | --- | --- |
| `items_LENGTH` | Output | longueur du tableau `items` |
| `items` | Output | corps JSON |
| `totalCount` | Output | corps JSON |
| `errors_LENGTH` | Output | longueur du tableau `errors` |
| `errors` | Output | corps JSON |
| `httpStatus` | Output | **HTTP response/status code** |
| `httpHeaders` | Output | **HTTP response headers** |

Activer **Detect length fields** ou l'option équivalente. Le but est que
`items_LENGTH` et `errors_LENGTH` pilotent la taille des tableaux sans apparaître dans
le JSON public.

### 7.2 Propriétés REST de la méthode

Pour `service_getlist_iws`, choisir :

| Propriété | Valeur |
| --- | --- |
| Méthode HTTP | `GET` |
| URI path template de la méthode | `*NONE` ou vide |
| Type de contenu entrant | `*ALL` |
| Type de contenu produit | `JSON` |
| Paramètre du statut HTTP | `httpStatus` |
| Paramètre des en-têtes HTTP | `httpHeaders` |
| Paramètres de sortie | enveloppés |

Il n'y a aucun paramètre d'entrée HTTP direct : les critères sont lus dans
`QUERY_STRING` par `CIWS_initRestRequest`.

### 7.3 Profil, bibliothèques et métadonnées

Pour le profil d'exécution :

- utiliser le profil de service prévu pour ce serveur ;
- vérifier qu'il est activé ;
- vérifier ses droits de lecture sur `DB2SAMPLE/DEPARTMENT` ;
- vérifier ses droits d'exécution sur `SERVIWS`, `SERVICE`, `CIWS` et leurs
  dépendances.

Placer au minimum dans la liste de bibliothèques du service :

```text
CMAGICTST
CKOOLBIN
DB2SAMPLE
ILEASTIC
```

Adapter `CKOOLBIN` et `ILEASTIC` aux bibliothèques réellement utilisées par les
runtimes `CIWS`, `CKOOL` et `NOXDB`.

Dans l'écran des informations de transport, sélectionner impérativement :

```text
QUERY_STRING
```

Cette métadonnée sera fournie au RPG sous forme de variable d'environnement. Sans
elle, l'URL répondra éventuellement, mais les filtres, le tri et la pagination seront
ignorés.

Avant de terminer, relire le résumé du wizard et prendre une capture des onglets :

- service ;
- méthode ;
- paramètres ;
- informations de transport ;
- liste de bibliothèques.

Valider le déploiement et attendre que le service apparaisse actif.

## 8. Porte 6 — Sauvegarder le contrat exposé par IWS

Depuis l'action de consultation ou de téléchargement disponible dans l'administration
IWS, enregistrer la description Swagger/OpenAPI générée sous :

```text
validation-cmagic-iws-20260730/openapi-iws.json
```

Ne pas la confondre avec `services.openapi.json` généré par CMagic. Ce dernier décrit
encore le contrat REST fonctionnel commun `{ data, total }`, tandis que la description
à contrôler ici est celle que le serveur IWS déduit réellement du PCML
`service_getlist_iws`.

Vérifier au minimum :

- URL de base : `/web/services/SERVICES` ;
- méthode `GET` ;
- opération `service_getlist_iws` ;
- schéma nominal contenant `items`, `totalCount` et `errors` ;
- absence de `items_LENGTH`, `errors_LENGTH`, `httpStatus` et `httpHeaders` dans le
  corps public.

Si les champs techniques apparaissent dans le corps, ne pas poursuivre comme si le
contrat était conforme : reprendre le mapping des paramètres ou l'option de détection
des longueurs.

## 9. Porte 7 — Exécuter la recette HTTP

### Résultat de la session du 5 août 2026

Un premier appel a atteint `service_getlist_iws`, mais s'est terminé par l'erreur
RPG `RNX0115` sur une variable à longueur variable. Cette capture est conservée comme
preuve de l'incident intermédiaire, et non comme résultat final :

![Échec intermédiaire RNX0115 dans service_getlist_iws](./image-3.png)

Après report des corrections dans les templates et le générateur, le même service
`SERVIWS2` a répondu nominalement. Le résultat final observé dans le navigateur
contient `14` éléments, `"totalCount": 14` et `"errors": []`. La validation finale a
été confirmée ; la capture de succès fournie pendant la session reste à archiver dans
le dossier de preuves du projet.

Le wrapper généré utilise désormais les helpers génériques `CIWS_setErrors` et
`CIWS_addCollectionHeaders`. Cette correction doit rester dans le template : aucune
modification manuelle de `services.iws.sqlrpgle` ne doit être nécessaire après une
régénération.

Depuis PASE ou un poste pouvant joindre le serveur, fixer l'URL réelle :

```bash
cmagic_iws_url="http://cmspw7t:10074/web/services/SERVIWS2"
mkdir -p validation-cmagic-iws-20260730
```

### 9.1 Liste par défaut

```bash
curl -sS \
  -D validation-cmagic-iws-20260730/list.headers \
  -o validation-cmagic-iws-20260730/list.json \
  -w "%{http_code}\n" \
  "$cmagic_iws_url"
```

Attendu :

- statut `200` ;
- `Content-Type` JSON ;
- en-tête `X-Total-Count` ;
- en-tête `Access-Control-Expose-Headers: X-Total-Count` ;
- corps de la forme :

```json
{
  "items": [
    {
      "id": "A00",
      "nom": "SPIFFY COMPUTER SERVICE DIV.",
      "idManageur": "000010",
      "idServiceAdmin": "A00",
      "site": ""
    }
  ],
  "totalCount": 9,
  "errors": []
}
```

Les valeurs exactes et le total dépendent de `DB2SAMPLE.DEPARTMENT`.

### 9.2 Pagination

```bash
curl -sS \
  -D validation-cmagic-iws-20260730/page.headers \
  -o validation-cmagic-iws-20260730/page.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?page=1&perPage=3"
```

Attendu : `200`, au plus trois éléments dans `items`, et un `totalCount` égal au total
non paginé.

### 9.3 Tri

```bash
curl -sS \
  -o validation-cmagic-iws-20260730/sort.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?page=1&perPage=10&sort=nom&order=ASC"
```

Attendu : `200`, éléments triés par `nom`.

### 9.4 Recherche libre

```bash
curl -sS \
  -o validation-cmagic-iws-20260730/search.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?q=PLANNING"
```

Attendu : `200`. Le tableau peut être vide si le jeu de données local ne contient pas
la valeur recherchée, mais la requête ne doit pas être ignorée.

### 9.5 Filtre exact

```bash
curl -sS \
  -o validation-cmagic-iws-20260730/filter-a00.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?id=A00"
```

Attendu : `200` et uniquement des éléments dont `id` vaut `A00`.

### 9.6 Tri non publié

```bash
curl -sS \
  -D validation-cmagic-iws-20260730/sort-invalid.headers \
  -o validation-cmagic-iws-20260730/sort-invalid.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?sort=inconnu&order=ASC"
```

Attendu : `400`. Lorsque `httpStatus` est désigné comme statut HTTP, IWS peut supprimer
le corps pour les statuts `4xx` et `5xx`. Un corps vide est donc acceptable pour cette
première recette ; noter le comportement réellement observé.

### 9.7 Valeur trop longue

```bash
curl -sS \
  -D validation-cmagic-iws-20260730/id-invalid.headers \
  -o validation-cmagic-iws-20260730/id-invalid.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}?id=A000"
```

Attendu : `400`, puis une nouvelle requête nominale doit encore répondre `200`.

### 9.8 Route `GET` par identifiant non publiée

```bash
curl -sS \
  -o validation-cmagic-iws-20260730/get-not-published.json \
  -w "%{http_code}\n" \
  "${cmagic_iws_url}A00"
```

Attendu : route non trouvée ou méthode non mappée par IWS. Ce résultat n'est pas un
échec de la v0 : seul `LIST/SEARCH` est généré pour IWS.

### 9.9 Vérifications rapides avec `jq`

Si `jq` est disponible :

```bash
jq -e '.items | type == "array"' \
  validation-cmagic-iws-20260730/list.json
jq -e '(.totalCount | type) == "number"' \
  validation-cmagic-iws-20260730/list.json
jq -e '.errors | type == "array"' \
  validation-cmagic-iws-20260730/list.json
jq -e '(.items | length) <= 3' \
  validation-cmagic-iws-20260730/page.json
jq -e 'all(.items[]; .id == "A00")' \
  validation-cmagic-iws-20260730/filter-a00.json
```

## 10. Porte 8 — Contrôler le job IWS et conserver les preuves

Après les requêtes :

1. vérifier dans IBM Web Administration que le service est toujours actif ;
2. consulter les journaux du serveur et du service ;
3. relever le job IWS dans `WRKACTJOB` si une requête a échoué ;
4. conserver son joblog avant de redémarrer le serveur ;
5. sauvegarder les preuves dans `validation-cmagic-iws-20260730`.

Conserver au minimum :

- `build.log` ;
- la description Swagger/OpenAPI IWS ;
- les captures du wizard et du service actif ;
- les en-têtes et corps des huit requêtes ;
- les versions IBM i, IWS et BOB/TOBi ;
- la liste et les dates des cinq objets générés ;
- la sortie de `DSPBNDDIRE` et des deux `DSPSRVPGM` ;
- le joblog en cas d'erreur ;
- les modifications locales d'`iproj.json` ou `.env`.

À la fin de la séance, arrêter ou désactiver le service de test depuis l'administration
IWS si l'environnement l'exige. Ne pas supprimer les objets ni la bibliothèque avant
l'analyse des résultats.

## 11. Diagnostic rapide

| Symptôme | Vérification prioritaire |
| --- | --- |
| `service_getlist_iws` absent du wizard | binder `services.iws.bnd`, export `SERVIWS`, PCML et `DSPSRVPGM` |
| Le wizard demande un PCML IFS | compilation de `SERVIWS.MODULE` avec `pgminfo(*pcml:*module:*dclcase)` |
| `CIWS` introuvable au build | objet `CIWS.SRVPGM`, liste de bibliothèques BOB et `SERVICE.BNDDIR` |
| Symbole `service_search` non résolu | ordre de build, `SERVICE.SRVPGM` et contenu de `SERVICE.BNDDIR` |
| HTTP `500` dès le premier appel | joblog IWS, droits du profil, liste de bibliothèques et table `DEPARTMENT` |
| Pagination et filtres ignorés | `QUERY_STRING` non sélectionné ; corriger puis redéployer |
| `items_LENGTH` apparaît dans le JSON | activer la détection des champs de longueur |
| Le JSON contient 100 lignes vides | mapping `items_LENGTH/items` incorrect |
| `httpStatus` apparaît dans le JSON ou les erreurs répondent `200` | désigner `httpStatus` comme code de réponse |
| `httpHeaders` apparaît dans le JSON | désigner `httpHeaders` comme tableau d'en-têtes |
| `X-Total-Count` absent | mapping des en-têtes, sortie RPG et capture des en-têtes avec `curl -D` |
| Tableau vide alors que Db2 contient des lignes | profil IWS, `DB2SAMPLE` dans la liste et SQLSTATE dans le joblog |
| Appel navigateur bloqué | CORS incomplet ; conserver les tests `curl` pour cette v0 |

## 12. Comparaison à remplir avec la recette ILEastic

| Point | ILEastic | IWS | Décision ou suite |
| --- | --- | --- | --- |
| Build sans modification manuelle | | | |
| Nombre d'objets spécifiques | 5 dans la recette actuelle | 5 générés + `CIWS` partagé | |
| Démarrage | programme `SERVAPI` | serveur IWS administré | |
| URL de liste | `/api/services` | `/web/services/SERVICES/` | |
| Enveloppe nominale | `{ data, total }` | `{ items, totalCount, errors }` | |
| Pagination et tri | | | |
| Recherche et filtres | | | |
| Statuts d'erreur | | | |
| Corps des réponses `4xx` | | potentiellement vide par IWS | |
| `X-Total-Count` | | | |
| CORS | | | |
| `GET` par identifiant | disponible si déclaré | non généré en IWS v0 | |
| Simplicité de déploiement | | | |
| Diagnostic et logs | | | |

## 13. Compte rendu

| Porte | Résultat | Preuve ou première erreur |
| --- | --- | --- |
| 1. Artefacts figés | OK | 118 tests, build et génération déterministe validés localement sur `3508c42` |
| 2. Sources transférées | OK | projet de validation `cMagicIws` |
| 3. Prérequis vérifiés | OK | compilation et exécution IWS abouties |
| 4. Cinq objets compilés | OK | service `SERVIWS2` exécutable |
| 5. Service IWS déployé | OK | URL `/web/services/SERVIWS2` active |
| 6. Contrat IWS sauvegardé | À compléter | archiver la description OpenAPI issue d'IWS |
| 7. Requêtes HTTP exécutées | OK | réponse nominale : 14 éléments, `totalCount: 14`, `errors: []` |
| 8. Preuves conservées | Partiel | erreur intermédiaire archivée ; capture finale et sorties `curl` à ajouter |

Conclusion de la session : **GO fonctionnel avec réserve documentaire**. Le service
IWS répond après régénération avec les helpers CIWS génériques. Il reste à archiver la
capture nominale, les en-têtes HTTP et le contrat OpenAPI afin de rendre la preuve
entièrement reproductible.

Conclusion :

- **GO** si les cinq objets compilent, si le service reste actif et si les recherches
  nominales et invalides respectent les statuts attendus ;
- **GO avec réserve** si l'écart concerne uniquement l'enveloppe JSON, CORS ou le corps
  vide des erreurs, à condition que cet écart soit précisément documenté ;
- **NO GO** si une source générée doit être modifiée à la main, si `QUERY_STRING` n'est
  pas transmis, si les contrôles de recherche sont contournés ou si le service tombe.

## Références IBM

- [Integrated Web Services for IBM i](https://www.ibm.com/docs/en/i/7.4?topic=tasks-integrated-web-services-i)
- [Tutoriel IBM de déploiement REST IWS](https://developer.ibm.com/tutorials/i-rest-web-services-server2/)
- [Principes REST IWS : paramètres, statuts et en-têtes](https://www.ibm.com/support/pages/system/files/inline-files/IWS-Building-REST-Service-Part-1-1.pdf)
- [Support actuel des versions IWS](https://www.ibm.com/support/pages/node/687889)
- [Métadonnée `QUERY_STRING` et mises à jour IWS](https://www.ibm.com/support/pages/system/files/inline-files/IWS-Updates-AUG2015.pdf)


## Compte rendu de la session de tests du 5 août 2026

- npm test,build ok
- node bin/cli.js generate-catalog ok
- git diff ok
- transfert vers projet BOB/TOBi ok
- compilation des cinq objets ok
- test rpgunit service.test.sqlrpgle ok
- test rpgunit serviws.test.sqlrpgle KO
  ![alt text](image-4.png)
  => ajouter SERVIWS dans le bnddir service de testbin
  ![alt text](image-5.png)
  à ajouter dans services.iws.bnddir (??)
  ==> tester à nouveau serviws.test.sqlrpgle ok
- déploiement IWS ok
- test basique ok 
![alt text](image-6.png)
- test complet via services.test.inb (TODO)
  src\services\services.inb
  ok
  