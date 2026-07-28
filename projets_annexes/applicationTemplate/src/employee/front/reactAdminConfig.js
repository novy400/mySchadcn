/**
 * Configuration React-Admin pour l'API Employee
 * 
 * Exemple complet d'intégration avec React-Admin incluant tous les composants
 * nécessaires pour une application complète
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
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
  useRecordContext
} from 'react-admin';

import { createEmployeeDataProvider } from './employeeDataProvider.js';

// ===== CONFIGURATION DATA PROVIDER =====

const dataProvider = createEmployeeDataProvider({
  apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:44000/api',
  timeout: 30000
});

// ===== FILTRES =====

const EmployeeFilter = (props) => (
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

const CustomPagination = props => (
  <Pagination rowsPerPageOptions={[10, 25, 50, 100]} {...props} />
);

// ===== ACTIONS PERSONNALISÉES =====

const ListActions = () => (
  <TopToolbar>
    <FilterButton />
    <CreateButton />
    <ExportButton />
  </TopToolbar>
);

// ===== CHAMPS PERSONNALISÉS =====

const SalaryField = () => {
  const record = useRecordContext();
  return record ? (
    <span style={{ fontWeight: 'bold', color: record.salaire > 80000 ? 'green' : 'inherit' }}>
      {new Intl.NumberFormat('fr-FR', { 
        style: 'currency', 
        currency: 'EUR' 
      }).format(record.salaire)}
    </span>
  ) : null;
};

const FullNameField = () => {
  const record = useRecordContext();
  return record ? `${record.prenom} ${record.nom}` : '';
};

const ServiceNameField = () => {
  const record = useRecordContext();
  const serviceNames = {
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
  
  return record ? `${record.service} - ${serviceNames[record.service] || 'Inconnu'}` : '';
};

// ===== COMPOSANTS PRINCIPAUX =====

/**
 * Liste des employés avec fonctionnalités avancées
 */
export const EmployeeList = (props) => (
  <List 
    {...props}
    filters={<EmployeeFilter />}
    actions={<ListActions />}
    pagination={<CustomPagination />}
    perPage={25}
    sort={{ field: 'nom', order: 'ASC' }}
  >
    <Datagrid>
      <TextField source="id" label="ID" />
      <FunctionField 
        label="Nom complet" 
        render={FullNameField}
        sortBy="nom"
      />
      <TextField source="initiale" label="Init." />
      <FunctionField 
        label="Service" 
        render={ServiceNameField}
        sortBy="service"
      />
      <TextField source="genre" label="Genre" />
      <DateField source="dateEmbauche" label="Embauche" />
      <DateField source="dateNaissance" label="Naissance" />
      <FunctionField 
        label="Salaire" 
        render={SalaryField}
        sortBy="salaire"
      />
      <ShowButton />
      <EditButton />
      <DeleteButton />
    </Datagrid>
  </List>
);

/**
 * Formulaire de création d'employé
 */
export const EmployeeCreate = (props) => (
  <Create {...props}>
    <SimpleForm>
      <TextInput source="prenom" label="Prénom" required />
      <TextInput source="nom" label="Nom" required />
      <TextInput source="initiale" label="Initiale" maxLength={1} />
      <SelectInput 
        source="service" 
        label="Service" 
        choices={[
          { id: 'A00', name: 'A00 - Direction' },
          { id: 'B01', name: 'B01 - Planification' },
          { id: 'C01', name: 'C01 - Support Information' },
          { id: 'D01', name: 'D01 - Développement' },
          { id: 'D11', name: 'D11 - Systèmes' },
          { id: 'D21', name: 'D21 - Support Système' },
          { id: 'E01', name: 'E01 - Support' },
          { id: 'E11', name: 'E11 - Opérations' },
          { id: 'E21', name: 'E21 - Logiciel' }
        ]}
        required
      />
      <SelectInput 
        source="genre" 
        label="Genre" 
        choices={[
          { id: 'M', name: 'Masculin' },
          { id: 'F', name: 'Féminin' }
        ]}
        required
      />
      <DateInput source="dateNaissance" label="Date de naissance" required />
      <DateInput source="dateEmbauche" label="Date d'embauche" required />
      <NumberInput 
        source="salaire" 
        label="Salaire" 
        min={0} 
        step={100}
        format={v => v ? new Intl.NumberFormat('fr-FR').format(v) : ''}
        parse={v => v ? parseFloat(v.replace(/\s/g, '')) : ''}
      />
    </SimpleForm>
  </Create>
);

/**
 * Formulaire d'édition d'employé
 */
export const EmployeeEdit = (props) => (
  <Edit {...props}>
    <SimpleForm>
      <TextInput source="id" label="ID" disabled />
      <TextInput source="prenom" label="Prénom" required />
      <TextInput source="nom" label="Nom" required />
      <TextInput source="initiale" label="Initiale" maxLength={1} />
      <SelectInput 
        source="service" 
        label="Service" 
        choices={[
          { id: 'A00', name: 'A00 - Direction' },
          { id: 'B01', name: 'B01 - Planification' },
          { id: 'C01', name: 'C01 - Support Information' },
          { id: 'D01', name: 'D01 - Développement' },
          { id: 'D11', name: 'D11 - Systèmes' },
          { id: 'D21', name: 'D21 - Support Système' },
          { id: 'E01', name: 'E01 - Support' },
          { id: 'E11', name: 'E11 - Opérations' },
          { id: 'E21', name: 'E21 - Logiciel' }
        ]}
        required
      />
      <SelectInput 
        source="genre" 
        label="Genre" 
        choices={[
          { id: 'M', name: 'Masculin' },
          { id: 'F', name: 'Féminin' }
        ]}
        required
      />
      <DateInput source="dateNaissance" label="Date de naissance" required />
      <DateInput source="dateEmbauche" label="Date d'embauche" required />
      <NumberInput 
        source="salaire" 
        label="Salaire" 
        min={0} 
        step={100}
        format={v => v ? new Intl.NumberFormat('fr-FR').format(v) : ''}
        parse={v => v ? parseFloat(v.replace(/\s/g, '')) : ''}
      />
    </SimpleForm>
  </Edit>
);

/**
 * Vue détaillée d'un employé
 */
export const EmployeeShow = (props) => (
  <Show {...props}>
    <SimpleShowLayout>
      <TextField source="id" label="ID Employé" />
      <FunctionField 
        label="Nom complet" 
        render={FullNameField}
      />
      <TextField source="prenom" label="Prénom" />
      <TextField source="nom" label="Nom" />
      <TextField source="initiale" label="Initiale" />
      <FunctionField 
        label="Service" 
        render={ServiceNameField}
      />
      <TextField source="genre" label="Genre" />
      <DateField source="dateNaissance" label="Date de naissance" />
      <DateField source="dateEmbauche" label="Date d'embauche" />
      <FunctionField 
        label="Salaire" 
        render={SalaryField}
      />
      <FunctionField
        label="Ancienneté"
        render={({ dateEmbauche }) => {
          if (!dateEmbauche) return 'N/A';
          const hire = new Date(dateEmbauche);
          const now = new Date();
          const years = Math.floor((now - hire) / (365.25 * 24 * 60 * 60 * 1000));
          return `${years} ans`;
        }}
      />
    </SimpleShowLayout>
  </Show>
);

// ===== APPLICATION REACT-ADMIN =====

/**
 * Application React-Admin complète pour la gestion des employés
 */
export const EmployeeApp = () => (
  <Admin 
    dataProvider={dataProvider}
    title="Gestion des Employés - IBM i"
  >
    <Resource
      name="employees"
      list={EmployeeList}
      edit={EmployeeEdit}
      create={EmployeeCreate}
      show={EmployeeShow}
      options={{ label: 'Employés' }}
    />
  </Admin>
);

// ===== DASHBOARD PERSONNALISÉ =====

import { Card, CardContent, Typography, Grid } from '@mui/material';
import { useDataProvider } from 'react-admin';

const DashboardCard = ({ title, value, subtitle }) => (
  <Card>
    <CardContent>
      <Typography color="textSecondary" gutterBottom>
        {title}
      </Typography>
      <Typography variant="h5" component="h2">
        {value}
      </Typography>
      <Typography color="textSecondary">
        {subtitle}
      </Typography>
    </CardContent>
  </Card>
);

export const EmployeeDashboard = () => {
  const [stats, setStats] = React.useState({});
  const dataProvider = useDataProvider();

  React.useEffect(() => {
    const fetchStats = async () => {
      try {
        const { total } = await dataProvider.getList('employees', {
          pagination: { page: 1, perPage: 1 },
          sort: { field: 'id', order: 'ASC' },
          filter: {}
        });

        const { data: recentHires } = await dataProvider.getList('employees', {
          pagination: { page: 1, perPage: 5 },
          sort: { field: 'dateEmbauche', order: 'DESC' },
          filter: {}
        });

        setStats({
          totalEmployees: total,
          recentHires: recentHires.length
        });
      } catch (error) {
        console.error('Erreur récupération stats:', error);
      }
    };

    fetchStats();
  }, [dataProvider]);

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} sm={6} md={3}>
        <DashboardCard
          title="Total Employés"
          value={stats.totalEmployees || 0}
          subtitle="Dans la base de données"
        />
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <DashboardCard
          title="Embauches Récentes"
          value={stats.recentHires || 0}
          subtitle="Derniers employés ajoutés"
        />
      </Grid>
    </Grid>
  );
};

export default {
  EmployeeApp,
  EmployeeList,
  EmployeeCreate,
  EmployeeEdit,
  EmployeeShow,
  EmployeeDashboard
};