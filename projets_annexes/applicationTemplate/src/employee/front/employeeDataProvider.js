/**
 * Employee Data Provider - Compatible avec l'API REST IBM i Employee
 * 
 * Compatible avec React-Admin, mais aussi utilisable de manière standalone
 * Supporte tous les paramètres avancés de l'API Employee (filtres, tri multi-niveaux, recherche)
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
  timeout: 30000
};

/**
 * Crée un data provider pour l'API Employee
 * @param {Object} config - Configuration du data provider
 * @param {string} config.apiUrl - URL de base de l'API
 * @param {Function} config.httpClient - Client HTTP à utiliser
 * @param {number} config.timeout - Timeout des requêtes
 * @returns {Object} Data provider compatible React-Admin
 */
export const createEmployeeDataProvider = (config = {}) => {
  const { apiUrl, httpClient, timeout } = { ...DEFAULT_CONFIG, ...config };

  /**
   * Helper pour construire les paramètres de requête avec support des filtres avancés
   */
  const buildQueryParams = (params) => {
    const query = {};

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
        if (key === 'q') {
          // Recherche générale
          query.q = params.filter[key];
        } else {
          // Filtres par champ
          query[key] = params.filter[key];
        }
      });
    }

    // Filtres avancés avec opérateurs (spécifique à notre API)
    if (params.advancedFilters) {
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
  const parseResponseHeaders = (headers) => {
    const totalCount = headers.get('x-total-count') || headers.get('X-Total-Count');
    return {
      total: totalCount ? parseInt(totalCount, 10) : 0
    };
  };

  /**
   * Helper pour gérer les erreurs
   */
  const handleError = (error, operation) => {
    console.error(`Employee API Error [${operation}]:`, error);
    
    // Enrichir l'erreur avec des informations contextuelles
    const enrichedError = new Error(`Employee API ${operation} failed: ${error.message}`);
    enrichedError.originalError = error;
    enrichedError.operation = operation;
    
    throw enrichedError;
  };

  // Data provider object
  return {
    /**
     * Récupère une liste d'employés avec pagination, filtres et tri
     */
    getList: async (resource, params) => {
      try {
        const query = buildQueryParams(params);
        const url = `${apiUrl}/${resource}?${stringify(query)}`;
        
        const { headers, json } = await httpClient(url, {
          signal: AbortSignal.timeout(timeout)
        });
        
        const { total } = parseResponseHeaders(headers);
        
        return {
          data: json,
          total: total
        };
      } catch (error) {
        handleError(error, 'getList');
      }
    },

    /**
     * Récupère un employé par son ID
     */
    getOne: async (resource, params) => {
      try {
        const url = `${apiUrl}/${resource}/${params.id}`;
        const { json } = await httpClient(url, {
          signal: AbortSignal.timeout(timeout)
        });
        
        return { data: json };
      } catch (error) {
        handleError(error, 'getOne');
      }
    },

    /**
     * Récupère plusieurs employés par leurs IDs
     */
    getMany: async (resource, params) => {
      try {
        const requests = params.ids.map(id => 
          httpClient(`${apiUrl}/${resource}/${id}`, {
            signal: AbortSignal.timeout(timeout)
          })
        );
        
        const responses = await Promise.all(requests);
        return { 
          data: responses.map(({ json }) => json) 
        };
      } catch (error) {
        handleError(error, 'getMany');
      }
    },

    /**
     * Récupère des employés liés à une ressource (ex: employés d'un département)
     */
    getManyReference: async (resource, params) => {
      try {
        const query = buildQueryParams(params);
        // Ajouter le filtre de référence
        query[params.target] = params.id;
        
        const url = `${apiUrl}/${resource}?${stringify(query)}`;
        const { headers, json } = await httpClient(url, {
          signal: AbortSignal.timeout(timeout)
        });
        
        const { total } = parseResponseHeaders(headers);
        
        return {
          data: json,
          total: total
        };
      } catch (error) {
        handleError(error, 'getManyReference');
      }
    },

    /**
     * Crée un nouvel employé
     */
    create: async (resource, params) => {
      try {
        const { json } = await httpClient(`${apiUrl}/${resource}`, {
          method: 'POST',
          body: JSON.stringify(params.data),
          signal: AbortSignal.timeout(timeout)
        });
        
        return { data: json };
      } catch (error) {
        handleError(error, 'create');
      }
    },

    /**
     * Met à jour un employé existant
     */
    update: async (resource, params) => {
      try {
        const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
          method: 'PUT',
          body: JSON.stringify(params.data),
          signal: AbortSignal.timeout(timeout)
        });
        
        return { data: json };
      } catch (error) {
        handleError(error, 'update');
      }
    },

    /**
     * Met à jour plusieurs employés
     */
    updateMany: async (resource, params) => {
      try {
        const requests = params.ids.map(id =>
          httpClient(`${apiUrl}/${resource}/${id}`, {
            method: 'PUT',
            body: JSON.stringify(params.data),
            signal: AbortSignal.timeout(timeout)
          })
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        handleError(error, 'updateMany');
      }
    },

    /**
     * Supprime un employé
     */
    delete: async (resource, params) => {
      try {
        const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
          method: 'DELETE',
          signal: AbortSignal.timeout(timeout)
        });
        
        return { data: json };
      } catch (error) {
        handleError(error, 'delete');
      }
    },

    /**
     * Supprime plusieurs employés
     */
    deleteMany: async (resource, params) => {
      try {
        const requests = params.ids.map(id =>
          httpClient(`${apiUrl}/${resource}/${id}`, { 
            method: 'DELETE',
            signal: AbortSignal.timeout(timeout)
          })
        );
        
        await Promise.all(requests);
        return { data: params.ids };
      } catch (error) {
        handleError(error, 'deleteMany');
      }
    },

    // Méthodes spécifiques à l'API Employee

    /**
     * Recherche d'employés avec filtres avancés
     * @param {Object} searchParams - Paramètres de recherche avancés
     * @param {string} searchParams.q - Recherche globale
     * @param {Array} searchParams.filters - Filtres avec opérateurs
     * @param {Array} searchParams.sorts - Tri multi-niveaux
     * @param {Object} searchParams.pagination - Pagination
     */
    searchEmployees: async (searchParams) => {
      try {
        const params = {
          pagination: searchParams.pagination || { page: 1, perPage: 10 },
          filter: searchParams.q ? { q: searchParams.q } : {},
          advancedFilters: searchParams.filters || [],
          multiSort: searchParams.sorts || []
        };
        
        return await this.getList('employees', params);
      } catch (error) {
        handleError(error, 'searchEmployees');
      }
    },

    /**
     * Récupère des statistiques sur les employés
     */
    getEmployeeStats: async () => {
      try {
        // Utiliser l'API existante pour compter
        const { total } = await this.getList('employees', {
          pagination: { page: 1, perPage: 1 }
        });
        
        return {
          totalEmployees: total,
          // Ici on pourrait ajouter d'autres stats si l'API les supportait
        };
      } catch (error) {
        handleError(error, 'getEmployeeStats');
      }
    }
  };
};

// Instance par défaut pour usage direct
export const employeeDataProvider = createEmployeeDataProvider();

// Export des helpers pour usage avancé
export const employeeApiHelpers = {
  buildQueryParams: (params) => {
    const provider = createEmployeeDataProvider();
    return provider.buildQueryParams ? provider.buildQueryParams(params) : {};
  },
  
  createAdvancedFilter: (field, operator, value) => ({
    field,
    operator,
    value
  }),
  
  createMultiSort: (sorts) => sorts.map(sort => ({
    field: sort.field,
    order: sort.order || 'ASC'
  }))
};