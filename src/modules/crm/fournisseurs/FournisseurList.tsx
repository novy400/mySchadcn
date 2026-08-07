import { DataTable, EmailField, List, TextField, TextInput } from '@/components/admin';
import type { Fournisseur } from './fournisseur.types';

const filters = [
  <TextInput source="q" placeholder="Rechercher un fournisseur" label={false} alwaysOn />,
  <TextInput source="ville" placeholder="Filtrer par ville" label="Ville" />,
];

export const FournisseurList = () => (
  <List<Fournisseur> filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
    <DataTable<Fournisseur> bulkActionButtons={false} rowClick="edit">
      <DataTable.Col<Fournisseur> source="id" disableSort>
        <TextField<Fournisseur> source="id" />
      </DataTable.Col>
      <DataTable.Col<Fournisseur> source="nom">
        <TextField<Fournisseur> source="nom" />
      </DataTable.Col>
      <DataTable.Col<Fournisseur> source="adresse" disableSort>
        <TextField<Fournisseur> source="adresse" />
      </DataTable.Col>
      <DataTable.Col<Fournisseur> source="ville" disableSort>
        <TextField<Fournisseur> source="ville" />
      </DataTable.Col>
      <DataTable.Col<Fournisseur> source="telephone" disableSort>
        <TextField<Fournisseur> source="telephone" />
      </DataTable.Col>
      <DataTable.Col<Fournisseur> source="email" disableSort>
        <EmailField<Fournisseur> source="email" />
      </DataTable.Col>
    </DataTable>
  </List>
);
