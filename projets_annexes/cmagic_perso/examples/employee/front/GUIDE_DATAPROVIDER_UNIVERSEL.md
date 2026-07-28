# Data Provider Universel TypeScript - Guide d'Utilisation

## 🎯 Vue d'ensemble

Le **Data Provider Universel TypeScript** est une solution complète pour intégrer facilement n'importe quelle API REST IBM i dans vos projets React-Admin. Il suit le pattern standard des APIs ArchiAPI et fournit une abstraction TypeScript complète.

## 🚀 Installation et Configuration

### Installation des dépendances

```bash
npm install react react-dom react-admin
npm install typescript @types/react @types/react-dom
```

### Configuration basique

```typescript
import { createUniversalDataProvider } from './universalDataProvider';

// Configuration simple pour une ressource
const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://your-ibmi-server:44000/api',
  resources: {
    employees: {
      endpoint: 'employees',
      defaultSort: { field: 'nom', order: 'ASC' }
    }
  }
});
```

### Configuration multi-ressources

```typescript
import { 
  createUniversalDataProvider,
  createUniversalReactAdminConfig,
  createConfiguredDataProvider
} from './universalDataProvider';

// Configuration complète
const config = createUniversalReactAdminConfig('http://your-server:44000/api', {
  appTitle: 'Gestion IBM i',
  enableLogs: true,
  resources: {
    employees: employeeReactAdminConfig,
    customers: customerReactAdminConfig,
    products: productReactAdminConfig
  }
});

const dataProvider = createConfiguredDataProvider(config);
```

## 📊 Utilisation avec React-Admin

### Application complète multi-ressources

```tsx
import React from 'react';
import { Admin, Resource, List, Datagrid, TextField } from 'react-admin';
import { createMultiResourceDataProvider } from './universalDataProviderExamples';

const dataProvider = createMultiResourceDataProvider('http://localhost:44000/api');

// Composants Employee
const EmployeeList = (props) => (
  <List {...props}>
    <Datagrid>
      <TextField source="id" />
      <TextField source="prenom" label="Prénom" />
      <TextField source="nom" label="Nom" />
      <TextField source="service" label="Service" />
    </Datagrid>
  </List>
);

// Composants Customer
const CustomerList = (props) => (
  <List {...props}>
    <Datagrid>
      <TextField source="id" />
      <TextField source="firstName" label="Prénom" />
      <TextField source="lastName" label="Nom" />
      <TextField source="email" label="Email" />
      <TextField source="status" label="Statut" />
    </Datagrid>
  </List>
);

// Application principale
const App = () => (
  <Admin dataProvider={dataProvider} title="Gestion IBM i">
    <Resource name="employees" list={EmployeeList} options={{ label: 'Employés' }} />
    <Resource name="customers" list={CustomerList} options={{ label: 'Clients' }} />
    <Resource name="products" list={ProductList} options={{ label: 'Produits' }} />
  </Admin>
);

export default App;
```

## 🔧 Fonctionnalités Avancées

### Filtres avancés avec opérateurs

```typescript
import { createAdvancedFilters, EmployeeFilters } from './universalDataProviderExamples';

// Utilisation des helpers de filtres
const filters = createAdvancedFilters([
  EmployeeFilters.byDepartment('IT'),
  EmployeeFilters.byMinSalary(50000),
  EmployeeFilters.byNameLike('john')
]);

// Appel API avec filtres
const employees = await dataProvider.getList('employees', {
  pagination: { page: 1, perPage: 20 },
  sort: { field: 'salaire', order: 'DESC' },
  filter: filters
});
```

### Transformation des données

```typescript
const dataProvider = createUniversalDataProvider({
  apiUrl: 'http://your-server:44000/api',
  resources: {
    customers: {
      endpoint: 'customers',
      transformResponse: (data) => {
        // Ajouter des champs calculés
        if (Array.isArray(data)) {
          return data.map(item => ({
            ...item,
            displayName: `${item.firstName} ${item.lastName}`,
            isVIP: item.company && item.company.length > 0
          }));
        }
        return {
          ...data,
          displayName: `${data.firstName} ${data.lastName}`,
          isVIP: data.company && data.company.length > 0
        };
      }
    }
  }
});
```

### Client HTTP personnalisé avec retry

```typescript
import { createCustomHttpDataProvider } from './universalDataProviderExamples';

// Data provider avec retry automatique
const dataProvider = createCustomHttpDataProvider('http://your-server:44000/api');

// Le client va automatiquement retry en cas d'échec
const employees = await dataProvider.getList('employees', {
  pagination: { page: 1, perPage: 10 },
  sort: { field: 'nom', order: 'ASC' },
  filter: {}
});
```

### Authentification

```typescript
import { createAuthenticatedDataProvider } from './universalDataProviderExamples';

// Data provider avec token d'authentification
const token = localStorage.getItem('authToken');
const dataProvider = createAuthenticatedDataProvider(
  'http://your-server:44000/api',
  token
);
```

## 🎨 Configurations Prédéfinies

### Ressource Employee

```typescript
import { employeeReactAdminConfig } from './universalReactAdminConfig';

// Configuration complète pour Employee
const config = {
  label: 'Employés',
  views: { list: true, create: true, edit: true, show: true },
  listFields: [
    { source: 'prenom', label: 'Prénom', type: 'text' },
    { source: 'nom', label: 'Nom', type: 'text' },
    { source: 'service', label: 'Service', type: 'text' },
    { source: 'salaire', label: 'Salaire', type: 'currency' }
  ],
  filters: [
    { source: 'q', label: 'Recherche', type: 'text', alwaysOn: true },
    { source: 'service', label: 'Service', type: 'select' },
    { source: 'salaire_gte', label: 'Salaire min', type: 'number' }
  ]
};
```

### Ressource Customer

```typescript
import { customerReactAdminConfig } from './universalReactAdminConfig';

// Configuration avec mapping de champs
const customerConfig = {
  endpoint: 'customers',
  fieldMapping: {
    'lastName': 'nom',
    'firstName': 'prenom'
  },
  defaultFilters: { status: 'active' }
};
```

## 🔍 API Complète

### Méthodes du Data Provider

```typescript
// Toutes les méthodes React-Admin standards
await dataProvider.getList(resource, params);
await dataProvider.getOne(resource, params);
await dataProvider.getMany(resource, params);
await dataProvider.getManyReference(resource, params);
await dataProvider.create(resource, params);
await dataProvider.update(resource, params);
await dataProvider.updateMany(resource, params);
await dataProvider.delete(resource, params);
await dataProvider.deleteMany(resource, params);
```

### Helpers de filtres disponibles

```typescript
// Employee
EmployeeFilters.byDepartment('IT')
EmployeeFilters.byMinSalary(50000)
EmployeeFilters.byMaxSalary(80000)
EmployeeFilters.byNameLike('john')
EmployeeFilters.byHiredAfter('2020-01-01')
EmployeeFilters.byGender('M')

// Customer
CustomerFilters.byStatus('active')
CustomerFilters.byCompany('Microsoft')
CustomerFilters.byEmailLike('@gmail.com')
CustomerFilters.byCreatedAfter('2023-01-01')

// Product
ProductFilters.byCategory('Electronics')
ProductFilters.byMinPrice(10)
ProductFilters.byMaxPrice(100)
ProductFilters.inStock()
ProductFilters.byActive(true)
```

## ⚡ Exemples Pratiques

### Recherche complexe Employee

```typescript
// Employés IT avec salaire élevé embauchés récemment
const results = await dataProvider.getList('employees', {
  pagination: { page: 1, perPage: 20 },
  sort: { field: 'salaire', order: 'DESC' },
  filter: createAdvancedFilters([
    EmployeeFilters.byDepartment('IT'),
    EmployeeFilters.byMinSalary(60000),
    EmployeeFilters.byHiredAfter('2023-01-01')
  ])
});
```

### CRUD complet Customer

```typescript
// Créer un client
const newCustomer = await dataProvider.create('customers', {
  data: {
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@company.com',
    status: 'active'
  }
});

// Modifier un client
const updatedCustomer = await dataProvider.update('customers', {
  id: '123',
  data: { status: 'inactive' }
});

// Supprimer un client
await dataProvider.delete('customers', { id: '123' });
```

### Recherche avec pagination

```typescript
// Pagination avancée
const products = await dataProvider.getList('products', {
  pagination: { page: 2, perPage: 50 },
  sort: { field: 'price', order: 'ASC' },
  filter: createAdvancedFilters([
    ProductFilters.byCategory('Electronics'),
    ProductFilters.byMinPrice(50),
    ProductFilters.byActive(true)
  ])
});

console.log(`Page 2/50 - ${products.data.length} produits sur ${products.total}`);
```

## 🎯 Ajouter une Nouvelle Ressource

### 1. Définir l'interface

```typescript
export interface Order extends BaseResource {
  orderNumber: string;
  customerId: string;
  amount: number;
  status: 'pending' | 'shipped' | 'delivered';
  orderDate: string;
}
```

### 2. Créer la configuration

```typescript
const orderConfig: ResourceConfig = {
  endpoint: 'orders',
  defaultSort: { field: 'orderDate', order: 'DESC' },
  defaultFilters: { status: 'pending' }
};
```

### 3. Ajouter les helpers de filtres

```typescript
export const OrderFilters = {
  byStatus: (status: string) => ({ field: 'status', operator: 'eq', value: status }),
  byCustomer: (customerId: string) => ({ field: 'customerId', operator: 'eq', value: customerId }),
  byMinAmount: (amount: number) => ({ field: 'amount', operator: 'gte', value: amount }),
  byDateAfter: (date: string) => ({ field: 'orderDate', operator: 'gte', value: date })
};
```

### 4. Configurer React-Admin

```typescript
const orderReactAdminConfig: ResourceReactAdminConfig = {
  label: 'Commandes',
  views: { list: true, create: true, edit: true, show: true },
  listFields: [
    { source: 'orderNumber', label: 'N° Commande', type: 'text' },
    { source: 'amount', label: 'Montant', type: 'currency' },
    { source: 'status', label: 'Statut', type: 'text' },
    { source: 'orderDate', label: 'Date', type: 'date' }
  ],
  // ... autres configurations
};
```

## 🚀 Génération Automatique

### Générer les composants React-Admin

```typescript
import { generateResourceCode } from './universalReactAdminConfig';

// Génère automatiquement les composants
const orderComponents = generateResourceCode('orders', orderReactAdminConfig);
console.log(orderComponents);
// Sortie: Code JSX complet pour OrderList, OrderCreate, OrderEdit, OrderShow
```

### Générer l'application complète

```typescript
import { generateReactAdminApp } from './universalReactAdminConfig';

const config = createUniversalReactAdminConfig('http://server:44000/api');
const appCode = generateReactAdminApp(config);
console.log(appCode);
// Sortie: Application React-Admin complète
```

## 🎉 Avantages

### ✅ **Réutilisabilité**
- Un seul data provider pour toutes vos ressources IBM i
- Configuration déclarative par ressource
- Helpers de filtres réutilisables

### ✅ **Type Safety**
- Types TypeScript complets
- IntelliSense avancé
- Validation à la compilation

### ✅ **Flexibilité**
- Transformation des données personnalisable
- Client HTTP configurable
- Mapping de champs automatique

### ✅ **Performance**
- Client HTTP avec retry automatique
- Gestion intelligente des erreurs
- Pagination optimisée

### ✅ **Compatibilité**
- Compatible avec toutes les APIs ArchiAPI
- Standards React-Admin respectés
- Pattern IBM i REST standard

## 📞 Support

Pour toute question ou personnalisation :
- Documentation complète dans les fichiers TypeScript
- Exemples d'utilisation fournis
- Types complets pour IntelliSense

**🎯 Votre data provider universel est prêt à être utilisé dans tous vos projets React-Admin !**