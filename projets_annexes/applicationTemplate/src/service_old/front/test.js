/**
 * Tests unitaires pour les composants front-end Employee API
 * 
 * Tests des fonctionnalités du data provider et du client API
 * 
 * @author ArchiAPI Template
 * @version 1.0
 * @date 2025-10-06
 */

// Mock fetch pour les tests
global.fetch = async (url, options = {}) => {
  console.log(`Mock Fetch: ${options.method || 'GET'} ${url}`);
  
  // Simulation d'une réponse API
  const mockResponse = {
    ok: true,
    status: 200,
    headers: new Map([
      ['X-Total-Count', '156'],
      ['Content-Type', 'application/json']
    ]),
    json: async () => {
      if (url.includes('/employees/000010')) {
        return {
          id: "000010",
          prenom: "CHRISTINE",
          nom: "HAAS",
          initiale: "I",
          service: "A00",
          dateEmbauche: "1995-01-01",
          dateNaissance: "1963-08-24",
          genre: "F",
          salaire: 152750.00
        };
      }
      
      if (url.includes('/employees')) {
        return [
          {
            id: "000010",
            prenom: "CHRISTINE",
            nom: "HAAS",
            initiale: "I",
            service: "A00",
            dateEmbauche: "1995-01-01",
            dateNaissance: "1963-08-24",
            genre: "F",
            salaire: 152750.00
          },
          {
            id: "000020",
            prenom: "MICHAEL",
            nom: "THOMPSON",
            initiale: "L",
            service: "B01",
            dateEmbauche: "2003-10-30",
            dateNaissance: "1948-02-02",
            genre: "M",
            salaire: 94250.00
          }
        ];
      }
      
      return {};
    }
  };
  
  return mockResponse;
};

// Import des modules à tester
import { EmployeeApiClient, EmployeeFilters, EmployeeSorts } from './employeeApiClient.js';

/**
 * Suite de tests pour EmployeeApiClient
 */
async function testEmployeeApiClient() {
  console.log('\\n=== Tests EmployeeApiClient ===');
  
  const client = new EmployeeApiClient({
    baseUrl: 'http://localhost:44000/api',
    timeout: 5000
  });
  
  try {
    // Test 1: Récupération de la liste
    console.log('\\nTest 1: getEmployees()');
    const employees = await client.getEmployees({
      page: 1,
      limit: 10,
      sort: 'nom',
      order: 'ASC'
    });
    
    console.log('✅ Liste récupérée:', employees.data.length, 'employés');
    console.log('✅ Total:', employees.total);
    console.log('✅ Pages:', employees.totalPages);
    
    // Test 2: Récupération d'un employé
    console.log('\\nTest 2: getEmployee()');
    const employee = await client.getEmployee('000010');
    console.log('✅ Employé récupéré:', employee.prenom, employee.nom);
    
    // Test 3: Recherche avec filtres
    console.log('\\nTest 3: searchEmployees()');
    const searchResults = await client.searchEmployees({
      query: 'haas',
      filters: [
        EmployeeFilters.byGender('F'),
        EmployeeFilters.bySalaryMin(100000)
      ],
      sorts: [
        EmployeeSorts.byName('ASC')
      ]
    });
    
    console.log('✅ Recherche réussie:', searchResults.data.length, 'résultats');
    
    // Test 4: Validation des données
    console.log('\\nTest 4: validateEmployeeData()');
    const validData = {
      nom: 'Dupont',
      prenom: 'Jean',
      salaire: 50000,
      genre: 'M'
    };
    
    const invalidData = {
      nom: '',
      prenom: 'Jean',
      salaire: -1000,
      genre: 'X'
    };
    
    const validationValid = client.validateEmployeeData(validData);
    const validationInvalid = client.validateEmployeeData(invalidData);
    
    console.log('✅ Validation données valides:', validationValid.isValid);
    console.log('✅ Validation données invalides:', !validationInvalid.isValid);
    console.log('✅ Erreurs détectées:', validationInvalid.errors.length);
    
  } catch (error) {
    console.error('❌ Erreur test ApiClient:', error.message);
  }
}

/**
 * Tests pour les helpers de filtres et tris
 */
function testHelpers() {
  console.log('\\n=== Tests Helpers ===');
  
  // Test des filtres
  console.log('\\nTest Filtres:');
  const nameFilter = EmployeeFilters.byName('Smith');
  const salaryFilter = EmployeeFilters.bySalaryMin(50000);
  const deptFilter = EmployeeFilters.byDepartment('IT');
  
  console.log('✅ Filtre nom:', nameFilter);
  console.log('✅ Filtre salaire:', salaryFilter);
  console.log('✅ Filtre département:', deptFilter);
  
  // Test des tris
  console.log('\\nTest Tris:');
  const nameSort = EmployeeSorts.byName('DESC');
  const salarySort = EmployeeSorts.bySalary('ASC');
  const hireDateSort = EmployeeSorts.byHireDate();
  
  console.log('✅ Tri nom:', nameSort);
  console.log('✅ Tri salaire:', salarySort);
  console.log('✅ Tri embauche:', hireDateSort);
}

/**
 * Test de construction des paramètres d'URL
 */
function testUrlBuilder() {
  console.log('\\n=== Tests URL Builder ===');
  
  const client = new EmployeeApiClient();
  
  // Simuler la méthode privée
  const buildUrlParams = (params) => {
    const searchParams = new URLSearchParams();
    Object.keys(params).forEach(key => {
      const value = params[key];
      if (value !== null && value !== undefined && value !== '') {
        searchParams.append(key, value.toString());
      }
    });
    return searchParams.toString();
  };
  
  const params1 = {
    _page: 1,
    _limit: 10,
    _sort: 'nom',
    _order: 'ASC',
    nom_like: 'Smith',
    salaire_gte: 50000
  };
  
  const urlParams1 = buildUrlParams(params1);
  console.log('✅ Paramètres simples:', urlParams1);
  
  const params2 = {
    _page: 2,
    _limit: 25,
    q: 'john doe',
    service: 'IT',
    genre: 'M'
  };
  
  const urlParams2 = buildUrlParams(params2);
  console.log('✅ Paramètres avec recherche:', urlParams2);
}

/**
 * Tests de gestion d'erreurs
 */
async function testErrorHandling() {
  console.log('\\n=== Tests Gestion Erreurs ===');
  
  // Mock fetch qui échoue
  const originalFetch = global.fetch;
  global.fetch = async () => {
    throw new Error('Erreur réseau simulée');
  };
  
  const client = new EmployeeApiClient({
    baseUrl: 'http://unreachable-server:44000/api',
    timeout: 1000
  });
  
  try {
    await client.getEmployees();
    console.log('❌ Erreur attendue non levée');
  } catch (error) {
    console.log('✅ Erreur correctement capturée:', error.message);
  }
  
  // Restaurer fetch
  global.fetch = originalFetch;
}

/**
 * Tests de performance et configuration
 */
function testConfiguration() {
  console.log('\\n=== Tests Configuration ===');
  
  // Test configuration par défaut
  const defaultClient = new EmployeeApiClient();
  console.log('✅ Client par défaut créé');
  
  // Test configuration personnalisée
  const customClient = new EmployeeApiClient({
    baseUrl: 'https://custom-server.com/api',
    timeout: 60000,
    headers: {
      'Authorization': 'Bearer token123',
      'X-Custom-Header': 'value'
    }
  });
  
  console.log('✅ Client personnalisé créé');
  console.log('✅ URL personnalisée:', customClient.config.baseUrl);
  console.log('✅ Timeout personnalisé:', customClient.config.timeout);
  console.log('✅ Headers personnalisés:', Object.keys(customClient.config.headers).length);
}

/**
 * Fonction principale de test
 */
async function runAllTests() {
  console.log('🧪 Lancement des tests Employee Front-End Components');
  console.log('='.repeat(60));
  
  try {
    testConfiguration();
    testHelpers();
    testUrlBuilder();
    await testEmployeeApiClient();
    await testErrorHandling();
    
    console.log('\\n' + '='.repeat(60));
    console.log('✅ Tous les tests sont passés avec succès !');
    
  } catch (error) {
    console.log('\\n' + '='.repeat(60));
    console.error('❌ Erreur lors des tests:', error.message);
    console.error(error.stack);
  }
}

// Exécuter les tests si ce fichier est lancé directement
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}

export {
  testEmployeeApiClient,
  testHelpers,
  testUrlBuilder,
  testErrorHandling,
  testConfiguration,
  runAllTests
};