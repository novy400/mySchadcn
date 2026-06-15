import {
  AutocompleteInput,
  DataTable,
  EmailField,
  List,
  NumberField,
  ReferenceInput,
  TextField,
  TextInput,
} from '@/components/admin';
import { SelectInput } from '@/components/admin/select-input';

const filters = [
  <TextInput source="q" placeholder="Rechercher" label={false} alwaysOn />,
  <ReferenceInput source="client_id" reference="clients" sort={{ field: 'nom', order: 'ASC' }} alwaysOn>
    <AutocompleteInput placeholder="Filtrer par client" label={false} />
  </ReferenceInput>,
  <SelectInput
    source="client_status"
    choices={[
      { id: 'ACTIF', name: 'Actif' },
      { id: 'PROSPECT', name: 'Prospect' },
      { id: 'SUSPENDU', name: 'Suspendu' },
    ]}
    label="Statut client"
  />,
  <TextInput source="client_city" placeholder="Filtrer par ville" label="Ville" />,
];

export const ContactSummaryList = () => (
  <List resource="contacts_summary" filters={filters} sort={{ field: 'nom', order: 'ASC' }}>
    <DataTable rowClick={(_, __, record) => `/contacts/${record.id}`}>
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="prenom">
        <TextField source="prenom" />
      </DataTable.Col>
      <DataTable.Col source="nom">
        <TextField source="nom" />
      </DataTable.Col>
      <DataTable.Col source="email">
        <EmailField source="email" />
      </DataTable.Col>
      <DataTable.Col source="client_name" label="Client">
        <TextField source="client_name" />
      </DataTable.Col>
      <DataTable.Col source="client_city" label="Ville">
        <TextField source="client_city" />
      </DataTable.Col>
      <DataTable.Col source="open_tasks" label="Tâches ouvertes">
        <NumberField source="open_tasks" />
      </DataTable.Col>
      <DataTable.Col source="last_note_date" label="Dernière note">
        <TextField source="last_note_date" />
      </DataTable.Col>
    </DataTable>
  </List>
);
