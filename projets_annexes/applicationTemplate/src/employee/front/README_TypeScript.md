# Employee API Front-End TypeScript

## 🎯 Vue d'ensemble

Package front-end TypeScript complet pour l'API Employee IBM i avec support React-Admin et types stricts.

## 📦 Installation

### Prérequis

```bash
npm install react react-dom @mui/material @mui/icons-material
npm install react-admin
npm install typescript @types/react @types/react-dom
```

### Usage TypeScript

```typescript
// Import des types
import { Employee, DataProviderConfig } from './types';

// Import du data provider typé
import { createEmployeeDataProvider } from './employeeDataProvider';

// Import du client API typé
import { TypedEmployeeApiClient } from './employeeApiClient';
```

## 🔧 Configuration

### Data Provider TypeScript

```typescript
import { createEmployeeDataProvider } from './employeeDataProvider';

const dataProvider = createEmployeeDataProvider({
  apiUrl: 'http://your-ibmi-server:44000/api',
  timeout: 30000,
  enableLogs: true
});

// Utilisation avec types stricts
const employees: GetListResponse<Employee> = await dataProvider.getList({
  pagination: { page: 1, perPage: 10 },
  sort: { field: 'nom', order: 'ASC' },
  filter: { service: 'IT' }
});
```

### API Client TypeScript

```typescript
import { TypedEmployeeApiClient, EmployeeFilters, EmployeeSorts } from './employeeApiClient';

const client = new TypedEmployeeApiClient({
  baseUrl: 'http://your-ibmi-server:44000/api',
  timeout: 30000
});

// Recherche avec types stricts
const result = await client.searchEmployees({
  filters: [
    EmployeeFilters.byDepartment('IT'),
    EmployeeFilters.bySalaryMin(50000)
  ],
  sorts: [EmployeeSorts.bySalary('DESC')],
  pagination: { page: 1, perPage: 20 }
});
```

### React-Admin TypeScript

```tsx
import React from 'react';
import { Admin, Resource } from 'react-admin';
import { 
  EmployeeList, 
  EmployeeCreate, 
  EmployeeEdit, 
  EmployeeShow,
  dataProvider 
} from './reactAdminConfig';

const App: React.FC = () => (
  <Admin dataProvider={dataProvider}>
    <Resource
      name="employees"
      list={EmployeeList}
      create={EmployeeCreate}
      edit={EmployeeEdit}
      show={EmployeeShow}
    />
  </Admin>
);
```

## 📋 Types disponibles

### Employee Interface

```typescript
interface Employee {
  id: string;
  prenom: string;
  nom: string;
  initiale?: string;
  service: string;
  dateEmbauche: string;
  dateNaissance: string;
  genre: 'M' | 'F';
  salaire: number;
  fullName?: string;
  age?: number;
}
```

### Filtres avancés

```typescript
interface AdvancedFilter {
  field: string;
  operator: FilterOperator;
  value: string | number | boolean;
}

type FilterOperator = 'eq' | 'ne' | 'like' | 'gte' | 'lte' | 'gt' | 'lt';
```

### Configuration

```typescript
interface DataProviderConfig {
  apiUrl: string;
  timeout?: number;
  enableLogs?: boolean;
  httpClient?: HttpClient;
  headers?: Record<string, string>;
}
```

## 🎨 Composants React-Admin

### Liste d'employés

```tsx
<EmployeeList />
```

Fonctionnalités :
- ✅ Pagination
- ✅ Tri multi-colonnes
- ✅ Filtres avancés
- ✅ Recherche globale
- ✅ Export CSV
- ✅ Actions CRUD

### Formulaires

```tsx
<EmployeeCreate />
<EmployeeEdit />
```

Avec validation complète :
- Champs obligatoires
- Validation de format
- Messages d'erreur typés

### Affichage détaillé

```tsx
<EmployeeShow />
```

Avec champs calculés :
- Nom complet
- Âge automatique
- Ancienneté
- Formatage des devises

## 🔍 Recherches avancées

### Filtres prédéfinis

```typescript
// Par département
EmployeeFilters.byDepartment('IT')

// Par plage salariale
EmployeeFilters.bySalaryMin(50000)
EmployeeFilters.bySalaryMax(80000)

// Par nom (LIKE)
EmployeeFilters.byNameLike('John')

// Par date d'embauche
EmployeeFilters.byHireDateAfter('2020-01-01')
EmployeeFilters.byHireDateBefore('2023-12-31')
```

### Tri prédéfini

```typescript
// Tri par nom
EmployeeSorts.byName('ASC')

// Tri par salaire
EmployeeSorts.bySalary('DESC')

// Tri par date d'embauche
EmployeeSorts.byHireDate('ASC')
```

## 🚀 Exemples d'utilisation

### CRUD complet

```typescript
import { employeeApi } from './employeeApiClient';

// Créer
const newEmployee = await employeeApi.createEmployee({
  prenom: 'John',
  nom: 'Doe',
  service: 'IT',
  salaire: 55000,
  dateEmbauche: '2024-01-15',
  dateNaissance: '1990-05-20',
  genre: 'M'
});

// Lire
const employee = await employeeApi.getEmployee('123');

// Mettre à jour
const updated = await employeeApi.updateEmployee('123', {
  salaire: 58000
});

// Supprimer
await employeeApi.deleteEmployee('123');
```

### Recherche complexe

```typescript
const results = await employeeApi.searchEmployees({
  q: 'développeur', // Recherche globale
  filters: [
    EmployeeFilters.byDepartment('IT'),
    EmployeeFilters.bySalaryMin(45000),
    EmployeeFilters.byHireDateAfter('2020-01-01')
  ],
  sorts: [
    EmployeeSorts.bySalary('DESC'),
    EmployeeSorts.byName('ASC')
  ],
  pagination: { page: 1, perPage: 25 }
});
```

### Gestion d'erreurs

```typescript
try {
  const employees = await dataProvider.getList(params);
} catch (error) {
  if (error.operation === 'getList') {
    console.error('Erreur lors de la récupération:', error.originalError);
  }
}
```

## 🛠️ Scripts de développement

```bash
# Vérification des types
npm run type-check

# Compilation TypeScript
npm run build

# Mode watch
npm run build:watch

# Tests
npm test

# Linting
npm run lint
```

## 📚 Documentation API

L'API suit les standards REST avec les endpoints suivants :

- `GET /api/employees` - Liste avec pagination
- `GET /api/employees/{id}` - Détail d'un employé
- `POST /api/employees` - Création
- `PUT /api/employees/{id}` - Mise à jour
- `DELETE /api/employees/{id}` - Suppression

### Headers requis

- `X-Total-Count` : Nombre total d'enregistrements (collections)
- `Content-Type: application/json`
- `Accept: application/json`

### Paramètres de requête

- `_page`, `_limit` : Pagination
- `_sort`, `_order` : Tri
- `q` : Recherche globale
- `field_like`, `field_gte`, `field_lte` : Filtres

## 🎯 Bonnes pratiques

### Types stricts

```typescript
// ✅ Bon
const employee: Employee = await api.getEmployee('123');

// ❌ Éviter
const employee: any = await api.getEmployee('123');
```

### Gestion d'erreurs

```typescript
// ✅ Bon
try {
  const result = await api.createEmployee(data);
  return result;
} catch (error) {
  logger.error('Création échouée', error);
  throw new ApiError('Impossible de créer l\'employé', error);
}
```

### Validation

```typescript
// ✅ Bon
const errors = validateEmployeeData(employeeData);
if (errors.length > 0) {
  throw new ValidationError(errors);
}
```

## 🔧 Configuration avancée

### Client personnalisé

```typescript
const customClient = new TypedEmployeeApiClient({
  baseUrl: process.env.REACT_APP_API_URL,
  timeout: 60000,
  headers: {
    'Authorization': `Bearer ${token}`,
    'X-Client-Version': '1.0'
  }
});
```

### Cache intégré

```typescript
const cachedClient = performanceExamples.createCachedApiClient();
// Les appels suivants utilisent le cache
const emp1 = await cachedClient.getEmployee('123');
const emp2 = await cachedClient.getEmployee('123'); // depuis le cache
```

## 📄 License

MIT - Voir LICENSE.md pour plus de détails.

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Commit les modifications
4. Push vers la branche
5. Ouvrir une Pull Request

## 📞 Support

- Documentation : [/docs/api](/docs/api)
- Issues : [GitHub Issues](https://github.com/your-org/repo/issues)
- Email : support@yourcompany.com