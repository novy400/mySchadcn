# Universal Data Provider TypeScript pour IBM i REST APIs

## 🎯 Objectif

Système de data provider universel TypeScript pour connecter des APIs REST IBM i (pattern ArchiAPI) avec React-Admin et autres frameworks frontend.

## 📁 Structure des Fichiers

```
src/employee/front/
├── universalDataProvider.ts          # Core: Data provider universel complet
├── universalDataProviderExamples.ts  # Examples: Employee, Customer, Product
├── universalReactAdminConfig.ts      # React-Admin: Configurations et génération
├── universalDataProviderIndex.ts     # Index: Export centralisé (avec erreurs TS)
├── simpleUniversalIndex.ts           # Index simplifié et fonctionnel
└── README_UNIVERSAL_DATAPROVIDER.md  # Cette documentation
```

## 🚀 Usage Rapide (Recommandé)

### 1. Import Simplifié
```typescript
import { UniversalDataProviderKit } from './simpleUniversalIndex';

// Configuration Employee uniquement
const employeeConfig = UniversalDataProviderKit.createQuickEmployeeConfig(
  'http://localhost:44000/api'
);

// Configuration multi-ressources
const multiConfig = UniversalDataProviderKit.createQuickMultiConfig(
  'http://localhost:44000/api'
);
```

### 2. Configuration Personnalisée
```typescript
import { UniversalDataProviderKit } from './simpleUniversalIndex';

const customConfig = UniversalDataProviderKit.createDataProviderConfig(
  'http://localhost:44000/api',
  {
    employees: UniversalDataProviderKit.configs.employee,
    departments: UniversalDataProviderKit.createResourceConfig('/departments', {
      defaultSort: { field: 'name', order: 'ASC' }
    })
  },
  {
    timeout: 60000,
    enableLogs: true,
    headers: {
      'Authorization': 'Bearer your-token'
    }
  }
);
```

### 3. Filtres Avancés
```typescript
// Filtres simples
const simpleFilters = UniversalDataProviderKit.createSimpleFilters({
  department: 'IT',
  status: 'active'
});

// Filtres avancés avec opérateurs
const advancedFilters = UniversalDataProviderKit.createAdvancedFilters([
  { field: 'salary', operator: '_gte', value: 50000 },
  { field: 'name', operator: '_like', value: 'John' },
  { field: 'department', operator: '_ne', value: 'HR' }
]);
```

## 🏗️ Usage Complet (Data Provider Fonctionnel)

### 1. Import Complet
```typescript
import { createUniversalDataProvider } from './universalDataProvider';

const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://localhost:44000/api',
  resources: {
    employees: {
      endpoint: '/employees',
      defaultSort: { field: 'empno', order: 'ASC' }
    },
    customers: {
      endpoint: '/customers',
      defaultSort: { field: 'custno', order: 'ASC' }
    }
  }
});

// Utilisation avec React-Admin
import { Admin, Resource } from 'react-admin';

const App = () => (
  <Admin dataProvider={dataProvider}>
    <Resource name="employees" />
    <Resource name="customers" />
  </Admin>
);
```

### 2. Appels Directs API
```typescript
// GET Liste
const employees = await dataProvider.getList('employees', {
  pagination: { page: 1, perPage: 10 },
  sort: { field: 'empno', order: 'ASC' },
  filter: { department: 'IT' }
});

// GET Un élément
const employee = await dataProvider.getOne('employees', { id: '123' });

// POST Création
const newEmployee = await dataProvider.create('employees', {
  data: { name: 'John Doe', department: 'IT' }
});

// PUT Mise à jour
const updatedEmployee = await dataProvider.update('employees', {
  id: '123',
  data: { department: 'HR' }
});

// DELETE Suppression
await dataProvider.delete('employees', { id: '123' });
```

## 🔧 Configuration React-Admin Automatique

### 1. Génération de Code
```typescript
import { generateResourceCode } from './universalReactAdminConfig';

// Génère le code JSX pour Employee
const employeeCode = generateResourceCode('Employee', {
  listFields: ['empno', 'firstname', 'lastname', 'department'],
  editFields: ['firstname', 'lastname', 'department', 'salary'],
  showFields: ['empno', 'firstname', 'lastname', 'department', 'salary', 'hiredate'],
  filters: ['department', 'salary_gte']
});

console.log(employeeCode);
```

### 2. Configuration App Complète
```typescript
import { generateReactAdminApp } from './universalReactAdminConfig';

const appCode = generateReactAdminApp({
  title: 'Mon App IBM i',
  apiUrl: 'http://localhost:44000/api',
  resources: ['employees', 'customers', 'products']
});

console.log(appCode);
```

## 📊 Patterns IBM i REST Supportés

### 1. Endpoints Standards
```typescript
// Collections (retourne tableau + X-Total-Count)
GET /api/employees
GET /api/employees?_page=1&_limit=10
GET /api/employees?_sort=empno&_order=ASC
GET /api/employees?department=IT&salary_gte=50000

// Éléments individuels
GET /api/employees/123
POST /api/employees
PUT /api/employees/123
DELETE /api/employees/123

// Actions métier
POST /api/employees/123/promote
POST /api/employees/123/transfer
```

### 2. Paramètres de Filtrage
```typescript
// Opérateurs supportés
const operators = {
  '=': 'égal',                    // ?name=John
  '_like': 'contient',            // ?name_like=Joh
  '_gte': 'supérieur ou égal',    // ?salary_gte=50000
  '_lte': 'inférieur ou égal',    // ?salary_lte=80000
  '_ne': 'différent de',          // ?department_ne=HR
  '_in': 'dans la liste'          // ?id_in=1,2,3
};
```

### 3. Headers Requis
```typescript
// Response headers IBM i
{
  'X-Total-Count': '150',                    // OBLIGATOIRE pour collections
  'Access-Control-Expose-Headers': 'X-Total-Count',
  'Content-Type': 'application/json'
}
```

## 🧪 Tests et Validation

### 1. Tests Basiques
```bash
# Test collection
curl "http://localhost:44000/api/employees"

# Test pagination
curl "http://localhost:44000/api/employees?_page=1&_limit=5"

# Test tri
curl "http://localhost:44000/api/employees?_sort=empno&_order=DESC"

# Test filtres
curl "http://localhost:44000/api/employees?department=IT&salary_gte=50000"
```

### 2. Validation Headers
```typescript
// Vérifier X-Total-Count
const response = await fetch('http://localhost:44000/api/employees');
const totalCount = response.headers.get('X-Total-Count');
console.log('Total Count:', totalCount);
```

## 🔍 Debugging et Logging

### 1. Activation des Logs
```typescript
const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://localhost:44000/api',
  enableLogs: true,  // Active les logs détaillés
  resources: { /* ... */ }
});
```

### 2. Logs Personnalisés
```typescript
// Le data provider loggue automatiquement :
// - Requêtes HTTP (URL, méthode, paramètres)
// - Réponses (status, headers, données)
// - Erreurs (avec stack trace)
// - Transformations de données
```

## 📚 Ressources et Exemples

### 1. Structures TypeScript
```typescript
// Employee (exemple complet)
interface Employee {
  empno: string;
  firstname: string;
  lastname: string;
  department: string;
  salary: number;
  hiredate: string;
  status: 'active' | 'inactive';
}

// Customer (exemple)
interface Customer {
  custno: string;
  name: string;
  city: string;
  country: string;
  creditlimit: number;
}
```

### 2. Configurations Prêtes
```typescript
// Import des configurations pré-définies
import { UniversalDataProviderKit } from './simpleUniversalIndex';

const configs = UniversalDataProviderKit.configs;
// configs.employee
// configs.customer  
// configs.standard (multi-ressources)
```

## 🛠️ Intégration dans Projet React

### 1. Installation Types (si nécessaire)
```bash
npm install --save-dev @types/react @types/react-dom
npm install react-admin
```

### 2. Configuration App.tsx
```typescript
import React from 'react';
import { Admin, Resource } from 'react-admin';
import { createUniversalDataProvider } from './universalDataProvider';

const dataProvider = createUniversalDataProvider({
  apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:44000/api',
  resources: {
    employees: {
      endpoint: '/employees',
      defaultSort: { field: 'empno', order: 'ASC' }
    }
  }
});

const App = () => (
  <Admin dataProvider={dataProvider} title="IBM i Admin">
    <Resource name="employees" />
  </Admin>
);

export default App;
```

## 🎯 Roadmap et Évolutions

### Phase Actuelle ✅
- [x] Data provider universel TypeScript
- [x] Support multi-ressources
- [x] Compatibilité React-Admin
- [x] Filtrage avancé
- [x] Documentation complète

### Phase Suivante 🔄
- [ ] Tests unitaires automatisés
- [ ] Cache et optimisations
- [ ] Support WebSocket (temps réel)
- [ ] Intégration CMagic DSL
- [ ] Génération automatique depuis schéma

### Phase Future 🚀
- [ ] Plugin VS Code
- [ ] Interface graphique de configuration
- [ ] Templates préconfigurés par industrie
- [ ] Monitoring et analytics

## 📞 Support et Contribution

### Documentation Technique
- `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- `ressources/docs/strategique/analyse_repositionnement_sept2024.md`
- `PLAN_MISE_EN_OEUVRE.md`

### Exemples de Référence
- `src/employee/` - API REST Employee complète
- Pattern à suivre pour toute nouvelle ressource

### Structure Projet
Suit l'architecture ArchiAPI standard IBM i avec séparation claire des responsabilités.

---

**🎯 Universal Data Provider TypeScript - Connectez vos APIs IBM i à React-Admin en quelques lignes !**