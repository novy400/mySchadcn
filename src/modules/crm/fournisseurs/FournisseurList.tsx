import { DataTable, EmailField, List, TextField } from '@/components/admin';

export const FournisseurList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="nom">
        <TextField source="nom" />
      </DataTable.Col>
      <DataTable.Col source="adresse">
        <TextField source="adresse" />
      </DataTable.Col>
      <DataTable.Col source="ville">
        <TextField source="ville" />
      </DataTable.Col>
      <DataTable.Col source="telephone">
        <TextField source="telephone" />
      </DataTable.Col>
      <DataTable.Col source="email">
        <EmailField source="email" />
      </DataTable.Col>
    </DataTable>
  </List>
);
