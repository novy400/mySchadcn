import { DataTable, EmailField, List, NumberField, TextField } from '@/components/admin';

export const ContactList = () => (
  <List>
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
