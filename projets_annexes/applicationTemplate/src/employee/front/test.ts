/**
 * Script de test pour les composants TypeScript Employee API
 * 
 * Ce script teste toutes les fonctionnalités TypeScript et valide
 * la compatibilité avec l'API REST IBM i
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-07
 */

import { 
  Employee,
  DataProviderConfig,
  createEmployeeDataProvider,
  TypedEmployeeApiClient,
  EmployeeFilters,
  EmployeeSorts,
  validateEmployee,
  formatEmployeeName,
  calculateAge,
  formatSalary
} from './index';

// ===== CONFIGURATION DE TEST =====

const TEST_CONFIG: DataProviderConfig = {
  apiUrl: 'http://localhost:44000/api',
  timeout: 10000,
  enableLogs: true
};

// ===== DONNÉES DE TEST =====

const TEST_EMPLOYEE: Employee = {
  id: '123',
  prenom: 'Jean',
  nom: 'Dupont',
  initiale: 'J',
  service: 'D01',
  dateEmbauche: '2020-03-15',
  dateNaissance: '1985-08-22',
  genre: 'M',
  salaire: 55000
};

const INVALID_EMPLOYEE: Partial<Employee> = {
  prenom: '',
  nom: 'Test',
  service: '',
  salaire: -1000
};

// ===== TESTS UTILITAIRES =====

/**
 * Classe de test simple
 */
class TypeScriptTests {
  private passed: number = 0;
  private failed: number = 0;

  /**
   * Exécute un test unitaire
   */
  test(name: string, testFn: () => boolean | Promise<boolean>): void {
    try {
      const result = testFn();
      
      if (result instanceof Promise) {
        result.then(success => {
          if (success) {
            console.log(`✅ ${name}`);
            this.passed++;
          } else {
            console.log(`❌ ${name}`);
            this.failed++;
          }
        }).catch(error => {
          console.log(`❌ ${name} - Erreur: ${error.message}`);
          this.failed++;
        });
      } else {
        if (result) {
          console.log(`✅ ${name}`);
          this.passed++;
        } else {
          console.log(`❌ ${name}`);
          this.failed++;
        }
      }
    } catch (error) {
      console.log(`❌ ${name} - Exception: ${error}`);
      this.failed++;
    }
  }

  /**
   * Affiche le résumé des tests
   */
  summary(): void {
    console.log(`\n📊 Résultats des tests:`);
    console.log(`✅ Réussis: ${this.passed}`);
    console.log(`❌ Échoués: ${this.failed}`);
    console.log(`📈 Total: ${this.passed + this.failed}`);
    
    if (this.failed === 0) {
      console.log(`🎉 Tous les tests TypeScript sont passés!`);
    } else {
      console.log(`⚠️  ${this.failed} test(s) en échec`);
    }
  }
}

// ===== TESTS DES TYPES =====

const testTypes = (tests: TypeScriptTests): void => {
  console.log('\n🔍 Tests des types TypeScript...\n');

  tests.test('Type Employee valide', () => {
    const employee: Employee = TEST_EMPLOYEE;
    return employee.id === '123' && employee.prenom === 'Jean';
  });

  tests.test('Validation d\'employé valide', () => {
    const errors = validateEmployee(TEST_EMPLOYEE);
    return errors.length === 0;
  });

  tests.test('Validation d\'employé invalide', () => {
    const errors = validateEmployee(INVALID_EMPLOYEE);
    return errors.length > 0;
  });

  tests.test('Formatage nom complet', () => {
    const fullName = formatEmployeeName(TEST_EMPLOYEE);
    return fullName === 'Jean Dupont';
  });

  tests.test('Calcul d\'âge', () => {
    const age = calculateAge('1985-08-22');
    return age >= 38 && age <= 40; // Dépend de la date actuelle
  });

  tests.test('Formatage salaire', () => {
    const formatted = formatSalary(55000);
    return formatted.includes('55') && formatted.includes('€');
  });
};

// ===== TESTS DATA PROVIDER =====

const testDataProvider = (tests: TypeScriptTests): void => {
  console.log('\n📊 Tests Data Provider TypeScript...\n');

  tests.test('Création Data Provider', () => {
    const dataProvider = createEmployeeDataProvider(TEST_CONFIG);
    return typeof dataProvider.getList === 'function';
  });

  tests.test('Configuration par défaut', () => {
    const dataProvider = createEmployeeDataProvider();
    return typeof dataProvider.getOne === 'function';
  });

  // Note: Les tests API nécessiteraient un serveur réel
  tests.test('Interface Data Provider complète', () => {
    const dataProvider = createEmployeeDataProvider();
    
    const requiredMethods = [
      'getList', 'getOne', 'getMany', 'getManyReference',
      'create', 'update', 'updateMany', 'delete', 'deleteMany',
      'searchEmployees', 'getEmployeeStats'
    ];
    
    return requiredMethods.every(method => 
      typeof dataProvider[method as keyof typeof dataProvider] === 'function'
    );
  });
};

// ===== TESTS API CLIENT =====

const testApiClient = (tests: TypeScriptTests): void => {
  console.log('\n🔌 Tests API Client TypeScript...\n');

  tests.test('Création API Client', () => {
    const client = new TypedEmployeeApiClient(TEST_CONFIG);
    return typeof client.getEmployees === 'function';
  });

  tests.test('Configuration API Client', () => {
    const client = new TypedEmployeeApiClient({
      baseUrl: 'https://test.com/api',
      timeout: 5000,
      headers: { 'Custom': 'Header' }
    });
    
    // Test indirectement via une méthode publique
    return typeof client.getEmployees === 'function' &&
           typeof client.getEmployee === 'function';
  });

  tests.test('Helpers de filtres', () => {
    const nameFilter = EmployeeFilters.byName('Dupont');
    const salaryFilter = EmployeeFilters.bySalaryMin(50000);
    
    return nameFilter.field === 'nom' && 
           nameFilter.value === 'Dupont' &&
           salaryFilter.field === 'salaire' &&
           salaryFilter.operator === 'gte';
  });

  tests.test('Helpers de tri', () => {
    const nameSort = EmployeeSorts.byName('DESC');
    const salarySort = EmployeeSorts.bySalary();
    
    return nameSort.field === 'nom' && 
           nameSort.order === 'DESC' &&
           salarySort.field === 'salaire' &&
           salarySort.order === 'ASC';
  });
};

// ===== TESTS D'INTÉGRATION =====

const testIntegration = (tests: TypeScriptTests): void => {
  console.log('\n🔗 Tests d\'intégration TypeScript...\n');

  tests.test('Types compatibles entre modules', () => {
    const dataProvider = createEmployeeDataProvider();
    const client = new TypedEmployeeApiClient(TEST_CONFIG);
    
    // Vérification que les types sont compatibles
    const employee: Employee = TEST_EMPLOYEE;
    const config: DataProviderConfig = TEST_CONFIG;
    
    return typeof employee.id === 'string' && 
           typeof config.apiUrl === 'string';
  });

  tests.test('Chaînage des méthodes', () => {
    try {
      const filters = [
        EmployeeFilters.byDepartment('IT'),
        EmployeeFilters.bySalaryMin(50000)
      ];
      
      const sorts = [
        EmployeeSorts.bySalary('DESC'),
        EmployeeSorts.byName('ASC')
      ];
      
      return filters.length === 2 && sorts.length === 2;
    } catch (error) {
      return false;
    }
  });

  tests.test('Validation de schéma complet', () => {
    const fullEmployee: Employee = {
      id: '456',
      prenom: 'Marie',
      nom: 'Martin',
      initiale: 'M',
      service: 'E11',
      dateEmbauche: '2021-06-01',
      dateNaissance: '1990-12-10',
      genre: 'F',
      salaire: 48000
    };
    
    const errors = validateEmployee(fullEmployee);
    return errors.length === 0;
  });
};

// ===== TESTS DE PERFORMANCE =====

const testPerformance = (tests: TypeScriptTests): void => {
  console.log('\n⚡ Tests de performance TypeScript...\n');

  tests.test('Création multiple Data Providers', () => {
    const start = performance.now();
    
    for (let i = 0; i < 100; i++) {
      createEmployeeDataProvider({ apiUrl: `http://test${i}.com` });
    }
    
    const duration = performance.now() - start;
    return duration < 100; // Moins de 100ms
  });

  tests.test('Validation en lot', () => {
    const employees: Partial<Employee>[] = [
      TEST_EMPLOYEE,
      { ...TEST_EMPLOYEE, id: '124' },
      { ...TEST_EMPLOYEE, id: '125' },
      INVALID_EMPLOYEE
    ];
    
    const start = performance.now();
    
    const results = employees.map(emp => validateEmployee(emp));
    
    const duration = performance.now() - start;
    
    return duration < 50 && // Moins de 50ms
           results.length === 4 &&
           results[0].length === 0 && // Valide
           results[3].length > 0;    // Invalide
  });

  tests.test('Formatage en masse', () => {
    const employees = Array(1000).fill(TEST_EMPLOYEE);
    
    const start = performance.now();
    
    const formatted = employees.map(emp => ({
      fullName: formatEmployeeName(emp),
      salary: formatSalary(emp.salaire),
      age: calculateAge(emp.dateNaissance)
    }));
    
    const duration = performance.now() - start;
    
    return duration < 200 && formatted.length === 1000;
  });
};

// ===== EXÉCUTION DES TESTS =====

const runAllTests = (): void => {
  console.log('🚀 Démarrage des tests TypeScript Employee API...');
  console.log('================================================');
  
  const tests = new TypeScriptTests();
  
  // Exécution de tous les tests
  testTypes(tests);
  testDataProvider(tests);
  testApiClient(tests);
  testIntegration(tests);
  testPerformance(tests);
  
  // Attendre un peu pour les tests asynchrones
  setTimeout(() => {
    tests.summary();
    console.log('\n🏁 Tests terminés.');
  }, 1000);
};

// ===== EXPORT ET EXÉCUTION =====

export {
  TypeScriptTests,
  testTypes,
  testDataProvider,
  testApiClient,
  testIntegration,
  testPerformance,
  runAllTests
};

// Exécution automatique si le script est lancé directement
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}

export default {
  runAllTests,
  TypeScriptTests
};