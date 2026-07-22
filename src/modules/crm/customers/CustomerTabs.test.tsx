import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { RecordContextProvider } from 'ra-core';
import type { ReactNode } from 'react';
import TestProvider from '@/test/TestProvider';
import { CustomerGeneralTab } from './tabs/CustomerGeneralTab';
import { CustomerRisqueTab } from './tabs/CustomerRisqueTab';
import { CustomerSignalietiqueTab } from './tabs/CustomerSignalietiqueTab';

const customer = { id: 1, name: 'Aviation Corp', type: 'Sarl' };

const renderTab = (tab: ReactNode) =>
  render(
    <TestProvider resource="customers">
      <RecordContextProvider value={customer}>{tab}</RecordContextProvider>
    </TestProvider>
  );

describe('customer tabs', () => {
  it('renders general customer data', () => {
    renderTab(<CustomerGeneralTab />);

    expect(screen.getByText('Aviation Corp')).toBeInTheDocument();
    expect(screen.getByText('Sarl')).toBeInTheDocument();
  });

  it('loads signaletic data from its reference resource', async () => {
    renderTab(<CustomerSignalietiqueTab />);

    await waitFor(() => {
      expect(screen.getByText("123 Rue de l'Air, Paris")).toBeInTheDocument();
      expect(screen.getByText('contact@aviation.fr')).toBeInTheDocument();
    });
  });

  it('loads risk data from its reference resource', async () => {
    renderTab(<CustomerRisqueTab />);

    await waitFor(() => {
      expect(screen.getByText('85')).toBeInTheDocument();
      expect(screen.getByText('OK')).toBeInTheDocument();
    });
  });
});
