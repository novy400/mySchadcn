import { Create, SimpleForm, TextInput } from '@/components/admin';

export const ClientCreate = () => (
  <Create>
    <SimpleForm>
      <TextInput source="code" />
      <TextInput source="nom" />
      <TextInput source="ville" />
      <TextInput source="statut" />
    </SimpleForm>
  </Create>
);
