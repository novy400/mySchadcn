/**
 * Universal Data Provider - Compatible avec toutes les APIs REST IBM i
 * 
 * Data provider universel compatible React-Admin pour toutes les ressources
 * Supporte tous les patterns de l'API REST standard IBM i (Employee, Customer, etc.)
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
 */

import { fetchUtils } from 'react-admin';
import { stringify } from 'query-string';

// Configuration par défaut
const DEFAULT_CONFIG = {
  apiUrl: 'http://localhost:44000/api',
  httpClient: fetchUtils.fetchJson,
  timeout: 30000,
  headers: {},
  enableLogs: false
};

/**
 * Crée un data provider universel pour les APIs IBM i
 * @param {Object} config - Configuration du data provider
 * @param {string} config.apiUrl - URL de base de l'API
 * @param {Function} config.httpClient - Client HTTP à utiliser
 * @param {number} config.timeout - Timeout des requêtes
 * @param {Object} config.headers - Headers personnalisés
 * @param {boolean} config.enableLogs - Activer les logs de debug
 * @param {Object} config.resourceConfig - Configuration spécifique par ressource
 * @returns {Object} Data provider universel compatible React-Admin
 */
export const createUniversalDataProvider = (config = {}) => {
  const finalConfig = { ...DEFAULT_CONFIG, ...config };
  
  const log = (...args) => {
    if (finalConfig.enableLogs) {
      console.log('[UniversalDataProvider]', ...args);
    }
  };

  /**
   * Helper pour construire les paramètres de requête universels
   */
  const buildQueryParams = (params, resource) => {
    const query = {};
    
    // Configuration spécifique à la ressource
    const resourceConfig = finalConfig.resourceConfig?.[resource] || {};

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
    if (params.multiSort) {
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
        const value = params.filter[key];
        
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
    if (params.advancedFilters) {
      params.advancedFilters.forEach(filter => {
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
  const parseResponseHeaders = (headers, resource) => {
    const resourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    // Header X-Total-Count standard
    let totalCount = headers.get('x-total-count') || headers.get('X-Total-Count');
    
    // Transformation spécifique à la ressource
    if (resourceConfig.parseTotalCount) {
      totalCount = resourceConfig.parseTotalCount(headers, totalCount);
    }
    
    return {
      total: totalCount ? parseInt(totalCount, 10) : 0
    };
  };

  /**
   * Helper pour transformer les données de réponse
   */
  const transformResponseData = (data, resource, operation) => {
    const resourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    if (resourceConfig.transformResponse) {
      return resourceConfig.transformResponse(data, operation);
    }
    
    return data;
  };

  /**
   * Helper pour transformer les données de requête
   */
  const transformRequestData = (data, resource, operation) => {
    const resourceConfig = finalConfig.resourceConfig?.[resource] || {};
    
    if (resourceConfig.transformRequest) {
      return resourceConfig.transformRequest(data, operation);
    }
    
    return data;
  };

  /**
   * Helper pour gérer les erreurs
   */
  const handleError = (error, operation, resource) => {
    const errorMessage = `Universal API Error [${operation}/${resource}]: ${error.message}`;
    
    if (finalConfig.enableLogs) {
      console.error(errorMessage, error);
    }
    
    // Enrichir l'erreur avec des informations contextuelles
    const enrichedError = new Error(errorMessage);
    enrichedError.originalError = error;
    enrichedError.operation = operation;
    enrichedError.resource = resource;
    
    throw enrichedError;
  };

  /**
   * Helper pour créer les options de requête HTTP
   */
  const createRequestOptions = (method = 'GET', body = null) => {
    const options = {
      method,
      headers: { ...finalConfig.headers },
      signal: AbortSignal.timeout(finalConfig.timeout)
    };

    if (body) {
      options.body = JSON.stringify(body);
      options.headers['Content-Type'] = 'application/json';
    }

    return options;
  };

  // Data provider object universel
  return {
    /**
     * Récupère une liste de ressources avec pagination, filtres et tri
     */
    getList: async (resource, params) => {
      try {
        log('getList', resource, params);
        
        const query = buildQueryParams(params, resource);
        const url = `${finalConfig.apiUrl}/${resource}?${stringify(query)}`;
        
        log('Request URL:', url);
        
        const { headers, json } = await finalConfig.httpClient(url, createRequestOptions());
        
        const { total } = parseResponseHeaders(headers, resource);
        const transformedData = transformResponseData(json, resource, 'getList');
        
        log('Response:', { total, count: transformedData.length });
        
        return {
          data: transformedData,
          total: total
        };
      } catch (error) {
        handleError(error, 'getList', resource);
      }
    },

    /**
     * Récupère une ressource par son ID
     */
    getOne: async (resource, params) => {
      try {
        log('getOne', resource, params.id);
        
        const url = `${finalConfig.apiUrl}/${resource}/${params.id}`;
        const { json } = await finalConfig.httpClient(url, createRequestOptions());
        
        const transformedData = transformResponseData(json, resource, 'getOne');
        
        return { data: transformedData };
      } catch (error) {
        handleError(error, 'getOne', resource);
      }
    },

    /**
     * Récupère plusieurs ressources par leurs IDs
     */
    getMany: async (resource, params) => {
      try {
        log('getMany', resource, params.ids);
        
        const requests = params.ids.map(id => 
          finalConfig.httpClient(`${finalConfig.apiUrl}/${resource}/${id}`, createRequestOptions())
        );
        
        const responses = await Promise.all(requests);
        const data = responses.map(({ json }) => transformResponseData(json, resource, 'getMany'));
        
        return { data };
      } catch (error) {
        handleError(error, 'getMany', resource);
      }
    },

    /**
     * Récupère des ressources liées à une autre ressource
     */
    getManyReference: async (resource, params) => {
      try {
        log('getManyReference', resource, params);
        
        const query = buildQueryParams(params, resource);
        // Ajouter le filtre de référence
        query[params.target] = params.id;
        
        const url = `${finalConfig.apiUrl}/${resource}?${stringify(query)}`;
        const { headers, json } = await finalConfig.httpClient(url, createRequestOptions());
        
        const { total } = parseResponseHeaders(headers, resource);
        const transformedData = transformResponseData(json, resource, 'getManyReference');
        
        return {
          data: transformedData,
          total: total
        };
      } catch (error) {
        handleError(error, 'getManyReference', resource);
      }
    },

    /**
     * Crée une nouvelle ressource
     */
    create: async (resource, params) => {
      try {
        log('create', resource, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'create');
        
        const { json } = await finalConfig.httpClient(
          `${finalConfig.apiUrl}/${resource}`, 
          createRequestOptions('POST', transformedData)
        );
        
        const responseData = transformResponseData(json, resource, 'create');
        
        return { data: responseData };
      } catch (error) {
        handleError(error, 'create', resource);
      }
    },

    /**
     * Met à jour une ressource existante
     */
    update: async (resource, params) => {
      try {
        log('update', resource, params.id, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'update');
        
        const { json } = await finalConfig.httpClient(
          `${finalConfig.apiUrl}/${resource}/${params.id}`, 
          createRequestOptions('PUT', transformedData)
        );
        
        const responseData = transformResponseData(json, resource, 'update');
        
        return { data: responseData };
      } catch (error) {
        handleError(error, 'update', resource);
      }
    },

    /**
     * Met à jour plusieurs ressources
     */
    updateMany: async (resource, params) => {
      try {
        log('updateMany', resource, params.ids, params.data);
        
        const transformedData = transformRequestData(params.data, resource, 'updateMany');
        
        const requests = params.ids.map(id =>
          finalConfig.httpClient(
            `${finalConfig.apiUrl}/${resource}/${id}`, 
            createRequestOptions('PUT', transformedData)
          )
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        handleError(error, 'updateMany', resource);
      }
    },

    /**
     * Supprime une ressource
     */
    delete: async (resource, params) => {
      try {
        log('delete', resource, params.id);
        
        const { json } = await finalConfig.httpClient(
          `${finalConfig.apiUrl}/${resource}/${params.id}`, 
          createRequestOptions('DELETE')
        );
        
        const responseData = transformResponseData(json, resource, 'delete');
        
        return { data: responseData };
      } catch (error) {
        handleError(error, 'delete', resource);
      }
    },

    /**
     * Supprime plusieurs ressources
     */
    deleteMany: async (resource, params) => {
      try {
        log('deleteMany', resource, params.ids);
        
        const requests = params.ids.map(id =>
          finalConfig.httpClient(
            `${finalConfig.apiUrl}/${resource}/${id}`, 
            createRequestOptions('DELETE')
          )
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        handleError(error, 'deleteMany', resource);
      }
    },

    // Méthodes étendues universelles

    /**
     * Recherche universelle avec filtres avancés
     */
    search: async (resource, searchParams) => {
      try {
        log('search', resource, searchParams);
        
        const params = {
          pagination: searchParams.pagination || { page: 1, perPage: 10 },
          filter: searchParams.q ? { q: searchParams.q } : {},
          advancedFilters: searchParams.filters || [],
          multiSort: searchParams.sorts || []
        };
        
        return await this.getList(resource, params);
      } catch (error) {
        handleError(error, 'search', resource);
      }
    },

    /**
     * Compte le nombre total d'éléments d'une ressource
     */
    getTotal: async (resource, filters = {}) => {
      try {
        log('getTotal', resource, filters);
        
        const { total } = await this.getList(resource, {
          pagination: { page: 1, perPage: 1 },
          filter: filters
        });
        
        return total;
      } catch (error) {
        handleError(error, 'getTotal', resource);
      }
    },

    /**
     * Test de connectivité pour une ressource
     */
    testConnection: async (resource = 'employees') => {
      try {
        await this.getList(resource, {
          pagination: { page: 1, perPage: 1 }
        });
        return { success: true, message: `Connexion API ${resource} réussie` };
      } catch (error) {
        return { success: false, message: error.message, resource };
      }
    },

    /**
     * Récupère la configuration d'une ressource
     */
    getResourceConfig: (resource) => {
      return finalConfig.resourceConfig?.[resource] || {};
    },

    /**
     * Met à jour la configuration d'une ressource
     */
    setResourceConfig: (resource, config) => {
      if (!finalConfig.resourceConfig) {
        finalConfig.resourceConfig = {};
      }
      finalConfig.resourceConfig[resource] = { 
        ...finalConfig.resourceConfig[resource], 
        ...config 
      };
    }
  };
};

// ===== HELPERS ET UTILITAIRES =====

/**
 * Factory pour créer des filtres universels
 */
export const createFilter = (field, operator, value) => ({
  field,
  operator,
  value
});

/**
 * Factory pour créer des tris universels
 */
export const createSort = (field, order = 'ASC') => ({
  field,
  order: order.toUpperCase()
});

/**
 * Helpers pour les opérateurs de filtres les plus communs
 */
export const FilterOperators = {
  EQUALS: '=',
  NOT_EQUALS: '!=',
  LIKE: 'like',
  CONTAINS: 'contains',
  GREATER_THAN: '>',
  GREATER_THAN_OR_EQUAL: '>=',
  LESS_THAN: '<',
  LESS_THAN_OR_EQUAL: '<=',
  
  // Helpers pour créer des filtres rapidement
  equals: (field, value) => createFilter(field, FilterOperators.EQUALS, value),
  notEquals: (field, value) => createFilter(field, FilterOperators.NOT_EQUALS, value),
  like: (field, value) => createFilter(field, FilterOperators.LIKE, value),
  contains: (field, value) => createFilter(field, FilterOperators.CONTAINS, value),
  greaterThan: (field, value) => createFilter(field, FilterOperators.GREATER_THAN, value),
  greaterThanOrEqual: (field, value) => createFilter(field, FilterOperators.GREATER_THAN_OR_EQUAL, value),
  lessThan: (field, value) => createFilter(field, FilterOperators.LESS_THAN, value),
  lessThanOrEqual: (field, value) => createFilter(field, FilterOperators.LESS_THAN_OR_EQUAL, value)
};

/**
 * Helpers pour les ordres de tri
 */
export const SortOrders = {
  ASC: 'ASC',
  DESC: 'DESC',
  
  // Helpers pour créer des tris rapidement
  ascending: (field) => createSort(field, SortOrders.ASC),
  descending: (field) => createSort(field, SortOrders.DESC)
};

/**
 * Configurations prédéfinies pour les ressources communes
 */
export const ResourceConfigs = {
  // Configuration pour les employés
  employees: {
    transformParams: (query, params) => {
      // Transformations spécifiques aux employés si nécessaire
      return query;
    },
    transformResponse: (data, operation) => {
      // Transformations de réponse spécifiques aux employés
      return data;
    }
  },
  
  // Configuration pour les clients
  customers: {
    transformParams: (query, params) => {
      // Transformations spécifiques aux clients
      return query;
    },
    transformResponse: (data, operation) => {
      // Transformations de réponse spécifiques aux clients
      return data;
    }
  },
  
  // Configuration générique
  generic: {
    transformParams: (query, params) => query,
    transformResponse: (data, operation) => data
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