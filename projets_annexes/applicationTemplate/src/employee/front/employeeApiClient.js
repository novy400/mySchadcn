/**
 * Employee API Client - Client JavaScript pour l'API Employee IBM i
 * 
 * Client standalone pour interagir avec l'API Employee sans dépendances React-Admin
 * Supporte tous les paramètres avancés de l'API (filtres, tri, recherche)
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
 */

/**
 * Configuration par défaut du client
 */
const DEFAULT_CONFIG = {
  baseUrl: 'http://localhost:44000/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
};

/**
 * Client API Employee
 */
export class EmployeeApiClient {
  constructor(config = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Effectue une requête HTTP avec gestion d'erreurs
   */
  async #request(endpoint, options = {}) {
    const url = `${this.config.baseUrl}/${endpoint}`;
    
    const requestOptions = {
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
      if (error.name === 'AbortError') {
        throw new Error('Request timeout');
      }
      throw error;
    }
  }

  /**
   * Construit les paramètres d'URL pour les requêtes GET
   */
  #buildUrlParams(params = {}) {
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
  async getEmployees(options = {}) {
    const {
      page = 1,
      limit = 10,
      sort = 'nom',
      order = 'ASC',
      search = '',
      filters = {},
      multiSort = []
    } = options;

    const params = {
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

    const queryString = this.#buildUrlParams(params);
    const endpoint = `employees${queryString ? '?' + queryString : ''}`;
    
    const response = await this.#request(endpoint);
    
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
  async getEmployee(id) {
    const response = await this.#request(`employees/${id}`);
    return response.data;
  }

  /**
   * Crée un nouvel employé
   */
  async createEmployee(employeeData) {
    const response = await this.#request('employees', {
      method: 'POST',
      body: JSON.stringify(employeeData)
    });
    return response.data;
  }

  /**
   * Met à jour un employé existant
   */
  async updateEmployee(id, employeeData) {
    const response = await this.#request(`employees/${id}`, {
      method: 'PUT',
      body: JSON.stringify(employeeData)
    });
    return response.data;
  }

  /**
   * Supprime un employé
   */
  async deleteEmployee(id) {
    const response = await this.#request(`employees/${id}`, {
      method: 'DELETE'
    });
    return response.data;
  }

  // ===== MÉTHODES DE RECHERCHE AVANCÉE =====

  /**
   * Recherche d'employés avec filtres avancés
   */
  async searchEmployees(searchOptions = {}) {
    const {
      query = '',
      filters = [],
      sorts = [],
      page = 1,
      limit = 10
    } = searchOptions;

    const params = {
      _page: page,
      _limit: limit
    };

    // Recherche globale
    if (query) {
      params.q = query;
    }

    // Filtres avancés avec opérateurs
    filters.forEach(filter => {
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
    sorts.forEach((sort, index) => {
      if (index === 0) {
        params._sort = sort.field;
        params._order = sort.order || 'ASC';
      } else {
        params[`sort${index}`] = sort.field;
        params[`order${index}`] = sort.order || 'ASC';
      }
    });

    const queryString = this.#buildUrlParams(params);
    const endpoint = `employees${queryString ? '?' + queryString : ''}`;
    
    const response = await this.#request(endpoint);
    
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
   * Recherche d'employés par département
   */
  async getEmployeesByDepartment(departmentCode, options = {}) {
    return this.searchEmployees({
      filters: [
        { field: 'service', operator: 'eq', value: departmentCode }
      ],
      ...options
    });
  }

  /**
   * Recherche d'employés par plage de salaire
   */
  async getEmployeesBySalaryRange(minSalary, maxSalary, options = {}) {
    const filters = [];
    
    if (minSalary !== null && minSalary !== undefined) {
      filters.push({ field: 'salaire', operator: 'gte', value: minSalary });
    }
    
    if (maxSalary !== null && maxSalary !== undefined) {
      filters.push({ field: 'salaire', operator: 'lte', value: maxSalary });
    }

    return this.searchEmployees({
      filters,
      ...options
    });
  }

  /**
   * Recherche d'employés par date d'embauche
   */
  async getEmployeesByHireDate(startDate, endDate, options = {}) {
    const filters = [];
    
    if (startDate) {
      filters.push({ field: 'dateEmbauche', operator: 'gte', value: startDate });
    }
    
    if (endDate) {
      filters.push({ field: 'dateEmbauche', operator: 'lte', value: endDate });
    }

    return this.searchEmployees({
      filters,
      sorts: [{ field: 'dateEmbauche', order: 'DESC' }],
      ...options
    });
  }

  // ===== MÉTHODES UTILITAIRES =====

  /**
   * Récupère les statistiques des employés
   */
  async getEmployeeStatistics() {
    // Utiliser l'API pour obtenir le total
    const result = await this.getEmployees({ page: 1, limit: 1 });
    
    return {
      totalEmployees: result.total,
      // Ici on pourrait ajouter d'autres statistiques si l'API les supportait
    };
  }

  /**
   * Valide les données d'un employé avant création/modification
   */
  validateEmployeeData(employeeData) {
    const errors = [];
    
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
  async testConnection() {
    try {
      await this.getEmployees({ page: 1, limit: 1 });
      return { success: true, message: 'Connexion API réussie' };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}

// Helpers pour créer des filtres et tris facilement
export const EmployeeFilters = {
  byName: (name) => ({ field: 'nom', operator: 'like', value: name }),
  byFirstName: (firstName) => ({ field: 'prenom', operator: 'like', value: firstName }),
  byDepartment: (dept) => ({ field: 'service', operator: 'eq', value: dept }),
  byGender: (gender) => ({ field: 'genre', operator: 'eq', value: gender }),
  bySalaryMin: (minSalary) => ({ field: 'salaire', operator: 'gte', value: minSalary }),
  bySalaryMax: (maxSalary) => ({ field: 'salaire', operator: 'lte', value: maxSalary }),
  byHireDateAfter: (date) => ({ field: 'dateEmbauche', operator: 'gte', value: date }),
  byHireDateBefore: (date) => ({ field: 'dateEmbauche', operator: 'lte', value: date })
};

export const EmployeeSorts = {
  byName: (order = 'ASC') => ({ field: 'nom', order }),
  byFirstName: (order = 'ASC') => ({ field: 'prenom', order }),
  byHireDate: (order = 'DESC') => ({ field: 'dateEmbauche', order }),
  bySalary: (order = 'DESC') => ({ field: 'salaire', order }),
  byDepartment: (order = 'ASC') => ({ field: 'service', order })
};

// Instance par défaut
export const employeeApi = new EmployeeApiClient();