import { DataTable, List, TextField } from '@/components/admin';

export const ClientList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="code">
        <TextField source="code" />
      </DataTable.Col>
      <DataTable.Col source="nom">
        <TextField source="nom" />
      </DataTable.Col>
      <DataTable.Col source="ville">
        <TextField source="ville" />
      </DataTable.Col>
      <DataTable.Col source="statut">
        <TextField source="statut" />
      </DataTable.Col>
    </DataTable>
  </List>
);
