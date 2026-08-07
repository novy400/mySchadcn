import { DataTable, List, TextField, TextInput } from '@/components/admin';

import type { ServiceRecord } from './service.types';

const filters = [
  <TextInput source="q" placeholder="Rechercher un service IBM i" label={false} alwaysOn />,
  <TextInput source="id" label="Identifiant" />,
  <TextInput source="nom" label="Nom" />,
  <TextInput source="idManageur" label="Identifiant manager" />,
  <TextInput source="idServiceAdmin" label="Service administratif" />,
  <TextInput source="site" label="Site" />,
];

export const ServiceList = () => (
  <List<ServiceRecord> filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
    <DataTable<ServiceRecord> bulkActionButtons={false} rowClick="show">
      <DataTable.Col<ServiceRecord> source="id" label="Identifiant">
        <TextField<ServiceRecord> source="id" />
      </DataTable.Col>
      <DataTable.Col<ServiceRecord> source="nom" label="Nom">
        <TextField<ServiceRecord> source="nom" />
      </DataTable.Col>
      <DataTable.Col<ServiceRecord> source="idManageur" label="Identifiant manager" disableSort>
        <TextField<ServiceRecord> source="idManageur" />
      </DataTable.Col>
      <DataTable.Col<ServiceRecord> source="idServiceAdmin" label="Service administratif" disableSort>
        <TextField<ServiceRecord> source="idServiceAdmin" />
      </DataTable.Col>
      <DataTable.Col<ServiceRecord> source="site" label="Site" disableSort>
        <TextField<ServiceRecord> source="site" />
      </DataTable.Col>
    </DataTable>
  </List>
);
