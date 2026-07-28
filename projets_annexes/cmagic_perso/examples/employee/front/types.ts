/**
 * Types TypeScript pour l'API Employee IBM i
 * 
 * Définit tous les types utilisés par le data provider et l'API client
 * Compatible avec l'API REST IBM i standard
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

// ===== TYPES DE BASE =====

/**
 * Structure d'un employé selon l'API IBM i
 */
export interface Employee {
  id: string;
  prenom: string;
  nom: string;
  initiale?: string;
  service: string;
  dateEmbauche: string; // Format ISO date
  dateNaissance: string; // Format ISO date
  genre: 'M' | 'F';
  salaire: number;
  // Champs calculés optionnels
  fullName?: string;
  age?: number;
}

/**
 * Structure d'un client (exemple pour multi-ressources)
 */
export interface Customer {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  status: 'active' | 'inactive' | 'pending';
  createdAt: string;
  updatedAt?: string;
  // Champs calculés optionnels
  displayName?: string;
  isVIP?: boolean;
}

/**
 * Interface générique pour toute ressource
 */
export interface BaseResource {
  id: string;
  [key: string]: any;
}

// ===== TYPES DE PAGINATION =====

/**
 * Paramètres de pagination React-Admin
 */
export interface Pagination {
  page: number;
  perPage: number;
}

/**
 * Réponse avec pagination
 */
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page?: number;
  limit?: number;
  totalPages?: number;
}

// ===== TYPES DE TRI =====

/**
 * Ordre de tri
 */
export type SortOrder = 'ASC' | 'DESC' | 'asc' | 'desc';

/**
 * Paramètres de tri React-Admin
 */
export interface Sort {
  field: string;
  order: SortOrder;
}

/**
 * Tri multi-niveaux (extension IBM i)
 */
export interface MultiSort extends Sort {}

// ===== TYPES DE FILTRES =====

/**
 * Opérateurs de filtres supportés par l'API IBM i
 */
export type FilterOperator = 
  | '=' | 'eq'
  | '!=' | 'ne' 
  | 'like' | 'contains'
  | '>=' | 'gte'
  | '<=' | 'lte'
  | '>' | 'gt'
  | '<' | 'lt';

/**
 * Filtre avancé avec opérateur
 */
export interface AdvancedFilter {
  field: string;
  operator: FilterOperator;
  value: string | number | boolean;
}

/**
 * Filtres simples (clé-valeur)
 */
export interface SimpleFilters {
  [key: string]: string | number | boolean | undefined;
  q?: string; // Recherche globale
}

// ===== TYPES DE REQUÊTES =====

/**
 * Paramètres pour getList
 */
export interface GetListParams {
  pagination: Pagination;
  sort: Sort;
  filter: SimpleFilters;
  // Extensions IBM i
  advancedFilters?: AdvancedFilter[];
  multiSort?: MultiSort[];
}

/**
 * Paramètres pour getOne
 */
export interface GetOneParams {
  id: string;
}

/**
 * Paramètres pour getMany
 */
export interface GetManyParams {
  ids: string[];
}

/**
 * Paramètres pour getManyReference
 */
export interface GetManyReferenceParams {
  target: string;
  id: string;
  pagination: Pagination;
  sort: Sort;
  filter: SimpleFilters;
}

/**
 * Paramètres pour create
 */
export interface CreateParams<T = BaseResource> {
  data: Partial<T>;
}

/**
 * Paramètres pour update
 */
export interface UpdateParams<T = BaseResource> {
  id: string;
  data: Partial<T>;
  previousData?: T;
}

/**
 * Paramètres pour updateMany
 */
export interface UpdateManyParams<T = BaseResource> {
  ids: string[];
  data: Partial<T>;
}

/**
 * Paramètres pour delete
 */
export interface DeleteParams {
  id: string;
  previousData?: BaseResource;
}

/**
 * Paramètres pour deleteMany
 */
export interface DeleteManyParams {
  ids: string[];
}

// ===== TYPES DE RÉPONSES =====

/**
 * Réponse standard pour getList et getManyReference
 */
export interface GetListResponse<T = BaseResource> {
  data: T[];
  total: number;
}

/**
 * Réponse standard pour getOne, create, update, delete
 */
export interface GetOneResponse<T = BaseResource> {
  data: T;
}

/**
 * Réponse standard pour getMany
 */
export interface GetManyResponse<T = BaseResource> {
  data: T[];
}

/**
 * Réponse standard pour updateMany et deleteMany
 */
export interface UpdateManyResponse {
  data: string[];
}

// ===== TYPES DE CONFIGURATION =====

/**
 * Headers HTTP
 */
export interface HttpHeaders {
  [key: string]: string;
}

/**
 * Configuration du client HTTP
 */
export interface HttpClientConfig {
  method?: string;
  headers?: HttpHeaders;
  body?: string;
  signal?: AbortSignal;
}

/**
 * Fonction de transformation des paramètres
 */
export type ParamsTransformer = (query: Record<string, any>, params: any) => Record<string, any>;

/**
 * Fonction de transformation des données de réponse
 */
export type ResponseTransformer<T = any> = (data: T, operation: string) => T;

/**
 * Fonction de transformation des données de requête
 */
export type RequestTransformer<T = any> = (data: T, operation: string) => T;

/**
 * Fonction de parsing du total count
 */
export type TotalCountParser = (headers: Headers, totalCount?: string | null) => string | undefined;

/**
 * Configuration spécifique à une ressource
 */
export interface ResourceConfig {
  transformParams?: ParamsTransformer;
  transformResponse?: ResponseTransformer;
  transformRequest?: RequestTransformer;
  parseTotalCount?: TotalCountParser;
}

/**
 * Configuration globale du data provider
 */
export interface DataProviderConfig {
  apiUrl: string;
  httpClient?: (url: string, options?: HttpClientConfig) => Promise<{ headers: Headers; json: any; status: number }>;
  timeout?: number;
  headers?: HttpHeaders;
  enableLogs?: boolean;
  resourceConfig?: Record<string, ResourceConfig>;
}

// ===== TYPES POUR RECHERCHE AVANCÉE =====

/**
 * Paramètres de recherche universelle
 */
export interface SearchParams {
  q?: string;
  filters?: AdvancedFilter[];
  sorts?: MultiSort[];
  pagination?: Pagination;
}

/**
 * Options pour la recherche d'employés
 */
export interface EmployeeSearchOptions {
  page?: number;
  limit?: number;
  sort?: string;
  order?: SortOrder;
  search?: string;
  filters?: SimpleFilters;
  multiSort?: MultiSort[];
}

// ===== INTERFACE DATA PROVIDER =====

/**
 * Interface complète du data provider React-Admin avec extensions
 */
export interface UniversalDataProvider {
  // Méthodes React-Admin standard
  getList: <T = BaseResource>(resource: string, params: GetListParams) => Promise<GetListResponse<T>>;
  getOne: <T = BaseResource>(resource: string, params: GetOneParams) => Promise<GetOneResponse<T>>;
  getMany: <T = BaseResource>(resource: string, params: GetManyParams) => Promise<GetManyResponse<T>>;
  getManyReference: <T = BaseResource>(resource: string, params: GetManyReferenceParams) => Promise<GetListResponse<T>>;
  create: <T = BaseResource>(resource: string, params: CreateParams<T>) => Promise<GetOneResponse<T>>;
  update: <T = BaseResource>(resource: string, params: UpdateParams<T>) => Promise<GetOneResponse<T>>;
  updateMany: <T = BaseResource>(resource: string, params: UpdateManyParams<T>) => Promise<UpdateManyResponse>;
  delete: <T = BaseResource>(resource: string, params: DeleteParams) => Promise<GetOneResponse<T>>;
  deleteMany: (resource: string, params: DeleteManyParams) => Promise<UpdateManyResponse>;
  
  // Méthodes étendues
  search: <T = BaseResource>(resource: string, searchParams: SearchParams) => Promise<GetListResponse<T>>;
  getTotal: (resource: string, filters?: SimpleFilters) => Promise<number>;
  testConnection: (resource?: string) => Promise<{ success: boolean; message: string; resource?: string }>;
  getResourceConfig: (resource: string) => ResourceConfig;
  setResourceConfig: (resource: string, config: ResourceConfig) => void;
}

// ===== TYPES POUR API CLIENT =====

/**
 * Résultat de validation des données
 */
export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * Configuration du client API
 */
export interface ApiClientConfig {
  baseUrl: string;
  timeout?: number;
  headers?: HttpHeaders;
}

/**
 * Interface du client API Employee
 */
export interface EmployeeApiClient {
  // CRUD de base
  getEmployees: (options?: EmployeeSearchOptions) => Promise<PaginatedResponse<Employee>>;
  getEmployee: (id: string) => Promise<Employee>;
  createEmployee: (employeeData: Partial<Employee>) => Promise<Employee>;
  updateEmployee: (id: string, employeeData: Partial<Employee>) => Promise<Employee>;
  deleteEmployee: (id: string) => Promise<Employee>;
  
  // Recherche avancée
  searchEmployees: (searchOptions?: SearchParams) => Promise<PaginatedResponse<Employee>>;
  getEmployeesByDepartment: (departmentCode: string, options?: EmployeeSearchOptions) => Promise<PaginatedResponse<Employee>>;
  getEmployeesBySalaryRange: (minSalary?: number, maxSalary?: number, options?: EmployeeSearchOptions) => Promise<PaginatedResponse<Employee>>;
  getEmployeesByHireDate: (startDate?: string, endDate?: string, options?: EmployeeSearchOptions) => Promise<PaginatedResponse<Employee>>;
  
  // Utilitaires
  getEmployeeStatistics: () => Promise<{ totalEmployees: number }>;
  validateEmployeeData: (employeeData: Partial<Employee>) => ValidationResult;
  testConnection: () => Promise<{ success: boolean; message: string }>;
}

// ===== TYPES POUR ERREURS =====

/**
 * Erreur enrichie du data provider
 */
export interface DataProviderError extends Error {
  originalError?: Error;
  operation?: string;
  resource?: string;
}

// ===== TYPES UTILITAIRES =====

/**
 * Helper pour créer des filtres typés
 */
export type FilterHelper<T> = {
  [K in keyof T]: (value: T[K]) => AdvancedFilter;
};

/**
 * Helper pour créer des tris typés
 */
export type SortHelper<T> = {
  [K in keyof T]: (order?: SortOrder) => Sort;
};

/**
 * Type pour les ressources connues
 */
export type KnownResource = 'employees' | 'customers' | 'products' | 'orders';

/**
 * Type générique pour les factory de filtres/tris
 */
export interface FilterSortFactory<T> {
  filters: FilterHelper<T>;
  sorts: SortHelper<T>;
}

// ===== EXPORTS POUR LES CONSTANTES =====

/**
 * Liste des opérateurs de filtres
 */
export const FILTER_OPERATORS = [
  '=', 'eq', '!=', 'ne', 'like', 'contains', 
  '>=', 'gte', '<=', 'lte', '>', 'gt', '<', 'lt'
] as const;

/**
 * Liste des ordres de tri
 */
export const SORT_ORDERS = ['ASC', 'DESC', 'asc', 'desc'] as const;

/**
 * Configuration par défaut
 */
export const DEFAULT_CONFIG: Required<Omit<DataProviderConfig, 'httpClient' | 'resourceConfig'>> = {
  apiUrl: 'http://localhost:44000/api',
  timeout: 30000,
  headers: {},
  enableLogs: false
};