import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import TestProvider from '@/test/TestProvider';
import { OrderList } from './OrderList';

describe('<OrderList />', () => {
  it('renders status tabs, filters and ordered records', async () => {
    render(
      <TestProvider resource="orders">
        <OrderList />
      </TestProvider>
    );

    expect(screen.getByPlaceholderText('Rechercher une commande')).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: /Commandées/i })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: /Livrées/i })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: /Annulées/i })).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('CMD-2026-0001')).toBeInTheDocument();
    });
  });

  it('changes the list filter when selecting another status', async () => {
    render(
      <TestProvider resource="orders">
        <OrderList />
      </TestProvider>
    );

    fireEvent.click(screen.getByRole('tab', { name: /Livrées/i }));

    await waitFor(
      () => {
        expect(screen.getByText('CMD-2026-0002')).toBeInTheDocument();
        expect(screen.queryByText('CMD-2026-0001')).not.toBeInTheDocument();
      },
      { timeout: 5000 }
    );
  });
});
