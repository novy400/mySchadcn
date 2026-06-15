import { List, TextInput } from '@/components/admin';
import { DataTable } from '@/components/admin/data-table';
import { TextField } from '@/components/admin/text-field';
import { SelectInput } from '@/components/admin/select-input';

const filters = [
  <TextInput source="q" placeholder="Rechercher un client" label={false} alwaysOn />,
  <SelectInput
    source="type"
    choices={[
      { id: 'SA', name: 'SA' },
      { id: 'Sarl', name: 'Sarl' },
    ]}
    label="Forme juridique"
  />,
];

export const CustomerList = () => (
  <List filters={filters} sort={{ field: 'name', order: 'ASC' }}>
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
