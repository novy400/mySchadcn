# **Filtres avancés pour les tâches**

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

## Améliorations possibles

Pour une implémentation encore plus complète, on pourrait ajouter :

1. **Filtre par client** : Utilisation de ReferenceInput avec AutocompleteInput

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

## Ressources

- Exemple de référence : https://marmelab.com/shadcn-admin-kit/demo/#/reviews
- Documentation shadcn-admin-kit pour les filtres