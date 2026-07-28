# Data Provider Universel - Guide d'utilisation

Ce fichier contient un **data provider universel** qui peut être utilisé avec **toutes les ressources** de votre API IBM i, pas seulement les employés.

## 🎯 **Avantages du Data Provider Universel**

### ✅ **Multi-Ressources**
- Compatible avec `employees`, `customers`, `products`, etc.
- Configuration spécifique par ressource
- Transformations de données personnalisables

### ✅ **Hautement Configurable**
- Headers personnalisés (authentification, etc.)
- Timeouts configurables
- Logs de debug
- Transformations de requête/réponse

### ✅ **Fonctionnalités Avancées**
- Filtres avec opérateurs (`like`, `gte`, `lte`, etc.)
- Tri multi-niveaux
- Recherche globale
- Gestion d'erreurs robuste

### ✅ **Compatible React-Admin**
- Toutes les méthodes React-Admin standard
- Extensions pour fonctionnalités IBM i
- Prêt à l'emploi

## 🚀 **Utilisation Rapide**

### **Import et Configuration Basique**
```javascript
import { 
  createUniversalDataProvider, 
  universalDataProvider,
  FilterOperators,
  SortOrders 
} from './dataProvider.js';

// Utilisation directe avec configuration par défaut
const result = await universalDataProvider.getList('employees', {
  pagination: { page: 1, perPage: 10 },
  sort: { field: 'nom', order: 'ASC' }
});
```

### **Configuration Personnalisée**
```javascript
const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://your-ibmi-server:44000/api',
  timeout: 30000,
  enableLogs: true,
  headers: {
    'Authorization': 'Bearer your-token'
  }
});
```

## 📋 **Exemples par Ressource**

### **Employees**
```javascript
// Liste simple
const employees = await dataProvider.getList('employees', {
  pagination: { page: 1, perPage: 20 },
  sort: { field: 'nom', order: 'ASC' },
  filter: { service: 'IT' }
});

// Recherche avancée
const search = await dataProvider.search('employees', {
  filters: [
    FilterOperators.like('nom', 'Smith'),
    FilterOperators.greaterThanOrEqual('salaire', 50000)
  ],
  sorts: [
    SortOrders.ascending('nom'),
    SortOrders.descending('salaire')
  ]
});
```

### **Customers**
```javascript
// Utilisation identique avec une autre ressource
const customers = await dataProvider.getList('customers', {
  pagination: { page: 1, perPage: 15 },
  sort: { field: 'name', order: 'ASC' },
  filter: { status: 'active' }
});

// Recherche par nom
const customerSearch = await dataProvider.search('customers', {
  q: 'john',
  filters: [
    FilterOperators.equals('status', 'active'),
    FilterOperators.like('city', 'Paris')
  ]
});
```

### **Products**
```javascript
// Même pattern pour n'importe quelle ressource
const products = await dataProvider.getList('products', {
  pagination: { page: 1, perPage: 50 },
  sort: { field: 'name', order: 'ASC' },
  filter: { category: 'electronics' }
});
```

## 🔧 **Configuration Avancée par Ressource**

### **Transformations de Données**
```javascript
const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://your-server:44000/api',
  resourceConfig: {
    employees: {
      // Transformer les paramètres de requête
      transformParams: (query, params) => {
        if (query.fullName) {
          query.q = query.fullName;
          delete query.fullName;
        }
        return query;
      },
      
      // Transformer les données de réponse
      transformResponse: (data, operation) => {
        if (Array.isArray(data)) {
          return data.map(emp => ({
            ...emp,
            fullName: `${emp.prenom} ${emp.nom}`,
            age: calculateAge(emp.dateNaissance)
          }));
        }
        return data;
      }
    },
    
    customers: {
      transformResponse: (data, operation) => {
        // Ajouter des champs calculés pour les clients
        if (Array.isArray(data)) {
          return data.map(customer => ({
            ...customer,
            displayName: `${customer.firstName} ${customer.lastName}`,
            isVIP: customer.totalOrders > 10000
          }));
        }
        return data;
      }
    }
  }
});
```

### **Headers et Authentification**
```javascript
const authenticatedProvider = createUniversalDataProvider({
  apiUrl: 'http://your-server:44000/api',
  headers: {
    'Authorization': 'Bearer your-jwt-token',
    'X-Client-Version': '1.0',
    'X-User-ID': 'current-user-id'
  },
  timeout: 60000
});
```

## 🎨 **React-Admin Multi-Ressources**

### **Configuration App Complète**
```javascript
import React from 'react';
import { Admin, Resource } from 'react-admin';
import { createUniversalDataProvider } from './dataProvider.js';

const dataProvider = createUniversalDataProvider({
  apiUrl: process.env.REACT_APP_API_URL,
  enableLogs: process.env.NODE_ENV === 'development'
});

const App = () => (
  <Admin dataProvider={dataProvider} title="IBM i Administration">
    <Resource 
      name="employees" 
      list={EmployeeList} 
      edit={EmployeeEdit} 
      create={EmployeeCreate}
    />
    <Resource 
      name="customers" 
      list={CustomerList} 
      edit={CustomerEdit} 
      create={CustomerCreate}
    />
    <Resource 
      name="products" 
      list={ProductList} 
      edit={ProductEdit} 
      create={ProductCreate}
    />
  </Admin>
);
```

### **Composant List Universel**
```javascript
import React from 'react';
import { List, Datagrid, TextField, NumberField } from 'react-admin';

export const UniversalList = ({ resource, fields, ...props }) => (
  <List {...props} resource={resource}>
    <Datagrid>
      {fields.map(field => (
        field.type === 'number' 
          ? <NumberField key={field.source} source={field.source} label={field.label} />
          : <TextField key={field.source} source={field.source} label={field.label} />
      ))}
    </Datagrid>
  </List>
);
```

## 🔍 **Filtres et Recherche Avancée**

### **Tous les Opérateurs Supportés**
```javascript
import { FilterOperators } from './dataProvider.js';

const filters = [
  FilterOperators.equals('service', 'IT'),
  FilterOperators.notEquals('genre', 'M'),
  FilterOperators.like('nom', 'Smith'),
  FilterOperators.contains('prenom', 'John'),
  FilterOperators.greaterThan('salaire', 50000),
  FilterOperators.greaterThanOrEqual('salaire', 50000),
  FilterOperators.lessThan('age', 65),
  FilterOperators.lessThanOrEqual('dateEmbauche', '2020-12-31')
];
```

### **Tri Multi-Niveaux**
```javascript
import { SortOrders } from './dataProvider.js';

const sorts = [
  SortOrders.ascending('service'),    // Trier par service ASC
  SortOrders.descending('salaire'),   // Puis par salaire DESC
  SortOrders.ascending('nom')         // Puis par nom ASC
];
```

### **Recherche Complexe**
```javascript
const complexSearch = await dataProvider.search('employees', {
  q: 'manager',  // Recherche globale
  filters: [
    FilterOperators.like('nom', 'Smith'),
    FilterOperators.greaterThanOrEqual('salaire', 60000),
    FilterOperators.equals('service', 'IT')
  ],
  sorts: [
    SortOrders.descending('salaire'),
    SortOrders.ascending('nom')
  ],
  pagination: { page: 1, perPage: 50 }
});
```

## ⚡ **Méthodes Étendues**

### **Comptage Total**
```javascript
const totalEmployees = await dataProvider.getTotal('employees');
const totalITEmployees = await dataProvider.getTotal('employees', { 
  service: 'IT' 
});
```

### **Test de Connectivité**
```javascript
// Test une ressource
const result = await dataProvider.testConnection('employees');
console.log(result.success ? 'OK' : 'Erreur');

// Test plusieurs ressources
const resources = ['employees', 'customers', 'products'];
for (const resource of resources) {
  const test = await dataProvider.testConnection(resource);
  console.log(`${resource}: ${test.success ? 'OK' : 'Erreur'}`);
}
```

### **Configuration Dynamique**
```javascript
// Ajouter/modifier la config d'une ressource
dataProvider.setResourceConfig('orders', {
  transformParams: (query, params) => {
    // Ajouter automatiquement l'ID utilisateur
    query.userId = getCurrentUserId();
    return query;
  }
});

// Récupérer la config
const config = dataProvider.getResourceConfig('orders');
```

## 🐛 **Debug et Logs**

### **Activer les Logs**
```javascript
import { debugDataProvider } from './dataProvider.js';

// Ou créer avec logs
const provider = createUniversalDataProvider({
  apiUrl: 'http://your-server:44000/api',
  enableLogs: true  // Active les logs détaillés
});
```

### **Gestion d'Erreurs**
```javascript
try {
  const result = await dataProvider.getList('employees', params);
} catch (error) {
  console.log('Opération:', error.operation);
  console.log('Ressource:', error.resource);
  console.log('Erreur originale:', error.originalError);
}
```

## 📊 **Tests et Validation**

### **Lancer les Tests**
```javascript
import { testingExamples } from './dataProviderExamples.js';

// Test complet
await testingExamples.runAllTests();

// Tests spécifiques
await testingExamples.testAllResources(['employees', 'customers']);
await testingExamples.validateConfiguration();
```

### **Test de Performance**
```javascript
import { advancedExamples } from './dataProviderExamples.js';

const perfTest = await advancedExamples.performanceTest();
console.log(`Test terminé en ${perfTest.duration}ms`);
```

## 🎯 **Points Clés**

### ✅ **Compatible IBM i**
- Format JSON conforme aux APIs IBM i
- Header `X-Total-Count` géré automatiquement
- Tous les opérateurs de filtres supportés
- Pagination standard React-Admin

### ✅ **Universel**
- Fonctionne avec toute ressource REST
- Configuration par ressource
- Transformations de données flexibles
- Extensible facilement

### ✅ **Production Ready**
- Gestion d'erreurs robuste
- Timeouts configurables
- Authentification supportée
- Logs de debug
- Tests inclus

---

**🎯 Le data provider universel est maintenant prêt ! Il peut gérer toutes vos ressources IBM i avec une configuration flexible et des fonctionnalités avancées.**