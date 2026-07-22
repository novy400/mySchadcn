import { render, screen } from '@testing-library/react';
import { RecordContextProvider } from 'ra-core';
import { describe, expect, it } from 'vitest';
import { createAuthProvider, createSessionStorageSessionStore } from '@/app/auth/authProvider';
import TestProvider from '@/test/TestProvider';
import { OrderActions } from './OrderActions';
import type { Order } from './order.types';

const baseOrder: Order = {
  id: 1,
  reference: 'CMD-001',
  date: '2026-07-22',
  customer_id: 1,
  basket: [],
  total_ex_taxes: 100,
  delivery_fees: 10,
  tax_rate: 0.2,
  taxes: 22,
  total: 132,
  status: 'ordered',
  returned: false,
};

const renderActions = (order: Order) =>
  render(
    <TestProvider resource="orders">
      <RecordContextProvider value={order}>
        <OrderActions />
      </RecordContextProvider>
    </TestProvider>,
  );

describe('OrderActions', () => {
  it('offers delivery and cancellation for an ordered order', () => {
    renderActions(baseOrder);

    expect(screen.getByText('Commandée')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Livrer' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Annuler' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Signaler le retour' })).not.toBeInTheDocument();
  });

  it('only offers a return for a delivered order', () => {
    renderActions({ ...baseOrder, status: 'delivered' });

    expect(screen.getByText('Livrée')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Signaler le retour' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Livrer' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Annuler' })).not.toBeInTheDocument();
  });

  it('does not offer an action after a return', () => {
    renderActions({ ...baseOrder, status: 'delivered', returned: true });

    expect(screen.getByText('Enregistré')).toBeInTheDocument();
    expect(screen.getByText('Aucune action disponible.')).toBeInTheDocument();
  });

  it("n'affiche aucune transition de commande à un Agent", async () => {
    const authProvider = createAuthProvider({
      identityAdapter: {
        authenticate: async () => ({
          id: 'agent-test',
          fullName: 'Agent Test',
          role: 'agent',
        }),
      },
      sessionStore: createSessionStorageSessionStore(sessionStorage, 'orders.auth.test'),
    });
    await authProvider.login({ email: 'agent@test.local', password: 'test' });

    render(
      <TestProvider resource="orders" authProvider={authProvider}>
        <RecordContextProvider value={baseOrder}>
          <OrderActions />
        </RecordContextProvider>
      </TestProvider>,
    );

    expect(await screen.findByText('Aucune action autorisée.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Livrer' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Annuler' })).not.toBeInTheDocument();
    sessionStorage.removeItem('orders.auth.test');
  });
});
