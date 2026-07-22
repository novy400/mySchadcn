# Commandes et statuts

_Statut : cycle de vie du prototype implémenté ; questions de modélisation avancée ouvertes._

## Modèle actuel

La ressource `orders` contient :

| Champ | Type | Rôle |
| --- | --- | --- |
| `id` | identifiant React Admin | clé technique |
| `reference` | chaîne | référence visible |
| `date` | date ISO | date de commande |
| `customer_id` | identifiant | relation vers `customers` |
| `basket` | tableau | lignes réduites à `product_id` et `quantity` |
| `total_ex_taxes` | nombre | total hors taxes |
| `delivery_fees` | nombre | frais de livraison |
| `tax_rate` | nombre | taux de taxe décimal |
| `taxes` | nombre | montant des taxes |
| `total` | nombre | total toutes taxes comprises |
| `status` | énumération | `ordered`, `delivered` ou `canceled` |
| `returned` | booléen | présence d'un retour |

## Interface implémentée

- liste séparée par onglets de statut ;
- compteur par statut ;
- recherche et filtre par client ;
- choix des colonnes et export ;
- ouverture de la commande en édition ;
- modification du client et de la date ;
- actions métier `Livrer`, `Annuler` et `Signaler le retour` selon l'état courant ;
- confirmation avant l'annulation ;
- affichage du panier et des totaux.

![Liste des commandes par statut](image/ordres_status/orders-list-by-status.png)

![Référence visuelle d'édition du statut](image/ordres_status/order-edit-status.png)

Les captures proviennent du kit de référence et peuvent différer du prototype local.

## Transitions retenues

| État courant | Action | Résultat |
| --- | --- | --- |
| `ordered` | Livrer | `delivered` |
| `ordered` | Annuler | `canceled` |
| `delivered` sans retour | Signaler le retour | `delivered` avec `returned: true` |

Une commande livrée ou annulée ne change plus de statut. Un retour n'est possible qu'une
fois sur une commande livrée. Ces règles sont contrôlées dans le frontend du prototype ;
le futur backend devra les appliquer à son tour et rester l'autorité métier.

## Questions restant à décider

1. Un retour doit-il devenir une ressource avec lignes, quantités et motif ?
2. Quel arrondi monétaire s'applique à la taxe et au total ?
3. Faut-il conserver un historique des transitions et leur auteur ?
4. Quelles garanties d'idempotence et de concurrence le backend doit-il fournir ?

## Références d'origine

- [Exemple orders de shadcn-admin-kit](https://github.com/marmelab/shadcn-admin-kit/tree/main/src/demo/orders)
- [OrderList de référence](https://github.com/marmelab/shadcn-admin-kit/blob/main/src/demo/orders/OrderList.tsx)
- [OrderEdit de référence](https://github.com/marmelab/shadcn-admin-kit/blob/main/src/demo/orders/OrderEdit.tsx)
