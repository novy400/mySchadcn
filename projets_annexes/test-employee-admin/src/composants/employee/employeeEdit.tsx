/* eslint-disable prettier/prettier */
import { DateInput, Edit, NumberInput, SimpleForm, TextInput } from 'react-admin';

export const EmployeeEdit = () => (
    <Edit 
        mutationMode="pessimistic"  // <--- INDISPENSABLE pour la validation serveur
    >
        <SimpleForm>
            <TextInput source="id" />
            <TextInput source="prenom" />
            <TextInput source="nom" />
            <TextInput source="initiale" />
            <TextInput source="idService" />
            <DateInput source="dateEmbauche" />
            <DateInput source="dateNaissance" />
            <TextInput source="genre" />
            <NumberInput source="salaire" />
        </SimpleForm>
    </Edit>
);