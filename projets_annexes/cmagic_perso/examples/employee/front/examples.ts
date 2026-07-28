/**
 * Exemples d'utilisation du Data Provider et API Client Employee - TypeScript
 * 
 * Ce fichier contient des exemples pratiques d'utilisation du data provider
 * et du client API pour l'API Employee IBM i avec TypeScript complet
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

import { employeeDataProvider, createEmployeeDataProvider, EmployeeDataProvider } from './employeeDataProvider';
import { TypedEmployeeApiClient, employeeApi, EmployeeFilters, EmployeeSorts } from './employeeApiClient';
import { Employee, GetListParams, GetListResponse, AdvancedFilter, MultiSort } from './types';

// ===== EXEMPLES REACT-ADMIN DATA PROVIDER =====

/**
 * Exemple 1: Utilisation basique avec React-Admin
 */
export const reactAdminExamples = {
  
  /**
   * Configuration du data provider pour React-Admin
   */
  setupDataProvider: (): EmployeeDataProvider => {
    const dataProvider = createEmployeeDataProvider({
      apiUrl: 'http://your-ibmi-server:44000/api',
      timeout: 30000
    });
    
    return dataProvider;
  },

  /**
   * Exemple d'utilisation dans un composant React-Admin
   */
  listComponent: `
    import React from 'react';
    import { List, Datagrid, TextField, NumberField, DateField } from 'react-admin';

    export const EmployeeList = (props: any) => (
      <List {...props}>
        <Datagrid>
          <TextField source="id" />
          <TextField source="prenom" label="Prénom" />
          <TextField source="nom" label="Nom" />
          <TextField source="service" label="Service" />
          <NumberField source="salaire" label="Salaire" />
          <DateField source="dateEmbauche" label="Date embauche" />
        </Datagrid>
      </List>
    );
  `,

  /**
   * Recherche avancée avec React-Admin
   */
  advancedSearch: async (dataProvider: EmployeeDataProvider): Promise<GetListResponse<Employee>> => {
    const params: GetListParams = {
      pagination: { page: 1, perPage: 20 },
      sort: { field: 'nom', order: 'ASC' },
      filter: { 
        q: 'john',
        service: 'IT'
      },
      advancedFilters: [
        { field: 'salaire', operator: 'gte', value: 50000 }
      ] as AdvancedFilter[],
      multiSort: [
        { field: 'nom', order: 'ASC' },
        { field: 'dateEmbauche', order: 'DESC' }
      ] as MultiSort[]
    };

    const result = await dataProvider.getList(params);
    
    console.log('Résultats:', result.data);
    console.log('Total:', result.total);
    
    return result;
  }
};

// ===== EXEMPLES API CLIENT STANDALONE =====

/**
 * Exemple 2: Utilisation du client API standalone
 */
export const apiClientExamples = {

  /**
   * Configuration personnalisée du client
   */
  setupCustomClient: (): TypedEmployeeApiClient => {
    const client = new TypedEmployeeApiClient({
      baseUrl: 'http://your-ibmi-server:44000/api',
      timeout: 60000,
      headers: {
        'Authorization': 'Bearer your-token',
        'X-Client-Version': '1.0'
      }
    });
    
    return client;
  },

  /**
   * Récupération simple d'employés
   */
  basicUsage: async (): Promise<void> => {
    try {
      // Liste avec pagination
      const employees = await employeeApi.getEmployees({
        page: 1,
        limit: 10
      });
      
      console.log(`${employees.data.length} employés trouvés sur ${employees.total}`);
      employees.data.forEach((emp: Employee) => {
        console.log(`- ${emp.prenom} ${emp.nom} (${emp.service})`);
      });

      // Récupération d'un employé spécifique
      const employee = await employeeApi.getEmployee('1');
      console.log('Détails employé:', employee);

    } catch (error) {
      console.error('Erreur API:', error);
    }
  },

  /**
   * Recherche avec filtres avancés
   */
  advancedFiltering: async (): Promise<void> => {
    try {
      // Recherche d'employés IT avec salaire >= 50000
      const highPaidIT = await employeeApi.searchEmployees({
        filters: [
          EmployeeFilters.byDepartment('IT'),
          EmployeeFilters.bySalaryMin(50000)
        ],
        sorts: [
          EmployeeSorts.bySalary('DESC'),
          EmployeeSorts.byName('ASC')
        ],
        pagination: { page: 1, perPage: 20 }
      });

      console.log('Employés IT bien payés:', highPaidIT.data);

      // Recherche par nom avec LIKE - utilisation de filtres multiples
      const johnEmployees = await employeeApi.searchEmployees({
        q: 'John', // Recherche générale
        sorts: [EmployeeSorts.byName('ASC')]
      });

      console.log('Employés nommés John:', johnEmployees.data);

    } catch (error) {
      console.error('Erreur recherche:', error);
    }
  },

  /**
   * Gestion CRUD complète
   */
  crudOperations: async (): Promise<void> => {
    try {
      // Création d'un nouvel employé
      const newEmployee: Omit<Employee, 'id'> = {
        prenom: 'Alice',
        nom: 'Dupont',
        service: 'RH',
        salaire: 45000,
        dateEmbauche: '2024-01-15',
        dateNaissance: '1990-05-20',
        genre: 'F'
      };

      const created = await employeeApi.createEmployee(newEmployee);
      console.log('Employé créé:', created);

      // Mise à jour
      const updated = await employeeApi.updateEmployee(created.id, {
        ...created,
        salaire: 47000
      });
      console.log('Employé mis à jour:', updated);

      // Suppression
      const deleted = await employeeApi.deleteEmployee(created.id);
      console.log('Employé supprimé:', deleted);

    } catch (error) {
      console.error('Erreur CRUD:', error);
    }
  }
};

// ===== EXEMPLES AVEC GESTION D'ERREURS =====

/**
 * Exemple 3: Gestion d'erreurs robuste
 */
export const errorHandlingExamples = {

  /**
   * Gestion d'erreurs avec retry automatique
   */
  withRetry: async (apiCall: () => Promise<any>, maxRetries: number = 3): Promise<any> => {
    let lastError: Error;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await apiCall();
      } catch (error) {
        lastError = error as Error;
        console.warn(`Tentative ${attempt}/${maxRetries} échouée:`, error);
        
        if (attempt === maxRetries) {
          throw lastError;
        }
        
        // Attendre avant le retry (backoff exponentiel)
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
      }
    }
  },

  /**
   * Validation des données avant envoi
   */
  validateEmployeeData: (data: Partial<Employee>): string[] => {
    const errors: string[] = [];
    
    if (!data.prenom?.trim()) {
      errors.push('Le prénom est obligatoire');
    }
    
    if (!data.nom?.trim()) {
      errors.push('Le nom est obligatoire');
    }
    
    if (data.salaire !== undefined && data.salaire < 0) {
      errors.push('Le salaire ne peut pas être négatif');
    }
    
    if (data.dateEmbauche && new Date(data.dateEmbauche) > new Date()) {
      errors.push('La date d\'embauche ne peut pas être dans le futur');
    }
    
    return errors;
  },

  /**
   * Création sécurisée avec validation
   */
  safeCreateEmployee: async (data: Omit<Employee, 'id'>): Promise<Employee> => {
    // Validation des données
    const errors = errorHandlingExamples.validateEmployeeData(data);
    if (errors.length > 0) {
      throw new Error(`Données invalides: ${errors.join(', ')}`);
    }

    // Création avec retry
    return await errorHandlingExamples.withRetry(
      () => employeeApi.createEmployee(data),
      3
    );
  }
};

// ===== EXEMPLES PERFORMANCE ET OPTIMISATION =====

/**
 * Exemple 4: Optimisations de performance
 */
export const performanceExamples = {

  /**
   * Chargement par batch pour de gros volumes
   */
  loadEmployeesBatch: async (batchSize: number = 100): Promise<Employee[]> => {
    const allEmployees: Employee[] = [];
    let page = 1;
    let hasMore = true;

    while (hasMore) {
      const batch = await employeeApi.getEmployees({
        page: page,
        limit: batchSize
      });

      allEmployees.push(...batch.data);
      
      hasMore = batch.data.length === batchSize;
      page++;
      
      console.log(`Chargé ${allEmployees.length} employés...`);
    }

    return allEmployees;
  },

  /**
   * Cache simple en mémoire
   */
  createSimpleCache: () => {
    const cache = new Map<string, { data: any; timestamp: number; ttl: number }>();
    
    return {
      get: <T>(key: string): T | null => {
        const entry = cache.get(key);
        if (!entry) return null;
        
        if (Date.now() - entry.timestamp > entry.ttl) {
          cache.delete(key);
          return null;
        }
        
        return entry.data as T;
      },
      
      set: <T>(key: string, data: T, ttlMs: number = 300000): void => {
        cache.set(key, {
          data,
          timestamp: Date.now(),
          ttl: ttlMs
        });
      },
      
      clear: (): void => {
        cache.clear();
      }
    };
  },

  /**
   * Client API avec cache intégré
   */
  createCachedApiClient: () => {
    const cache = performanceExamples.createSimpleCache();
    const client = apiClientExamples.setupCustomClient();
    
    // Wrapper du client avec cache
    const cachedClient = {
      ...client,
      cache,
      
      async getEmployee(id: string): Promise<Employee> {
        const cacheKey = `employee:${id}`;
        let employee = cache.get<Employee>(cacheKey);
        
        if (!employee) {
          employee = await client.getEmployee(id);
          cache.set(cacheKey, employee, 300000); // 5 minutes
        }
        
        return employee;
      }
    };
    
    return cachedClient;
  }
};

// ===== EXEMPLES D'INTÉGRATION =====

/**
 * Exemple 5: Intégration avec d'autres systèmes
 */
export const integrationExamples = {

  /**
   * Export CSV des employés
   */
  exportToCsv: async (): Promise<string> => {
    const employees = await performanceExamples.loadEmployeesBatch();
    
    const headers = ['ID', 'Prénom', 'Nom', 'Service', 'Salaire', 'Date Embauche', 'Genre'];
    const rows = employees.map(emp => [
      emp.id,
      emp.prenom,
      emp.nom,
      emp.service,
      emp.salaire,
      emp.dateEmbauche,
      emp.genre
    ]);
    
    const csvContent = [headers, ...rows]
      .map(row => row.map(cell => `"${cell}"`).join(','))
      .join('\n');
    
    return csvContent;
  },

  /**
   * Synchronisation avec système externe
   */
  syncWithExternalSystem: async (externalEmployees: any[]): Promise<{ created: number; updated: number; errors: string[] }> => {
    const results = { created: 0, updated: 0, errors: [] as string[] };
    
    for (const extEmp of externalEmployees) {
      try {
        // Mapper les données externes vers notre format
        const employeeData: Omit<Employee, 'id'> = {
          prenom: extEmp.first_name,
          nom: extEmp.last_name,
          service: extEmp.department,
          salaire: extEmp.salary,
          dateEmbauche: extEmp.hire_date,
          dateNaissance: extEmp.birth_date || '1980-01-01',
          genre: extEmp.gender === 'male' ? 'M' : 'F'
        };

        // Vérifier si l'employé existe (par nom+prénom par exemple)
        const existing = await employeeApi.searchEmployees({
          filters: [
            EmployeeFilters.byFirstName(employeeData.prenom),
            EmployeeFilters.byName(employeeData.nom)
          ]
        });

        if (existing.data.length > 0) {
          // Mise à jour
          await employeeApi.updateEmployee(existing.data[0].id, {
            ...existing.data[0],
            ...employeeData
          });
          results.updated++;
        } else {
          // Création
          await employeeApi.createEmployee(employeeData);
          results.created++;
        }
        
      } catch (error) {
        results.errors.push(`Erreur pour ${extEmp.first_name} ${extEmp.last_name}: ${error}`);
      }
    }
    
    return results;
  }
};

// ===== FONCTION DE DÉMONSTRATION COMPLÈTE =====

/**
 * Démonstration complète des fonctionnalités
 */
export const runCompleteDemo = async (): Promise<void> => {
  console.log('=== DÉMONSTRATION COMPLETE API EMPLOYEE ===\n');

  try {
    // 1. Configuration
    console.log('1. Configuration du data provider...');
    const dataProvider = reactAdminExamples.setupDataProvider();
    console.log('✓ Data provider configuré\n');

    // 2. Recherche basique
    console.log('2. Recherche basique...');
    await apiClientExamples.basicUsage();
    console.log('✓ Recherche terminée\n');

    // 3. Filtres avancés
    console.log('3. Filtres avancés...');
    await apiClientExamples.advancedFiltering();
    console.log('✓ Filtres testés\n');

    // 4. Statistiques
    console.log('4. Statistiques...');
    const stats = await dataProvider.getEmployeeStats();
    console.log(`✓ Total employés: ${stats.totalEmployees}\n`);

    // 5. Performance
    console.log('5. Test de performance...');
    const cachedClient = performanceExamples.createCachedApiClient();
    const emp1 = await cachedClient.getEmployee('1'); // Charge depuis l'API
    const emp2 = await cachedClient.getEmployee('1'); // Charge depuis le cache
    console.log('✓ Cache testé\n');

    console.log('=== DÉMONSTRATION TERMINÉE AVEC SUCCÈS ===');

  } catch (error) {
    console.error('❌ Erreur durant la démonstration:', error);
  }
};

// Export par défaut pour usage direct
export default {
  reactAdminExamples,
  apiClientExamples,
  errorHandlingExamples,
  performanceExamples,
  integrationExamples,
  runCompleteDemo
};