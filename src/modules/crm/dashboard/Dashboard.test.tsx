import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { Dashboard } from './Dashboard';

describe('<Dashboard />', () => {
  it('renders the main CRM indicators', () => {
    render(<Dashboard />);

    expect(screen.getByRole('heading', { name: 'Dashboard CRM' })).toBeInTheDocument();
    expect(screen.getAllByText('2')).toHaveLength(2);
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('Contacts à suivre')).toBeInTheDocument();
    expect(screen.getByText(/Jean/)).toBeInTheDocument();
    expect(screen.getByText(/Sophie/)).toBeInTheDocument();
  });
});
