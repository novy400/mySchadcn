import { describe, expect, it } from 'vitest';
import { DataTableHead } from './data-table-head';

describe('<DataTableHead />', () => {
  it('is defined', () => {
    expect(DataTableHead).toBeDefined();
    expect(typeof DataTableHead).toBe('function');
  });
});