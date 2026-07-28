/**
 * Configuration React-Admin pour l'API Employee - TypeScript
 * 
 * Exemple complet d'intégration avec React-Admin incluant tous les composants
 * nécessaires pour une application complète avec TypeScript
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

import React from 'react';
import {
  Admin,
  Resource,
  List,
  Edit,
  Create,
  Show,
  Datagrid,
  TextField,
  NumberField,
  DateField,
  EditButton,
  ShowButton,
  DeleteButton,
  SimpleForm,
  TextInput,
  NumberInput,
  DateInput,
  SelectInput,
  SimpleShowLayout,
  Filter,
  SearchInput,
  ReferenceInput,
  AutocompleteInput,
  TopToolbar,
  ExportButton,
  FilterButton,
  CreateButton,
  Pagination,
  BooleanField,
  FunctionField,
  useRecordContext,
  DataProvider,
  FilterProps,
  ListProps,
  CreateProps,
  EditProps,
  ShowProps,
  Record,
  RaRecord
} from 'react-admin';

import { createEmployeeDataProvider } from './employeeDataProvider';
import { Employee } from './types';

// ===== CONFIGURATION DATA PROVIDER =====

const dataProvider: DataProvider = createEmployeeDataProvider({
  apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:44000/api',
  timeout: 30000
}) as DataProvider;

// ===== TYPES REACT-ADMIN =====

interface EmployeeRecord extends RaRecord, Employee {}

// ===== FILTRES =====

const EmployeeFilter: React.FC<FilterProps> = (props) => (
  <Filter {...props}>
    <SearchInput source="q" alwaysOn placeholder="Recherche globale" />
    <TextInput label="Nom" source="nom" />
    <TextInput label="Prénom" source="prenom" />
    <SelectInput 
      label="Service" 
      source="service" 
      choices={[
        { id: 'A00', name: 'Direction' },
        { id: 'B01', name: 'Planification' },
        { id: 'C01', name: 'Support Information' },
        { id: 'D01', name: 'Développement' },
        { id: 'D11', name: 'Systèmes' },
        { id: 'D21', name: 'Support Système' },
        { id: 'E01', name: 'Support' },
        { id: 'E11', name: 'Opérations' },
        { id: 'E21', name: 'Logiciel' }
      ]}
    />
    <SelectInput 
      label="Genre" 
      source="genre" 
      choices={[
        { id: 'M', name: 'Masculin' },
        { id: 'F', name: 'Féminin' }
      ]}
    />
    <NumberInput label="Salaire minimum" source="salaire_gte" />
    <NumberInput label="Salaire maximum" source="salaire_lte" />
    <DateInput label="Embauché après" source="dateEmbauche_gte" />
    <DateInput label="Embauché avant" source="dateEmbauche_lte" />
  </Filter>
);

// ===== PAGINATION PERSONNALISÉE =====

const CustomPagination: React.FC<any> = (props) => (
  <Pagination rowsPerPageOptions={[10, 25, 50, 100]} {...props} />
);

// ===== ACTIONS PERSONNALISÉES =====

const ListActions: React.FC = () => (
  <TopToolbar>
    <FilterButton />
    <CreateButton />
    <ExportButton />
  </TopToolbar>
);

// ===== CHAMPS PERSONNALISÉS =====

const FullNameField: React.FC<{ source?: string }> = ({ source = 'fullName' }) => {
  const record = useRecordContext<EmployeeRecord>();
  if (!record) return null;
  
  return (
    <span>{record.prenom} {record.nom}</span>
  );
};

FullNameField.defaultProps = { source: 'fullName' };

const SalaryField: React.FC<{ source?: string }> = ({ source = 'salaire' }) => {
  const record = useRecordContext<EmployeeRecord>();
  if (!record) return null;
  
  const formatSalary = (value: number): string => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(value);
  };
  
  return <span>{formatSalary(record.salaire)}</span>;
};

const AgeField: React.FC<{ source?: string }> = ({ source = 'age' }) => {
  const record = useRecordContext<EmployeeRecord>();
  if (!record || !record.dateNaissance) return null;
  
  const calculateAge = (birthDate: string): number => {
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    
    return age;
  };
  
  return <span>{calculateAge(record.dateNaissance)} ans</span>;
};

const ServiceField: React.FC<{ source?: string }> = ({ source = 'service' }) => {
  const record = useRecordContext<EmployeeRecord>();
  if (!record) return null;
  
  const serviceLabels: Record<string, string> = {
    'A00': 'Direction',
    'B01': 'Planification', 
    'C01': 'Support Information',
    'D01': 'Développement',
    'D11': 'Systèmes',
    'D21': 'Support Système',
    'E01': 'Support',
    'E11': 'Opérations',
    'E21': 'Logiciel'
  };
  
  return <span>{serviceLabels[record.service] || record.service}</span>;
};

// ===== COMPOSANTS LISTE =====

export const EmployeeList: React.FC<ListProps> = (props) => (
  <List
    {...props}
    filters={<EmployeeFilter />}
    actions={<ListActions />}
    pagination={<CustomPagination />}
    perPage={25}
    sort={{ field: 'nom', order: 'ASC' }}
    title="Liste des Employés"
  >
    <Datagrid
      rowClick="show"
      bulkActionButtons={false}
      sx={{
        '& .column-id': { width: 80 },
        '& .column-service': { width: 120 },
        '& .column-salaire': { width: 120, textAlign: 'right' },
        '& .column-dateEmbauche': { width: 130 },
        '& .column-actions': { width: 120 }
      }}
    >
      <TextField source="id" label="ID" />
      <FullNameField source="fullName" label="Nom complet" />
      <ServiceField source="service" label="Service" />
      <SalaryField source="salaire" label="Salaire" />
      <DateField source="dateEmbauche" label="Date embauche" locales="fr-FR" />
      <AgeField source="age" label="Âge" />
      <TextField source="genre" label="Genre" />
      <ShowButton />
      <EditButton />
      <DeleteButton />
    </Datagrid>
  </List>
);

// ===== COMPOSANTS CRÉATION =====

export const EmployeeCreate: React.FC<CreateProps> = (props) => (
  <Create {...props} title="Créer un Employé">
    <SimpleForm>
      <TextInput source="prenom" label="Prénom" validate={required()} />
      <TextInput source="nom" label="Nom" validate={required()} />
      <TextInput source="initiale" label="Initiale" />
      <SelectInput 
        source="service" 
        label="Service" 
        validate={required()}
        choices={[
          { id: 'A00', name: 'Direction' },
          { id: 'B01', name: 'Planification' },
          { id: 'C01', name: 'Support Information' },
          { id: 'D01', name: 'Développement' },
          { id: 'D11', name: 'Systèmes' },
          { id: 'D21', name: 'Support Système' },
          { id: 'E01', name: 'Support' },
          { id: 'E11', name: 'Opérations' },
          { id: 'E21', name: 'Logiciel' }
        ]}
      />
      <DateInput source="dateEmbauche" label="Date embauche" validate={required()} />
      <DateInput source="dateNaissance" label="Date naissance" validate={required()} />
      <SelectInput 
        source="genre" 
        label="Genre" 
        validate={required()}
        choices={[
          { id: 'M', name: 'Masculin' },
          { id: 'F', name: 'Féminin' }
        ]}
      />
      <NumberInput source="salaire" label="Salaire" validate={[required(), minValue(0)]} />
    </SimpleForm>
  </Create>
);

// ===== COMPOSANTS ÉDITION =====

export const EmployeeEdit: React.FC<EditProps> = (props) => (
  <Edit {...props} title={<EmployeeTitle />}>
    <SimpleForm>
      <TextInput source="id" label="ID" disabled />
      <TextInput source="prenom" label="Prénom" validate={required()} />
      <TextInput source="nom" label="Nom" validate={required()} />
      <TextInput source="initiale" label="Initiale" />
      <SelectInput 
        source="service" 
        label="Service" 
        validate={required()}
        choices={[
          { id: 'A00', name: 'Direction' },
          { id: 'B01', name: 'Planification' },
          { id: 'C01', name: 'Support Information' },
          { id: 'D01', name: 'Développement' },
          { id: 'D11', name: 'Systèmes' },
          { id: 'D21', name: 'Support Système' },
          { id: 'E01', name: 'Support' },
          { id: 'E11', name: 'Opérations' },
          { id: 'E21', name: 'Logiciel' }
        ]}
      />
      <DateInput source="dateEmbauche" label="Date embauche" validate={required()} />
      <DateInput source="dateNaissance" label="Date naissance" validate={required()} />
      <SelectInput 
        source="genre" 
        label="Genre" 
        validate={required()}
        choices={[
          { id: 'M', name: 'Masculin' },
          { id: 'F', name: 'Féminin' }
        ]}
      />
      <NumberInput source="salaire" label="Salaire" validate={[required(), minValue(0)]} />
    </SimpleForm>
  </Edit>
);

// ===== TITRE DYNAMIQUE =====

const EmployeeTitle: React.FC = () => {
  const record = useRecordContext<EmployeeRecord>();
  return record ? <span>Employé {record.prenom} {record.nom}</span> : null;
};

// ===== COMPOSANTS AFFICHAGE =====

export const EmployeeShow: React.FC<ShowProps> = (props) => (
  <Show {...props} title={<EmployeeTitle />}>
    <SimpleShowLayout>
      <TextField source="id" label="ID" />
      <FullNameField source="fullName" label="Nom complet" />
      <TextField source="prenom" label="Prénom" />
      <TextField source="nom" label="Nom" />
      <TextField source="initiale" label="Initiale" />
      <ServiceField source="service" label="Service" />
      <DateField source="dateEmbauche" label="Date embauche" locales="fr-FR" />
      <DateField source="dateNaissance" label="Date naissance" locales="fr-FR" />
      <AgeField source="age" label="Âge" />
      <TextField source="genre" label="Genre" />
      <SalaryField source="salaire" label="Salaire" />
      <FunctionField 
        label="Ancienneté"
        render={(record: EmployeeRecord) => {
          if (!record.dateEmbauche) return 'N/A';
          
          const now = new Date();
          const hire = new Date(record.dateEmbauche);
          const years = now.getFullYear() - hire.getFullYear();
          const months = now.getMonth() - hire.getMonth();
          
          let anciennete = years;
          if (months < 0) anciennete--;
          
          return `${anciennete} an${anciennete > 1 ? 's' : ''}`;
        }}
      />
    </SimpleShowLayout>
  </Show>
);

// ===== VALIDATION =====

import { required, minValue } from 'react-admin';

// ===== THEME PERSONNALISÉ =====

const theme = {
  palette: {
    mode: 'light' as const,
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none' as const,
        },
      },
    },
  },
};

// ===== APPLICATION PRINCIPALE =====

const App: React.FC = () => (
  <Admin
    dataProvider={dataProvider}
    theme={theme}
    title="Gestion des Employés - IBM i"
  >
    <Resource
      name="employees"
      list={EmployeeList}
      create={EmployeeCreate}
      edit={EmployeeEdit}
      show={EmployeeShow}
      options={{ label: 'Employés' }}
    />
  </Admin>
);

export default App;

// ===== EXPORTS POUR USAGE MODULAIRE =====

export {
  dataProvider,
  EmployeeFilter,
  CustomPagination,
  ListActions,
  FullNameField,
  SalaryField,
  AgeField,
  ServiceField,
  EmployeeTitle,
  theme
};

// ===== CONFIGURATION AVANCÉE =====

/**
 * Configuration pour intégration avec authentification
 */
export const createAuthenticatedApp = (authProvider: any, i18nProvider?: any): React.FC => {
  return () => (
    <Admin
      dataProvider={dataProvider}
      authProvider={authProvider}
      i18nProvider={i18nProvider}
      theme={theme}
      title="Gestion des Employés - IBM i"
    >
      <Resource
        name="employees"
        list={EmployeeList}
        create={EmployeeCreate}
        edit={EmployeeEdit}
        show={EmployeeShow}
        options={{ label: 'Employés' }}
      />
    </Admin>
  );
};

/**
 * Configuration pour environnement de développement
 */
export const DevApp: React.FC = () => (
  <Admin
    dataProvider={dataProvider}
    theme={theme}
    title="[DEV] Gestion des Employés - IBM i"
  >
    <Resource
      name="employees"
      list={EmployeeList}
      create={EmployeeCreate}
      edit={EmployeeEdit}
      show={EmployeeShow}
      options={{ label: 'Employés' }}
    />
  </Admin>
);

/**
 * Hooks personnalisés pour les employés
 */
export const useEmployeeActions = () => {
  // Ici on pourrait ajouter des hooks personnalisés
  // pour les actions spécifiques aux employés
  return {
    promoteEmployee: (id: string) => {
      // Logique de promotion
      console.log(`Promoting employee ${id}`);
    },
    
    archiveEmployee: (id: string) => {
      // Logique d'archivage
      console.log(`Archiving employee ${id}`);
    }
  };
};