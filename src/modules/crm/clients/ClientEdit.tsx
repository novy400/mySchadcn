import { Edit, SimpleForm, TextInput } from '@/components/admin';

export const ClientEdit = () => (
  <Edit>
    <SimpleForm>
      <TextInput source="code" />
      <TextInput source="nom" />
      <TextInput source="ville" />
      <TextInput source="statut" />
    </SimpleForm>
  </Edit>
);
