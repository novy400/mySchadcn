/**
 * Point d'entrée principal - Data Provider Universel TypeScript
 * 
 * Export centralisé de tous les composants du data provider universel
 * pour APIs REST IBM i compatibles React-Admin
 * 
 * @author ArchiAPI Template
 * @version 1.0.0
 * @date 2025-10-07
 */

// ===== EXPORTS CORE =====

export {
  createUniversalDataProvider,
  createAdvancedFilters,
  type UniversalDataProviderConfig,
  type ResourceConfig,
  type BaseResource,
  type SearchOptions,
  type AdvancedFilter,
  type MultiSort,
  type Pagination,
  type FilterOperator,
  type HttpClient
} from './universalDataProvider';

// ===== EXPORTS EXEMPLES ET HELPERS =====

export {
  type Employee,
  type Customer,
  type Product,
  EmployeeFilters,
  CustomerFilters,
  ProductFilters,
  createEmployeeResourceConfig,
  createCustomerResourceConfig,
  createProductResourceConfig
} from './universalDataProviderExamples';

export {
  default as Examples,
  createSimpleEmployeeDataProvider,
  createMultiResourceDataProvider,
  createAuthenticatedDataProvider,
  createCustomHttpDataProvider,
  testUniversalDataProvider,
  advancedFilteringExample,
  EmployeeFilters,
  CustomerFilters,
  ProductFilters,
  type Employee,
  type Customer,
  type Product
} from './universalDataProviderExamples';

// ===== EXPORTS REACT-ADMIN =====

export {
  default as ReactAdminConfig,
  createUniversalReactAdminConfig,
  createConfiguredDataProvider,
  generateResourceCode,
  generateReactAdminApp,
  employeeReactAdminConfig,
  customerReactAdminConfig,
  productReactAdminConfig,
  type UniversalReactAdminConfig,
  type ResourceReactAdminConfig,
  type FieldConfig,
  type FilterConfig,
  type AuthConfig
} from './universalReactAdminConfig';

// ===== CONFIGURATIONS PRÊTES À L'EMPLOI =====

/**
 * Configuration Employee simple et rapide
 */
export const createQuickEmployeeDataProvider = (apiUrl: string) => {
  return createUniversalDataProvider({
    apiUrl,
    resources: {
      employees: createEmployeeResourceConfig()
    }
  });
};

/**
 * Configuration multi-ressources standard IBM i
 */
export const createStandardIBMiDataProvider = (apiUrl: string, options?: {
  enableLogs?: boolean;
  timeout?: number;
  authToken?: string;
}) => {
  const config = {
    apiUrl,
    enableLogs: options?.enableLogs || false,
    timeout: options?.timeout || 30000,
    headers: options?.authToken ? {
      'Authorization': `Bearer ${options.authToken}`
    } : {},
    resources: {
      employees: createEmployeeResourceConfig(),
      customers: createCustomerResourceConfig()
    }
  };

  return createUniversalDataProvider(config);
};

// ===== CONSTANTES UTILES =====

/**
 * Version du data provider universel
 */
export const UNIVERSAL_DATA_PROVIDER_VERSION = '1.0.0';

/**
 * Endpoints standards pour APIs IBM i
 */
export const STANDARD_ENDPOINTS = {
  employees: 'employees',
  customers: 'customers', 
  products: 'products',
  orders: 'orders',
  invoices: 'invoices'
} as const;

/**
 * Opérateurs de filtrage supportés
 */
export const FILTER_OPERATORS = {
  equals: 'eq',
  notEquals: 'ne',
  like: 'like',
  greaterThan: 'gt',
  greaterThanOrEqual: 'gte',
  lessThan: 'lt',
  lessThanOrEqual: 'lte',
  in: 'in',
  notIn: 'nin'
} as const;

/**
 * Types de champs React-Admin supportés
 */
export const FIELD_TYPES = {
  text: 'text',
  number: 'number',
  date: 'date',
  email: 'email',
  select: 'select',
  boolean: 'boolean',
  currency: 'currency'
} as const;

// ===== HELPERS RAPIDES =====

/**
 * Crée rapidement des filtres pour n'importe quelle ressource
 */
export const createQuickFilters = (resource: string) => ({
  byField: (field: string, value: any) => ({ field, operator: 'eq' as const, value }),
  byFieldLike: (field: string, value: string) => ({ field, operator: 'like' as const, value }),
  byFieldRange: (field: string, min: number, max: number) => [
    { field, operator: 'gte' as const, value: min },
    { field, operator: 'lte' as const, value: max }
  ],
  byFieldGreaterThan: (field: string, value: number) => ({ field, operator: 'gt' as const, value }),
  byFieldLessThan: (field: string, value: number) => ({ field, operator: 'lt' as const, value })
});

/**
 * Crée une configuration de ressource basique
 */
export const createBasicResourceConfig = (
  endpoint: string,
  defaultSortField: string = 'id',
  defaultSortOrder: 'ASC' | 'DESC' = 'ASC'
): import('./universalDataProvider').ResourceConfig => ({
  endpoint,
  defaultSort: { field: defaultSortField, order: defaultSortOrder },
  defaultFilters: {}
});

/**
 * Valide la configuration d'un data provider
 */
export const validateDataProviderConfig = (config: import('./universalDataProvider').UniversalDataProviderConfig): string[] => {
  const errors: string[] = [];
  
  if (!config.apiUrl) {
    errors.push('apiUrl est requis');
  }
  
  if (config.apiUrl && !config.apiUrl.startsWith('http')) {
    errors.push('apiUrl doit commencer par http:// ou https://');
  }
  
  if (config.timeout && config.timeout < 1000) {
    errors.push('timeout doit être d\'au moins 1000ms');
  }
  
  if (config.resources) {
    Object.keys(config.resources).forEach(resourceName => {
      const resourceConfig = config.resources![resourceName];
      
      if (!resourceConfig.endpoint && !resourceName) {
        errors.push(`Resource ${resourceName}: endpoint ou nom de ressource requis`);
      }
    });
  }
  
  return errors;
};

// ===== EXPORT PAR DÉFAUT =====

/**
 * Configuration par défaut recommandée
 */
const UniversalDataProviderKit = {
  // Fonctions principales
  createQuick: createQuickEmployeeDataProvider,
  createStandard: createStandardIBMiDataProvider,
  
  // Helpers
  createQuickFilters,
  createBasicConfig: createBasicResourceConfig,
  validate: validateDataProviderConfig,
  
  // Constantes
  version: UNIVERSAL_DATA_PROVIDER_VERSION,
  endpoints: STANDARD_ENDPOINTS,
  operators: FILTER_OPERATORS,
  fieldTypes: FIELD_TYPES
};

export default UniversalDataProviderKit;

// ===== IMPORTS RAPIDES RECOMMANDÉS =====

/**
 * Import recommandé pour usage simple :
 * 
 * ```typescript
 * import UniversalDataProvider from './universalDataProviderIndex';
 * 
 * const dataProvider = UniversalDataProvider.createQuick('http://server:44000/api');
 * ```
 * 
 * Import recommandé pour usage avancé :
 * 
 * ```typescript
 * import { 
 *   createUniversalDataProvider,
 *   createAdvancedFilters,
 *   EmployeeFilters 
 * } from './universalDataProviderIndex';
 * ```
 * 
 * Import recommandé pour React-Admin :
 * 
 * ```typescript
 * import { 
 *   createConfiguredDataProvider,
 *   createUniversalReactAdminConfig 
 * } from './universalDataProviderIndex';
 * ```
 */