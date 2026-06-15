import { DataTable, EmailField, List, TextField, TextInput } from '@/components/admin';

const filters = [
  <TextInput source="q" placeholder="Rechercher un fournisseur" label={false} alwaysOn />,
  <TextInput source="ville" placeholder="Filtrer par ville" label="Ville" />,
];

export const FournisseurList = () => (
  <List filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
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
