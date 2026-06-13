import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { ClientList } from './ClientList';
import { AdminContext, defaultI18nProvider } from 'ra-core';
import { dataProvider } from '@/app/providers/dataProvider';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

// Configuration basique de i18n pour les tests
i18n.init({
  lng: 'fr',
  resources: {
    fr: {
      translation: {
        'ra': {
          'page': {
            'list': '%{name}',
          },
        },
        'resources': {
          'clients': {
            'name': 'clients',
          },
        },
      },
    },
  },
});

describe('<ClientList />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ClientList).toBeDefined();
    expect(typeof ClientList).toBe('function');
  });

  it('renders client data in DataTable', async () => {
    render(
      <AdminContext
        dataProvider={dataProvider}
        i18nProvider={defaultI18nProvider}
        resource="clients"
      >
        <I18nextProvider i18n={i18n}>
          <ClientList />
        </I18nextProvider>
      </AdminContext>
    );

    // Vérifie que le titre de la liste est présent
    await waitFor(() => {
      expect(screen.getByRole('heading', { name: 'clients' })).toBeInTheDocument();
    });
  });
});