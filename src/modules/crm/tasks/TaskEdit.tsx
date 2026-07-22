import { Edit, NumberInput, SimpleForm, TextInput } from '@/components/admin';

export const TaskEdit = () => (
  <Edit resource="tasks" redirect="/tasks_with_client">
    <SimpleForm>
      <NumberInput source="contact_id" />
      <TextInput source="titre" />
      <TextInput source="status" />
      <TextInput source="due_date" />
    </SimpleForm>
  </Edit>
);
