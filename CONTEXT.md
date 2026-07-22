# CRM Administration

Ce contexte décrit les concepts métier manipulés par le prototype CRM et ses futurs
services IBM i.

## Language

**Commande**:
Engagement d'un client portant sur un panier et un montant figés, suivi jusqu'à sa
livraison, son annulation ou son éventuel retour.
_Avoid_: Order, transaction

**Commande en cours**:
Commande acceptée qui peut encore être livrée ou annulée.
_Avoid_: Brouillon, commande ouverte

**Commande livrée**:
Commande dont la livraison est achevée. Elle ne peut plus être annulée, mais peut faire
l'objet d'un retour.
_Avoid_: Commande terminée

**Commande annulée**:
Commande arrêtée avant sa livraison. Cet état est terminal.
_Avoid_: Commande supprimée

**Livraison**:
Action métier qui fait passer une commande en cours à l'état livré.
_Avoid_: Changement de statut

**Annulation**:
Action métier qui arrête une commande en cours avant sa livraison.
_Avoid_: Suppression

**Retour**:
Action métier appliquée une seule fois à une commande livrée pour signaler qu'elle a été
retournée.
_Avoid_: Annulation, remboursement

**Utilisateur**:
Personne identifiée qui accède à l'administration CRM avec un rôle déterminant ses droits.
_Avoid_: Compte client, customer

**Lecteur**:
Utilisateur autorisé à consulter les informations du CRM sans les modifier.
_Avoid_: Invité, visiteur

**Agent**:
Utilisateur autorisé à consulter et gérer les clients, contacts, tâches, notes et
fournisseurs, sans piloter le cycle de vie des commandes.
_Avoid_: Opérateur, commercial

**Responsable**:
Utilisateur disposant des droits de l'Agent et autorisé à modifier une commande et à
déclencher ses actions métier.
_Avoid_: Administrateur, manager
