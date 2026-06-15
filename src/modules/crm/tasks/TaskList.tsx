import { DataTable, List, NumberField, TextField, TextInput } from '@/components/admin';

const filters = [
  <TextInput source="q" placeholder="Search" label={false} alwaysOn />,
  <TextInput source="status" placeholder="Filter by status" label={false} alwaysOn />,
];

export const TaskList = () => (
  <List filters={filters}>
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
