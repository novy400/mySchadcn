import { describe, expect, it } from 'vitest';
import { DataTableRow } from './data-table-row';

describe('<DataTableRow />', () => {
  it('is defined', () => {
    expect(DataTableRow).toBeDefined();
    expect(typeof DataTableRow).toBe('function');
  });
});