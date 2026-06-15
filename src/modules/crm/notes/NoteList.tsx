import {
  AutocompleteInput,
  DataTable,
  List,
  NumberField,
  ReferenceInput,
  TextField,
  TextInput,
} from '@/components/admin';

const filters = [
  <TextInput source="q" placeholder="Rechercher une note" label={false} alwaysOn />,
  <ReferenceInput source="contact_id" reference="contacts" sort={{ field: 'nom', order: 'ASC' }} alwaysOn>
    <AutocompleteInput placeholder="Filtrer par contact" label={false} />
  </ReferenceInput>,
  <TextInput source="date" placeholder="AAAA-MM-JJ" label="Date" />,
];

export const NoteList = () => (
  <List filters={filters} sort={{ field: 'date', order: 'DESC' }}>
    <DataTable rowClick="edit">
      <DataTable.Col source="id">
        <TextField source="id" />
      </DataTable.Col>
      <DataTable.Col source="contact_id">
        <NumberField source="contact_id" />
      </DataTable.Col>
      <DataTable.Col source="contenu">
        <TextField source="contenu" />
      </DataTable.Col>
      <DataTable.Col source="date">
        <TextField source="date" />
      </DataTable.Col>
    </DataTable>
  </List>
);
