# Recette IBM i du catalogue CMagic

Cette procédure prépare la première compilation et la première exécution sur IBM i du
catalogue `Service` généré par CMagic. Elle doit être exécutée sur un environnement de
test, avec les artefacts du commit `1f5cd8d` ou d'un commit ultérieur explicitement
noté dans le compte rendu.

BOB porte désormais le nom TOBi, mais la procédure conserve la commande `makei`
utilisée par `applicationTemplate`. Noter la version réellement installée avant le
build.

## Objectif et périmètre

La recette doit établir séparément que :

1. BOB parcourt l'arborescence générée ;
2. les cinq objets IBM i attendus sont créés ;
3. `SERVAPI` démarre et écoute sur le port choisi ;
4. `LIST` et `GET` respectent le contrat HTTP `{ data, total }` et `{ data }` ;
5. les requêtes invalides sont rejetées sans arrêter le serveur.

Cette première recette est en lecture seule. Ne pas tester de mutation et ne pas
exécuter `services.ddl.sql` : la ressource pilote doit lire la table existante
`DB2SAMPLE.DEPARTMENT`.

Le programme généré ne configure pas encore CORS. Les tests doivent donc être réalisés
avec `curl`, depuis IBM i ou un poste autorisé à joindre le port, et non depuis le
navigateur de `mySchadcn`.

## Valeurs à fixer avant de commencer

Noter les valeurs réellement utilisées :

| Paramètre | Exemple | Valeur du test |
| --- | --- | --- |
| Hôte IBM i | `myibmi.example.net` | |
| Utilisateur | `GIYVOVIE` | |
| Racine IFS d'`applicationTemplate` | `/home/user/projects/applicationTemplate` | |
| Bibliothèque de test | `CMAGICTST` | |
| Port ILEastic | `44000` | |
| Commit testé | `1f5cd8d` | |
| Version IBM i | `7.4` ou `7.5` | |
| Version BOB | sortie de `makei --version` | |

Utiliser une bibliothèque dédiée. Ne pas compiler cette première version dans une
bibliothèque de production.

## Porte 1 — Préparer et figer les artefacts locaux

Depuis PowerShell, dans le dépôt `mySchadcn` :

```powershell
cd C:\Users\giyvovie\Documents\mesProjets\mySchadcn\projets_annexes\cmagic_perso
npm.cmd test
npm.cmd run build
node bin/cli.js generate-catalog examples/service-catalogue.cmagic `
  --destination examples/generated-catalog
git -c safe.directory=C:/Users/giyvovie/Documents/mesProjets/mySchadcn `
  diff --exit-code -- examples/service-catalogue.cmagic examples/generated-catalog
```

Résultat attendu :

- 100 tests CMagic réussis ;
- aucune différence après régénération ;
- présence de :

```text
generated-catalog/
├── Rules.mk
├── services/
│   ├── Rules.mk
│   ├── services.bnd
│   ├── services.read.rpgleinc
│   ├── services.read.sqlrpgle
│   ├── services.ileastic.rpgleinc
│   └── services.ileastic.sqlrpgle
└── serviceapi/
    ├── Rules.mk
    └── serviceapi.main.sqlrpgle
```

Arrêter la recette si la régénération modifie les fichiers suivis : le contenu à
transférer ne correspondrait pas au commit annoncé.

## Porte 2 — Installer le projet généré dans le projet BOB

Transférer le contenu exact de `examples/generated-catalog` vers :

```text
<applicationTemplate>/src/cmagic-generated/
```

Le transfert peut être réalisé avec le déploiement VS Code for IBM i, Git ou `scp`.
Après transfert, vérifier sur IBM i :

```bash
cd /home/user/projects/applicationTemplate
find src/cmagic-generated -maxdepth 2 -type f | sort
```

Le résultat doit contenir les deux sous-dossiers `services` et `serviceapi`, ainsi que
le `Rules.mk` racine. Éviter une arborescence accidentelle
`cmagic-generated/generated-catalog/...`.

### Ajuster les includes BOB

Faire une copie de sauvegarde d'`iproj.json`, puis ajouter le dossier des interfaces
générées à `includePath` :

```json
{
  "includePath": [
    "includes",
    "src/cmagic-generated/services",
    "/usr/local/include"
  ]
}
```

Conserver les entrées `preUsrlibl` et `postUsrlibl` du projet de référence, notamment
`CKOOLBIN`, `DB2SAMPLE` et `ILEASTIC`.

Créer ou vérifier le fichier `.env` à la racine du projet :

```dotenv
CURLIB=CMAGICTST
```

Remplacer `CMAGICTST` par la bibliothèque dédiée choisie. Si la bibliothèque n'existe
pas encore, la créer depuis une session 5250 autorisée :

```cl
CRTLIB LIB(CMAGICTST) TEXT('Tests catalogue CMagic')
```

## Porte 3 — Vérifier les prérequis IBM i

Depuis ACS Run SQL Scripts, vérifier les données de référence :

```sql
SELECT COUNT(*) AS TOTAL
FROM DB2SAMPLE.DEPARTMENT;

SELECT DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION
FROM DB2SAMPLE.DEPARTMENT
ORDER BY DEPTNO
FETCH FIRST 10 ROWS ONLY;
```

Noter un identifiant existant ; les exemples suivants utilisent `A00`.

Depuis une session 5250, vérifier les objets runtime :

```cl
WRKOBJ OBJ(*ALL/ILEASTIC) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(*ALL/NOXDB) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(*ALL/CREST) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(*ALL/CKOOL) OBJTYPE(*BNDDIR)
WRKOBJ OBJ(*ALL/CMAGIC) OBJTYPE(*SRVPGM)
WRKOBJ OBJ(DB2SAMPLE/DEPARTMENT) OBJTYPE(*FILE)
```

L'emplacement exact des binding directories dépend de l'installation. L'objectif est
de confirmer leur présence et leur accessibilité dans la liste de bibliothèques, pas de
les recréer pendant la recette.

Vérifier également les includes IFS :

```bash
for cmagic_header in \
  /usr/local/include/sqlstates.rpginc \
  /usr/local/include/llist/llist_h.rpgle \
  /usr/local/include/ileastic/ileastic.rpgle \
  /usr/local/include/ileastic/noxdb.rpgleinc
do
  test -f "$cmagic_header" \
    && echo "OK      $cmagic_header" \
    || echo "MISSING $cmagic_header"
done
```

Un résultat non nul bloque le build. Noter alors le fichier absent et l'installation
runtime concernée.

## Porte 4 — Compiler avec BOB

Depuis la racine d'`applicationTemplate` :

```bash
mkdir -p validation-cmagic-20260729
makei --version
makei list
makei build -v -l src/cmagic-generated \
  > validation-cmagic-20260729/build.log 2>&1
cmagic_build_rc=$?
tail -n 100 validation-cmagic-20260729/build.log
echo "BOB return code: $cmagic_build_rc"
```

Le code retour attendu est `0`.

Si le build global échoue, isoler le premier objet défaillant dans cet ordre :

```bash
makei build -v -t SERVICE.MODULE
makei build -v -t SERVICE.SRVPGM
makei build -v -t SERVREST.MODULE
makei build -v -t SERVAPI.MODULE
makei build -v -t SERVAPI.PGM
```

Ne pas modifier directement un fichier généré pour faire passer le build. Conserver le
premier message d'erreur complet, le nom de l'objet et le log BOB ; la correction devra
être faite dans le modèle ou le template puis régénérée.

### Objets attendus

Vérifier dans la bibliothèque de test :

```cl
DSPOBJD OBJ(CMAGICTST/SERVICE) OBJTYPE(*MODULE)
DSPOBJD OBJ(CMAGICTST/SERVICE) OBJTYPE(*SRVPGM)
DSPOBJD OBJ(CMAGICTST/SERVREST) OBJTYPE(*MODULE)
DSPOBJD OBJ(CMAGICTST/SERVAPI) OBJTYPE(*MODULE)
DSPOBJD OBJ(CMAGICTST/SERVAPI) OBJTYPE(*PGM)
```

Les cinq objets doivent avoir une date de création ou de modification correspondant à
la recette.

## Porte 5 — Démarrer le serveur

Vérifier d'abord que le port n'est pas déjà occupé :

```bash
netstat -an | grep 44000
```

Si le port est utilisé par un autre serveur, ne pas l'arrêter sans en connaître le
propriétaire. Choisir un port libre dans le DSL, régénérer et reconstruire.

Depuis la même session 5250 ou PASE, préparer la liste de bibliothèques utilisée par le
serveur. Ajouter uniquement les bibliothèques qui ne sont pas déjà présentes :

```cl
ADDLIBLE LIB(CMAGICTST) POSITION(*FIRST)
ADDLIBLE LIB(CKOOLBIN) POSITION(*LAST)
ADDLIBLE LIB(DB2SAMPLE) POSITION(*LAST)
ADDLIBLE LIB(ILEASTIC) POSITION(*LAST)
```

Démarrer ensuite le programme dans un job séparé. `INLLIBL(*CURRENT)` rend explicite
l'héritage de cette liste et `CURLIB(CMAGICTST)` fixe la bibliothèque courante :

```bash
system "SBMJOB CMD(CALL PGM(CMAGICTST/SERVAPI)) JOB(SERVAPI) JOBQ(QSYSNOMAX) INLLIBL(*CURRENT) CURLIB(CMAGICTST) ALWMLTTHD(*YES)"
```

Puis contrôler :

```bash
netstat -an | grep 44000
curl -sS -i "http://localhost:44000/api/services?page=1&perPage=1"
```

Résultat attendu : port en écoute et réponse HTTP `200`. Si le job se termine
immédiatement, relever son joblog depuis `WRKACTJOB` ou `WRKSPLF` avant toute nouvelle
tentative.

## Porte 6 — Exécuter la recette HTTP

Créer le dossier de preuves s'il n'existe pas, puis exécuter les requêtes suivantes.
Depuis un poste client, remplacer `localhost` par le nom ou l'adresse de l'IBM i.

### 1. Liste par défaut

```bash
curl -sS -D validation-cmagic-20260729/list.headers \
  -o validation-cmagic-20260729/list.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services"
```

Attendu : `200`, `Content-Type: application/json`, un objet `data` tableau et un
`total` entier.

### 2. Pagination et tri

```bash
curl -sS -o validation-cmagic-20260729/page.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services?page=1&perPage=5&sort=nom&order=ASC"
```

Attendu : `200`, au maximum cinq éléments, triés par `nom`.

### 3. Recherche libre

```bash
curl -sS -o validation-cmagic-20260729/search.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services?q=PLANNING"
```

Attendu : `200` et le même format `{ "data": [...], "total": n }`.

### 4. Filtre exact

```bash
curl -sS -o validation-cmagic-20260729/filter.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services?id=A00"
```

Attendu : `200`; chaque élément retourné possède `id = "A00"`.

### 5. Lecture d'un service existant

```bash
curl -sS -o validation-cmagic-20260729/get-a00.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services/A00"
```

Attendu : `200` et `{ "data": { "id": "A00", ... } }`.

### 6. Identifiant inconnu

```bash
curl -sS -o validation-cmagic-20260729/get-unknown.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services/ZZZ"
```

Attendu : `404` avec une erreur JSON.

### 7. Identifiant trop long

```bash
curl -sS -o validation-cmagic-20260729/get-invalid.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services/A000"
```

Attendu : `400`; le serveur reste actif.

### 8. Tri non publié

```bash
curl -sS -o validation-cmagic-20260729/sort-invalid.json \
  -w "%{http_code}\n" \
  "http://localhost:44000/api/services?sort=inconnu&order=ASC"
```

Attendu : `400`; aucun SQL arbitraire n'est exécuté.

Si `jq` est installé, contrôler rapidement les enveloppes :

```bash
jq -e '.data | type == "array"' validation-cmagic-20260729/list.json
jq -e '(.total | type) == "number"' validation-cmagic-20260729/list.json
jq -e '.data.id == "A00"' validation-cmagic-20260729/get-a00.json
```

## Porte 7 — Arrêter proprement et conserver les preuves

Depuis `WRKACTJOB`, retrouver le job `SERVAPI` et noter son identifiant qualifié
`numéro/utilisateur/SERVAPI`. L'arrêter de façon contrôlée :

```cl
ENDJOB JOB(123456/USER/SERVAPI) OPTION(*CNTRLD) DELAY(30)
```

Vérifier ensuite que le port n'écoute plus. Ne pas supprimer la bibliothèque de test :
elle doit rester disponible jusqu'à l'analyse des résultats.

Conserver :

- `build.log` ;
- les en-têtes et corps des huit requêtes ;
- le joblog `SERVAPI` ;
- les versions IBM i, BOB, ILEastic, CREST et CMagic ;
- la liste des cinq objets avec leurs dates ;
- toute modification locale d'`iproj.json` ou `.env`.

## Diagnostic rapide

| Symptôme | Vérification prioritaire |
| --- | --- |
| Include introuvable | `includePath`, dossier `services`, `/usr/local/include` |
| Binding directory introuvable | `WRKOBJ *ALL/ILEASTIC`, `NOXDB`, `CREST`, `CKOOL` et liste de bibliothèques |
| Symbole CMagic non résolu | log de création de `SERVICE.SRVPGM` et runtime `CMAGIC` |
| Table `DEPARTMENT` introuvable | présence de `DB2SAMPLE` dans la liste de bibliothèques |
| `SERVAPI` se termine immédiatement | joblog, port occupé, binding runtime |
| Toutes les routes renvoient `404` | bon objet `SERVAPI`, date du build, appel à `service_registerRoutes` |
| HTTP `500` | corps CREST, joblog, SQLSTATE, droits sur `DB2SAMPLE.DEPARTMENT` |
| Réponse illisible | conserver la réponse brute et vérifier CCSID/UTF-8 |

## Compte rendu à compléter

| Porte | Résultat | Preuve ou erreur |
| --- | --- | --- |
| 1. Artefacts figés | OK / KO | |
| 2. Projet transféré | OK / KO | |
| 3. Prérequis runtime | OK / KO | |
| 4. Build BOB | OK / KO | |
| 5. Serveur démarré | OK / KO | |
| 6. Tests HTTP | OK / KO | |
| 7. Arrêt et preuves | OK / KO | |

Conclusion :

- **GO** si le build, les cinq objets, le démarrage et les huit tests HTTP sont
  conformes ;
- **GO avec réserve** si seuls un contrôle optionnel ou l'outillage de preuve échouent ;
- **NO GO** si un objet ne compile pas, si le serveur s'arrête ou si le contrat JSON est
  incorrect.

## Références

- [IBM TOBi, anciennement BOB](https://github.com/IBM/ibmi-tobi)
- [IBM i — commande SBMJOB](https://www.ibm.com/docs/en/i/7.5.0?topic=ssw_ibm_i_75%2Fcl%2Fsbmjob.html)
