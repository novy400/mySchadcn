/* eslint-disable prettier/prettier */
import { Show, SimpleShowLayout, TextField } from 'react-admin';

export const EmployeeShow = () => (
    <Show>
        <SimpleShowLayout>
            <TextField source="id" />
            <TextField source="prenom" />
            <TextField source="nom" />
            <TextField source="initiale" />
            <TextField source="idService" />
        </SimpleShowLayout>
    </Show>
);