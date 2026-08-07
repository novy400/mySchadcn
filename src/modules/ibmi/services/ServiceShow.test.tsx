import { render, screen, waitFor } from '@testing-library/react';
import { CoreAdminContext, ResourceContextProvider, testDataProvider } from 'ra-core';
import { MemoryRouter, Route, Routes } from 'react-router';
import { describe, expect, it, vi } from 'vitest';

import { i18nProvider } from '@/lib/i18nProvider';

import { ServiceShow } from './ServiceShow';

const service = {
  id: 'A00',
  nom: 'Centre de services',
  idManageur: '000010',
  idServiceAdmin: 'A01',
  site: 'Paris',
};

describe('<ServiceShow />', () => {
  it('charge un service par getOne sans relation ni opération d’écriture', async () => {
    const getOne = vi.fn().mockResolvedValue({ data: service });
    const getMany = vi.fn();
    const getManyReference = vi.fn();
    const create = vi.fn();
    const update = vi.fn();
    const remove = vi.fn();
    const dataProvider = testDataProvider({
      getOne,
      getMany,
      getManyReference,
      create,
      update,
      delete: remove,
    });

    render(
      <MemoryRouter initialEntries={['/services/A00/show']}>
        <CoreAdminContext dataProvider={dataProvider} i18nProvider={i18nProvider}>
          <ResourceContextProvider value="services">
            <Routes>
              <Route path="/services/:id/show" element={<ServiceShow id="A00" />} />
            </Routes>
          </ResourceContextProvider>
        </CoreAdminContext>
      </MemoryRouter>,
    );

    await waitFor(() => {
      expect(getOne).toHaveBeenCalledWith(
        'services',
        expect.objectContaining({ id: 'A00' }),
      );
    });

    for (const value of Object.values(service)) {
      expect(await screen.findByText(value)).toBeInTheDocument();
    }
    expect(getMany).not.toHaveBeenCalled();
    expect(getManyReference).not.toHaveBeenCalled();
    expect(create).not.toHaveBeenCalled();
    expect(update).not.toHaveBeenCalled();
    expect(remove).not.toHaveBeenCalled();
    expect(screen.queryByRole('button', { name: /edit|create|delete/i })).not.toBeInTheDocument();
  });
});
