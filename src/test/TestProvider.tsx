import React from 'react';
import { AdminContext, defaultI18nProvider } from 'ra-core';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';
import { dataProvider } from '@/app/providers/dataProvider';

// Configuration basique de i18n pour les tests
i18n.init({
  lng: 'fr',
  resources: {
    fr: {
      translation: {
        'ra': {
          'action': {
            'edit': 'Éditer',
            'create': 'Créer',
            'delete': 'Supprimer',
            'show': 'Voir',
            'list': 'Liste',
          },
          'page': {
            'list': '%{name}',
          },
          'column': {
            'id': 'id',
            'code': 'code',
            'nom': 'nom',
            'ville': 'ville',
            'statut': 'statut',
          },
        },
      },
    },
  },
});

const TestProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <AdminContext
      dataProvider={dataProvider}
      i18nProvider={defaultI18nProvider}
    >
      <I18nextProvider i18n={i18n}>
        {children}
      </I18nextProvider>
    </AdminContext>
  );
};

export default TestProvider;