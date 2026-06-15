import {
  AutocompleteInput,
  DataTable,
  EmailField,
  List,
  NumberField,
  ReferenceInput,
  TextField,
  TextInput,
} from '@/components/admin';

const filters = [
  <TextInput source="q" placeholder="Rechercher un contact" label={false} alwaysOn />,
  <ReferenceInput source="client_id" reference="clients" sort={{ field: 'nom', order: 'ASC' }} alwaysOn>
    <AutocompleteInput placeholder="Filtrer par client" label={false} />
  </ReferenceInput>,
  <TextInput source="email" placeholder="Filtrer par email" label="Email" />,
];

export const ContactList = () => (
  <List filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="client_id">
        <NumberField source="client_id" />
      </DataTable.Col>
      <DataTable.Col source="prenom">
        <TextField source="prenom" />
      </DataTable.Col>
      <DataTable.Col source="nom">
        <TextField source="nom" />
      </DataTable.Col>
      <DataTable.Col source="email">
        <EmailField source="email" />
      </DataTable.Col>
      <DataTable.Col source="telephone">
        <TextField source="telephone" />
      </DataTable.Col>
    </DataTable>
  </List>
);
