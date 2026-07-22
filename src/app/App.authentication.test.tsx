import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import App from './App';

const renderApp = () =>
  render(
    <MemoryRouter>
      <App />
    </MemoryRouter>,
  );

describe("authentification de l’administration", () => {
  beforeEach(() => sessionStorage.clear());
  afterEach(() => sessionStorage.clear());

  it('demande une authentification avant d’afficher le CRM', async () => {
    renderApp();

    expect(await screen.findByRole('heading', { name: 'Connexion' })).toBeInTheDocument();
    expect(screen.queryByText('Dashboard CRM')).not.toBeInTheDocument();
  });

  it('ouvre le CRM avec un compte de démonstration valide', async () => {
    renderApp();

    fireEvent.change(await screen.findByLabelText(/E-mail/), {
      target: { value: 'responsable@demo.local' },
    });
    fireEvent.change(screen.getByLabelText(/Mot de passe/), {
      target: { value: 'demo' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Se connecter' }));

    expect(await screen.findByText('Dashboard CRM', {}, { timeout: 5_000 })).toBeInTheDocument();
  }, 10_000);

});
