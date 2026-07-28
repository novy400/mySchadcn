/**
 * Employee Data Provider TypeScript - Compatible avec l'API REST Employee IBM i
 * 
 * Data provider spécialement conçu pour les employés avec TypeScript complet
 * Compatible avec React-Admin et types stricts
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

import {
  Employee,
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
  DEFAULT_CONFIG
} from './types';

// Temporary implementations until React-Admin is available
const stringify = (obj: Record<string, any>): string => {
  return new URLSearchParams(
    Object.entries(obj).reduce((acc, [key, value]) => {
      if (value !== null && value !== undefined && value !== '') {
        acc[key] = String(value);
      }
      return acc;
    }, {} as Record<string, string>)
  ).toString();
};

const fetchJson = async (url: string, options: RequestInit = {}) => {
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
  return { headers: response.headers, json, status: response.status };
};

/**
 * Configuration par défaut
 */
const defaultEmployeeConfig: Omit<DataProviderConfig, 'resourceConfig'> = {
  ...DEFAULT_CONFIG,
  httpClient: fetchJson
};

/**
 * Interface spécifique au data provider Employee
 */
export interface EmployeeDataProvider {
  getList: (params: GetListParams) => Promise<GetListResponse<Employee>>;
  getOne: (params: GetOneParams) => Promise<GetOneResponse<Employee>>;
  getMany: (params: GetManyParams) => Promise<GetManyResponse<Employee>>;
  getManyReference: (params: GetManyReferenceParams) => Promise<GetListResponse<Employee>>;
  create: (params: CreateParams<Employee>) => Promise<GetOneResponse<Employee>>;
  update: (params: UpdateParams<Employee>) => Promise<GetOneResponse<Employee>>;
  updateMany: (params: UpdateManyParams<Employee>) => Promise<UpdateManyResponse>;
  delete: (params: DeleteParams) => Promise<GetOneResponse<Employee>>;
  deleteMany: (params: DeleteManyParams) => Promise<UpdateManyResponse>;
  
  // Méthodes spécifiques aux employés
  searchEmployees: (searchParams: SearchParams) => Promise<GetListResponse<Employee>>;
  getEmployeeStats: () => Promise<{ totalEmployees: number }>;
}

/**
 * Crée un data provider typé pour l'API Employee
 */
export const createEmployeeDataProvider = (config: Partial<DataProviderConfig> = {}): EmployeeDataProvider => {
  const finalConfig: DataProviderConfig = { 
    ...defaultEmployeeConfig, 
    ...config,
    httpClient: config.httpClient || fetchJson
  };
  
  const log = (...args: any[]): void => {
    if (finalConfig.enableLogs) {
      console.log('[EmployeeDataProvider]', ...args);
    }
  };

  /**
   * Helper pour construire les paramètres de requête avec support des filtres avancés
   */
  const buildQueryParams = (params: Partial<GetListParams | GetManyReferenceParams>): Record<string, any> => {
    const query: Record<string, any> = {};

    // Pagination
    if (params.pagination) {
      query._page = params.pagination.page;
      query._limit = params.pagination.perPage;
    }

    // Tri principal (React-Admin)
    if (params.sort) {
      query._sort = params.sort.field;
      query._order = params.sort.order;
    }

    // Tri multi-niveaux (spécifique à notre API)
    if ('multiSort' in params && params.multiSort) {
      params.multiSort.forEach((sort, index) => {
        if (index === 0) {
          query._sort = sort.field;
          query._order = sort.order;
        } else {
          query[`sort${index}`] = sort.field;
          query[`order${index}`] = sort.order;
        }
      });
    }

    // Filtres standards et recherche
    if (params.filter) {
      Object.keys(params.filter).forEach(key => {
        const value = params.filter![key];
        if (key === 'q') {
          // Recherche générale
          query.q = value;
        } else {
          // Filtres par champ
          query[key] = value;
        }
      });
    }

    // Filtres avancés avec opérateurs (spécifique à notre API)
    if ('advancedFilters' in params && params.advancedFilters) {
      params.advancedFilters.forEach(filter => {
        const { field, operator, value } = filter;
        switch (operator) {
          case 'like':
            query[`${field}_like`] = value;
            break;
          case 'gte':
            query[`${field}_gte`] = value;
            break;
          case 'lte':
            query[`${field}_lte`] = value;
            break;
          case 'ne':
            query[`${field}_ne`] = value;
            break;
          case 'gt':
            query[`${field}_gt`] = value;
            break;
          case 'lt':
            query[`${field}_lt`] = value;
            break;
          default:
            query[field] = value;
        }
      });
    }

    return query;
  };

  /**
   * Helper pour parser les headers de réponse
   */
  const parseResponseHeaders = (headers: Headers): { total: number } => {
    const totalCount = headers.get('x-total-count') || headers.get('X-Total-Count');
    return {
      total: totalCount ? parseInt(totalCount, 10) : 0
    };
  };

  /**
   * Helper pour gérer les erreurs
   */
  const handleError = (error: Error, operation: string): never => {
    console.error(`Employee API Error [${operation}]:`, error);
    
    const enrichedError = new Error(`Employee API ${operation} failed: ${error.message}`) as any;
    enrichedError.originalError = error;
    enrichedError.operation = operation;
    
    throw enrichedError;
  };

  // Data provider object
  const dataProvider: EmployeeDataProvider = {
    /**
     * Récupère une liste d'employés avec pagination, filtres et tri
     */
    getList: async (params: GetListParams): Promise<GetListResponse<Employee>> => {
      try {
        const query = buildQueryParams(params);
        const url = `${finalConfig.apiUrl}/employees?${stringify(query)}`;
        
        const { headers, json } = await finalConfig.httpClient!(url, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const { total } = parseResponseHeaders(headers);
        
        return {
          data: json as Employee[],
          total: total
        };
      } catch (error) {
        return handleError(error as Error, 'getList');
      }
    },

    /**
     * Récupère un employé par son ID
     */
    getOne: async (params: GetOneParams): Promise<GetOneResponse<Employee>> => {
      try {
        const url = `${finalConfig.apiUrl}/employees/${params.id}`;
        const { json } = await finalConfig.httpClient!(url, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        return { data: json as Employee };
      } catch (error) {
        return handleError(error as Error, 'getOne');
      }
    },

    /**
     * Récupère plusieurs employés par leurs IDs
     */
    getMany: async (params: GetManyParams): Promise<GetManyResponse<Employee>> => {
      try {
        const requests = params.ids.map(id => 
          finalConfig.httpClient!(`${finalConfig.apiUrl}/employees/${id}`, {
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
        );
        
        const responses = await Promise.all(requests);
        return { 
          data: responses.map(({ json }) => json as Employee) 
        };
      } catch (error) {
        return handleError(error as Error, 'getMany');
      }
    },

    /**
     * Récupère des employés liés à une ressource (ex: employés d'un département)
     */
    getManyReference: async (params: GetManyReferenceParams): Promise<GetListResponse<Employee>> => {
      try {
        const query = buildQueryParams(params);
        // Ajouter le filtre de référence
        query[params.target] = params.id;
        
        const url = `${finalConfig.apiUrl}/employees?${stringify(query)}`;
        const { headers, json } = await finalConfig.httpClient!(url, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const { total } = parseResponseHeaders(headers);
        
        return {
          data: json as Employee[],
          total: total
        };
      } catch (error) {
        return handleError(error as Error, 'getManyReference');
      }
    },

    /**
     * Crée un nouvel employé
     */
    create: async (params: CreateParams<Employee>): Promise<GetOneResponse<Employee>> => {
      try {
        const { json } = await finalConfig.httpClient!(`${finalConfig.apiUrl}/employees`, {
          method: 'POST',
          body: JSON.stringify(params.data),
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        return { data: json as Employee };
      } catch (error) {
        return handleError(error as Error, 'create');
      }
    },

    /**
     * Met à jour un employé existant
     */
    update: async (params: UpdateParams<Employee>): Promise<GetOneResponse<Employee>> => {
      try {
        const { json } = await finalConfig.httpClient!(`${finalConfig.apiUrl}/employees/${params.id}`, {
          method: 'PUT',
          body: JSON.stringify(params.data),
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        return { data: json as Employee };
      } catch (error) {
        return handleError(error as Error, 'update');
      }
    },

    /**
     * Met à jour plusieurs employés
     */
    updateMany: async (params: UpdateManyParams<Employee>): Promise<UpdateManyResponse> => {
      try {
        const requests = params.ids.map(id =>
          finalConfig.httpClient!(`${finalConfig.apiUrl}/employees/${id}`, {
            method: 'PUT',
            body: JSON.stringify(params.data),
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        return handleError(error as Error, 'updateMany');
      }
    },

    /**
     * Supprime un employé
     */
    delete: async (params: DeleteParams): Promise<GetOneResponse<Employee>> => {
      try {
        const { json } = await finalConfig.httpClient!(`${finalConfig.apiUrl}/employees/${params.id}`, {
          method: 'DELETE',
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        return { data: json as Employee };
      } catch (error) {
        return handleError(error as Error, 'delete');
      }
    },

    /**
     * Supprime plusieurs employés
     */
    deleteMany: async (params: DeleteManyParams): Promise<UpdateManyResponse> => {
      try {
        const requests = params.ids.map(id =>
          finalConfig.httpClient!(`${finalConfig.apiUrl}/employees/${id}`, { 
            method: 'DELETE',
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        return handleError(error as Error, 'deleteMany');
      }
    },

    // Méthodes spécifiques à l'API Employee

    /**
     * Recherche d'employés avec filtres avancés
     */
    searchEmployees: async (searchParams: SearchParams): Promise<GetListResponse<Employee>> => {
      try {
        const params: GetListParams = {
          pagination: searchParams.pagination || { page: 1, perPage: 10 },
          sort: { field: 'nom', order: 'ASC' },
          filter: searchParams.q ? { q: searchParams.q } : {},
          advancedFilters: searchParams.filters || [],
          multiSort: searchParams.sorts || []
        };
        
        return await dataProvider.getList(params);
      } catch (error) {
        return handleError(error as Error, 'searchEmployees');
      }
    },

    /**
     * Récupère des statistiques sur les employés
     */
    getEmployeeStats: async (): Promise<{ totalEmployees: number }> => {
      try {
        // Utiliser l'API existante pour compter
        const { total } = await dataProvider.getList({
          pagination: { page: 1, perPage: 1 },
          sort: { field: 'id', order: 'ASC' },
          filter: {}
        });
        
        return {
          totalEmployees: total
        };
      } catch (error) {
        return handleError(error as Error, 'getEmployeeStats');
      }
    }
  };

  return dataProvider;
};

// Instance par défaut pour usage direct
export const employeeDataProvider = createEmployeeDataProvider();

// Export des helpers pour usage avancé
export const employeeApiHelpers = {
  buildQueryParams: (params: Partial<GetListParams>) => {
    const provider = createEmployeeDataProvider();
    // Cette fonction serait disponible si on exposait buildQueryParams
    return {};
  },
  
  createAdvancedFilter: (field: string, operator: string, value: string | number | boolean) => ({
    field,
    operator: operator as any,
    value
  }),
  
  createMultiSort: (sorts: Array<{ field: string; order?: string }>) => sorts.map(sort => ({
    field: sort.field,
    order: (sort.order || 'ASC') as 'ASC' | 'DESC'
  }))
};