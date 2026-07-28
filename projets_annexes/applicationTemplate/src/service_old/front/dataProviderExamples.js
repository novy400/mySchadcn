/**
 * Exemples d'utilisation du Data Provider Universel
 * 
 * Ce fichier contient des exemples pratiques d'utilisation du data provider
 * universel pour différentes ressources IBM i
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
 */

import { 
  createUniversalDataProvider, 
  universalDataProvider,
  debugDataProvider,
  configuredDataProvider,
  FilterOperators,
  SortOrders,
  ResourceConfigs
} from './dataProvider.js';

// ===== EXEMPLES DE CONFIGURATION =====

/**
 * Exemple 1: Configuration basique pour une seule ressource
 */
export const basicUsageExamples = {
  
  // Configuration simple pour employees
  setupEmployeeProvider: () => {
    return createUniversalDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      timeout: 30000,
      enableLogs: true
    });
  },

  // Utilisation basique
  basicEmployeeList: async () => {
    const dataProvider = universalDataProvider;
    
    const result = await dataProvider.getList('employees', {
      pagination: { page: 1, perPage: 10 },
      sort: { field: 'nom', order: 'ASC' },
      filter: { service: 'IT' }
    });
    
    console.log('Employés IT:', result.data);
    return result;
  },

  // Recherche avec filtres avancés
  advancedEmployeeSearch: async () => {
    const dataProvider = universalDataProvider;
    
    const result = await dataProvider.search('employees', {
      q: 'john',
      filters: [
        FilterOperators.like('nom', 'Smith'),
        FilterOperators.greaterThanOrEqual('salaire', 50000),
        FilterOperators.equals('genre', 'M')
      ],
      sorts: [
        SortOrders.ascending('nom'),
        SortOrders.descending('salaire')
      ],
      pagination: { page: 1, perPage: 20 }
    });
    
    console.log('Recherche avancée:', result.data);
    return result;
  }
};

// ===== EXEMPLES MULTI-RESSOURCES =====

/**
 * Exemple 2: Utilisation avec plusieurs ressources
 */
export const multiResourceExamples = {
  
  // Configuration pour plusieurs ressources
  setupMultiResourceProvider: () => {
    return createUniversalDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      timeout: 30000,
      enableLogs: true,
      resourceConfig: {
        employees: {
          transformParams: (query, params) => {
            // Transformation spécifique aux employés
            if (query.fullName) {
              query.q = query.fullName;
              delete query.fullName;
            }
            return query;
          },
          transformResponse: (data, operation) => {
            // Ajouter nom complet aux employés
            if (Array.isArray(data)) {
              return data.map(emp => ({
                ...emp,
                fullName: `${emp.prenom} ${emp.nom}`
              }));
            } else if (data.prenom && data.nom) {
              return {
                ...data,
                fullName: `${data.prenom} ${data.nom}`
              };
            }
            return data;
          }
        },
        customers: {
          transformParams: (query, params) => {
            // Transformation spécifique aux clients
            return query;
          },
          transformResponse: (data, operation) => {
            // Transformation spécifique aux clients
            return data;
          }
        },
        products: {
          transformParams: (query, params) => {
            // Transformation spécifique aux produits
            return query;
          }
        }
      }
    });
  },

  // Utilisation avec employees
  useEmployees: async () => {
    const dataProvider = multiResourceExamples.setupMultiResourceProvider();
    
    const employees = await dataProvider.getList('employees', {
      pagination: { page: 1, perPage: 5 },
      sort: { field: 'nom', order: 'ASC' }
    });
    
    console.log('Employés avec nom complet:', employees.data);
    return employees;
  },

  // Utilisation avec customers
  useCustomers: async () => {
    const dataProvider = multiResourceExamples.setupMultiResourceProvider();
    
    const customers = await dataProvider.getList('customers', {
      pagination: { page: 1, perPage: 5 },
      sort: { field: 'name', order: 'ASC' }
    });
    
    console.log('Clients:', customers.data);
    return customers;
  },

  // Recherche croisée
  crossResourceSearch: async () => {
    const dataProvider = multiResourceExamples.setupMultiResourceProvider();
    
    const [employees, customers] = await Promise.all([
      dataProvider.search('employees', {
        q: 'smith',
        pagination: { page: 1, perPage: 5 }
      }),
      dataProvider.search('customers', {
        q: 'smith',
        pagination: { page: 1, perPage: 5 }
      })
    ]);
    
    console.log('Employés Smith:', employees.data);
    console.log('Clients Smith:', customers.data);
    
    return { employees: employees.data, customers: customers.data };
  }
};

// ===== EXEMPLES REACT-ADMIN =====

/**
 * Exemple 3: Intégration React-Admin multi-ressources
 */
export const reactAdminMultiResourceExample = {
  
  // Configuration React-Admin pour plusieurs ressources
  setupReactAdminApp: () => {
    const dataProvider = createUniversalDataProvider({
      apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:44000/api',
      enableLogs: process.env.NODE_ENV === 'development',
      resourceConfig: ResourceConfigs
    });

    return `
import React from 'react';
import { Admin, Resource } from 'react-admin';

const App = () => (
  <Admin dataProvider={dataProvider} title="IBM i Administration">
    <Resource 
      name="employees" 
      list={EmployeeList} 
      edit={EmployeeEdit} 
      create={EmployeeCreate}
      show={EmployeeShow}
    />
    <Resource 
      name="customers" 
      list={CustomerList} 
      edit={CustomerEdit} 
      create={CustomerCreate}
      show={CustomerShow}
    />
    <Resource 
      name="products" 
      list={ProductList} 
      edit={ProductEdit} 
      create={ProductCreate}
    />
  </Admin>
);

export default App;
    `;
  },

  // Exemple de composant List universel
  universalListComponent: () => {
    return `
import React from 'react';
import { List, Datagrid, TextField, NumberField, DateField } from 'react-admin';

// Composant List universel configurable
export const UniversalList = ({ 
  resource, 
  fields = [], 
  filters = null,
  defaultSort = { field: 'id', order: 'ASC' },
  ...props 
}) => (
  <List 
    {...props} 
    resource={resource}
    filters={filters}
    sort={defaultSort}
  >
    <Datagrid>
      {fields.map(field => {
        switch (field.type) {
          case 'text':
            return <TextField key={field.source} source={field.source} label={field.label} />;
          case 'number':
            return <NumberField key={field.source} source={field.source} label={field.label} />;
          case 'date':
            return <DateField key={field.source} source={field.source} label={field.label} />;
          default:
            return <TextField key={field.source} source={field.source} label={field.label} />;
        }
      })}
    </Datagrid>
  </List>
);

// Utilisation pour employees
export const EmployeeList = (props) => (
  <UniversalList 
    {...props}
    resource="employees"
    fields={[
      { source: 'id', type: 'text', label: 'ID' },
      { source: 'prenom', type: 'text', label: 'Prénom' },
      { source: 'nom', type: 'text', label: 'Nom' },
      { source: 'service', type: 'text', label: 'Service' },
      { source: 'salaire', type: 'number', label: 'Salaire' },
      { source: 'dateEmbauche', type: 'date', label: 'Embauche' }
    ]}
    defaultSort={{ field: 'nom', order: 'ASC' }}
  />
);

// Utilisation pour customers
export const CustomerList = (props) => (
  <UniversalList 
    {...props}
    resource="customers"
    fields={[
      { source: 'id', type: 'text', label: 'ID' },
      { source: 'name', type: 'text', label: 'Nom' },
      { source: 'email', type: 'text', label: 'Email' },
      { source: 'phone', type: 'text', label: 'Téléphone' },
      { source: 'createdAt', type: 'date', label: 'Créé le' }
    ]}
    defaultSort={{ field: 'name', order: 'ASC' }}
  />
);
    `;
  }
};

// ===== EXEMPLES AVANCÉS =====

/**
 * Exemple 4: Fonctionnalités avancées
 */
export const advancedExamples = {
  
  // Configuration avec authentification
  setupWithAuth: () => {
    return createUniversalDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      headers: {
        'Authorization': 'Bearer your-jwt-token',
        'X-Client-Version': '1.0',
        'X-User-ID': 'user123'
      },
      timeout: 60000,
      enableLogs: true
    });
  },

  // Gestion dynamique de la configuration
  dynamicConfiguration: async () => {
    const dataProvider = createUniversalDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api'
    });

    // Configuration dynamique pour une ressource
    dataProvider.setResourceConfig('orders', {
      transformParams: (query, params) => {
        // Ajouter automatiquement le filtre utilisateur
        query.userId = 'current-user-id';
        return query;
      },
      transformResponse: (data, operation) => {
        // Calculer le total des commandes
        if (Array.isArray(data)) {
          return data.map(order => ({
            ...order,
            total: order.quantity * order.price
          }));
        }
        return data;
      }
    });

    // Test de la nouvelle configuration
    const orders = await dataProvider.getList('orders', {
      pagination: { page: 1, perPage: 10 }
    });

    console.log('Commandes avec total calculé:', orders.data);
    return orders;
  },

  // Recherche complexe multi-critères
  complexSearch: async () => {
    const dataProvider = debugDataProvider;

    const searchCriteria = {
      filters: [
        FilterOperators.like('nom', 'Smith'),
        FilterOperators.greaterThanOrEqual('salaire', 60000),
        FilterOperators.lessThanOrEqual('salaire', 120000),
        FilterOperators.equals('genre', 'M'),
        FilterOperators.greaterThanOrEqual('dateEmbauche', '2020-01-01')
      ],
      sorts: [
        SortOrders.descending('salaire'),
        SortOrders.ascending('nom'),
        SortOrders.descending('dateEmbauche')
      ],
      pagination: { page: 1, perPage: 50 }
    };

    const results = await dataProvider.search('employees', searchCriteria);
    
    console.log('Recherche complexe:', {
      criteria: searchCriteria,
      results: results.data.length,
      total: results.total
    });

    return results;
  },

  // Test de performance multi-ressources
  performanceTest: async () => {
    const dataProvider = createUniversalDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      timeout: 120000
    });

    const startTime = Date.now();

    try {
      const results = await Promise.all([
        dataProvider.getTotal('employees'),
        dataProvider.getTotal('customers'),
        dataProvider.getList('employees', { 
          pagination: { page: 1, perPage: 100 } 
        }),
        dataProvider.getList('customers', { 
          pagination: { page: 1, perPage: 100 } 
        })
      ]);

      const endTime = Date.now();
      const duration = endTime - startTime;

      console.log('Test de performance:', {
        duration: `${duration}ms`,
        employeeTotal: results[0],
        customerTotal: results[1],
        employeesSample: results[2].data.length,
        customersSample: results[3].data.length
      });

      return {
        success: true,
        duration,
        results
      };
    } catch (error) {
      console.error('Erreur test performance:', error);
      return {
        success: false,
        error: error.message,
        duration: Date.now() - startTime
      };
    }
  }
};

// ===== TESTS DE CONNECTIVITÉ =====

/**
 * Exemple 5: Tests et validation
 */
export const testingExamples = {
  
  // Test de connectivité multi-ressources
  testAllResources: async (resources = ['employees', 'customers']) => {
    const dataProvider = universalDataProvider;
    
    const results = {};
    
    for (const resource of resources) {
      try {
        const result = await dataProvider.testConnection(resource);
        results[resource] = result;
      } catch (error) {
        results[resource] = {
          success: false,
          message: error.message,
          resource
        };
      }
    }
    
    console.log('Tests de connectivité:', results);
    return results;
  },

  // Validation de la configuration
  validateConfiguration: () => {
    const dataProvider = configuredDataProvider;
    
    const resources = ['employees', 'customers', 'generic'];
    
    const configValidation = resources.map(resource => {
      const config = dataProvider.getResourceConfig(resource);
      return {
        resource,
        hasConfig: Object.keys(config).length > 0,
        config
      };
    });
    
    console.log('Validation configuration:', configValidation);
    return configValidation;
  },

  // Test de tous les exemples
  runAllTests: async () => {
    console.log('=== Tests Data Provider Universel ===');
    
    try {
      console.log('\\n1. Test basique...');
      await basicUsageExamples.basicEmployeeList();
      
      console.log('\\n2. Test recherche avancée...');
      await basicUsageExamples.advancedEmployeeSearch();
      
      console.log('\\n3. Test multi-ressources...');
      await multiResourceExamples.crossResourceSearch();
      
      console.log('\\n4. Test configuration dynamique...');
      await advancedExamples.dynamicConfiguration();
      
      console.log('\\n5. Test connectivité...');
      await testingExamples.testAllResources();
      
      console.log('\\n6. Validation configuration...');
      testingExamples.validateConfiguration();
      
      console.log('\\n✅ Tous les tests sont passés !');
      
    } catch (error) {
      console.error('\\n❌ Erreur lors des tests:', error.message);
    }
  }
};

// Export de tous les exemples
export default {
  basicUsageExamples,
  multiResourceExamples,
  reactAdminMultiResourceExample,
  advancedExamples,
  testingExamples
};