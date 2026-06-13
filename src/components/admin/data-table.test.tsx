import { describe, expect, it } from 'vitest';
import { DataTable } from './data-table';

describe('<DataTable />', () => {
  it('is defined', () => {
    expect(DataTable).toBeDefined();
    expect(typeof DataTable).toBe('function');
  });
});