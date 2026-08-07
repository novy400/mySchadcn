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

import { FournisseurList } from './FournisseurList';

const fournisseur = {
  id: 'FOU000001',
  nom: 'Fournitures Pro',
  adresse: '12 rue des Ateliers',
  ville: 'Lille',
  telephone: '0320123456',
  email: 'contact@fourniturespro.fr',
};

const renderFournisseurList = (dataProvider: DataProvider) =>
  render(
    <MemoryRouter>
      <CoreAdminContext dataProvider={dataProvider} i18nProvider={i18nProvider}>
        <ResourceContextProvider value="fournisseurs">
          <FournisseurList />
        </ResourceContextProvider>
      </CoreAdminContext>
    </MemoryRouter>,
  );

describe('<FournisseurList />', () => {
  it('charge les six champs avec pagination et tri nom au seam DataProvider', async () => {
    const getList = vi.fn().mockResolvedValue({ data: [fournisseur], total: 1 });

    renderFournisseurList(testDataProvider({ getList }));

    await waitFor(() => {
      expect(getList).toHaveBeenCalledWith(
        'fournisseurs',
        expect.objectContaining({
          filter: {},
          pagination: { page: 1, perPage: 10 },
          sort: { field: 'nom', order: 'ASC' },
        }),
      );
    });
    for (const value of Object.values(fournisseur)) {
      expect(await screen.findByText(value)).toBeInTheDocument();
    }
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
  });

  it('limite filtres et tris au contrat fournisseurs', async () => {
    renderFournisseurList(
      testDataProvider({
        getList: vi.fn().mockResolvedValue({ data: [fournisseur], total: 1 }),
      }),
    );

    expect(screen.getByPlaceholderText('Rechercher un fournisseur')).toBeInTheDocument();
    const addFilterButton = screen.getByRole('button', { name: /add filter/i });
    fireEvent.pointerDown(addFilterButton, { button: 0, ctrlKey: false });
    fireEvent.click(addFilterButton);
    expect(await screen.findByRole('menuitemcheckbox', { name: 'Ville' })).toBeInTheDocument();
    fireEvent.keyDown(screen.getByRole('menu'), { key: 'Escape' });

    await screen.findByText(fournisseur.nom);
    const headers = screen.getAllByRole('columnheader');
    const header = (label: string) =>
      headers.find((element) => element.textContent === label);

    expect(header('Nom')?.querySelector('button')).not.toBeNull();
    for (const label of ['Id', 'Adresse', 'Ville', 'Telephone', 'Email']) {
      expect(header(label)?.querySelector('button')).toBeNull();
    }
  });

  it('ouvre EDIT depuis une ligne sans opération de relation', async () => {
    const getMany = vi.fn();
    const getManyReference = vi.fn();
    const dataProvider = testDataProvider({
      getList: vi.fn().mockResolvedValue({ data: [fournisseur], total: 1 }),
      getMany,
      getManyReference,
    });

    render(
      <MemoryRouter initialEntries={['/fournisseurs']}>
        <CoreAdminContext dataProvider={dataProvider} i18nProvider={i18nProvider}>
          <ResourceContextProvider value="fournisseurs">
            <Routes>
              <Route path="/fournisseurs" element={<FournisseurList />} />
              <Route path="/fournisseurs/:id" element={<p>Édition fournisseur ouverte</p>} />
            </Routes>
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    const row = (await screen.findByText(fournisseur.nom)).closest('tr');
    expect(row).not.toBeNull();
    fireEvent.click(row!);

    expect(await screen.findByText('Édition fournisseur ouverte')).toBeInTheDocument();
    expect(getMany).not.toHaveBeenCalled();
    expect(getManyReference).not.toHaveBeenCalled();
  });

  it('transmet la recherche q au DataProvider', async () => {
    const getList = vi.fn().mockResolvedValue({ data: [fournisseur], total: 1 });
    renderFournisseurList(testDataProvider({ getList }));

    fireEvent.change(screen.getByPlaceholderText('Rechercher un fournisseur'), {
      target: { value: 'nord' },
    });

    await waitFor(
      () => {
        expect(getList).toHaveBeenCalledWith(
          'fournisseurs',
          expect.objectContaining({ filter: { q: 'nord' } }),
        );
      },
      { timeout: 2_000 },
    );
  });
});
