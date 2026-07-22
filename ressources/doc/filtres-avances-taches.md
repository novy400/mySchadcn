# Filtres avancés pour les tâches

_État vérifié le 2026-07-22._

## Implémentation actuelle

Les filtres avancés ont été implémentés pour la ressource "tasks" avec les filtres suivants :

1. **Recherche texte** (q) : Permet de rechercher dans tous les champs de la tâche
2. **Filtre par contact** : Utilisation de ReferenceInput avec AutocompleteInput pour filtrer par contact
3. **Filtre par statut** : Utilisation d'AutocompleteInput avec choix prédéfinis (OPEN/DONE)

## Code implémenté

```jsx
const filters = [
  <TextInput source="q" placeholder="Search" label={false} alwaysOn />,
  <ReferenceInput
    source="contact_id"
    reference="contacts"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filter by contact" label={false} />
  </ReferenceInput>,
  <AutocompleteInput
    source="status"
    placeholder="Filter by status"
    choices={[
      { id: 'OPEN', name: 'Open' },
      { id: 'DONE', name: 'Done' },
    ]}
    label={false}
    alwaysOn
  />,
];
```

## État actuel vérifié

Le filtre par client a depuis été ajouté. La liste s'appuie sur la ressource enrichie
`tasks_with_client`, qui expose `client_id`, `client_name` et `contact_name` en plus des
champs de la tâche.

Les quatre filtres actifs sont donc :

1. recherche textuelle ;
2. contact ;
3. client ;
4. statut.

Exemple d'implémentation étendue :

```jsx
const filters = [
  <TextInput source="q" placeholder="Search" label={false} alwaysOn />,
  <ReferenceInput
    source="client_id"
    reference="clients"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filter by client" label={false} />
  </ReferenceInput>,
  <ReferenceInput
    source="contact_id"
    reference="contacts"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filter by contact" label={false} />
  </ReferenceInput>,
  <AutocompleteInput
    source="status"
    placeholder="Filter by status"
    choices={[
      { id: 'OPEN', name: 'Open' },
      { id: 'DONE', name: 'Done' },
    ]}
    label={false}
    alwaysOn
  />,
];
```

## Points de vigilance

- `tasks_with_client` est calculée au chargement puis resynchronisée par le DataProvider
  après une mutation de ses sources FakeRest ;
- le filtre client dépend de cette projection et non d'un champ de la tâche brute ;
- une future API devra gérer `q`, `contact_id`, `client_id`, `status`, le tri et la
  pagination avec les mêmes contrats ;
- la sauvegarde des requêtes filtrées relève du composant `SavedQueries` et doit être
  testée séparément de la définition des filtres.

## Ressources

- Exemple de référence : https://marmelab.com/shadcn-admin-kit/demo/#/reviews

## Captures de travail

- [Référence : filtre avec autocomplétion](./image/filtres-avances-taches/reference-filter-autocomplete.png)
- [Menu des requêtes sauvegardées](./image/filtres-avances-taches/saved-query-menu.png)
- [Dialogue de sauvegarde](./image/filtres-avances-taches/saved-query-dialog.png)
- [Suppression d'une requête sauvegardée](./image/filtres-avances-taches/remove-saved-query.png)

Les captures suivantes documentent des erreurs rencontrées pendant l'exploration. Elles
ne constituent pas des exemples de code valide :

- [Erreur de typage sur la liste](./image/filtres-avances-taches/typescript-error-list-sort.png)
- [Erreurs de typage sur les filtres](./image/filtres-avances-taches/typescript-error-filter-components.png)
- Documentation shadcn-admin-kit pour les filtres
