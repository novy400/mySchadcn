import { describe, expect, it } from 'vitest';
import { DataTableHeadCell, DataTableCell } from './data-table-cell';

describe('<DataTableHeadCell />', () => {
  it('is defined', () => {
    expect(DataTableHeadCell).toBeDefined();
    expect(typeof DataTableHeadCell).toBe('function');
  });
});

describe('<DataTableCell />', () => {
  it('is defined', () => {
    expect(DataTableCell).toBeDefined();
    expect(typeof DataTableCell).toBe('function');
  });
});