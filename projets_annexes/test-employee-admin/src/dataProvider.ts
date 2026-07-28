import { createUniversalDataProvider } from './universalDataProvider';

// Configuration simple pour une ressource
export const dataProvider = createUniversalDataProvider({
  apiUrl: '/api',
  resources: {
    employees: {
      endpoint: 'employees',
      defaultSort: { field: 'nom', order: 'ASC' }
    },
    services: {
      endpoint: 'services',
      defaultSort: { field: 'nom', order: 'ASC' }
    }
  }
});

