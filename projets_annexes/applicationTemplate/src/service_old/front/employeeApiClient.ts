/**
 * Employee API Client TypeScript - Client JavaScript typé pour l'API Employee IBM i
 * 
 * Client standalone pour interagir avec l'API Employee sans dépendances React-Admin
 * Supporte tous les paramètres avancés de l'API (filtres, tri, recherche)
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

import {
  Employee,
  ApiClientConfig,
  EmployeeApiClient,
  EmployeeSearchOptions,
  SearchParams,
  PaginatedResponse,
  ValidationResult,
  AdvancedFilter,
  MultiSort,
  HttpHeaders
} from './types';

/**
 * Configuration par défaut du client
 */
const DEFAULT_CONFIG: Required<ApiClientConfig> = {
  baseUrl: 'http://localhost:44000/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
};

/**
 * Client API Employee typé
 */
export class TypedEmployeeApiClient implements EmployeeApiClient {
  private config: Required<ApiClientConfig>;

  constructor(config: Partial<ApiClientConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Effectue une requête HTTP avec gestion d'erreurs
   */
  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<{
    data: T;
    headers: Headers;
    status: number;
  }> {
    const url = `${this.config.baseUrl}/${endpoint}`;
    
    const requestOptions: RequestInit = {
      headers: { ...this.config.headers, ...options.headers },
      signal: AbortSignal.timeout(this.config.timeout),
      ...options
    };

    try {
      const response = await fetch(url, requestOptions);
      
      if (!response.ok) {
        let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
        
        try {
          const errorBody = await response.json();
          if (errorBody.message) {
            errorMessage = errorBody.message;
          }
        } catch (e) {
          // Ignorer si on ne peut pas parser l'erreur JSON
        }
        
        throw new Error(errorMessage);
      }

      const data = await response.json();
      
      return {
        data,
        headers: response.headers,
        status: response.status
      };
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Request timeout');
      }
      throw error;
    }
  }

  /**
   * Construit les paramètres d'URL pour les requêtes GET
   */
  private buildUrlParams(params: Record<string, any> = {}): string {
    const searchParams = new URLSearchParams();
    
    Object.keys(params).forEach(key => {
      const value = params[key];
      if (value !== null && value !== undefined && value !== '') {
        searchParams.append(key, value.toString());
      }
    });
    
    return searchParams.toString();
  }

  // ===== MÉTHODES CRUD DE BASE =====

  /**
   * Récupère la liste des employés
   */
  async getEmployees(options: EmployeeSearchOptions = {}): Promise<PaginatedResponse<Employee>> {
    const {
      page = 1,
      limit = 10,
      sort = 'nom',
      order = 'ASC',
      search = '',
      filters = {},
      multiSort = []
    } = options;

    const params: Record<string, any> = {
      _page: page,
      _limit: limit,
      _sort: sort,
      _order: order
    };

    // Recherche générale
    if (search) {
      params.q = search;
    }

    // Filtres simples
    Object.keys(filters).forEach(key => {
      if (filters[key] !== null && filters[key] !== undefined && filters[key] !== '') {
        params[key] = filters[key];
      }
    });

    // Tri multi-niveaux
    multiSort.forEach((sortItem, index) => {
      if (index === 0) {
        params._sort = sortItem.field;
        params._order = sortItem.order;
      } else {
        params[`sort${index}`] = sortItem.field;
        params[`order${index}`] = sortItem.order;
      }
    });

    const queryString = this.buildUrlParams(params);
    const endpoint = `employees${queryString ? '?' + queryString : ''}`;
    
    const response = await this.request<Employee[]>(endpoint);
    
    const totalCount = response.headers.get('X-Total-Count') || 
                      response.headers.get('x-total-count') || '0';
    
    return {
      data: response.data,
      total: parseInt(totalCount, 10),
      page,
      limit,
      totalPages: Math.ceil(parseInt(totalCount, 10) / limit)
    };
  }

  /**
   * Récupère un employé par son ID
   */
  async getEmployee(id: string): Promise<Employee> {
    const response = await this.request<Employee>(`employees/${id}`);
    return response.data;
  }

  /**
   * Crée un nouvel employé
   */
  async createEmployee(employeeData: Partial<Employee>): Promise<Employee> {
    const response = await this.request<Employee>('employees', {
      method: 'POST',
      body: JSON.stringify(employeeData)
    });
    return response.data;
  }

  /**
   * Met à jour un employé existant
   */
  async updateEmployee(id: string, employeeData: Partial<Employee>): Promise<Employee> {
    const response = await this.request<Employee>(`employees/${id}`, {
      method: 'PUT',
      body: JSON.stringify(employeeData)
    });
    return response.data;
  }

  /**
   * Supprime un employé
   */
  async deleteEmployee(id: string): Promise<Employee> {
    const response = await this.request<Employee>(`employees/${id}`, {
      method: 'DELETE'
    });
    return response.data;
  }

  // ===== MÉTHODES DE RECHERCHE AVANCÉE =====

  /**
   * Recherche d'employés avec filtres avancés
   */
  async searchEmployees(searchOptions: SearchParams = {}): Promise<PaginatedResponse<Employee>> {
    const {
      q = '',
      filters = [],
      sorts = [],
      pagination = { page: 1, perPage: 10 }
    } = searchOptions;

    const params: Record<string, any> = {
      _page: pagination.page,
      _limit: pagination.perPage
    };

    // Recherche globale
    if (q) {
      params.q = q;
    }

    // Filtres avancés avec opérateurs
    filters.forEach((filter: AdvancedFilter) => {
      const { field, operator, value } = filter;
      
      if (!field || value === null || value === undefined || value === '') {
        return;
      }

      switch (operator) {
        case 'like':
        case 'contains':
          params[`${field}_like`] = value;
          break;
        case 'gte':
        case '>=':
          params[`${field}_gte`] = value;
          break;
        case 'lte':
        case '<=':
          params[`${field}_lte`] = value;
          break;
        case 'gt':
        case '>':
          params[`${field}_gt`] = value;
          break;
        case 'lt':
        case '<':
          params[`${field}_lt`] = value;
          break;
        case 'ne':
        case '!=':
          params[`${field}_ne`] = value;
          break;
        case 'eq':
        case '=':
        default:
          params[field] = value;
          break;
      }
    });

    // Tri multi-niveaux
    sorts.forEach((sort: MultiSort, index: number) => {
      if (index === 0) {
        params._sort = sort.field;
        params._order = sort.order || 'ASC';
      } else {
        params[`sort${index}`] = sort.field;
        params[`order${index}`] = sort.order || 'ASC';
      }
    });

    const queryString = this.buildUrlParams(params);
    const endpoint = `employees${queryString ? '?' + queryString : ''}`;
    
    const response = await this.request<Employee[]>(endpoint);
    
    const totalCount = response.headers.get('X-Total-Count') || 
                      response.headers.get('x-total-count') || '0';
    
    return {
      data: response.data,
      total: parseInt(totalCount, 10),
      page: pagination.page,
      limit: pagination.perPage,
      totalPages: Math.ceil(parseInt(totalCount, 10) / pagination.perPage)
    };
  }

  /**
   * Recherche d'employés par département
   */
  async getEmployeesByDepartment(
    departmentCode: string, 
    options: EmployeeSearchOptions = {}
  ): Promise<PaginatedResponse<Employee>> {
    return this.searchEmployees({
      filters: [
        { field: 'service', operator: 'eq', value: departmentCode }
      ],
      pagination: { page: options.page || 1, perPage: options.limit || 10 },
      sorts: options.multiSort || []
    });
  }

  /**
   * Recherche d'employés par plage de salaire
   */
  async getEmployeesBySalaryRange(
    minSalary?: number, 
    maxSalary?: number, 
    options: EmployeeSearchOptions = {}
  ): Promise<PaginatedResponse<Employee>> {
    const filters: AdvancedFilter[] = [];
    
    if (minSalary !== null && minSalary !== undefined) {
      filters.push({ field: 'salaire', operator: 'gte', value: minSalary });
    }
    
    if (maxSalary !== null && maxSalary !== undefined) {
      filters.push({ field: 'salaire', operator: 'lte', value: maxSalary });
    }

    return this.searchEmployees({
      filters,
      pagination: { page: options.page || 1, perPage: options.limit || 10 },
      sorts: options.multiSort || []
    });
  }

  /**
   * Recherche d'employés par date d'embauche
   */
  async getEmployeesByHireDate(
    startDate?: string, 
    endDate?: string, 
    options: EmployeeSearchOptions = {}
  ): Promise<PaginatedResponse<Employee>> {
    const filters: AdvancedFilter[] = [];
    
    if (startDate) {
      filters.push({ field: 'dateEmbauche', operator: 'gte', value: startDate });
    }
    
    if (endDate) {
      filters.push({ field: 'dateEmbauche', operator: 'lte', value: endDate });
    }

    return this.searchEmployees({
      filters,
      sorts: [{ field: 'dateEmbauche', order: 'DESC' }],
      pagination: { page: options.page || 1, perPage: options.limit || 10 }
    });
  }

  // ===== MÉTHODES UTILITAIRES =====

  /**
   * Récupère les statistiques des employés
   */
  async getEmployeeStatistics(): Promise<{ totalEmployees: number }> {
    // Utiliser l'API pour obtenir le total
    const result = await this.getEmployees({ page: 1, limit: 1 });
    
    return {
      totalEmployees: result.total
      // Ici on pourrait ajouter d'autres statistiques si l'API les supportait
    };
  }

  /**
   * Valide les données d'un employé avant création/modification
   */
  validateEmployeeData(employeeData: Partial<Employee>): ValidationResult {
    const errors: string[] = [];
    
    if (!employeeData.nom || employeeData.nom.trim() === '') {
      errors.push('Le nom est obligatoire');
    }
    
    if (!employeeData.prenom || employeeData.prenom.trim() === '') {
      errors.push('Le prénom est obligatoire');
    }
    
    if (employeeData.salaire && (isNaN(employeeData.salaire) || employeeData.salaire < 0)) {
      errors.push('Le salaire doit être un nombre positif');
    }
    
    if (employeeData.genre && !['M', 'F'].includes(employeeData.genre.toUpperCase())) {
      errors.push('Le genre doit être M ou F');
    }
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Teste la connectivité de l'API
   */
  async testConnection(): Promise<{ success: boolean; message: string }> {
    try {
      await this.getEmployees({ page: 1, limit: 1 });
      return { success: true, message: 'Connexion API réussie' };
    } catch (error) {
      return { success: false, message: (error as Error).message };
    }
  }
}

// ===== HELPERS TYPÉS =====

/**
 * Factory de filtres typés pour les employés
 */
export const EmployeeFilters = {
  byName: (name: string): AdvancedFilter => ({ field: 'nom', operator: 'like', value: name }),
  byFirstName: (firstName: string): AdvancedFilter => ({ field: 'prenom', operator: 'like', value: firstName }),
  byDepartment: (dept: string): AdvancedFilter => ({ field: 'service', operator: 'eq', value: dept }),
  byGender: (gender: 'M' | 'F'): AdvancedFilter => ({ field: 'genre', operator: 'eq', value: gender }),
  bySalaryMin: (minSalary: number): AdvancedFilter => ({ field: 'salaire', operator: 'gte', value: minSalary }),
  bySalaryMax: (maxSalary: number): AdvancedFilter => ({ field: 'salaire', operator: 'lte', value: maxSalary }),
  byHireDateAfter: (date: string): AdvancedFilter => ({ field: 'dateEmbauche', operator: 'gte', value: date }),
  byHireDateBefore: (date: string): AdvancedFilter => ({ field: 'dateEmbauche', operator: 'lte', value: date })
};

/**
 * Factory de tris typés pour les employés
 */
export const EmployeeSorts = {
  byName: (order: 'ASC' | 'DESC' = 'ASC'): MultiSort => ({ field: 'nom', order }),
  byFirstName: (order: 'ASC' | 'DESC' = 'ASC'): MultiSort => ({ field: 'prenom', order }),
  byHireDate: (order: 'ASC' | 'DESC' = 'DESC'): MultiSort => ({ field: 'dateEmbauche', order }),
  bySalary: (order: 'ASC' | 'DESC' = 'DESC'): MultiSort => ({ field: 'salaire', order }),
  byDepartment: (order: 'ASC' | 'DESC' = 'ASC'): MultiSort => ({ field: 'service', order })
};

// Instance par défaut
export const employeeApi = new TypedEmployeeApiClient();