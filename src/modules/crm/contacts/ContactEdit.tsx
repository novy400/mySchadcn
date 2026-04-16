import { Edit, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const ContactEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="client_id" />
      <TextInput source="prenom" />
      <TextInput source="nom" />
      <TextInput source="email" />
      <TextInput source="telephone" />
    </SimpleForm>
  </Edit>
);
