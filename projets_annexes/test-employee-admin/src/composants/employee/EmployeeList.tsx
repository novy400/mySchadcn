/* eslint-disable prettier/prettier */
import { DataTable, List, TextInput, CreateButton,
    DatagridConfigurable,
    ExportButton,
    FilterButton,
    SelectColumnsButton,
    TopToolbar,EditButton, ReferenceField} from 'react-admin';
const employeeFilters = [
    <TextInput source="q" label="Recherche" alwaysOn />,
    <TextInput source="prenom" label="Prénom" />,
    <TextInput source="nom" label="Nom" />,
    <TextInput source="initiale" label="Initiales" />,
    <TextInput source="idService" label="Service" />,
];
const ListActions = () => (
    <TopToolbar>
        <SelectColumnsButton />
        <FilterButton/>
        <CreateButton/>
        <ExportButton/>
    </TopToolbar>
);

export const EmployeeList = () => (
      <List filters={employeeFilters} actions={<ListActions/>}>
        <DataTable>
            <DataTable.Col source="id" />
            <DataTable.Col source="prenom" />
            <DataTable.Col source="nom" />
            <DataTable.Col source="initiale" />
            <DataTable.Col source="idService" />
           <DataTable.Col source="idService">
                <ReferenceField source="idService" reference="services" />
            </DataTable.Col>    
            <DataTable.Col>
                <EditButton />
            </DataTable.Col>
        </DataTable>
    </List>
);