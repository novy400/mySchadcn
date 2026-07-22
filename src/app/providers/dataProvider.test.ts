import { describe, expect, it } from 'vitest';
import dataProvider, { removeEmptyFilters } from './dataProvider';

describe('dataProvider filter normalization', () => {
  it('removes empty UI filters while preserving meaningful falsey values', () => {
    expect(
      removeEmptyFilters({
        q: '',
        padded: '   ',
        ids: [],
        optional: undefined,
        returned: false,
        score: 0,
        nullable: null,
        status: 'ordered',
      })
    ).toEqual({
      returned: false,
      score: 0,
      nullable: null,
      status: 'ordered',
    });
  });

  it('does not hide records when the permanent search filter is empty', async () => {
    const result = await dataProvider.getList('fournisseurs', {
      pagination: { page: 1, perPage: 25 },
      sort: { field: 'nom', order: 'ASC' },
      filter: { q: '' },
    });

    expect(result.total).toBe(2);
    expect(result.data.map(record => record.nom)).toEqual([
      'Fournitures Pro',
      'Logis Transport',
    ]);
  });
});
