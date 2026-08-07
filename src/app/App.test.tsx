import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import { afterEach, describe, expect, it, vi } from 'vitest';

vi.mock('./providers/dataProvider', async () => {
  const { testDataProvider } = await import('ra-core');
  return {
    default: testDataProvider({
      getList: async () => ({ data: [], total: 0 }),
    }),
  };
});

import App from './App';

const sessionKey = 'myschadcn.auth.identity';

afterEach(() => sessionStorage.removeItem(sessionKey));

describe('<App />', () => {
  it('affiche Services IBM i dans la navigation d’un rôle autorisé', async () => {
    sessionStorage.setItem(
      sessionKey,
      JSON.stringify({
        id: 'lecteur-test',
        fullName: 'Lecteur Test',
        role: 'lecteur',
      }),
    );

    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByRole('link', { name: /Services IBM i/i })).toBeInTheDocument();
  });
});
