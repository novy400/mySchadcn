import { DataTable, EmailField, List, NumberField, TextField } from '@/components/admin';

export const ContactSummaryList = () => (
  <List resource="contacts_summary">
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
