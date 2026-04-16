import { DataTable, List, NumberField, TextField } from '@/components/admin';

export const NoteList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="contact_id">
        <NumberField source="contact_id" />
      </DataTable.Col>
      <DataTable.Col source="contenu">
        <TextField source="contenu" />
      </DataTable.Col>
      <DataTable.Col source="date">
        <TextField source="date" />
      </DataTable.Col>
    </DataTable>
  </List>
);
