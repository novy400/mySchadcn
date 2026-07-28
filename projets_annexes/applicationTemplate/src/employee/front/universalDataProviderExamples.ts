/**
 * Exemples d'utilisation du Data Provider Universel TypeScript
 * 
 * Ce fichier montre comment utiliser le data provider universel avec
 * différentes ressources (Employee, Customer, Product, etc.)
 * 
 * @author ArchiAPI Template
 * @version 1.0.0
 * @date 2025-10-07
 */

import { 
  createUniversalDataProvider,
  createAdvancedFilters,
  UniversalDataProviderConfig,
  ResourceConfig,
  BaseResource
} from './universalDataProvider';

// ===== DÉFINITION DES RESSOURCES =====

/**
 * Interface Employee (hérite de BaseResource)
 */
export interface Employee extends BaseResource {
  prenom: string;
  nom: string;
  service: string;
  salaire: number;
  dateEmbauche: string;
  dateNaissance: string;
  genre: 'M' | 'F';
}

/**
 * Interface Customer (hérite de BaseResource)
 */
export interface Customer extends BaseResource {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  company?: string;
  status: 'active' | 'inactive' | 'pending';
  createdAt: string;
}

/**
 * Interface Product (hérite de BaseResource)
 */
export interface Product extends BaseResource {
  name: string;
  description: string;
  price: number;
  category: string;
  stock: number;
  active: boolean;
  createdAt: string;
  updatedAt?: string;
}

// ===== CONFIGURATIONS PAR RESSOURCE =====

/**
 * Configuration pour la ressource Employee
 */
const employeeConfig: ResourceConfig = {
  endpoint: 'employees',
  defaultSort: { field: 'nom', order: 'ASC' },
  defaultFilters: {},
  // Pas de mapping de champs nécessaire pour Employee
};

/**
 * Configuration pour la ressource Customer
 */
const customerConfig: ResourceConfig = {
  endpoint: 'customers',
  defaultSort: { field: 'lastName', order: 'ASC' },
  defaultFilters: { status: 'active' },
  // Mapping optionnel pour adapter les noms de champs
  fieldMapping: {
    'lastName': 'nom',
    'firstName': 'prenom'
  },
  // Transformation optionnelle des données
  transformResponse: (data) => {
    if (Array.isArray(data)) {
      return data.map(item => ({
        ...item,
        displayName: `${item.firstName} ${item.lastName}`,
        isVIP: item.company && item.company.length > 0
      }));
    } else {
      return {
        ...data,
        displayName: `${data.firstName} ${data.lastName}`,
        isVIP: data.company && data.company.length > 0
      };
    }
  }
};

/**
 * Configuration pour la ressource Product
 */
const productConfig: ResourceConfig = {
  endpoint: 'products',
  defaultSort: { field: 'name', order: 'ASC' },
  defaultFilters: { active: true },
  transformResponse: (data) => {
    if (Array.isArray(data)) {
      return data.map(item => ({
        ...item,
        formattedPrice: new Intl.NumberFormat('fr-FR', {
          style: 'currency',
          currency: 'EUR'
        }).format(item.price),
        stockStatus: item.stock > 0 ? 'available' : 'out_of_stock'
      }));
    } else {
      return {
        ...data,
        formattedPrice: new Intl.NumberFormat('fr-FR', {
          style: 'currency',
          currency: 'EUR'
        }).format(data.price),
        stockStatus: data.stock > 0 ? 'available' : 'out_of_stock'
      };
    }
  }
};

// ===== EXEMPLES D'UTILISATION =====

/**
 * Exemple 1: Configuration simple avec une seule ressource
 */
export const createSimpleEmployeeDataProvider = (apiUrl: string) => {
  return createUniversalDataProvider({
    apiUrl,
    enableLogs: true,
    resources: {
      employees: employeeConfig
    }
  });
};

/**
 * Exemple 2: Configuration multi-ressources complète
 */
export const createMultiResourceDataProvider = (apiUrl: string) => {
  const config: UniversalDataProviderConfig = {
    apiUrl,
    timeout: 30000,
    enableLogs: process.env.NODE_ENV === 'development',
    headers: {
      'X-Client-Version': '1.0.0',
      'X-Source': 'React-Admin'
    },
    resources: {
      employees: employeeConfig,
      customers: customerConfig,
      products: productConfig
    }
  };

  return createUniversalDataProvider(config);
};

/**
 * Exemple 3: Configuration avec authentification
 */
export const createAuthenticatedDataProvider = (apiUrl: string, authToken: string) => {
  return createUniversalDataProvider({
    apiUrl,
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    },
    resources: {
      employees: employeeConfig,
      customers: customerConfig,
      products: productConfig
    }
  });
};

/**
 * Exemple 4: Configuration avec client HTTP personnalisé
 */
export const createCustomHttpDataProvider = (apiUrl: string) => {
  // Client HTTP avec retry automatique
  const customHttpClient = async (url: string, options: RequestInit = {}) => {
    const maxRetries = 3;
    let lastError: Error;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const response = await fetch(url, {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...options.headers
          },
          ...options
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const json = await response.json();
        
        return {
          json,
          headers: response.headers,
          status: response.status
        };
      } catch (error) {
        lastError = error as Error;
        
        if (attempt === maxRetries) {
          throw lastError;
        }
        
        // Attendre avant le retry (backoff exponentiel)
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
      }
    }
    
    throw lastError!;
  };

  return createUniversalDataProvider({
    apiUrl,
    httpClient: customHttpClient,
    resources: {
      employees: employeeConfig,
      customers: customerConfig,
      products: productConfig
    }
  });
};

// ===== EXEMPLES D'UTILISATION AVEC REACT-ADMIN =====

/**
 * Exemple d'utilisation avec React-Admin - Employee
 */
export const employeeReactAdminExample = `
import React from 'react';
import { Admin, Resource, List, Datagrid, TextField, NumberField } from 'react-admin';
import { createSimpleEmployeeDataProvider } from './universalDataProviderExamples';

const dataProvider = createSimpleEmployeeDataProvider('http://your-server:44000/api');

const EmployeeList = (props) => (
  <List {...props}>
    <Datagrid>
      <TextField source="id" />
      <TextField source="prenom" label="Prénom" />
      <TextField source="nom" label="Nom" />
      <TextField source="service" label="Service" />
      <NumberField source="salaire" label="Salaire" />
    </Datagrid>
  </List>
);

const App = () => (
  <Admin dataProvider={dataProvider}>
    <Resource name="employees" list={EmployeeList} />
  </Admin>
);

export default App;
`;

/**
 * Exemple d'utilisation avec React-Admin - Multi-ressources
 */
export const multiResourceReactAdminExample = `
import React from 'react';
import { Admin, Resource } from 'react-admin';
import { createMultiResourceDataProvider } from './universalDataProviderExamples';

const dataProvider = createMultiResourceDataProvider('http://your-server:44000/api');

const App = () => (
  <Admin dataProvider={dataProvider}>
    <Resource name="employees" list={EmployeeList} />
    <Resource name="customers" list={CustomerList} />
    <Resource name="products" list={ProductList} />
  </Admin>
);

export default App;
`;

// ===== TESTS ET VALIDATION =====

/**
 * Tests de base pour valider le data provider
 */
export const testUniversalDataProvider = async () => {
  console.log('🧪 Test du Data Provider Universel...');
  
  // Configuration de test
  const dataProvider = createMultiResourceDataProvider('http://localhost:44000/api');
  
  try {
    // Test Employee
    console.log('Test Employee...');
    const employees = await dataProvider.getList('employees', {
      pagination: { page: 1, perPage: 10 },
      sort: { field: 'nom', order: 'ASC' },
      filter: {}
    });
    console.log(`✅ Employees trouvés: ${employees.total}`);
    
    // Test Customer  
    console.log('Test Customer...');
    const customers = await dataProvider.getList('customers', {
      pagination: { page: 1, perPage: 10 },
      sort: { field: 'lastName', order: 'ASC' },
      filter: { status: 'active' }
    });
    console.log(`✅ Customers trouvés: ${customers.total}`);
    
    // Test Product
    console.log('Test Product...');
    const products = await dataProvider.getList('products', {
      pagination: { page: 1, perPage: 10 },
      sort: { field: 'name', order: 'ASC' },
      filter: { active: true }
    });
    console.log(`✅ Products trouvés: ${products.total}`);
    
    console.log('🎉 Tous les tests sont passés!');
    
  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
};

// ===== HELPERS POUR FILTRES AVANCÉS =====

/**
 * Helpers pour créer des filtres Employee
 */
export const EmployeeFilters = {
  byDepartment: (dept: string) => ({ field: 'service', operator: 'eq' as const, value: dept }),
  byMinSalary: (salary: number) => ({ field: 'salaire', operator: 'gte' as const, value: salary }),
  byMaxSalary: (salary: number) => ({ field: 'salaire', operator: 'lte' as const, value: salary }),
  byNameLike: (name: string) => ({ field: 'nom', operator: 'like' as const, value: name }),
  byHiredAfter: (date: string) => ({ field: 'dateEmbauche', operator: 'gte' as const, value: date }),
  byGender: (gender: 'M' | 'F') => ({ field: 'genre', operator: 'eq' as const, value: gender })
};

/**
 * Helpers pour créer des filtres Customer
 */
export const CustomerFilters = {
  byStatus: (status: string) => ({ field: 'status', operator: 'eq' as const, value: status }),
  byCompany: (company: string) => ({ field: 'company', operator: 'like' as const, value: company }),
  byEmailLike: (email: string) => ({ field: 'email', operator: 'like' as const, value: email }),
  byNameLike: (name: string) => ({ field: 'lastName', operator: 'like' as const, value: name }),
  byCreatedAfter: (date: string) => ({ field: 'createdAt', operator: 'gte' as const, value: date })
};

/**
 * Helpers pour créer des filtres Product
 */
export const ProductFilters = {
  byCategory: (category: string) => ({ field: 'category', operator: 'eq' as const, value: category }),
  byMinPrice: (price: number) => ({ field: 'price', operator: 'gte' as const, value: price }),
  byMaxPrice: (price: number) => ({ field: 'price', operator: 'lte' as const, value: price }),
  byNameLike: (name: string) => ({ field: 'name', operator: 'like' as const, value: name }),
  byActive: (active: boolean) => ({ field: 'active', operator: 'eq' as const, value: active }),
  inStock: () => ({ field: 'stock', operator: 'gt' as const, value: 0 }),
  outOfStock: () => ({ field: 'stock', operator: 'eq' as const, value: 0 })
};

// ===== EXEMPLE D'UTILISATION AVANCÉE =====

/**
 * Exemple d'utilisation avec filtres avancés
 */
export const advancedFilteringExample = async () => {
  const dataProvider = createMultiResourceDataProvider('http://localhost:44000/api');
  
  // Recherche d'employés IT avec salaire >= 50000
  const highPaidITEmployees = await dataProvider.getList('employees', {
    pagination: { page: 1, perPage: 20 },
    sort: { field: 'salaire', order: 'DESC' },
    filter: createAdvancedFilters([
      EmployeeFilters.byDepartment('IT'),
      EmployeeFilters.byMinSalary(50000)
    ])
  });
  
  // Recherche de customers actifs d'une entreprise
  const activeCustomers = await dataProvider.getList('customers', {
    pagination: { page: 1, perPage: 50 },
    sort: { field: 'lastName', order: 'ASC' },
    filter: createAdvancedFilters([
      CustomerFilters.byStatus('active'),
      CustomerFilters.byCompany('Microsoft')
    ])
  });
  
  // Recherche de produits dans une gamme de prix
  const affordableProducts = await dataProvider.getList('products', {
    pagination: { page: 1, perPage: 30 },
    sort: { field: 'price', order: 'ASC' },
    filter: createAdvancedFilters([
      ProductFilters.byMinPrice(10),
      ProductFilters.byMaxPrice(100),
      ProductFilters.byActive(true)
    ])
  });
  
  return {
    employees: highPaidITEmployees,
    customers: activeCustomers,
    products: affordableProducts
  };
};

export default {
  createSimpleEmployeeDataProvider,
  createMultiResourceDataProvider,
  createAuthenticatedDataProvider,
  createCustomHttpDataProvider,
  testUniversalDataProvider,
  advancedFilteringExample,
  EmployeeFilters,
  CustomerFilters,
  ProductFilters
};