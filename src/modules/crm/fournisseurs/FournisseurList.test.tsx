import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import TestProvider from '@/test/TestProvider';
import { FournisseurList } from './FournisseurList';

describe('<FournisseurList />', () => {
  it('renders supplier data and filters', async () => {
    render(
      <TestProvider resource="fournisseurs">
        <FournisseurList />
      </TestProvider>
    );

    expect(screen.getByPlaceholderText('Rechercher un fournisseur')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Fournitures Pro')).toBeInTheDocument();
      expect(screen.getByText('Logis Transport')).toBeInTheDocument();
    });
  });
});
