import { email, maxLength, required } from 'ra-core';

import { TextInput } from '@/components/admin';

const idValidators = [required(), maxLength(10)];
const nomValidators = [required(), maxLength(100)];
const adresseValidators = [maxLength(160)];
const villeValidators = [maxLength(80)];
const telephoneValidators = [maxLength(20)];
const emailValidators = [maxLength(254), email()];

export const FournisseurFormFields = ({ edit = false }: { edit?: boolean }) => (
  <>
    <TextInput source="id" disabled={edit} validate={idValidators} />
    <TextInput source="nom" validate={nomValidators} />
    <TextInput source="adresse" validate={adresseValidators} />
    <TextInput source="ville" validate={villeValidators} />
    <TextInput
      source="telephone"
      validate={telephoneValidators}
    />
    <TextInput source="email" validate={emailValidators} />
  </>
);
