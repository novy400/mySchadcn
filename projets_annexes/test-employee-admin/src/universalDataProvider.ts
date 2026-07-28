/**
 * Data Provider Universel TypeScript pour APIs REST IBM i
 * 
 * Data provider générique compatible avec React-Admin et toutes les ressources
 * suivant le pattern API REST IBM i standard (Employee, Customer, Product, etc.)
 * 
 * @author ArchiAPI Template
 * @version 1.0.0
 * @date 2025-10-07
 */

import { DataProvider, HttpError } from 'react-admin';

// ===== TYPES UNIVERSELS =====

/**
 * Interface de base pour toute ressource API IBM i
 */
export interface BaseResource {
  id: string;
  [key: string]: any;
}

/**
 * Configuration du data provider universel
 */
export interface UniversalDataProviderConfig {
  /** URL de base de l'API (ex: http://server:44000/api) */
  apiUrl: string;
  /** Timeout des requêtes en ms (défaut: 30000) */
  timeout?: number;
  /** Headers HTTP personnalisés */
  headers?: Record<string, string>;
  /** Activer les logs de debug */
  enableLogs?: boolean;
  /** Configuration par ressource */
  resources?: Record<string, ResourceConfig>;
  /** Client HTTP personnalisé */
  httpClient?: HttpClient;
}

/**
 * Configuration spécifique par ressource
 */
export interface ResourceConfig {
  /** Nom de la ressource dans l'URL (défaut: clé) */
  endpoint?: string;
  /** Champs par défaut pour le tri */
  defaultSort?: { field: string; order: 'ASC' | 'DESC' };
  /** Filtres par défaut */
  defaultFilters?: Record<string, any>;
  /** Mapping des champs pour compatibilité */
  fieldMapping?: Record<string, string>;
  /** Transformations des données */
  transformRequest?: (data: any) => any;
  transformResponse?: (data: any) => any;
}

/**
 * Client HTTP pour les requêtes
 */
export type HttpClient = (url: string, options?: RequestInit) => Promise<{
  json: any;
  headers: Headers;
  status: number;
}>;

/**
 * Paramètres de recherche avancée
 */
export interface SearchOptions {
  /** Recherche textuelle globale */
  q?: string;
  /** Filtres avancés avec opérateurs */
  filters?: AdvancedFilter[];
  /** Tri multi-niveaux */
  sorts?: MultiSort[];
  /** Pagination */
  pagination?: Pagination;
}

export interface AdvancedFilter {
  field: string;
  operator: FilterOperator;
  value: string | number | boolean;
}

export type FilterOperator = 'eq' | 'ne' | 'like' | 'gte' | 'lte' | 'gt' | 'lt' | 'in' | 'nin';

export interface MultiSort {
  field: string;
  order: 'ASC' | 'DESC';
}

export interface Pagination {
  page: number;
  perPage: number;
}

// ===== IMPLEMENTATION UNIVERSELLE =====

/**
 * Implémentation par défaut du client HTTP
 */
const defaultHttpClient: HttpClient = async (url: string, options: RequestInit = {}) => {
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...options.headers
    },
    ...options
  });

  if (!response.ok) {
    let errorBody: any;
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    
    try {
      errorBody = await response.json();
      
      // Récupération du message d'erreur standard
      if (errorBody && errorBody.message) {
        errorMessage = errorBody.message;
      }
    } catch (e) {
      // Si le body n'est pas du JSON, on garde le message par défaut
      // et on crée un body vide pour éviter les plantages
      errorBody = { message: errorMessage };
    }
    
    // ⚡ C'est ICI la correction majeure :
    // On utilise HttpError pour passer le body complet (qui contient l'objet 'errors')
    // à React-Admin. Cela permet d'afficher les erreurs sous les champs du formulaire.
    throw new HttpError(
        errorMessage, 
        response.status, 
        errorBody // Le body contient { message: "...", errors: { "genre": "..." } }
    );
  }

  const json = await response.json();
  
  return {
    json,
    headers: response.headers,
    status: response.status
  };
};

/**
 * Configuration par défaut
 */
const DEFAULT_CONFIG: Partial<UniversalDataProviderConfig> = {
  timeout: 30000,
  enableLogs: false,
  headers: {},
  resources: {},
  httpClient: defaultHttpClient
};

/**
 * Crée un data provider universel pour APIs REST IBM i
 */
export const createUniversalDataProvider = (config: UniversalDataProviderConfig): DataProvider => {
  const finalConfig = { ...DEFAULT_CONFIG, ...config };
  
  const log = (...args: any[]): void => {
    if (finalConfig.enableLogs) {
      console.log('[UniversalDataProvider]', ...args);
    }
  };

  /**
   * Obtient la configuration d'une ressource
   */
  const getResourceConfig = (resource: string): ResourceConfig => {
    return finalConfig.resources?.[resource] || {};
  };

  /**
   * Construit l'URL pour une ressource
   */
  const buildResourceUrl = (resource: string, id?: string): string => {
    const resourceConfig = getResourceConfig(resource);
    const endpoint = resourceConfig.endpoint || resource;
    const baseUrl = `${finalConfig.apiUrl}/${endpoint}`;
    return id ? `${baseUrl}/${id}` : baseUrl;
  };

  /**
   * Construit les paramètres de requête
   */
  const buildQueryParams = (params: Record<string, any>): string => {
    const searchParams = new URLSearchParams();
    
    Object.keys(params).forEach(key => {
      const value = params[key];
      if (value !== null && value !== undefined && value !== '') {
        searchParams.append(key, value.toString());
      }
    });
    
    return searchParams.toString();
  };

  /**
   * Transforme les paramètres React-Admin en paramètres API IBM i
   */
  const transformParams = (resource: string, params: any): Record<string, any> => {
    const resourceConfig = getResourceConfig(resource);
    const query: Record<string, any> = {};

    // Pagination
    if (params.pagination) {
      query._page = params.pagination.page;
      query._limit = params.pagination.perPage;
    }

    // Tri
    if (params.sort) {
      query._sort = params.sort.field;
      query._order = params.sort.order;
    } else if (resourceConfig.defaultSort) {
      query._sort = resourceConfig.defaultSort.field;
      query._order = resourceConfig.defaultSort.order;
    }

    // Filtres
    if (params.filter) {
      Object.keys(params.filter).forEach(key => {
        const value = params.filter[key];
        if (key === 'q') {
          // Recherche globale
          query.q = value;
        } else {
          // Filtres par champ avec support des opérateurs
          if (key.includes('_')) {
            // Filtres avec opérateurs (ex: salary_gte, name_like)
            query[key] = value;
          } else {
            // Filtres simples
            query[key] = value;
          }
        }
      });
    }

    // Filtres par défaut
    if (resourceConfig.defaultFilters) {
      Object.assign(query, resourceConfig.defaultFilters);
    }

    return query;
  };

  /**
   * Transforme les données selon la configuration de la ressource
   */
  const transformData = (resource: string, data: any, direction: 'request' | 'response'): any => {
    const resourceConfig = getResourceConfig(resource);
    
    if (direction === 'request' && resourceConfig.transformRequest) {
      return resourceConfig.transformRequest(data);
    }
    
    if (direction === 'response' && resourceConfig.transformResponse) {
      return resourceConfig.transformResponse(data);
    }
    
    // Mapping des champs si configuré
    if (resourceConfig.fieldMapping && Array.isArray(data)) {
      return data.map(item => {
        const mappedItem = { ...item };
        Object.keys(resourceConfig.fieldMapping!).forEach(from => {
          const to = resourceConfig.fieldMapping![from];
          if (mappedItem[from] !== undefined) {
            mappedItem[to] = mappedItem[from];
            if (from !== to) {
              delete mappedItem[from];
            }
          }
        });
        return mappedItem;
      });
    }
    
    if (resourceConfig.fieldMapping && !Array.isArray(data)) {
      const mappedItem = { ...data };
      Object.keys(resourceConfig.fieldMapping).forEach(from => {
        const to = resourceConfig.fieldMapping![from];
        if (mappedItem[from] !== undefined) {
          mappedItem[to] = mappedItem[from];
          if (from !== to) {
            delete mappedItem[from];
          }
        }
      });
      return mappedItem;
    }
    
    return data;
  };

  /**
   * Parse les headers de réponse
   */
  const parseHeaders = (headers: Headers): { total: number } => {
    const totalCount = headers.get('x-total-count') || headers.get('X-Total-Count');
    return {
      total: totalCount ? parseInt(totalCount, 10) : 0
    };
  };

  /**
   * Gère les erreurs de manière standardisée
   */
  const handleError = (error: Error, operation: string, resource: string): never => {
    log(`Error in ${operation} for ${resource}:`, error);
    
    // ⚡ CORRECTION : Si c'est déjà une HttpError (validation RPG), on la laisse passer !
    // Sinon React-Admin ne verra jamais l'objet "errors" à l'intérieur.
    if (error instanceof HttpError) {
        throw error;
    }
    
    // Pour les autres erreurs techniques (réseau, crash JS...), on enrichit le message
    const enrichedError = new Error(`${operation} failed for ${resource}: ${error.message}`) as any;
    enrichedError.originalError = error;
    enrichedError.operation = operation;
    enrichedError.resource = resource;
    
    throw enrichedError;
  };

  // ===== IMPLEMENTATION DU DATA PROVIDER =====

  const dataProvider: DataProvider = {
    /**
     * Récupère une liste de ressources
     */
    getList: async (resource: string, params: any) => {
      try {
        log(`getList ${resource}`, params);
        
        const query = transformParams(resource, params);
        const url = buildResourceUrl(resource);
        const queryString = buildQueryParams(query);
        const fullUrl = queryString ? `${url}?${queryString}` : url;
        
        const { headers, json } = await finalConfig.httpClient!(fullUrl, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const { total } = parseHeaders(headers);
        const transformedData = transformData(resource, json, 'response');
        
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
    getOne: async (resource: string, params: any) => {
      try {
        log(`getOne ${resource}`, params);
        
        const url = buildResourceUrl(resource, params.id);
        const { json } = await finalConfig.httpClient!(url, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const transformedData = transformData(resource, json, 'response');
        
        return { data: transformedData };
      } catch (error) {
        return handleError(error as Error, 'getOne', resource);
      }
    },

    /**
     * Récupère plusieurs ressources par leurs IDs
     */
    getMany: async (resource: string, params: any) => {
      try {
        log(`getMany ${resource}`, params);
        
        const requests = params.ids.map((id: string) =>
          finalConfig.httpClient!(buildResourceUrl(resource, id), {
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
        );
        
        const responses = await Promise.all(requests);
        const data = responses.map(({ json }) => transformData(resource, json, 'response'));
        
        return { data };
      } catch (error) {
        return handleError(error as Error, 'getMany', resource);
      }
    },

    /**
     * Récupère des ressources liées à une autre ressource
     */
    getManyReference: async (resource: string, params: any) => {
      try {
        log(`getManyReference ${resource}`, params);
        
        const query = transformParams(resource, params);
        // Ajouter le filtre de référence
        query[params.target] = params.id;
        
        const url = buildResourceUrl(resource);
        const queryString = buildQueryParams(query);
        const fullUrl = queryString ? `${url}?${queryString}` : url;
        
        const { headers, json } = await finalConfig.httpClient!(fullUrl, {
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const { total } = parseHeaders(headers);
        const transformedData = transformData(resource, json, 'response');
        
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
    create: async (resource: string, params: any) => {
      try {
        log(`create ${resource}`, params);
        
        const transformedData = transformData(resource, params.data, 'request');
        const url = buildResourceUrl(resource);
        
        const { json } = await finalConfig.httpClient!(url, {
          method: 'POST',
          body: JSON.stringify(transformedData),
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const responseData = transformData(resource, json, 'response');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'create', resource);
      }
    },

    /**
     * Met à jour une ressource existante
     */
    update: async (resource: string, params: any) => {
      try {
        log(`update ${resource}`, params);
        
        const transformedData = transformData(resource, params.data, 'request');
        const url = buildResourceUrl(resource, params.id);
        
        const { json } = await finalConfig.httpClient!(url, {
          method: 'PUT',
          body: JSON.stringify(transformedData),
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const responseData = transformData(resource, json, 'response');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'update', resource);
      }
    },

    /**
     * Met à jour plusieurs ressources
     */
    updateMany: async (resource: string, params: any) => {
      try {
        log(`updateMany ${resource}`, params);
        
        const transformedData = transformData(resource, params.data, 'request');
        const requests = params.ids.map((id: string) =>
          finalConfig.httpClient!(buildResourceUrl(resource, id), {
            method: 'PUT',
            body: JSON.stringify(transformedData),
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
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
    delete: async (resource: string, params: any) => {
      try {
        log(`delete ${resource}`, params);
        
        const url = buildResourceUrl(resource, params.id);
        const { json } = await finalConfig.httpClient!(url, {
          method: 'DELETE',
          signal: AbortSignal.timeout(finalConfig.timeout || 30000)
        });
        
        const responseData = transformData(resource, json, 'response');
        
        return { data: responseData };
      } catch (error) {
        return handleError(error as Error, 'delete', resource);
      }
    },

    /**
     * Supprime plusieurs ressources
     */
    deleteMany: async (resource: string, params: any) => {
      try {
        log(`deleteMany ${resource}`, params);
        
        const requests = params.ids.map((id: string) =>
          finalConfig.httpClient!(buildResourceUrl(resource, id), {
            method: 'DELETE',
            signal: AbortSignal.timeout(finalConfig.timeout || 30000)
          })
        );
        
        await Promise.all(requests);
        
        return { data: params.ids };
      } catch (error) {
        return handleError(error as Error, 'deleteMany', resource);
      }
    }
  };

  return dataProvider;
};

// ===== HELPERS UTILITAIRES =====

/**
 * Crée des filtres avancés pour une ressource
 */
export const createAdvancedFilters = (filters: AdvancedFilter[]): Record<string, any> => {
  const result: Record<string, any> = {};
  
  filters.forEach(filter => {
    const { field, operator, value } = filter;
    
    switch (operator) {
      case 'like':
        result[`${field}_like`] = value;
        break;
      case 'gte':
        result[`${field}_gte`] = value;
        break;
      case 'lte':
        result[`${field}_lte`] = value;
        break;
      case 'gt':
        result[`${field}_gt`] = value;
        break;
      case 'lt':
        result[`${field}_lt`] = value;
        break;
      case 'ne':
        result[`${field}_ne`] = value;
        break;
      case 'in':
        result[`${field}_in`] = Array.isArray(value) ? value.join(',') : value;
        break;
      case 'nin':
        result[`${field}_nin`] = Array.isArray(value) ? value.join(',') : value;
        break;
      case 'eq':
      default:
        result[field] = value;
        break;
    }
  });
  
  return result;
};

/**
 * Crée une configuration de ressource pré-configurée pour Employee
 */
export const createEmployeeResourceConfig = (): ResourceConfig => ({
  endpoint: 'employees',
  defaultSort: { field: 'nom', order: 'ASC' },
  defaultFilters: {},
  fieldMapping: {}
});

/**
 * Crée une configuration de ressource pré-configurée pour Customer
 */
export const createCustomerResourceConfig = (): ResourceConfig => ({
  endpoint: 'customers',
  defaultSort: { field: 'lastName', order: 'ASC' },
  defaultFilters: { status: 'active' },
  fieldMapping: {
    'lastName': 'nom',
    'firstName': 'prenom'
  }
});

// ===== EXPORT CONFIGURÉ POUR EMPLOYEE =====

/**
 * Data provider pré-configuré pour Employee (exemple)
 */
export const createEmployeeDataProvider = (apiUrl: string, additionalConfig?: Partial<UniversalDataProviderConfig>): DataProvider => {
  return createUniversalDataProvider({
    apiUrl,
    resources: {
      employees: createEmployeeResourceConfig()
    },
    ...additionalConfig
  });
};

export default createUniversalDataProvider;