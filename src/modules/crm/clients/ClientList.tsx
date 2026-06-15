import { DataTable, List, TextField, TextInput } from '@/components/admin';
import { SelectInput } from '@/components/admin/select-input';

const filters = [
  <TextInput source="q" placeholder="Rechercher un client" label={false} alwaysOn />,
  <SelectInput
    source="statut"
    choices={[
      { id: 'ACTIF', name: 'Actif' },
      { id: 'PROSPECT', name: 'Prospect' },
      { id: 'SUSPENDU', name: 'Suspendu' },
    ]}
    label="Statut"
  />,
  <TextInput source="ville" placeholder="Filtrer par ville" label="Ville" />,
];

export const ClientList = () => (
  <List filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
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
