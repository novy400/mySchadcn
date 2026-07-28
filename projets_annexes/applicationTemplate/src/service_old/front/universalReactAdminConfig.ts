/**
 * Configuration React-Admin Universelle pour APIs IBM i
 * 
 * Composants et configurations React-Admin génériques pour toutes les
 * ressources suivant le pattern API REST IBM i standard
 * 
 * @author ArchiAPI Template
 * @version 1.0.0
 * @date 2025-10-07
 */

import React from 'react';
import { 
  createUniversalDataProvider, 
  UniversalDataProviderConfig 
} from './universalDataProvider';

// ===== TYPES REACT-ADMIN (mock sans dépendance) =====

// Types simplifiés pour éviter la dépendance React-Admin
interface ListProps {
  resource?: string;
  children?: React.ReactNode;
}

interface CreateProps {
  resource?: string;
  children?: React.ReactNode;
}

interface EditProps {
  resource?: string;
  children?: React.ReactNode;
}

interface ShowProps {
  resource?: string;
  children?: React.ReactNode;
}

interface FilterProps {
  resource?: string;
  children?: React.ReactNode;
}

// ===== CONFIGURATIONS UNIVERSELLES =====

/**
 * Configuration React-Admin complète pour multi-ressources
 */
export interface UniversalReactAdminConfig {
  /** URL de base de l'API */
  apiUrl: string;
  /** Configuration du data provider */
  dataProviderConfig?: Partial<UniversalDataProviderConfig>;
  /** Configuration des ressources */
  resources: {
    [resourceName: string]: ResourceReactAdminConfig;
  };
  /** Titre de l'application */
  appTitle?: string;
  /** Configuration d'authentification */
  authConfig?: AuthConfig;
}

export interface ResourceReactAdminConfig {
  /** Nom affiché dans React-Admin */
  label: string;
  /** Icône de la ressource */
  icon?: string;
  /** Configuration des vues */
  views: {
    list?: boolean;
    create?: boolean;
    edit?: boolean;
    show?: boolean;
  };
  /** Champs pour la liste */
  listFields: FieldConfig[];
  /** Champs pour le formulaire */
  formFields: FieldConfig[];
  /** Champs pour l'affichage */
  showFields: FieldConfig[];
  /** Filtres disponibles */
  filters?: FilterConfig[];
  /** Configuration de pagination */
  pagination?: {
    perPage: number;
    perPageOptions: number[];
  };
  /** Tri par défaut */
  defaultSort?: {
    field: string;
    order: 'ASC' | 'DESC';
  };
}

export interface FieldConfig {
  /** Nom du champ dans l'API */
  source: string;
  /** Label affiché */
  label: string;
  /** Type de champ */
  type: 'text' | 'number' | 'date' | 'email' | 'select' | 'boolean' | 'currency';
  /** Obligatoire dans les formulaires */
  required?: boolean;
  /** Options pour les select */
  choices?: { id: string | number; name: string }[];
  /** Formatage personnalisé */
  format?: (value: any) => string;
  /** Propriétés supplémentaires */
  props?: Record<string, any>;
}

export interface FilterConfig {
  source: string;
  label: string;
  type: 'text' | 'select' | 'number' | 'date';
  choices?: { id: string | number; name: string }[];
  alwaysOn?: boolean;
}

export interface AuthConfig {
  loginUrl?: string;
  logoutUrl?: string;
  checkAuthUrl?: string;
  tokenStorageKey?: string;
}

// ===== CONFIGURATIONS PRÉDÉFINIES =====

/**
 * Configuration Employee pour React-Admin
 */
export const employeeReactAdminConfig: ResourceReactAdminConfig = {
  label: 'Employés',
  icon: 'person',
  views: {
    list: true,
    create: true,
    edit: true,
    show: true
  },
  listFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'prenom', label: 'Prénom', type: 'text' },
    { source: 'nom', label: 'Nom', type: 'text' },
    { source: 'service', label: 'Service', type: 'text' },
    { 
      source: 'salaire', 
      label: 'Salaire', 
      type: 'currency',
      format: (value) => new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR'
      }).format(value)
    },
    { source: 'dateEmbauche', label: 'Date embauche', type: 'date' }
  ],
  formFields: [
    { source: 'prenom', label: 'Prénom', type: 'text', required: true },
    { source: 'nom', label: 'Nom', type: 'text', required: true },
    { 
      source: 'service', 
      label: 'Service', 
      type: 'select', 
      required: true,
      choices: [
        { id: 'A00', name: 'Direction' },
        { id: 'B01', name: 'Planification' },
        { id: 'C01', name: 'Support Information' },
        { id: 'D01', name: 'Développement' },
        { id: 'D11', name: 'Systèmes' },
        { id: 'D21', name: 'Support Système' },
        { id: 'E01', name: 'Support' },
        { id: 'E11', name: 'Opérations' },
        { id: 'E21', name: 'Logiciel' }
      ]
    },
    { source: 'dateEmbauche', label: 'Date embauche', type: 'date', required: true },
    { source: 'dateNaissance', label: 'Date naissance', type: 'date', required: true },
    { 
      source: 'genre', 
      label: 'Genre', 
      type: 'select', 
      required: true,
      choices: [
        { id: 'M', name: 'Masculin' },
        { id: 'F', name: 'Féminin' }
      ]
    },
    { source: 'salaire', label: 'Salaire', type: 'number', required: true }
  ],
  showFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'prenom', label: 'Prénom', type: 'text' },
    { source: 'nom', label: 'Nom', type: 'text' },
    { source: 'service', label: 'Service', type: 'text' },
    { source: 'dateEmbauche', label: 'Date embauche', type: 'date' },
    { source: 'dateNaissance', label: 'Date naissance', type: 'date' },
    { source: 'genre', label: 'Genre', type: 'text' },
    { 
      source: 'salaire', 
      label: 'Salaire', 
      type: 'currency',
      format: (value) => new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR'
      }).format(value)
    }
  ],
  filters: [
    { source: 'q', label: 'Recherche globale', type: 'text', alwaysOn: true },
    { source: 'nom', label: 'Nom', type: 'text' },
    { source: 'prenom', label: 'Prénom', type: 'text' },
    { 
      source: 'service', 
      label: 'Service', 
      type: 'select',
      choices: [
        { id: 'A00', name: 'Direction' },
        { id: 'B01', name: 'Planification' },
        { id: 'C01', name: 'Support Information' },
        { id: 'D01', name: 'Développement' },
        { id: 'D11', name: 'Systèmes' },
        { id: 'D21', name: 'Support Système' },
        { id: 'E01', name: 'Support' },
        { id: 'E11', name: 'Opérations' },
        { id: 'E21', name: 'Logiciel' }
      ]
    },
    { 
      source: 'genre', 
      label: 'Genre', 
      type: 'select',
      choices: [
        { id: 'M', name: 'Masculin' },
        { id: 'F', name: 'Féminin' }
      ]
    },
    { source: 'salaire_gte', label: 'Salaire minimum', type: 'number' },
    { source: 'salaire_lte', label: 'Salaire maximum', type: 'number' },
    { source: 'dateEmbauche_gte', label: 'Embauché après', type: 'date' },
    { source: 'dateEmbauche_lte', label: 'Embauché avant', type: 'date' }
  ],
  pagination: {
    perPage: 25,
    perPageOptions: [10, 25, 50, 100]
  },
  defaultSort: {
    field: 'nom',
    order: 'ASC'
  }
};

/**
 * Configuration Customer pour React-Admin
 */
export const customerReactAdminConfig: ResourceReactAdminConfig = {
  label: 'Clients',
  icon: 'business',
  views: {
    list: true,
    create: true,
    edit: true,
    show: true
  },
  listFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'firstName', label: 'Prénom', type: 'text' },
    { source: 'lastName', label: 'Nom', type: 'text' },
    { source: 'email', label: 'Email', type: 'email' },
    { source: 'company', label: 'Entreprise', type: 'text' },
    { 
      source: 'status', 
      label: 'Statut', 
      type: 'select',
      choices: [
        { id: 'active', name: 'Actif' },
        { id: 'inactive', name: 'Inactif' },
        { id: 'pending', name: 'En attente' }
      ]
    }
  ],
  formFields: [
    { source: 'firstName', label: 'Prénom', type: 'text', required: true },
    { source: 'lastName', label: 'Nom', type: 'text', required: true },
    { source: 'email', label: 'Email', type: 'email', required: true },
    { source: 'phone', label: 'Téléphone', type: 'text' },
    { source: 'company', label: 'Entreprise', type: 'text' },
    { 
      source: 'status', 
      label: 'Statut', 
      type: 'select', 
      required: true,
      choices: [
        { id: 'active', name: 'Actif' },
        { id: 'inactive', name: 'Inactif' },
        { id: 'pending', name: 'En attente' }
      ]
    }
  ],
  showFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'firstName', label: 'Prénom', type: 'text' },
    { source: 'lastName', label: 'Nom', type: 'text' },
    { source: 'email', label: 'Email', type: 'email' },
    { source: 'phone', label: 'Téléphone', type: 'text' },
    { source: 'company', label: 'Entreprise', type: 'text' },
    { source: 'status', label: 'Statut', type: 'text' },
    { source: 'createdAt', label: 'Créé le', type: 'date' }
  ],
  filters: [
    { source: 'q', label: 'Recherche globale', type: 'text', alwaysOn: true },
    { source: 'firstName', label: 'Prénom', type: 'text' },
    { source: 'lastName', label: 'Nom', type: 'text' },
    { source: 'email', label: 'Email', type: 'text' },
    { source: 'company', label: 'Entreprise', type: 'text' },
    { 
      source: 'status', 
      label: 'Statut', 
      type: 'select',
      choices: [
        { id: 'active', name: 'Actif' },
        { id: 'inactive', name: 'Inactif' },
        { id: 'pending', name: 'En attente' }
      ]
    }
  ],
  pagination: {
    perPage: 25,
    perPageOptions: [10, 25, 50, 100]
  },
  defaultSort: {
    field: 'lastName',
    order: 'ASC'
  }
};

/**
 * Configuration Product pour React-Admin
 */
export const productReactAdminConfig: ResourceReactAdminConfig = {
  label: 'Produits',
  icon: 'inventory',
  views: {
    list: true,
    create: true,
    edit: true,
    show: true
  },
  listFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'name', label: 'Nom', type: 'text' },
    { source: 'category', label: 'Catégorie', type: 'text' },
    { 
      source: 'price', 
      label: 'Prix', 
      type: 'currency',
      format: (value) => new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR'
      }).format(value)
    },
    { source: 'stock', label: 'Stock', type: 'number' },
    { source: 'active', label: 'Actif', type: 'boolean' }
  ],
  formFields: [
    { source: 'name', label: 'Nom', type: 'text', required: true },
    { source: 'description', label: 'Description', type: 'text' },
    { source: 'price', label: 'Prix', type: 'number', required: true },
    { source: 'category', label: 'Catégorie', type: 'text', required: true },
    { source: 'stock', label: 'Stock', type: 'number', required: true },
    { source: 'active', label: 'Actif', type: 'boolean' }
  ],
  showFields: [
    { source: 'id', label: 'ID', type: 'text' },
    { source: 'name', label: 'Nom', type: 'text' },
    { source: 'description', label: 'Description', type: 'text' },
    { source: 'category', label: 'Catégorie', type: 'text' },
    { 
      source: 'price', 
      label: 'Prix', 
      type: 'currency',
      format: (value) => new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR'
      }).format(value)
    },
    { source: 'stock', label: 'Stock', type: 'number' },
    { source: 'active', label: 'Actif', type: 'boolean' },
    { source: 'createdAt', label: 'Créé le', type: 'date' }
  ],
  filters: [
    { source: 'q', label: 'Recherche globale', type: 'text', alwaysOn: true },
    { source: 'name', label: 'Nom', type: 'text' },
    { source: 'category', label: 'Catégorie', type: 'text' },
    { source: 'price_gte', label: 'Prix minimum', type: 'number' },
    { source: 'price_lte', label: 'Prix maximum', type: 'number' },
    { source: 'active', label: 'Actif', type: 'select', choices: [
      { id: 'true', name: 'Oui' },
      { id: 'false', name: 'Non' }
    ]}
  ],
  pagination: {
    perPage: 25,
    perPageOptions: [10, 25, 50, 100]
  },
  defaultSort: {
    field: 'name',
    order: 'ASC'
  }
};

// ===== FONCTIONS DE CRÉATION =====

/**
 * Crée une configuration React-Admin complète
 */
export const createUniversalReactAdminConfig = (
  apiUrl: string,
  options?: Partial<UniversalReactAdminConfig>
): UniversalReactAdminConfig => {
  return {
    apiUrl,
    appTitle: 'Gestion IBM i',
    resources: {
      employees: employeeReactAdminConfig,
      customers: customerReactAdminConfig,
      products: productReactAdminConfig
    },
    ...options
  };
};

/**
 * Crée un data provider configuré pour React-Admin
 */
export const createConfiguredDataProvider = (config: UniversalReactAdminConfig) => {
  const dataProviderConfig: UniversalDataProviderConfig = {
    apiUrl: config.apiUrl,
    enableLogs: process.env.NODE_ENV === 'development',
    resources: {},
    ...config.dataProviderConfig
  };

  // Configuration automatique des ressources
  Object.keys(config.resources).forEach(resourceName => {
    const resourceConfig = config.resources[resourceName];
    
    dataProviderConfig.resources![resourceName] = {
      endpoint: resourceName,
      defaultSort: resourceConfig.defaultSort,
      // Autres configurations peuvent être ajoutées ici
    };
  });

  return createUniversalDataProvider(dataProviderConfig);
};

// ===== GÉNÉRATEURS DE CODE REACT-ADMIN =====

/**
 * Génère le code JSX pour une ressource
 */
export const generateResourceCode = (
  resourceName: string, 
  config: ResourceReactAdminConfig
): string => {
  const componentName = resourceName.charAt(0).toUpperCase() + resourceName.slice(1);
  
  const listFields = config.listFields.map(field => {
    switch (field.type) {
      case 'currency':
        return `    <NumberField source="${field.source}" label="${field.label}" options={{style: 'currency', currency: 'EUR'}} />`;
      case 'date':
        return `    <DateField source="${field.source}" label="${field.label}" />`;
      case 'email':
        return `    <EmailField source="${field.source}" label="${field.label}" />`;
      case 'boolean':
        return `    <BooleanField source="${field.source}" label="${field.label}" />`;
      default:
        return `    <TextField source="${field.source}" label="${field.label}" />`;
    }
  }).join('\n');

  return `
// ${componentName} Components
export const ${componentName}List = (props) => (
  <List {...props}>
    <Datagrid>
${listFields}
      <EditButton />
      <ShowButton />
      <DeleteButton />
    </Datagrid>
  </List>
);

export const ${componentName}Create = (props) => (
  <Create {...props}>
    <SimpleForm>
      {/* Formulaire généré automatiquement */}
    </SimpleForm>
  </Create>
);

export const ${componentName}Edit = (props) => (
  <Edit {...props}>
    <SimpleForm>
      {/* Formulaire généré automatiquement */}
    </SimpleForm>
  </Edit>
);

export const ${componentName}Show = (props) => (
  <Show {...props}>
    <SimpleShowLayout>
      {/* Affichage généré automatiquement */}
    </SimpleShowLayout>
  </Show>
);
`;
};

/**
 * Génère le code complet de l'application React-Admin
 */
export const generateReactAdminApp = (config: UniversalReactAdminConfig): string => {
  const resources = Object.keys(config.resources).map(resourceName => {
    const resourceConfig = config.resources[resourceName];
    const componentName = resourceName.charAt(0).toUpperCase() + resourceName.slice(1);
    
    return `    <Resource 
      name="${resourceName}" 
      list={${componentName}List}
      create={${componentName}Create}
      edit={${componentName}Edit}
      show={${componentName}Show}
      options={{ label: '${resourceConfig.label}' }}
    />`;
  }).join('\n');

  return `
import React from 'react';
import { Admin, Resource } from 'react-admin';
import { createConfiguredDataProvider } from './universalReactAdminConfig';

// Configuration
const config = ${JSON.stringify(config, null, 2)};
const dataProvider = createConfiguredDataProvider(config);

// Application principale
const App = () => (
  <Admin dataProvider={dataProvider} title="${config.appTitle}">
${resources}
  </Admin>
);

export default App;
`;
};

// ===== EXPORT =====

export default {
  createUniversalReactAdminConfig,
  createConfiguredDataProvider,
  generateResourceCode,
  generateReactAdminApp,
  employeeReactAdminConfig,
  customerReactAdminConfig,
  productReactAdminConfig
};