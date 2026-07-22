# Synthèse CMagic : modernisation IBM i et Flight400

_Statut : vision consolidée._

## Vision

CMagic propose de moderniser une application IBM i en partant du métier plutôt que des
écrans 5250. Le frontend sert à valider l'expérience et les contrats ; le backend IBM i
reste responsable des règles, des transactions locales et de l'intégrité métier.

## Langage commun

| Concept | Question principale | Exemple Flight400 |
| --- | --- | --- |
| Catalogue | quelles données de référence faut-il gérer ? | aéroports, avions |
| Processus | quels états et transitions gouvernent le dossier ? | réservation |
| Action métier | quelle intention déclenche la transition ? | confirmer, annuler |
| Saga | quels systèmes et compensations sont impliqués ? | siège + paiement |

Voir [Concepts CMagic](./concepts-cmagic.md) pour les définitions normatives.

## Rôle de mySchadcn

`mySchadcn` est le laboratoire UX et contractuel :

- composants admin construits sur `ra-core` et shadcn/ui ;
- données locales FakeRest ;
- ressources organisées par modules métier ;
- projections TypeScript adaptées aux écrans ;
- tests de composants et de transformations.

Le dataset n'est pas un fichier `data.json`. Le flux réel est documenté dans
[Architecture actuelle](../architecture-actuelle.md).

## Trajectoire proposée

### 1. Explorer le domaine

- inventorier fichiers, programmes, écrans et utilisateurs ;
- identifier le langage métier existant ;
- classer les capacités sans forcer artificiellement une Saga.

### 2. Prototyper une tranche verticale

- sélectionner une capacité représentative ;
- créer ses données locales et ses écrans ;
- valider listes, filtres, détail et actions avec les utilisateurs ;
- écrire la recette et les tests du prototype.

### 3. Formaliser le contrat

- ressources, identifiants et relations ;
- pagination, tri et filtres ;
- états et transitions ;
- actions, erreurs et règles d'idempotence ;
- projections nécessaires aux écrans.

### 4. Implémenter le backend IBM i

- vues Db2 for i et services RPG ;
- API CRUD et endpoints d'actions métier ;
- authentification et autorisations ;
- tests de contrat et observabilité.

### 5. Ajouter une Saga seulement si nécessaire

Une Saga devient pertinente lorsqu'une action traverse réellement plusieurs frontières
transactionnelles. Elle doit alors définir les étapes, compensations, délais, reprises et
états visibles. Elle fournit une cohérence éventuelle, pas une transaction ACID globale.

### 6. Basculer le DataProvider

- migrer ressource par ressource ;
- comparer FakeRest et REST avec les mêmes tests fonctionnels ;
- surveiller les erreurs et prévoir un retour arrière ;
- supprimer la simulation uniquement après validation.

## Première tranche Flight400 recommandée

Une première tranche peut associer :

1. un catalogue simple, par exemple `airports` ;
2. une liste filtrable de `flights` ;
3. un processus limité de réservation avec transitions explicites ;
4. aucune Saga tant que le paiement ou un second système réel n'est pas intégré.

Cette progression valide l'architecture sans introduire prématurément l'orchestration la
plus complexe.

## Documents exploratoires

`patterns++.md`, les images générées et `ordres_status.md` sont conservés comme matériaux
de réflexion. Ils peuvent inspirer les spécifications, mais ne font pas foi sur l'état du
code ou les contrats techniques.
