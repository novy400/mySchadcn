import { AutocompleteInput, DataTable, List, ReferenceInput, TextField, TextInput } from '@/components/admin';
import { BadgeField } from '@/components/admin/badge-field';

const filters = [
  <TextInput source="q" placeholder="Rechercher une tâche" label={false} alwaysOn />,
  <ReferenceInput
    source="contact_id"
    reference="contacts"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filtrer par contact" label={false} />
  </ReferenceInput>,
  <ReferenceInput
    source="client_id"
    reference="clients"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filtrer par client" label={false} />
  </ReferenceInput>,
  <AutocompleteInput
    source="status"
    placeholder="Filtrer par statut"
    choices={[
      { id: 'OPEN', name: 'Ouverte' },
      { id: 'DONE', name: 'Terminée' },
    ]}
    label={false}
    alwaysOn
  />,
];

export const TaskList = () => (
  <List filters={filters} sort={{ field: 'due_date', order: 'ASC' }}>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="contact_name">
        <TextField source="contact_name" />
      </DataTable.Col>
      <DataTable.Col source="client_name">
        <TextField source="client_name" />
      </DataTable.Col>
      <DataTable.Col source="titre">
        <TextField source="titre" />
      </DataTable.Col>
      <DataTable.Col source="status">
        <BadgeField source="status" variant="outline" />
      </DataTable.Col>
      <DataTable.Col source="due_date">
        <TextField source="due_date" />
      </DataTable.Col>
    </DataTable>
  </List>
);