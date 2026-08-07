import { Create, SimpleForm } from '@/components/admin';
import { FournisseurFormFields } from './FournisseurFormFields';

export const FournisseurCreate = () => (
  <Create>
    <SimpleForm>
      <FournisseurFormFields />
    </SimpleForm>
  </Create>
);
