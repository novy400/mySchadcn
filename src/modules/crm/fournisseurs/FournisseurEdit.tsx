import { Edit, SimpleForm, type EditProps } from '@/components/admin';
import { FournisseurFormFields } from './FournisseurFormFields';

export const FournisseurEdit = (props: Pick<EditProps, 'id'>) => (
  <Edit {...props} actions={false} mutationMode="pessimistic">
    <SimpleForm>
      <FournisseurFormFields edit />
    </SimpleForm>
  </Edit>
);
