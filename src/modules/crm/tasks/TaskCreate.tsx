import { Create, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const TaskCreate = () => (
  <Create>
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Create>
);
