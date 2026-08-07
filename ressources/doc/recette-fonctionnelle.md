# Recette fonctionnelle rapide

## Prerequis

- Node.js 20+
- dependances installees via `npm install`

## Verification technique

```bash
npm run lint
npm run test
npm run build
```

## Demarrage local

```bash
npm run dev
```

Ouvrir ensuite l'URL affichee par Vite.

## Parcours de recette

### 0. Authentification et rôles

- vérifier que le CRM est inaccessible sans connexion
- se connecter comme Lecteur et vérifier l'absence des créations, éditions et actions de commande
- se connecter comme Agent et vérifier la gestion des clients, contacts, tâches, notes et fournisseurs
- vérifier que l'Agent ne peut ni modifier une commande ni déclencher son cycle de vie
- se connecter comme Responsable et vérifier les actions autorisées sur les commandes
- se déconnecter et vérifier le retour à la page de connexion

### 1. Dashboard

- verifier le titre `Dashboard CRM`
- verifier les cartes de synthese
- verifier la section `Contacts à suivre`

### 2. Clients

- ouvrir la liste
- creer un client
- modifier un client existant

### 3. Contacts

- ouvrir la liste
- creer un contact rattache a un client
- verifier l'edition

### 4. Taches

- ouvrir la liste
- vérifier les filtres texte, contact, client et statut
- creer une tache `OPEN`
- modifier une tache en `DONE`

### 5. Notes

- ouvrir la liste
- creer une note
- verifier sa restitution

### 6. Vue de synthese

- ouvrir `contacts_summary`
- verifier la coherence des compteurs et de la derniere note

### 7. Customers

- ouvrir la liste `customers`
- ouvrir une fiche
- verifier les onglets `General`, `Signalétique`, `Risque métier`

### 8. Fournisseurs

La ressource CRM `fournisseurs` est préparée pour une bascule atomique vers la nouvelle
table Db2 `FOURNIS` et le service IWS `FOURIWS1`. Elle autorise LIST, GET, CREATE et UPDATE,
sans DELETE, opération de masse ou chargement de relation.

La procédure IBM i détaillée, depuis le transfert des sources jusqu'au nettoyage SQL, est
[`recette-ibmi-fournisseurs-iws.md`](./cmagic/recette-ibmi-fournisseurs-iws.md).

#### 8.1 Vérifier le seam React Admin sans réseau réel

```bash
npm run test -- src/app/providers/resourceContracts.test.ts src/app/providers/iwsDataProvider.test.ts src/app/providers/dataProvider.test.ts src/app/auth/accessPolicy.test.ts src/modules/crm/fournisseurs/FournisseurList.test.tsx src/modules/crm/fournisseurs/FournisseurForm.test.tsx
```

Résultat de référence : six fichiers et 53 tests réussis. Les tests emploient un
DataProvider ou un `fetcher` simulé et vérifient :

- LIST avec pagination, recherche `q`, filtre `ville` et tri `nom` ;
- GET avant EDIT, POST au CREATE et PUT complet à l'UPDATE ;
- les six champs et l'identifiant saisi au CREATE puis immuable dans EDIT ;
- les droits : Lecteur en lecture seule, Agent et Responsable en création/modification ;
- l'absence de DELETE, sélection groupée, `getMany` et `getManyReference` ;
- le maintien de `services` en lecture seule et des autres ressources sur FakeRest.

#### 8.2 Préparer la recette IBM i

Avant toute écriture, créer `FOURNIS` depuis le DDL généré, compiler les objets `FOURNIS`
et `FOURIWS`, puis publier ce dernier sous `/web/services/FOURIWS1`. Utiliser une
bibliothèque de recette explicitement choisie et un identifiant isolé, par exemple
`T14REC001`. Prévoir son nettoyage par SQL : DELETE n'appartient pas à l'API publique.

Le fichier `.env.local`, ignoré par Git, doit contenir uniquement la cible serveur du
proxy. Le navigateur consomme l'URL relative documentée dans `.env.example` :

```bash
VITE_IBM_I_FOURNISSEURS_API_URL=/web/services/FOURIWS1
```

#### 8.3 Vérifier LIST et GET via le proxy Vite

Lancer `npm run dev`, relever le port Vite, puis adapter les commandes suivantes :

```powershell
$list = Invoke-RestMethod "http://localhost:5173/web/services/FOURIWS1?page=1&perPage=5&sort=nom&order=ASC&q=nord&ville=Lille"
$list | ConvertTo-Json -Depth 5

$detail = Invoke-RestMethod "http://localhost:5173/web/services/FOURIWS1/T14REC001"
$detail | ConvertTo-Json -Depth 5
```

Vérifier les statuts `200`, les enveloppes `{ items, totalCount, errors }` et
`{ item, errors }`, les six champs, la pagination et la stabilité de `item.id`.

#### 8.4 Vérifier CREATE et UPDATE

```powershell
$createBody = @{
  id = "T14REC001"
  nom = "Fournisseur recette tranche 14"
  adresse = "1 rue du Test"
  ville = "Lille"
  telephone = "0300000000"
  email = "recette14@example.test"
} | ConvertTo-Json

$created = Invoke-RestMethod "http://localhost:5173/web/services/FOURIWS1" -Method Post -ContentType "application/json" -Body $createBody
$created | ConvertTo-Json -Depth 5

$updateBody = @{
  id = "T14REC001"
  nom = "Fournisseur recette tranche 14 modifié"
  adresse = "2 rue du Test"
  ville = "Lille"
  telephone = "0300000001"
  email = "recette14@example.test"
} | ConvertTo-Json

$updated = Invoke-RestMethod "http://localhost:5173/web/services/FOURIWS1/T14REC001" -Method Put -ContentType "application/json" -Body $updateBody
$updated | ConvertTo-Json -Depth 5
```

Attendre `201` au CREATE et `200` à l'UPDATE, puis relire l'identifiant. Rejouer le POST
avec la même clé pour vérifier le `409`, envoyer un champ invalide pour vérifier `400` ou
`422`, et demander une clé absente pour vérifier `404`. Nettoyer ensuite `T14REC001`
directement en SQL dans la bibliothèque de recette.

Dans l'interface, vérifier la liste avec les trois rôles, l'absence de bouton CREATE pour
Lecteur, la création pour Agent/Responsable, l'ouverture d'une ligne vers EDIT, la clé
désactivée, la sauvegarde pessimiste et l'absence totale de suppression.

Au 7 août 2026, le smoke test en lecture via Vite atteint le proxy mais reçoit `404` sans
enveloppe IWS sur `FOURIWS1`. Les étapes 8.3 et 8.4 sont donc en attente du déploiement ;
aucune écriture réelle n'a été tentée.

### 9. Commandes

- ouvrir la liste `orders`
- vérifier les onglets Commandées, Livrées et Annulées
- vérifier les compteurs par statut
- filtrer par client
- ouvrir une commande et vérifier le panier et les totaux
- sur une commande en cours, vérifier que seules les actions `Livrer` et `Annuler` sont proposées
- annuler une commande après confirmation et vérifier qu'aucune autre action n'est disponible
- livrer une autre commande et vérifier que seule l'action `Signaler le retour` reste disponible
- signaler le retour et vérifier que l'action ne peut pas être répétée

### 10. DataProvider IBM i — ressource technique `services`

La ressource `services` expose maintenant des écrans LIST et SHOW en lecture seule sous le
libellé « Services IBM i ». Elle reste un référentiel technique séparé des notions métier
CRM. La recette porte sur le seam public du DataProvider, les écrans React Admin, l'accès
HTTP en lecture seule et la non-régression des ressources restées sur FakeRest.

#### 10.1 Préparer l'accès local

Créer ou vérifier le fichier `.env.local`, ignoré par Git :

```bash
IBM_I_DEV_PROXY_TARGET=http://cmspw7t:10074
```

L'URL consommée par le navigateur reste relative :
`/web/services/SERVIWS3`. Aucun changement de `httpd.conf` n'est requis tant que
`http://cmspw7t:10074/web/services/SERVIWS3` est accessible depuis le poste.

#### 10.2 Vérifier le contrat DataProvider sans réseau réel

```bash
npm run test -- src/app/providers/iwsDataProvider.test.ts src/app/providers/compositeDataProvider.test.ts src/app/providers/dataProvider.test.ts src/app/providers/resourceContracts.test.ts
```

Résultat attendu : quatre fichiers et 37 tests réussis. Ces tests doivent confirmer :

- la sérialisation de `page`, `perPage`, `sort`, `order`, `q` et des filtres ;
- l'adaptation de `{ items, totalCount, errors }` vers `{ data, total }` ;
- l'adaptation de `{ item, errors }` vers `{ data }` ;
- la présence d'un `id` stable et le rejet d'un identifiant incohérent ;
- la conversion déterministe des statuts `400`, `401`, `403`, `404`, `409`, `422` et `500` ;
- la transmission de l'`AbortSignal` ;
- le routage de `services` et `fournisseurs` vers leurs URL IWS respectives et le maintien
  des autres ressources sur FakeRest ;
- le rejet de `getMany`, `getManyReference`, `CREATE`, `UPDATE` et `DELETE` pour
  `services`.

#### 10.3 Vérifier les écrans LIST et SHOW sans réseau réel

```bash
npm run test -- src/app/App.test.tsx src/modules/ibmi/services/ServiceList.test.tsx src/modules/ibmi/services/ServiceShow.test.tsx src/modules/ibmi/services/ServiceResource.test.tsx
```

Résultat attendu : quatre fichiers et huit tests réussis. Ces tests utilisent un
DataProvider simulé et doivent confirmer :

- l'entrée « Services IBM i » dans la navigation d'un rôle autorisé ;
- l'appel de `getList('services')`, la pagination, la recherche `q`, les filtres permis et
  les seuls tris `id` et `nom` ;
- la restitution de `id`, `nom`, `idManageur`, `idServiceAdmin` et `site` ;
- l'ouverture de SHOW depuis une ligne et l'appel de `getOne('services')` ;
- l'absence de sélection groupée, CREATE, EDIT, DELETE, `getMany` et
  `getManyReference`.

Avec `npm run dev`, se connecter successivement comme Lecteur, Agent et Responsable puis :

- vérifier la présence de « Services IBM i » dans la navigation ;
- ouvrir LIST, changer la pagination et trier par `id` puis `nom` ;
- saisir une recherche et activer quelques filtres techniques ;
- ouvrir une ligne et vérifier les cinq champs dans SHOW ;
- confirmer l'absence de bouton de création, modification ou suppression sur les deux
  écrans.

#### 10.4 Vérifier LIST via le proxy Vite

Lancer `npm run dev`, relever l'URL affichée par Vite, puis exécuter depuis un second
terminal en adaptant le port si nécessaire :

```powershell
$list = Invoke-RestMethod "http://localhost:5173/web/services/SERVIWS3?page=1&perPage=5&sort=id&order=ASC"
$list | ConvertTo-Json -Depth 5
```

Vérifier que :

- la réponse HTTP vaut `200` ;
- `items` est un tableau contenant au maximum cinq lignes ;
- `totalCount` est un entier supérieur ou égal au nombre d'éléments retournés ;
- `errors` est vide ;
- chaque élément possède un `id` non vide et unique dans la page.

Rejouer ensuite une recherche et un filtre :

```powershell
Invoke-RestMethod "http://localhost:5173/web/services/SERVIWS3?page=1&perPage=10&sort=nom&order=DESC&q=planning"
Invoke-RestMethod "http://localhost:5173/web/services/SERVIWS3?page=1&perPage=10&sort=id&order=ASC&idServiceAdmin=A00"
```

Vérifier que la recherche ne restitue que les lignes sémantiquement correspondantes,
que le filtre exact est respecté et que le tri est observable.

#### 10.5 Vérifier GET et les erreurs de lecture

```powershell
$detail = Invoke-RestMethod "http://localhost:5173/web/services/SERVIWS3/A00"
$detail | ConvertTo-Json -Depth 5

$notFound = Invoke-WebRequest "http://localhost:5173/web/services/SERVIWS3/ZZZ" -SkipHttpErrorCheck
$notFound.StatusCode
$notFound.Content

$badRequest = Invoke-WebRequest "http://localhost:5173/web/services/SERVIWS3?sort=inconnu&order=ASC" -SkipHttpErrorCheck
$badRequest.StatusCode
$badRequest.Content
```

Vérifier que :

- `GET /A00` répond `200`, expose `item.id = "A00"` et un tableau `errors` vide ;
- `GET /ZZZ` répond `404` avec une erreur IWS déterministe ;
- un tri invalide répond `400` ;
- deux lectures successives de `A00` conservent le même identifiant.

Ne pas provoquer volontairement de `409` ou `500` sur l'environnement IBM i. Leur
adaptation, ainsi que celles de `401` et `403`, est vérifiée par les tests unitaires avec
des réponses HTTP simulées.

#### 10.6 Vérifier les non-régressions et les limites de tranche

- ouvrir le Dashboard, `clients`, `contacts`, `tasks` et `contacts_summary` ;
- vérifier que leurs listes et projections se chargent comme avant ;
- créer ou modifier une donnée FakeRest autorisée, puis vérifier la projection associée ;
- confirmer que les écrans CRM autres que `fournisseurs` n'effectuent aucun appel IWS ;
- ne réaliser aucun `POST`, `PUT`, `PATCH` ou `DELETE` sur `services` dans cette tranche ;
- terminer par `npm run check` et attendre 43 fichiers et 125 tests réussis.

La tranche est **GO** si les écrans LIST et SHOW restent strictement en lecture seule, si
LIST et GET fonctionnent via Vite, si les erreurs de lecture sont conformes, si les
ressources autres que `services` et `fournisseurs` restent sur FakeRest et si
`npm run check` reste vert.
Elle est **NO GO** si une écriture atteint `services`, si une ressource non migrée est
routée vers IWS, si un `id` est absent ou instable, ou si une projection existante régresse.

## Important

Les écrans CRM autres que `fournisseurs` utilisent encore `ra-data-fakerest`. Leurs
modifications sont donc en mémoire et ne persistent pas après un rechargement complet.
La ressource technique `services`, limitée à LIST et GET, lit `SERVIWS3` ; la ressource CRM
`fournisseurs` utilise LIST, GET, CREATE et UPDATE sur `FOURIWS1` après son déploiement.
