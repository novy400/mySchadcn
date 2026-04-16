import { Create, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const NoteCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="contenu" multiline />
      <TextInput source="date" />
    </SimpleForm>
  </Create>
);
