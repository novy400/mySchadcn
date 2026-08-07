import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import {
  CoreAdminContext,
  ResourceContextProvider,
  testDataProvider,
  type DataProvider,
} from 'ra-core';
import { MemoryRouter, Route, Routes } from 'react-router';
import { describe, expect, it, vi } from 'vitest';

import { i18nProvider } from '@/lib/i18nProvider';

import { ServiceList } from './ServiceList';

const service = {
  id: 'A00',
  nom: 'Centre de services',
  idManageur: '000010',
  idServiceAdmin: 'A01',
  site: 'Paris',
};

const renderServiceList = (dataProvider: DataProvider) =>
  render(
    <MemoryRouter>
      <CoreAdminContext dataProvider={dataProvider} i18nProvider={i18nProvider}>
        <ResourceContextProvider value="services">
          <ServiceList />
        </ResourceContextProvider>
      </CoreAdminContext>
    </MemoryRouter>,
  );

describe('<ServiceList />', () => {
  it('charge la liste services et restitue les cinq champs du contrat', async () => {
    const getList = vi.fn().mockResolvedValue({ data: [service], total: 1 });
    const dataProvider = testDataProvider({ getList });

    renderServiceList(dataProvider);

    await waitFor(() => {
      expect(getList).toHaveBeenCalledWith(
        'services',
        expect.objectContaining({
          filter: {},
          pagination: { page: 1, perPage: 10 },
          sort: { field: 'nom', order: 'ASC' },
        }),
      );
    });

    for (const value of Object.values(service)) {
      expect(await screen.findByText(value)).toBeInTheDocument();
    }
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
  });

  it('propose uniquement les recherches, filtres et tris du contrat services', async () => {
    const dataProvider = testDataProvider({
      getList: vi.fn().mockResolvedValue({ data: [service], total: 1 }),
    });

    renderServiceList(dataProvider);

    expect(screen.getByPlaceholderText('Rechercher un service IBM i')).toBeInTheDocument();
    const addFilterButton = screen.getByRole('button', { name: /add filter/i });
    fireEvent.pointerDown(addFilterButton, { button: 0, ctrlKey: false });
    fireEvent.click(addFilterButton);

    expect(await screen.findByRole('menuitemcheckbox', { name: 'Identifiant' })).toBeInTheDocument();
    expect(screen.getByRole('menuitemcheckbox', { name: 'Nom' })).toBeInTheDocument();
    expect(screen.getByRole('menuitemcheckbox', { name: 'Identifiant manager' })).toBeInTheDocument();
    expect(screen.getByRole('menuitemcheckbox', { name: 'Service administratif' })).toBeInTheDocument();
    expect(screen.getByRole('menuitemcheckbox', { name: 'Site' })).toBeInTheDocument();
    fireEvent.keyDown(screen.getByRole('menu'), { key: 'Escape' });

    await screen.findByText(service.nom);
    const headers = screen.getAllByRole('columnheader');
    const header = (label: string) => headers.find((element) => element.textContent === label);

    expect(header('Identifiant')?.querySelector('button')).not.toBeNull();
    expect(header('Nom')?.querySelector('button')).not.toBeNull();
    expect(header('Identifiant manager')?.querySelector('button')).toBeNull();
    expect(header('Service administratif')?.querySelector('button')).toBeNull();
    expect(header('Site')?.querySelector('button')).toBeNull();
  });

  it('ouvre la route SHOW du service depuis une ligne', async () => {
    const dataProvider = testDataProvider({
      getList: vi.fn().mockResolvedValue({ data: [service], total: 1 }),
    });

    render(
      <MemoryRouter initialEntries={['/services']}>
        <CoreAdminContext dataProvider={dataProvider} i18nProvider={i18nProvider}>
          <ResourceContextProvider value="services">
            <Routes>
              <Route path="/services" element={<ServiceList />} />
              <Route path="/services/:id/show" element={<p>Fiche service ouverte</p>} />
            </Routes>
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    const row = (await screen.findByText(service.nom)).closest('tr');
    expect(row).not.toBeNull();
    fireEvent.click(row!);

    expect(await screen.findByText('Fiche service ouverte')).toBeInTheDocument();
  });

  it('transmet la recherche q au DataProvider', async () => {
    const getList = vi.fn().mockResolvedValue({ data: [service], total: 1 });
    const dataProvider = testDataProvider({ getList });

    renderServiceList(dataProvider);

    fireEvent.change(screen.getByPlaceholderText('Rechercher un service IBM i'), {
      target: { value: 'planning' },
    });

    await waitFor(
      () => {
        expect(getList).toHaveBeenCalledWith(
          'services',
          expect.objectContaining({ filter: { q: 'planning' } }),
        );
      },
      { timeout: 2_000 },
    );
  });
});
