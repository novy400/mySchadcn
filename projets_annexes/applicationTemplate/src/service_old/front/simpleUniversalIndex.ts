/**
 * Index Simplifié - Universal Data Provider TypeScript
 * 
 * Version simplifiée et fonctionnelle sans dépendances
 * pour APIs REST IBM i compatibles React-Admin
 * 
 * @author ArchiAPI Template
 * @version 1.0.0
 * @date 2025-10-07
 */

// ===== TYPES DE BASE =====

export interface BaseResource {
  id: string | number;
  [key: string]: any;
}

export interface ResourceConfig {
  endpoint: string;
  defaultSort?: { field: string; order: 'ASC' | 'DESC' };
  defaultFilters?: Record<string, any>;
  transformResponse?: (data: any) => any;
  transformRequest?: (data: any) => any;
}

export interface UniversalDataProviderConfig {
  apiUrl: string;
  resources: Record<string, ResourceConfig>;
  timeout?: number;
  headers?: Record<string, string>;
  enableLogs?: boolean;
}

// ===== CONFIGURATION DE BASE =====

/**
 * Configuration Employee
 */
export const EmployeeConfig: ResourceConfig = {
  endpoint: '/employees',
  defaultSort: { field: 'empno', order: 'ASC' },
  defaultFilters: {},
  transformResponse: (data: any) => data,
  transformRequest: (data: any) => data
};

/**
 * Configuration Customer  
 */
export const CustomerConfig: ResourceConfig = {
  endpoint: '/customers',
  defaultSort: { field: 'custno', order: 'ASC' },
  defaultFilters: {},
  transformResponse: (data: any) => data,
  transformRequest: (data: any) => data
};

// ===== HELPERS DE FILTRES =====

export const FilterOperators = {
  EQUALS: '=',
  LIKE: '_like',
  GREATER_THAN: '_gte',
  LESS_THAN: '_lte',
  NOT_EQUALS: '_ne',
  IN: '_in'
} as const;

export type FilterOperator = typeof FilterOperators[keyof typeof FilterOperators];

/**
 * Crée des filtres simples
 */
export const createSimpleFilters = (filters: Record<string, any>) => {
  const result: Record<string, string> = {};
  
  Object.entries(filters).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      result[key] = String(value);
    }
  });
  
  return result;
};

/**
 * Crée des filtres avancés
 */
export const createAdvancedFilters = (filters: Array<{
  field: string;
  operator: FilterOperator;
  value: any;
}>) => {
  const result: Record<string, string> = {};
  
  filters.forEach(({ field, operator, value }) => {
    if (value !== undefined && value !== null && value !== '') {
      const key = operator === '=' ? field : `${field}${operator}`;
      result[key] = String(value);
    }
  });
  
  return result;
};

// ===== UTILITAIRES =====

/**
 * Valide une URL d'API
 */
export const validateApiUrl = (url: string): boolean => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

/**
 * Crée les headers par défaut
 */
export const createDefaultHeaders = (customHeaders: Record<string, string> = {}) => ({
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  ...customHeaders
});

// ===== CONFIGURATIONS PRETES =====

/**
 * Configuration standard IBM i avec Employee et Customer
 */
export const StandardIBMiConfig = {
  employee: EmployeeConfig,
  customer: CustomerConfig
};

/**
 * Endpoints standards IBM i
 */
export const StandardEndpoints = {
  EMPLOYEES: '/api/employees',
  CUSTOMERS: '/api/customers',
  PRODUCTS: '/api/products',
  ORDERS: '/api/orders',
  INVOICES: '/api/invoices'
} as const;

// ===== FACTORY FUNCTIONS =====

/**
 * Crée une configuration basique pour une ressource
 */
export const createResourceConfig = (
  endpoint: string,
  options: Partial<ResourceConfig> = {}
): ResourceConfig => ({
  endpoint,
  defaultSort: { field: 'id', order: 'ASC' },
  defaultFilters: {},
  transformResponse: (data: any) => data,
  transformRequest: (data: any) => data,
  ...options
});

/**
 * Crée une configuration de data provider complète
 */
export const createDataProviderConfig = (
  apiUrl: string,
  resources: Record<string, ResourceConfig>,
  options: Partial<UniversalDataProviderConfig> = {}
): UniversalDataProviderConfig => ({
  apiUrl,
  resources,
  timeout: 30000,
  headers: createDefaultHeaders(),
  enableLogs: false,
  ...options
});

// ===== QUICK START =====

/**
 * Configuration rapide pour Employee
 */
export const createQuickEmployeeConfig = (apiUrl: string) => 
  createDataProviderConfig(apiUrl, {
    employees: EmployeeConfig
  });

/**
 * Configuration rapide multi-ressources
 */
export const createQuickMultiConfig = (apiUrl: string) => 
  createDataProviderConfig(apiUrl, StandardIBMiConfig);

// ===== EXPORT PRINCIPAL =====

/**
 * Kit complet Universal Data Provider
 */
export const UniversalDataProviderKit = {
  // Configurations
  configs: {
    employee: EmployeeConfig,
    customer: CustomerConfig,
    standard: StandardIBMiConfig
  },
  
  // Factories
  createResourceConfig,
  createDataProviderConfig,
  createQuickEmployeeConfig,
  createQuickMultiConfig,
  
  // Utilitaires
  createSimpleFilters,
  createAdvancedFilters,
  createDefaultHeaders,
  validateApiUrl,
  
  // Constantes
  operators: FilterOperators,
  endpoints: StandardEndpoints,
  
  // Version
  version: '1.0.0'
};

export default UniversalDataProviderKit;

// ===== EXEMPLE D'USAGE =====

export const USAGE_EXAMPLES = {
  basic: `
// Configuration basique Employee
import { createQuickEmployeeConfig } from './simpleUniversalIndex';

const config = createQuickEmployeeConfig('http://localhost:44000/api');
console.log(config);
`,
  
  multiResource: `
// Configuration multi-ressources
import { createQuickMultiConfig } from './simpleUniversalIndex';

const config = createQuickMultiConfig('http://localhost:44000/api');
console.log(config);
`,
  
  custom: `
// Configuration personnalisée
import { UniversalDataProviderKit } from './simpleUniversalIndex';

const config = UniversalDataProviderKit.createDataProviderConfig(
  'http://localhost:44000/api',
  {
    employees: UniversalDataProviderKit.configs.employee,
    departments: UniversalDataProviderKit.createResourceConfig('/departments')
  }
);
`,
  
  filters: `
// Utilisation des filtres
import { UniversalDataProviderKit } from './simpleUniversalIndex';

// Filtres simples
const simpleFilters = UniversalDataProviderKit.createSimpleFilters({
  department: 'IT',
  status: 'active'
});

// Filtres avancés
const advancedFilters = UniversalDataProviderKit.createAdvancedFilters([
  { field: 'salary', operator: '_gte', value: 50000 },
  { field: 'name', operator: '_like', value: 'John' }
]);
`
};