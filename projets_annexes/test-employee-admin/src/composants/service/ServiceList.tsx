/* eslint-disable prettier/prettier */
import { DataTable, List, TextInput, CreateButton,
    DatagridConfigurable,
    ExportButton,
    FilterButton,
    SelectColumnsButton,
    TopToolbar,EditButton} from 'react-admin';

const serviceFilters = [
    <TextInput source="q" label="Recherche" alwaysOn />,
    <TextInput source="nom" label="Nom" />,
];

const ListActions = () => (
    <TopToolbar>
        <SelectColumnsButton />
        <FilterButton/>
        <CreateButton/>
        <ExportButton/>
    </TopToolbar>
);

export const ServiceList = () => (
    <List filters={serviceFilters} actions={<ListActions/>}>
        <DataTable>
            <DataTable.Col source="id" />
            <DataTable.Col source="nom" />
            <DataTable.Col>
                <EditButton />
            </DataTable.Col>
        </DataTable>
    </List>
);
