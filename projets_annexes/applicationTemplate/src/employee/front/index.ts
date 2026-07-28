/**
 * Point d'entrée principal pour les composants TypeScript Employee API
 * 
 * Ce fichier expose tous les types, composants et utilitaires
 * disponibles dans le package Employee Front-End TypeScript
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

// ===== EXPORTS TYPES =====

export type {
  Employee,
  Customer,
  BaseResource,
  DataProviderConfig,
  GetListParams,
  GetListResponse,
  GetOneParams,
  GetOneResponse,
  GetManyParams,
  GetManyResponse,
  GetManyReferenceParams,
  CreateParams,
  UpdateParams,
  UpdateManyParams,
  UpdateManyResponse,
  DeleteParams,
  DeleteManyParams,
  SearchParams,
  Pagination,
  Sort,
  AdvancedFilter,
  MultiSort,
  FilterOperator,
  ResourceConfig,
  UniversalDataProvider,
  PaginatedResponse,
  EmployeeSearchOptions,
  ValidationResult,
  EmployeeApiClient as EmployeeApiClientInterface
} from './types';

// ===== EXPORTS DATA PROVIDERS =====

export {
  createEmployeeDataProvider,
  employeeDataProvider,
  employeeApiHelpers,
  type EmployeeDataProvider
} from './employeeDataProvider';

export {
  createUniversalDataProvider
} from './dataProvider';

// ===== EXPORTS API CLIENTS =====

export {
  TypedEmployeeApiClient,
  employeeApi,
  EmployeeFilters,
  EmployeeSorts
} from './employeeApiClient';

// ===== EXPORTS REACT-ADMIN COMPONENTS =====

export {
  default as ReactAdminApp,
  EmployeeList,
  EmployeeCreate,
  EmployeeEdit,
  EmployeeShow,
  EmployeeFilter,
  CustomPagination,
  ListActions,
  FullNameField,
  SalaryField,
  AgeField,
  ServiceField,
  EmployeeTitle,
  dataProvider as reactAdminDataProvider,
  theme as reactAdminTheme,
  createAuthenticatedApp,
  DevApp,
  useEmployeeActions
} from './reactAdminConfig';

// ===== EXPORTS EXAMPLES =====

export {
  default as Examples,
  reactAdminExamples,
  apiClientExamples,
  errorHandlingExamples,
  performanceExamples,
  integrationExamples,
  runCompleteDemo
} from './examples';

// ===== CONSTANTES UTILES =====

export const EMPLOYEE_API_VERSION = '1.0.0';

export const DEFAULT_EMPLOYEE_CONFIG = {
  apiUrl: 'http://localhost:44000/api',
  timeout: 30000,
  enableLogs: false
} as const;

export const EMPLOYEE_SERVICE_CODES = {
  'A00': 'Direction',
  'B01': 'Planification',
  'C01': 'Support Information',
  'D01': 'Développement',
  'D11': 'Systèmes',
  'D21': 'Support Système',
  'E01': 'Support',
  'E11': 'Opérations',
  'E21': 'Logiciel'
} as const;

export const GENDER_OPTIONS = {
  'M': 'Masculin',
  'F': 'Féminin'
} as const;

// ===== HELPERS UTILITAIRES =====

/**
 * Crée un configuration complète pour l'Employee API
 */
export const createEmployeeConfig = (config: Partial<import('./types').DataProviderConfig>) => ({
  ...DEFAULT_EMPLOYEE_CONFIG,
  ...config
});

/**
 * Valide un objet Employee
 */
export const validateEmployee = (employee: Partial<import('./types').Employee>): string[] => {
  const errors: string[] = [];
  
  if (!employee.nom?.trim()) {
    errors.push('Le nom est obligatoire');
  }
  
  if (!employee.prenom?.trim()) {
    errors.push('Le prénom est obligatoire');
  }
  
  if (!employee.service?.trim()) {
    errors.push('Le service est obligatoire');
  }
  
  if (!employee.dateEmbauche) {
    errors.push('La date d\'embauche est obligatoire');
  }
  
  if (!employee.dateNaissance) {
    errors.push('La date de naissance est obligatoire');
  }
  
  if (!employee.genre || !['M', 'F'].includes(employee.genre)) {
    errors.push('Le genre doit être M ou F');
  }
  
  if (typeof employee.salaire !== 'number' || employee.salaire < 0) {
    errors.push('Le salaire doit être un nombre positif');
  }
  
  return errors;
};

/**
 * Formate un nom complet d'employé
 */
export const formatEmployeeName = (employee: Pick<import('./types').Employee, 'prenom' | 'nom'>): string => {
  return `${employee.prenom} ${employee.nom}`;
};

/**
 * Calcule l'âge d'un employé
 */
export const calculateAge = (birthDate: string): number => {
  const today = new Date();
  const birth = new Date(birthDate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  
  return age;
};

/**
 * Calcule l'ancienneté d'un employé en années
 */
export const calculateSeniority = (hireDate: string): number => {
  const today = new Date();
  const hire = new Date(hireDate);
  let years = today.getFullYear() - hire.getFullYear();
  const monthDiff = today.getMonth() - hire.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < hire.getDate())) {
    years--;
  }
  
  return Math.max(0, years);
};

/**
 * Formate un salaire en euros
 */
export const formatSalary = (salary: number, locale: string = 'fr-FR'): string => {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: 'EUR'
  }).format(salary);
};

/**
 * Obtient le libellé d'un service
 */
export const getServiceLabel = (serviceCode: string): string => {
  return EMPLOYEE_SERVICE_CODES[serviceCode as keyof typeof EMPLOYEE_SERVICE_CODES] || serviceCode;
};

/**
 * Obtient le libellé d'un genre
 */
export const getGenderLabel = (genderCode: string): string => {
  return GENDER_OPTIONS[genderCode as keyof typeof GENDER_OPTIONS] || genderCode;
};

// ===== EXPORTS PAR DÉFAUT =====

/**
 * Configuration par défaut complète
 */
export default {
  // Utilitaires
  utils: {
    validateEmployee,
    formatEmployeeName,
    calculateAge,
    calculateSeniority,
    formatSalary,
    getServiceLabel,
    getGenderLabel
  },
  
  // Constantes
  constants: {
    version: EMPLOYEE_API_VERSION,
    serviceCodes: EMPLOYEE_SERVICE_CODES,
    genderOptions: GENDER_OPTIONS
  }
};