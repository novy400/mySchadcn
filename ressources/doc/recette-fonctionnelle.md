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

- ouvrir la liste `fournisseurs`
- créer un fournisseur
- modifier ses coordonnées

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
- la conversion déterministe des statuts `400`, `401`, `403`, `404`, `409` et `500` ;
- la transmission de l'`AbortSignal` ;
- le routage exclusif de `services` vers IWS et le maintien des autres ressources sur
  FakeRest ;
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

- ouvrir le Dashboard, `clients`, `contacts`, `tasks`, `contacts_summary` et
  `fournisseurs` ;
- vérifier que leurs listes et projections se chargent comme avant ;
- créer ou modifier une donnée FakeRest autorisée, puis vérifier la projection associée ;
- confirmer qu'aucun écran CRM existant n'effectue d'appel vers `SERVIWS3` ;
- ne réaliser aucun `POST`, `PUT`, `PATCH` ou `DELETE` sur `services` dans cette tranche ;
- terminer par `npm run check` et attendre 43 fichiers et 111 tests réussis.

La tranche est **GO** si les écrans LIST et SHOW restent strictement en lecture seule, si
LIST et GET fonctionnent via Vite, si les erreurs de lecture sont conformes, si les
ressources CRM restent sur FakeRest et si `npm run check` reste vert.
Elle est **NO GO** si une écriture atteint IBM i, si une autre ressource est routée vers
IWS, si un `id` est absent ou instable, ou si une projection existante régresse.

## Important

Les écrans CRM utilisent encore `ra-data-fakerest`. Leurs modifications sont donc en
mémoire et ne persistent pas après un rechargement complet de la page. Seule la ressource
technique `services`, limitée à LIST et GET et exposée par des écrans en lecture seule, lit
les données réelles du service IBM i `SERVIWS3`.
