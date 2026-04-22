import { List } from '@/components/admin';
import { DataTable } from '@/components/admin/data-table';
import { TextField } from '@/components/admin/text-field';

export const CustomerList = () => (
  <List>
    <DataTable rowClick="show">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="name" label="Raison Sociale">
        <TextField source="name" />
      </DataTable.Col>
      <DataTable.Col source="type" label="Forme Juridique">
        <TextField source="type" />
      </DataTable.Col>
    </DataTable>
  </List>
);
