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

## Important

Les donnees proviennent de `ra-data-fakerest`.
Les modifications sont donc en memoire et ne persistent pas apres un rechargement complet de la page.
