import { DataTable, List, TextField, TextInput, ReferenceInput, AutocompleteInput } from '@/components/admin';

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
  <ReferenceInput
    source="client_id"
    reference="clients"
    sort={{ field: 'nom', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filter by client" label={false} />
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

export const TaskList = () => (
  <List filters={filters}>
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
        <TextField source="status" />
      </DataTable.Col>
      <DataTable.Col source="due_date">
        <TextField source="due_date" />
      </DataTable.Col>
    </DataTable>
  </List>
);