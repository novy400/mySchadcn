# Contrat du DataProvider IBM i

_Version du contrat : 1 — 2026-07-22_

## Finalité

Ce document fixe l'interface entre les écrans React Admin et le futur adapter REST IBM i.
Le registre typé [`resourceContracts.ts`](../../src/app/providers/resourceContracts.ts)
est la source de vérité exécutable pour les noms de ressources, les champs consommés, les
filtres, les tris, les relations et les capacités.

Le backend peut conserver ses noms de fichiers, de colonnes et ses formats internes. Leur
conversion vers ce contrat appartient à l'adapter REST, pas aux écrans.

## Invariants communs

- chaque enregistrement exposé au DataProvider possède un champ `id` stable, de type chaîne
  ou nombre ;
- les clés étrangères emploient le même type d'identifiant que la ressource cible ;
- une date sans heure est fournie au format `YYYY-MM-DD`, sans conversion de fuseau ;
- les montants reçus par les écrans sont des nombres JavaScript exprimés en euros ;
- le transport IBM i peut employer des chaînes décimales exactes, à convertir dans l'adapter
  après validation ;
- les textes sont normalisés en UTF-8 ;
- une projection est en lecture seule et possède son propre endpoint ;
- une capacité absente du registre ne doit pas être exposée par l'interface.

## Opérations de lecture

### Liste

```http
GET /api/clients?page=1&perPage=25&sort=nom&order=ASC&q=dupont&statut=ACTIF
```

```json
{
  "data": [{ "id": 1, "code": "CLI001", "nom": "Dupont SA", "ville": "Paris", "statut": "ACTIF" }],
  "total": 1
}
```

Règles :

- `page` commence à `1` et `perPage` est strictement positif ;
- `order` vaut `ASC` ou `DESC` ;
- seuls les filtres et tris déclarés pour la ressource sont acceptés ;
- `total` compte tous les résultats avant pagination ;
- un filtre absent et un filtre vide ont la même signification ;
- la réponse conserve un ordre déterministe en ajoutant `id` comme dernier critère de tri.

### Enregistrement et références

```http
GET /api/clients/1
GET /api/clients?ids=1,2
GET /api/contacts?client_id=1&page=1&perPage=25&sort=nom&order=ASC
```

Les réponses utilisent respectivement :

- `getOne` : `{ "data": {...} }` ;
- `getMany` : `{ "data": [...] }` ;
- `getManyReference` : `{ "data": [...], "total": n }`.

## Opérations d'écriture

Pour une ressource possédant la capacité correspondante :

| Capacité | Requête | Réponse |
| --- | --- | --- |
| `create` | `POST /api/{resource}` | `201` avec `{ "data": record }` |
| `update` | `PATCH /api/{resource}/{id}` | `200` avec `{ "data": record }` |
| `delete` | `DELETE /api/{resource}/{id}` | `200` avec `{ "data": record }` |

Le backend renvoie toujours l'enregistrement résultant, avec son `id`. Une mise à jour
doit être atomique. Le mécanisme de version optimiste reste à choisir avec l'équipe IBM i ;
un conflit doit déjà être représenté par le statut HTTP `409`.

## Catalogue des ressources

Le catalogue détaillé n'est pas recopié dans ce document. Les noms, natures, champs,
capacités, filtres, tris, relations, projections et actions sont définis une seule fois
dans [`resourceContracts.ts`](../../src/app/providers/resourceContracts.ts), puis vérifiés
par `resourceContracts.test.ts`.

Point d'attention : la ressource de mutation `tasks` appartient au contrat même si seule
sa projection `tasks_with_client` est enregistrée dans `App.tsx`. Les écrans de cette
projection déclarent `tasks` comme ressource de mutation.

Le filtre `q` est une recherche textuelle insensible à la casse sur les champs textuels
visibles de la ressource. Sa stratégie exacte côté Db2 doit rester cohérente pour toutes
les ressources.

## Actions métier des commandes

Les transitions ne passent pas par une mise à jour libre de `status` en production :

```http
POST /api/orders/{id}/deliver
POST /api/orders/{id}/cancel
POST /api/orders/{id}/return
```

Chaque action renvoie `{ "data": order }`. Le backend vérifie les préconditions décrites
dans [`CONTEXT.md`](../../CONTEXT.md). Une transition interdite ou concurrente renvoie
`409`, avec un code métier stable. L'idempotence et la clé de déduplication feront l'objet
d'une décision dédiée avant le branchement REST.

## Erreurs

Toute erreur HTTP fournit une structure exploitable par l'adapter :

```json
{
  "status": 409,
  "code": "ORDER_TRANSITION_NOT_ALLOWED",
  "message": "La commande livrée ne peut pas être annulée.",
  "fieldErrors": {},
  "correlationId": "01J..."
}
```

| HTTP | Usage |
| --- | --- |
| `400` | paramètres de liste ou corps illisible |
| `401` | session absente ou expirée |
| `403` | opération interdite à l'utilisateur |
| `404` | ressource ou enregistrement inconnu |
| `409` | conflit de version ou règle métier incompatible avec l'état courant |
| `422` | validation de champs |
| `500` | erreur interne corrélée et journalisée |

Le DataProvider transforme cette réponse en erreur React Admin tout en conservant
`status`, `code`, `fieldErrors` et `correlationId`.

Le traitement de `401`, `403` et du contrat de session est détaillé dans
[Authentification et autorisations](./authentification-autorisations.md).

## Migration progressive

Le module [`compositeDataProvider.ts`](../../src/app/providers/compositeDataProvider.ts)
route toutes les opérations standard vers l'adapter REST pour les ressources migrées et
vers FakeRest pour les autres. La configuration refuse un nom absent du registre, ce qui
évite une bascule silencieuse vers la mauvaise source.

Ordre recommandé : `clients`, `contacts`, `tasks` avec `tasks_with_client`, puis le reste
des ressources. Une ressource et ses projections dépendantes doivent être migrées dans la
même tranche ou exposées par des endpoints backend cohérents.
