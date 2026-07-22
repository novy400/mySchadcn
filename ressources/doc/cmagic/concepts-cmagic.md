# Concepts CMagic

_Statut : vocabulaire de conception._

CMagic classe les capacités métier selon leur comportement, pas selon leur apparence à
l'écran. Cette classification aide à décider du contrat API et de l'expérience utilisateur.

## Catalogue

Un catalogue gère des données de référence dont le cycle de vie reste simple.

Exemples : aéroports, fournisseurs, types d'avion.

Caractéristiques :

- opérations CRUD explicites ;
- listes, recherche, tri et filtres ;
- validations de champs ;
- absence de workflow métier complexe.

Dans `mySchadcn`, `clients` et `fournisseurs` sont les exemples les plus proches de ce
pattern.

## Processus

Un processus représente un dossier métier qui évolue selon des états et des transitions
autorisées.

Exemples : réservation, commande, dossier de risque.

Caractéristiques :

- statut courant ;
- transitions nommées ;
- règles d'autorisation et de validation ;
- historique des décisions ;
- actions proposées selon l'état.

Modifier directement un champ `status` convient à un prototype, mais ne suffit pas à
garantir un workflow. La cible doit exposer des actions métier telles que `confirmer`,
`annuler` ou `retourner`.

## Action métier

Une action métier est une commande explicite qui dépasse la mise à jour générique d'un
champ.

Elle doit préciser :

- son nom métier ;
- ses préconditions ;
- les états source et cible ;
- ses effets ;
- son résultat et ses erreurs ;
- son caractère idempotent ou non.

Dans React Admin, l'interface déclenche l'action via un client ou une extension typée du
DataProvider. `customAction` n'est pas une méthode standard du contrat `DataProvider` et ne
doit pas être utilisée sans déclaration TypeScript et implémentation explicites.

## Saga

Une Saga coordonne plusieurs transactions locales lorsque l'action traverse plusieurs
systèmes.

Elle définit :

- les étapes ;
- l'ordre ou les événements ;
- les compensations ;
- les reprises sur erreur ;
- la corrélation et la traçabilité ;
- les états observables par l'utilisateur.

Une Saga n'offre pas une transaction ACID globale. Elle vise une cohérence éventuelle et
des compensations explicites. Son orchestration appartient au backend ; le frontend ne fait
qu'initier l'action et afficher son avancement.

## Règle de décision

```text
Données stables et CRUD ?
└─ Catalogue

Cycle de vie avec transitions contrôlées ?
└─ Processus + actions métier

Action répartie sur plusieurs systèmes ?
└─ Processus + actions métier + Saga
```

## Passage du prototype à la cible

1. Valider la terminologie et l'UX avec FakeRest.
2. Formaliser les états, transitions et invariants.
3. Définir les contrats HTTP et les erreurs métier.
4. Implémenter les règles et orchestrations côté backend IBM i/API.
5. Remplacer le provider local sans déplacer la logique métier dans les composants React.
