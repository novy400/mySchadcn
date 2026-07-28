# Employee Front-End Data Provider

Ce dossier contient les composants front-end pour interagir avec l'API Employee IBM i.

## 📋 Fichiers Disponibles

### `employeeDataProvider.js`
Data provider compatible React-Admin avec support complet des fonctionnalités avancées :
- ✅ Pagination standard React-Admin
- ✅ Filtres simples et avancés avec opérateurs
- ✅ Tri multi-niveaux
- ✅ Recherche globale
- ✅ Gestion d'erreurs
- ✅ Timeout configurable
- ✅ Headers X-Total-Count

### `employeeApiClient.js`
Client API standalone pour usage hors React-Admin :
- ✅ CRUD complet (Create, Read, Update, Delete)
- ✅ Recherche avancée avec filtres et opérateurs
- ✅ Méthodes spécialisées (par département, salaire, etc.)
- ✅ Validation des données
- ✅ Test de connectivité
- ✅ Helpers pour filtres et tris

### `reactAdminConfig.js`
Configuration complète React-Admin :
- ✅ Composants List, Edit, Create, Show
- ✅ Filtres UI avec tous les champs
- ✅ Pagination personnalisée
- ✅ Champs formatés (salaire, nom complet, etc.)
- ✅ Dashboard avec statistiques
- ✅ Application complète prête à l'emploi

### `examples.js`
Exemples d'utilisation et cas d'usage :
- ✅ Exemples React-Admin
- ✅ Exemples client API standalone
- ✅ Recherches spécialisées
- ✅ Intégrations avancées
- ✅ Tests de connectivité

## 🚀 Installation et Utilisation

### Avec React-Admin

```bash
npm install react-admin
```

```javascript
import { EmployeeApp } from './reactAdminConfig.js';
import { createEmployeeDataProvider } from './employeeDataProvider.js';

// Configuration du data provider
const dataProvider = createEmployeeDataProvider({
  apiUrl: 'http://your-ibmi-server:44000/api'
});

// Utilisation dans votre app
function App() {
  return <EmployeeApp />;
}
```

### Avec le Client API Standalone

```javascript
import { employeeApi, EmployeeFilters, EmployeeSorts } from './employeeApiClient.js';

// Récupérer des employés
const employees = await employeeApi.getEmployees({
  page: 1,
  limit: 10,
  sort: 'nom',
  order: 'ASC'
});

// Recherche avancée
const results = await employeeApi.searchEmployees({
  query: 'john',
  filters: [
    EmployeeFilters.byDepartment('IT'),
    EmployeeFilters.bySalaryMin(50000)
  ],
  sorts: [
    EmployeeSorts.byName('ASC')
  ]
});
```

## 🔧 Configuration

### Variables d'Environnement
```bash
# .env
REACT_APP_API_URL=http://your-ibmi-server:44000/api
```

### Configuration Personnalisée
```javascript
const customConfig = {
  apiUrl: 'http://your-server:44000/api',
  timeout: 30000,
  headers: {
    'Authorization': 'Bearer your-token',
    'X-Client-Version': '1.0'
  }
};
```

## 📊 Fonctionnalités Supportées

### Filtres Standards
- `q` : Recherche globale
- `nom` : Filtrage par nom
- `prenom` : Filtrage par prénom
- `service` : Filtrage par département
- `genre` : Filtrage par genre (M/F)
- `salaire` : Filtrage par salaire
- `dateEmbauche` : Filtrage par date d'embauche
- `dateNaissance` : Filtrage par date de naissance

### Opérateurs de Filtres
- `=` (égal) : `field=value`
- `like` (contient) : `field_like=value`
- `>=` (supérieur ou égal) : `field_gte=value`
- `<=` (inférieur ou égal) : `field_lte=value`
- `>` (supérieur) : `field_gt=value`
- `<` (inférieur) : `field_lt=value`
- `!=` (différent) : `field_ne=value`

### Tri Multi-niveaux
```javascript
// Tri principal + tri secondaire
sorts: [
  { field: 'nom', order: 'ASC' },
  { field: 'dateEmbauche', order: 'DESC' }
]
```

### Pagination
```javascript
pagination: {
  page: 1,      // Page courante (commence à 1)
  perPage: 10   // Nombre d'éléments par page
}
```

## 🧪 Tests et Exemples

### Test de Connectivité
```javascript
import { integrationExamples } from './examples.js';

const result = await integrationExamples.healthCheck();
console.log('API disponible:', result.success);
```

### Exécuter Tous les Exemples
```javascript
import { runAllExamples } from './examples.js';

await runAllExamples();
```

## 🔍 Debugging

### Logs Détaillés
Le data provider et le client API incluent des logs détaillés pour le debugging :

```javascript
// Les erreurs sont automatiquement loggées avec contexte
try {
  await employeeApi.getEmployees();
} catch (error) {
  console.log('Opération:', error.operation);
  console.log('Erreur originale:', error.originalError);
}
```

### Inspection des Requêtes
```javascript
// Activer les logs de requêtes dans fetchUtils
import { fetchUtils } from 'react-admin';

const httpClient = (url, options = {}) => {
  console.log('Requête:', url, options);
  return fetchUtils.fetchJson(url, options);
};
```

## 📈 Performance

### Optimisations Incluses
- ✅ Timeout configurables
- ✅ Gestion d'erreurs robuste
- ✅ Pagination efficace
- ✅ Headers CORS exposés
- ✅ AbortSignal pour annulation

### Recommandations
- Utiliser la pagination pour les grandes listes
- Configurer des timeouts appropriés
- Implémenter un cache côté client si nécessaire
- Monitorer les performances avec les logs

## 🚨 Points Importants

### Compatibilité API
Les composants sont conçus pour l'API Employee IBM i qui :
- Retourne un tableau `[]` pour les collections
- Inclut le header `X-Total-Count`
- Supporte tous les opérateurs de filtres
- Utilise la pagination basée sur `_page` et `_limit`

### Gestion CORS
Assurez-vous que votre API IBMi expose le header `X-Total-Count` :
```rpg
il_addHttpHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
```

### Format de Données
Les employés doivent avoir la structure :
```json
{
  "id": "000010",
  "prenom": "CHRISTINE",
  "nom": "HAAS",
  "initiale": "I",
  "service": "A00",
  "dateEmbauche": "1995-01-01",
  "dateNaissance": "1963-08-24",
  "genre": "F",
  "salaire": 152750.00
}
```

## 📚 Documentation API

Pour plus de détails sur l'API, consultez :
- `../README_REST_API.md` : Documentation complète de l'API
- `../REST_API_EXAMPLES.md` : Exemples cURL et Postman
- `../../ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md` : Guide technique complet