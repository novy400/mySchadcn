/* eslint-disable prettier/prettier */
import {
    Edit,
    SimpleForm,
    TextInput,
    required,
} from 'react-admin';

export const ServiceEdit = () => (
    <Edit>
        <SimpleForm>
            <TextInput source="id" disabled />
            <TextInput 
                source="nom" 
                validate={[required()]}
                fullWidth
            />
        </SimpleForm>
    </Edit>
);
