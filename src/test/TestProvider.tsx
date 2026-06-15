import React from 'react';
import { CoreAdminContext, ResourceContextProvider } from 'ra-core';
import { I18nextProvider } from 'react-i18next';
import { MemoryRouter } from 'react-router';
import i18n from 'i18next';
import { dataProvider } from '@/app/providers/dataProvider';
import { i18nProvider } from '@/lib/i18nProvider';

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

const TestProvider: React.FC<{ children: React.ReactNode; resource?: string }> = ({
  children,
  resource,
}) => {
  const content = resource ? (
    <ResourceContextProvider value={resource}>{children}</ResourceContextProvider>
  ) : (
    children
  );

  return (
    <MemoryRouter>
      <CoreAdminContext
        dataProvider={dataProvider}
        i18nProvider={i18nProvider}
      >
        <I18nextProvider i18n={i18n}>
          {content}
        </I18nextProvider>
      </CoreAdminContext>
    </MemoryRouter>
  );
};

export default TestProvider;