# Documentation du projet

Ce dossier rassemble la documentation du prototype `mySchadcn` et les travaux de
conception liés à sa future intégration IBM i.

## Documents de référence

| Document | Rôle | Statut |
| --- | --- | --- |
| [État du projet](./etat-du-projet.md) | Fonctionnalités et qualité constatées dans le dépôt | Actuel |
| [Architecture actuelle](./architecture-actuelle.md) | Organisation du code et flux de données | Actuel |
| [Recette fonctionnelle](./recette-fonctionnelle.md) | Parcours de vérification manuelle | À actualiser |
| [Plan d'amélioration documentaire](./PLAN_AMELIORATION_DOC.md) | Travaux décidés et avancement | Actuel |
| [Plan d'implémentation](./PLAN_IMPLEMENTATION.md) | Tranches applicatives issues de l'audit | Actuel |

## Guides pratiques

- [Ajouter une ressource métier](./howto-ajouter-ressource-module.md)
- [Ajouter une projection de synthèse](./howto-ajouter-ressource-projection-summary.md)
- [Filtres avancés des tâches](./filtres-avances-taches.md)
- [Créer un projet à partir de mySchadcn](./howto-creer-nouveau-projet.md)
- [Migrer FakeRest vers une API IBM i](./howto-migrer-fakerest-vers-rest-ibmi.md)
- [Contrat du DataProvider IBM i](./contrat-data-provider-ibmi.md)
- [Authentification et autorisations](./authentification-autorisations.md)
- [Diagnostic des tests CSS et du bundle](./diagnostic-tests-et-bundle.md)
- [Mettre à jour depuis shadcn-admin-kit](./git-upstream-maj.md)
- [Stratégie de mise à jour Shadcn](./STRATEGIE_MAJ_SHADCN.md)

## Cadrage et conception

- [Cadrage initial](./0_cadrage.md) : historique de la conception, à ne pas utiliser
  comme photographie de l'état courant.
- [Variante de starter](./starter-variante-2-react-admin-fakerest-ibmi.md) : description
  historique à consolider.
- [Tutoriel modulaire](./tutoriel-vite-react-admin-fakerest-modulaire.md) : tutoriel à
  actualiser.
- [`cmagic/`](./cmagic/) : vision et notes de conception CMagic/Flight400. Certains
  documents sont encore des matériaux de travail et non des spécifications normatives.

## Règle de lecture

En cas de contradiction :

1. le code et les tests actifs font foi pour l'état implémenté ;
2. `etat-du-projet.md` et `architecture-actuelle.md` décrivent cet état ;
3. les documents de cadrage et CMagic décrivent une intention ou une cible future.
