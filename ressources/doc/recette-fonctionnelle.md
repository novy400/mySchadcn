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

## Important

Les donnees proviennent de `ra-data-fakerest`.
Les modifications sont donc en memoire et ne persistent pas apres un rechargement complet de la page.
