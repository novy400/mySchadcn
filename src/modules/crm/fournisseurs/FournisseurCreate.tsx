import { Create, SimpleForm, TextInput } from '@/components/admin';

export const FournisseurCreate = () => (
  <Create>
    <SimpleForm>
      <TextInput source="nom" />
      <TextInput source="adresse" />
      <TextInput source="ville" />
      <TextInput source="telephone" />
      <TextInput source="email" />
    </SimpleForm>
  </Create>
);
