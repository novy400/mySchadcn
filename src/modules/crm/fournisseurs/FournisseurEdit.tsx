import { Edit, SimpleForm, TextInput } from '@/components/admin';

export const FournisseurEdit = () => (
  <Edit>
    <SimpleForm>
      <TextInput source="nom" />
      <TextInput source="adresse" />
      <TextInput source="ville" />
      <TextInput source="telephone" />
      <TextInput source="email" />
    </SimpleForm>
  </Edit>
);
