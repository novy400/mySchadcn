import { Edit, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const NoteEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="contenu" multiline />
      <TextInput source="date" />
    </SimpleForm>
  </Edit>
);
