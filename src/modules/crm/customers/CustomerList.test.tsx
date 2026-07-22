import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import TestProvider from '@/test/TestProvider';
import { CustomerList } from './CustomerList';

describe('<CustomerList />', () => {
  it('renders customers and its search filter', async () => {
    render(
      <TestProvider resource="customers">
        <CustomerList />
      </TestProvider>
    );

    expect(screen.getByPlaceholderText('Rechercher un client')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Aviation Corp')).toBeInTheDocument();
      expect(screen.getByText('Global Logistics')).toBeInTheDocument();
    });
  });
});
