import { Edit, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const TaskEdit = () => (
  <Edit>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Edit>
);
