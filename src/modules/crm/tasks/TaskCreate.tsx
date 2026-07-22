import { Create, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const TaskCreate = () => (
  <Create resource="tasks" redirect="/tasks_with_client">
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Create>
);
