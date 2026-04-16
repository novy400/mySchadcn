import { DataTable, List, NumberField, TextField } from '@/components/admin';

export const TaskList = () => (
  <List>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="contact_id">
        <NumberField source="contact_id" />
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
