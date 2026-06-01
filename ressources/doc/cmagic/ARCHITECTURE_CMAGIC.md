# Référentiel d'Architecture CMagic

## Contexte du Projet
Nous modernisons une application IBM i / AS400 historique appelée **Flight400**. 
L'objectif est de remplacer les écrans 5250 monolithiques par une architecture Web moderne, modulaire, inspirée d'**Atomic CRM**.

## Langage Ubiquitaire (Triptyque)
Chaque fonctionnalité doit être classée dans l'un de ces trois patterns :

1. **CATALOGUE :** Données stables (CRUD). 
   * *Exemples :* Aéroports (`AIRPORTP`), Vols (`FLIGHTP`).
2. **PROCESSUS :** Dossier avec statuts et Actions Métier. 
   * *Exemples :* Fiche de Réservation (`BOOKINGP`). Passe de "Brouillon" à "Confirmé".
3. **SAGA :** Orchestration multi-systèmes avec compensations. 
   * *Exemples :* Parcours de paiement Extranet (RPG local + API externe).

## Stack Technique
* **Frontend :** React Admin, shadcn/ui, Tailwind CSS. Prototypage via FakeRest (`data.json`).
* **Backend :** Db2 for i (SQL DDL), RPG ILE Full-Free, DSL CMagic.