/**
 * Universal Data Provider TypeScript - Version complète et corrigée
 * 
 * Data provider universel typé compatible React-Admin pour toutes les ressources
 * Supporte tous les patterns de l'API REST standard IBM i (Employee, Customer, etc.)
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

// Note: Uncomment these imports when React-Admin is available
// import { fetchUtils } from 'react-admin';
// import { stringify } from 'query-string';

import {
  DataProviderConfig,
  UniversalDataProvider,
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
  SimpleFilters,
  BaseResource,
  HttpClientConfig,
  ResourceConfig,
  AdvancedFilter,
  MultiSort,
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

const fetchJson = async (url: string, options: HttpClientConfig = {}) => {
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
 * Configuration par défaut du data provider
 */
const defaultConfig: Omit<DataProviderConfig, 'resourceConfig'> = {
  ...DEFAULT_CONFIG,
  httpClient: fetchJson
};

/**
 * Crée un data provider universel pour les APIs IBM i
 */
export const createUniversalDataProvider = (config: Partial<DataProviderConfig> = {}): UniversalDataProvider => {
  const finalConfig: DataProviderConfig = { 
    ...defaultConfig, 
    ...config,
    httpClient: config.httpClient || fetchJson
  };
  
  const log = (...args: any[]): void => {
    if (finalConfig.enableLogs) {
      console.log('[UniversalDataProvider]', ...args);
    }
  };

  /**
   * Helper pour construire les paramètres de requête universels
   */
  const buildQueryParams = (params: Partial<GetListParams | GetManyReferenceParams>, resource: string): Record<string, any> => {
    const query: Record<string, any> = {};
    
    // Configuration spécifique à la ressource
    const resourceConfig: ResourceConfig = finalConfig.resourceConfig?.[resource] || {};

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

    // Tri multi-niveaux (extension IBM i)
    if ('multiSort' in params && params.multiSort) {
      params.multiSort.forEach((sort: MultiSort, index: number) => {
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
      Object.keys(params.filter).forEach((key: string) => {
        const value = params.filter![key];
        
        if (value === null || value === undefined || value === '') {
          return;
        }

        if (key === 'q') {
          // Recherche générale
          query.q = value;
        } else if (key.includes('_')) {
          // Filtre avec opérateur déjà formaté (ex: salaire_gte)
          query[key] = value;
        } else {
          // Filtre simple
          query[key] = value;
        }
      });
    }

    // Filtres avancés avec opérateurs (extension)
    if ('advancedFilters' in params && params.advancedFilters) {
      params.advancedFilters.forEach((filter: AdvancedFilter) => {
        const { field, operator, value } = filter;
        
        if (!field || value === null || value === undefined || value === '') {
          return;
        }

        switch (operator) {
          case 'like':
          case 'contains':
            query[`${field}_like`] = value;
            break;
          case 'gte':
          case '>=':
            query[`${field}_gte`] = value;
            break;
          case 'lte':
          case '<=':
            query[`${field}_lte`] = value;
            break;
          case 'gt':
          case '>':
            query[`${field}_gt`] = value;
            break;
          case 'lt':
          case '<':
            query[`${field}_lt`] = value;
            break;
          case 'ne':
          case '!=':
            query[`${field}_ne`] = value;
            break;
          case 'eq':
          case '=':
          default:
            query[field] = value;
            break;
        }
      });
    }

    // Transformations spécifiques à la ressource
    if (resourceConfig.transformParams) {
      return resourceConfig.transformParams(query, params);
    }

    return query;
  };

  /**
   * Helper pour parser les headers de réponse
   */
  const parseResponseHeaders = (headers: Headers, resource: string): { total: number } => {
    const resourceConfig: ResourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    // Header X-Total-Count standard
    let totalCount = headers.get('x-total-count') || headers.get('X-Total-Count');
    
    // Transformation spécifique à la ressource
    if (resourceConfig.parseTotalCount) {
      const totalCountInput = totalCount === undefined ? null : totalCount;
      totalCount = resourceConfig.parseTotalCount(headers, totalCountInput);
    }
    
    return {
      total: totalCount ? parseInt(totalCount, 10) : 0
    };
  };

  /**
   * Helper pour transformer les données de réponse
   */
  const transformResponseData = <T>(data: T, resource: string, operation: string): T => {
    const resourceConfig: ResourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    if (resourceConfig.transformResponse) {
      return resourceConfig.transformResponse(data, operation);
    }
    
    return data;
  };

  /**
   * Helper pour transformer les données de requête
   */
  const transformRequestData = <T>(data: T, resource: string, operation: string): T => {
    const resourceConfig: ResourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    if (resourceConfig.transformRequest) {
      return resourceConfig.transformRequest(data, operation);
    }
    
    return data;
  };

  /**
   * Helper pour gérer les erreurs
   */
  const handleError = (error: Error, operation: string, resource: string): never => {
    const errorMessage = `Universal API Error [${operation}/${resource}]: ${error.message}`;
    
    if (finalConfig.enableLogs) {
      console.error(errorMessage, error);
    }
    
    // Enrichir l'erreur avec des informations contextuelles
    const enrichedError = new Error(errorMessage) as any;
    enrichedError.originalError = error;
    enrichedError.operation = operation;
    enrichedError.resource = resource;
    
    throw enrichedError;
  };

  /**
   * Helper pour créer les options de requête HTTP
   */
  const createRequestOptions = (method: string = 'GET', body?: any): HttpClientConfig => {
    const options: HttpClientConfig = {
      method,
      headers: { ...finalConfig.headers },
      signal: AbortSignal.timeout(finalConfig.timeout || 30000)
    };

    if (body) {
      options.body = JSON.stringify(body);
      options.headers = {
        ...options.headers,
        'Content-Type': 'application/json'
      };
    }

    return options;
  };

  // Data provider object universel
  const dataProvider: UniversalDataProvider = {
    /**
     * Récupère une liste de ressources avec pagination, filtres et tri
     */
    getList: async <T = BaseResource>(
      resource: string, 
      params: GetListParams
    ): Promise<GetListResponse<T>> => {
      try {
        log('getList', resource, params);
        
        const query = buildQueryParams(params, resource);
        const url = `${finalConfig.apiUrl}/${resource}?${stringify(query)}`;
        
        log('Request URL:', url);
        
        const response = await finalConfig.httpClient!(url, createRequestOptions());
        
        const { total } = parseResponseHeaders(response.headers, resource);
        const transformedData = transformResponseData<T[]>(response.json, resource, 'getList');
        
        log('Response:', { total, count: transformedData.length });
        
        return {
          data: transformedData,
          total: total
        };
      } catch (error) {
        return handleError(error as Error, 'getList', resource);
      }
    },

    /**
     * Récupère une ressource par son ID
     */
    getOne: async <T = BaseResource>(
      resource: string, 
      params: GetOneParams
    ): Promise<GetOneResponse<T>> => {
      try {
        log('getOne', resource, params.id);
        
        const url = `${finalConfig.apiUrl}/${resource}/${params.id}`;
        const response = await finalConfig.httpClient!(url, createRequestOptions());
        
        const transformedData = transformResponseData<T>(response.json, resource, 'getOne');
        
        return { data: transformedData };
      } catch (error) {
        return handleError(error as Error, 'getOne', resource);
      }
    },

    /**
     * Récupère plusieurs ressources par leurs IDs
     */
    getMany: async <T = BaseResource>(
      resource: string, 
      params: GetManyParams
    ): Promise<GetManyResponse<T>> => {
      try {
        log('getMany', resource, params.ids);
        
        const requests = params.ids.map((id: string) => 
          finalConfig.httpClient!(`${finalConfig.apiUrl}/${resource}/${id}`, createRequestOptions())
        );
        
        const responses = await Promise.all(requests);
        const data = responses.map(response => transformResponseData<T>(response.json, resource, 'getMany'));
        
        return { data };
      } catch (error) {
        return handleError(error as Error, 'getMany', resource);
      }
    },

    /**
     * Récupère des ressources liées à une autre ressource
     */
    getManyReference: async <T = BaseResource>(
      resource: string, 
      params: GetManyReferenceParams
    ): Promise<GetListResponse<T>> => {
      try {
        log('getManyReference', resource, params);
        
        const query = buildQueryParams(params, resource);
        // Ajouter le filtre de référence
        query[params.target] = params.id;
        
        const url = `${finalConfig.apiUrl}/${resource}?${stringify(query)}`;
        const response = await finalConfig.httpClient!(url, createRequestOptions());
        
        const { total } = parseResponseHeaders(response.headers, resource);
        const transformedData = transformResponseData<T[]>(response.json, resource, 'getManyReference');
        
        return {
          data: transformedData,
          total: total
        };
      } catch (error) {
        return handleError(error as Error, 'getManyReference', resource);
      }
    },

    /**
     * Crée une nouvelle ressource
     */
    create: async <T = BaseResource>(
      resource: string, 
      params: CreateParams<T>
    ): Promise<GetOneResponse<T>> => {
      try {
        log('create', resource, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'create');
        
        const response = await finalConfig.httpClient!(
          `${finalConfig.apiUrl}/${resource}`, 
          createRequestOptions('POST', transformedData)
        );
        
        const responseData = transformResponseData<T>(response.json, resource, 'create');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'create', resource);
      }
    },

    /**
     * Met à jour une ressource existante
     */
    update: async <T = BaseResource>(
      resource: string, 
      params: UpdateParams<T>
    ): Promise<GetOneResponse<T>> => {
      try {
        log('update', resource, params.id, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'update');
        
        const response = await finalConfig.httpClient!(
          `${finalConfig.apiUrl}/${resource}/${params.id}`, 
          createRequestOptions('PUT', transformedData)
        );
        
        const responseData = transformResponseData<T>(response.json, resource, 'update');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'update', resource);
      }
    },

    /**
     * Met à jour plusieurs ressources
     */
    updateMany: async <T = BaseResource>(
      resource: string, 
      params: UpdateManyParams<T>
    ): Promise<UpdateManyResponse> => {
      try {
        log('updateMany', resource, params.ids, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'updateMany');
        
        const requests = params.ids.map((id: string) =>
          finalConfig.httpClient!(
            `${finalConfig.apiUrl}/${resource}/${id}`, 
            createRequestOptions('PUT', transformedData)
          )
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        return handleError(error as Error, 'updateMany', resource);
      }
    },

    /**
     * Supprime une ressource
     */
    delete: async <T = BaseResource>(
      resource: string, 
      params: DeleteParams
    ): Promise<GetOneResponse<T>> => {
      try {
        log('delete', resource, params.id);
        
        const response = await finalConfig.httpClient!(
          `${finalConfig.apiUrl}/${resource}/${params.id}`, 
          createRequestOptions('DELETE')
        );
        
        const responseData = transformResponseData<T>(response.json, resource, 'delete');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'delete', resource);
      }
    },

    /**
     * Supprime plusieurs ressources
     */
    deleteMany: async (resource: string, params: DeleteManyParams): Promise<UpdateManyResponse> => {
      try {
        log('deleteMany', resource, params.ids);
        
        const requests = params.ids.map((id: string) =>
          finalConfig.httpClient!(
            `${finalConfig.apiUrl}/${resource}/${id}`, 
            createRequestOptions('DELETE')
          )
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        return handleError(error as Error, 'deleteMany', resource);
      }
    },

    // Méthodes étendues universelles

    /**
     * Recherche universelle avec filtres avancés
     */
    search: async <T = BaseResource>(
      resource: string, 
      searchParams: SearchParams
    ): Promise<GetListResponse<T>> => {
      try {
        log('search', resource, searchParams);
        
        const params: GetListParams = {
          pagination: searchParams.pagination || { page: 1, perPage: 10 },
          sort: { field: 'id', order: 'ASC' },
          filter: searchParams.q ? { q: searchParams.q } : {},
          advancedFilters: searchParams.filters || [],
          multiSort: searchParams.sorts || []
        };
        
        return await dataProvider.getList<T>(resource, params);
      } catch (error) {
        return handleError(error as Error, 'search', resource);
      }
    },

    /**
     * Compte le nombre total d'éléments d'une ressource
     */
    getTotal: async (resource: string, filters: SimpleFilters = {}): Promise<number> => {
      try {
        log('getTotal', resource, filters);
        
        const result = await dataProvider.getList(resource, {
          pagination: { page: 1, perPage: 1 },
          sort: { field: 'id', order: 'ASC' },
          filter: filters
        });
        
        return result.total;
      } catch (error) {
        return handleError(error as Error, 'getTotal', resource);
      }
    },

    /**
     * Test de connectivité pour une ressource
     */
    testConnection: async (resource: string = 'employees'): Promise<{ success: boolean; message: string; resource?: string }> => {
      try {
        await dataProvider.getList(resource, {
          pagination: { page: 1, perPage: 1 },
          sort: { field: 'id', order: 'ASC' },
          filter: {}
        });
        return { success: true, message: `Connexion API ${resource} réussie` };
      } catch (error) {
        return { 
          success: false, 
          message: (error as Error).message, 
          resource 
        };
      }
    },

    /**
     * Récupère la configuration d'une ressource
     */
    getResourceConfig: (resource: string): ResourceConfig => {
      return finalConfig.resourceConfig?.[resource] || {};
    },

    /**
     * Met à jour la configuration d'une ressource
     */
    setResourceConfig: (resource: string, config: ResourceConfig): void => {
      if (!finalConfig.resourceConfig) {
        finalConfig.resourceConfig = {};
      }
      finalConfig.resourceConfig[resource] = { 
        ...finalConfig.resourceConfig[resource], 
        ...config 
      };
    }
  };

  return dataProvider;
};

// ===== HELPERS ET UTILITAIRES =====

/**
 * Factory pour créer des filtres universels
 */
export const createFilter = (field: string, operator: string, value: string | number | boolean): AdvancedFilter => ({
  field,
  operator: operator as any,
  value
});

/**
 * Factory pour créer des tris universels
 */
export const createSort = (field: string, order: 'ASC' | 'DESC' = 'ASC'): MultiSort => ({
  field,
  order: order.toUpperCase() as 'ASC' | 'DESC'
});

/**
 * Helpers pour les opérateurs de filtres les plus communs
 */
export const FilterOperators = {
  EQUALS: '=' as const,
  NOT_EQUALS: '!=' as const,
  LIKE: 'like' as const,
  CONTAINS: 'contains' as const,
  GREATER_THAN: '>' as const,
  GREATER_THAN_OR_EQUAL: '>=' as const,
  LESS_THAN: '<' as const,
  LESS_THAN_OR_EQUAL: '<=' as const,
  
  // Helpers pour créer des filtres rapidement
  equals: (field: string, value: string | number | boolean) => createFilter(field, FilterOperators.EQUALS, value),
  notEquals: (field: string, value: string | number | boolean) => createFilter(field, FilterOperators.NOT_EQUALS, value),
  like: (field: string, value: string) => createFilter(field, FilterOperators.LIKE, value),
  contains: (field: string, value: string) => createFilter(field, FilterOperators.CONTAINS, value),
  greaterThan: (field: string, value: number) => createFilter(field, FilterOperators.GREATER_THAN, value),
  greaterThanOrEqual: (field: string, value: number) => createFilter(field, FilterOperators.GREATER_THAN_OR_EQUAL, value),
  lessThan: (field: string, value: number) => createFilter(field, FilterOperators.LESS_THAN, value),
  lessThanOrEqual: (field: string, value: number) => createFilter(field, FilterOperators.LESS_THAN_OR_EQUAL, value)
};

/**
 * Helpers pour les ordres de tri
 */
export const SortOrders = {
  ASC: 'ASC' as const,
  DESC: 'DESC' as const,
  
  // Helpers pour créer des tris rapidement
  ascending: (field: string) => createSort(field, SortOrders.ASC),
  descending: (field: string) => createSort(field, SortOrders.DESC)
};

/**
 * Configurations prédéfinies pour les ressources communes
 */
export const ResourceConfigs: Record<string, ResourceConfig> = {
  // Configuration pour les employés
  employees: {
    transformParams: (query: Record<string, any>) => {
      // Transformations spécifiques aux employés si nécessaire
      return query;
    },
    transformResponse: (data: any) => {
      // Transformations de réponse spécifiques aux employés
      return data;
    }
  },
  
  // Configuration pour les clients
  customers: {
    transformParams: (query: Record<string, any>) => {
      // Transformations spécifiques aux clients
      return query;
    },
    transformResponse: (data: any) => {
      // Transformations de réponse spécifiques aux clients
      return data;
    }
  },
  
  // Configuration générique
  generic: {
    transformParams: (query: Record<string, any>) => query,
    transformResponse: (data: any) => data
  }
};

// ===== INSTANCES PRÉDÉFINIES =====

/**
 * Instance par défaut du data provider universel
 */
export const universalDataProvider = createUniversalDataProvider();

/**
 * Instance avec logs activés pour le debug
 */
export const debugDataProvider = createUniversalDataProvider({
  enableLogs: true
});

/**
 * Instance avec configurations de ressources prédéfinies
 */
export const configuredDataProvider = createUniversalDataProvider({
  resourceConfig: ResourceConfigs
});

// Export par défaut
export default {
  createUniversalDataProvider,
  universalDataProvider,
  debugDataProvider,
  configuredDataProvider,
  createFilter,
  createSort,
  FilterOperators,
  SortOrders,
  ResourceConfigs
};