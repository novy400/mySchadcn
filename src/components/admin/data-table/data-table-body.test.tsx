import { describe, expect, it } from 'vitest';
import { DataTableBody } from './data-table-body';

describe('<DataTableBody />', () => {
  it('is defined', () => {
    expect(DataTableBody).toBeDefined();
    expect(typeof DataTableBody).toBe('function');
  });
});