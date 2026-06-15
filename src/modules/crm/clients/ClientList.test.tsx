import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { ClientList } from './ClientList';
import { CoreAdminContext, ResourceContextProvider } from 'ra-core';
import { dataProvider } from '@/app/providers/dataProvider';
import { i18nProvider } from '@/lib/i18nProvider';
import { I18nextProvider } from 'react-i18next';
import { MemoryRouter } from 'react-router';
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
      <MemoryRouter>
        <CoreAdminContext
          dataProvider={dataProvider}
          i18nProvider={i18nProvider}
        >
          <I18nextProvider i18n={i18n}>
            <ResourceContextProvider value="clients">
              <ClientList />
            </ResourceContextProvider>
          </I18nextProvider>
        </CoreAdminContext>
      </MemoryRouter>
    );

    // Vérifie que le titre de la liste est présent
    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /clients/i })).toBeInTheDocument();
    });
  });
});