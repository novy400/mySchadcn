import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { CoreAdminContext, ResourceContextProvider, testDataProvider } from 'ra-core';
import { MemoryRouter, Route, Routes } from 'react-router';
import { describe, expect, it, vi } from 'vitest';
import { i18nProvider } from '@/lib/i18nProvider';
import { FournisseurCreate } from './FournisseurCreate';
import { FournisseurEdit } from './FournisseurEdit';
import { fournisseurs } from './fournisseur.resource';

describe('fournisseurs resource', () => {
  it('registers its list, create and edit screens', () => {
    expect(fournisseurs.name).toBe('fournisseurs');
    expect(fournisseurs.list).toBeDefined();
    expect(fournisseurs.create).toBe(FournisseurCreate);
    expect(fournisseurs.edit).toBe(FournisseurEdit);
    expect(fournisseurs.recordRepresentation).toBe('nom');
  });

  it('demande la clé métier au CREATE pour respecter le contrat CMagic', async () => {
    render(
      <MemoryRouter initialEntries={['/fournisseurs/create']}>
        <CoreAdminContext
          dataProvider={testDataProvider()}
          i18nProvider={i18nProvider}
        >
          <ResourceContextProvider value="fournisseurs">
            <FournisseurCreate />
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    expect(await screen.findByLabelText(/^Id/)).toBeInTheDocument();
  });

  it('valide les champs requis puis appelle create avec les six champs', async () => {
    const fournisseur = {
      id: 'FOU000003',
      nom: 'Ateliers du Nord',
      adresse: '5 rue du Port',
      ville: 'Lille',
      telephone: '0320998877',
      email: 'contact@ateliers-nord.fr',
    };
    const create = vi.fn().mockResolvedValue({ data: fournisseur });

    render(
      <MemoryRouter initialEntries={['/fournisseurs/create']}>
        <CoreAdminContext
          dataProvider={testDataProvider({ create })}
          i18nProvider={i18nProvider}
        >
          <ResourceContextProvider value="fournisseurs">
            <FournisseurCreate />
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    fireEvent.submit(document.querySelector('form')!);
    expect(await screen.findAllByText('Required')).toHaveLength(2);
    expect(create).not.toHaveBeenCalled();

    for (const [label, value] of [
      [/^Id/, fournisseur.id],
      [/^Nom/, fournisseur.nom],
      ['Adresse', fournisseur.adresse],
      ['Ville', fournisseur.ville],
      ['Telephone', fournisseur.telephone],
      ['Email', fournisseur.email],
    ] as const) {
      fireEvent.change(screen.getByLabelText(label), { target: { value } });
    }
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(create).toHaveBeenCalledWith(
        'fournisseurs',
        expect.objectContaining({ data: fournisseur }),
      );
    });
  });

  it('charge EDIT par getOne, protège id et appelle update sans relation', async () => {
    const fournisseur = {
      id: 'FOU000001',
      nom: 'Fournitures Pro',
      adresse: '12 rue des Ateliers',
      ville: 'Lille',
      telephone: '0320123456',
      email: 'contact@fourniturespro.fr',
    };
    const getOne = vi.fn().mockResolvedValue({ data: fournisseur });
    const update = vi.fn().mockImplementation(async (_resource, params) => ({
      data: { ...fournisseur, ...params.data },
    }));
    const getMany = vi.fn();
    const getManyReference = vi.fn();
    const remove = vi.fn();

    render(
      <MemoryRouter initialEntries={['/fournisseurs/FOU000001']}>
        <CoreAdminContext
          dataProvider={testDataProvider({
            getOne,
            update,
            getMany,
            getManyReference,
            delete: remove,
          })}
          i18nProvider={i18nProvider}
        >
          <ResourceContextProvider value="fournisseurs">
            <Routes>
              <Route
                path="/fournisseurs/:id"
                element={<FournisseurEdit id="FOU000001" />}
              />
            </Routes>
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    await waitFor(() => {
      expect(getOne).toHaveBeenCalledWith(
        'fournisseurs',
        expect.objectContaining({ id: 'FOU000001' }),
      );
    });
    const idInput = await screen.findByLabelText(/^Id/);
    expect(idInput).toBeDisabled();
    expect(screen.queryByRole('button', { name: /delete/i })).not.toBeInTheDocument();
    fireEvent.change(screen.getByLabelText(/^Nom/), {
      target: { value: 'Fournitures Pro SAS' },
    });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(update).toHaveBeenCalledWith(
        'fournisseurs',
        expect.objectContaining({
          id: 'FOU000001',
          data: expect.objectContaining({
            nom: 'Fournitures Pro SAS',
          }),
          previousData: fournisseur,
        }),
      );
    });
    expect(getMany).not.toHaveBeenCalled();
    expect(getManyReference).not.toHaveBeenCalled();
    expect(remove).not.toHaveBeenCalled();
  });
});
