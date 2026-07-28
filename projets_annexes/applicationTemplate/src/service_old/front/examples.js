/**
 * Exemples d'utilisation du Data Provider et API Client Employee
 * 
 * Ce fichier contient des exemples pratiques d'utilisation du data provider
 * et du client API pour l'API Employee IBM i
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
 */

import { employeeDataProvider, createEmployeeDataProvider } from './employeeDataProvider.js';
import { EmployeeApiClient, employeeApi, EmployeeFilters, EmployeeSorts } from './employeeApiClient.js';

// ===== EXEMPLES REACT-ADMIN DATA PROVIDER =====

/**
 * Exemple 1: Utilisation basique avec React-Admin
 */
export const reactAdminExamples = {
  
  // Configuration du data provider pour React-Admin
  setupDataProvider: () => {
    const dataProvider = createEmployeeDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      timeout: 30000
    });
    
    return dataProvider;
  },

  // Exemple d'utilisation dans un composant React-Admin
  listComponent: `
    import React from 'react';
    import { List, Datagrid, TextField, NumberField, DateField } from 'react-admin';

    export const EmployeeList = (props) => (
      <List {...props}>
        <Datagrid>
          <TextField source="id" />
          <TextField source="prenom" label="Prénom" />
          <TextField source="nom" label="Nom" />
          <TextField source="service" label="Service" />
          <NumberField source="salaire" label="Salaire" />
          <DateField source="dateEmbauche" label="Date embauche" />
        </Datagrid>
      </List>
    );
  `,

  // Recherche avancée avec React-Admin
  advancedSearch: async (dataProvider) => {
    const result = await dataProvider.getList('employees', {
      pagination: { page: 1, perPage: 20 },
      sort: { field: 'nom', order: 'ASC' },
      filter: { 
        q: 'john',
        service: 'IT'
      },
      advancedFilters: [
        { field: 'salaire', operator: 'gte', value: 50000 }
      ],
      multiSort: [
        { field: 'nom', order: 'ASC' },
        { field: 'dateEmbauche', order: 'DESC' }
      ]
    });
    
    console.log('Résultats:', result.data);
    console.log('Total:', result.total);
    
    return result;
  }
};

// ===== EXEMPLES API CLIENT STANDALONE =====

/**
 * Exemple 2: Utilisation du client API standalone
 */
export const apiClientExamples = {

  // Configuration personnalisée du client
  setupCustomClient: () => {
    const client = new EmployeeApiClient({
      baseUrl: 'http://your-ibmi-server:44000/api',
      timeout: 60000,
      headers: {
        'Authorization': 'Bearer your-token',
        'X-Client-Version': '1.0'
      }
    });
    
    return client;
  },

  // Récupération simple d'employés
  basicUsage: async () => {
    try {
      // Liste avec pagination
      const employees = await employeeApi.getEmployees({
        page: 1,
        limit: 10,
        sort: 'nom',
        order: 'ASC'
      });
      
      console.log('Employés:', employees.data);
      console.log('Total:', employees.total);
      
      // Récupérer un employé spécifique
      const employee = await employeeApi.getEmployee('000010');
      console.log('Employé:', employee);
      
      return { employees, employee };
    } catch (error) {
      console.error('Erreur:', error.message);
    }
  },

  // Recherche avec filtres
  searchWithFilters: async () => {
    try {
      const results = await employeeApi.searchEmployees({
        query: 'smith',
        filters: [
          EmployeeFilters.byDepartment('IT'),
          EmployeeFilters.bySalaryMin(50000),
          EmployeeFilters.byGender('M')
        ],
        sorts: [
          EmployeeSorts.byName('ASC'),
          EmployeeSorts.byHireDate('DESC')
        ],
        page: 1,
        limit: 20
      });
      
      console.log('Résultats recherche:', results);
      return results;
    } catch (error) {
      console.error('Erreur recherche:', error.message);
    }
  },

  // Opérations CRUD
  crudOperations: async () => {
    try {
      // Créer un employé
      const newEmployee = await employeeApi.createEmployee({
        prenom: 'Jean',
        nom: 'Dupont',
        initiale: 'J',
        service: 'IT',
        dateEmbauche: '2025-01-15',
        dateNaissance: '1990-05-20',
        genre: 'M',
        salaire: 55000.00
      });
      console.log('Employé créé:', newEmployee);
      
      // Mettre à jour l'employé
      const updatedEmployee = await employeeApi.updateEmployee(newEmployee.id, {
        ...newEmployee,
        salaire: 60000.00
      });
      console.log('Employé mis à jour:', updatedEmployee);
      
      // Supprimer l'employé
      await employeeApi.deleteEmployee(newEmployee.id);
      console.log('Employé supprimé');
      
    } catch (error) {
      console.error('Erreur CRUD:', error.message);
    }
  }
};

// ===== EXEMPLES AVANCÉS =====

/**
 * Exemple 3: Recherches spécialisées
 */
export const advancedSearchExamples = {

  // Employés par département
  getITEmployees: async () => {
    return await employeeApi.getEmployeesByDepartment('IT', {
      sorts: [EmployeeSorts.bySalary('DESC')]
    });
  },

  // Employés dans une fourchette de salaire
  getHighEarners: async () => {
    return await employeeApi.getEmployeesBySalaryRange(80000, null, {
      sorts: [EmployeeSorts.bySalary('DESC')]
    });
  },

  // Nouveaux employés (derniers 6 mois)
  getRecentHires: async () => {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    return await employeeApi.getEmployeesByHireDate(
      sixMonthsAgo.toISOString().split('T')[0], 
      null,
      {
        sorts: [EmployeeSorts.byHireDate('DESC')]
      }
    );
  },

  // Recherche combinée complexe
  complexSearch: async () => {
    return await employeeApi.searchEmployees({
      filters: [
        EmployeeFilters.byDepartment('IT'),
        EmployeeFilters.bySalaryMin(60000),
        EmployeeFilters.byHireDateAfter('2020-01-01')
      ],
      sorts: [
        EmployeeSorts.bySalary('DESC'),
        EmployeeSorts.byHireDate('ASC')
      ],
      limit: 50
    });
  }
};

// ===== EXEMPLES D'INTÉGRATION =====

/**
 * Exemple 4: Intégration dans une application
 */
export const integrationExamples = {

  // Dashboard avec statistiques
  getDashboardData: async () => {
    try {
      const [stats, recentHires, topEarners] = await Promise.all([
        employeeApi.getEmployeeStatistics(),
        advancedSearchExamples.getRecentHires(),
        advancedSearchExamples.getHighEarners()
      ]);
      
      return {
        statistics: stats,
        recentHires: recentHires.data.slice(0, 5),
        topEarners: topEarners.data.slice(0, 5)
      };
    } catch (error) {
      console.error('Erreur dashboard:', error.message);
      return null;
    }
  },

  // Validation avant création
  createEmployeeWithValidation: async (employeeData) => {
    const validation = employeeApi.validateEmployeeData(employeeData);
    
    if (!validation.isValid) {
      console.error('Données invalides:', validation.errors);
      return { success: false, errors: validation.errors };
    }
    
    try {
      const employee = await employeeApi.createEmployee(employeeData);
      return { success: true, data: employee };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },

  // Test de connectivité
  healthCheck: async () => {
    const result = await employeeApi.testConnection();
    console.log('Test connexion:', result);
    return result;
  }
};

// ===== FONCTION D'INITIALISATION =====

/**
 * Fonction d'initialisation pour tester tous les exemples
 */
export const runAllExamples = async () => {
  console.log('=== Test de connectivité ===');
  await integrationExamples.healthCheck();
  
  console.log('\\n=== Exemples basiques ===');
  await apiClientExamples.basicUsage();
  
  console.log('\\n=== Recherche avec filtres ===');
  await apiClientExamples.searchWithFilters();
  
  console.log('\\n=== Recherches spécialisées ===');
  const itEmployees = await advancedSearchExamples.getITEmployees();
  console.log('Employés IT:', itEmployees.data.length);
  
  console.log('\\n=== Dashboard ===');
  const dashboardData = await integrationExamples.getDashboardData();
  console.log('Données dashboard:', dashboardData);
  
  console.log('\\n=== Tests terminés ===');
};

// Export de tous les exemples
export default {
  reactAdminExamples,
  apiClientExamples,
  advancedSearchExamples,
  integrationExamples,
  runAllExamples
};