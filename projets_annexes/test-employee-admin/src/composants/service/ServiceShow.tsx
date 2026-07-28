/* eslint-disable prettier/prettier */
import {
    Show,
    SimpleShowLayout,
    TextField,
    DateField,
    EditButton,
    TopToolbar,
} from 'react-admin';

const ServiceShowActions = () => (
    <TopToolbar>
        <EditButton />
    </TopToolbar>
);

export const ServiceShow = () => (
    <Show actions={<ServiceShowActions />}>
        <SimpleShowLayout>
            <TextField source="id" />
            <TextField source="nom" />
        </SimpleShowLayout>
    </Show>
);
