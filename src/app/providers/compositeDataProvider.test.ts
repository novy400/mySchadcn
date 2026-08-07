import type { DataProvider } from 'ra-core';
import { describe, expect, it } from 'vitest';
import {
  createCompositeDataProvider,
  UnsupportedResourceOperationError,
  UnknownResourceError,
} from './compositeDataProvider';

const createSourceProvider = (source: 'rest' | 'fake') =>
  ({
    getList: async () => ({ data: [{ id: source }], total: 1 }),
    getOne: async (_resource: string, params: { id: number }) => ({ data: { id: params.id, source } }),
    getMany: async () => ({ data: [{ id: source }] }),
    getManyReference: async () => ({ data: [{ id: source }], total: 1 }),
    create: async () => ({ data: { id: source } }),
    update: async (_resource: string, params: { id: number }) => ({
      data: { id: params.id, source },
    }),
    updateMany: async () => ({ data: [source] }),
    delete: async (_resource: string, params: { id: number }) => ({ data: { id: params.id, source } }),
    deleteMany: async () => ({ data: [source] }),
  }) as DataProvider;

describe('composite DataProvider', () => {
  it('routes migrated resources to REST and keeps the others on FakeRest', async () => {
    const provider = createCompositeDataProvider({
      restProvider: createSourceProvider('rest'),
      fallbackProvider: createSourceProvider('fake'),
      restResources: ['clients'],
    });

    await expect(provider.getList('clients', { filter: {} })).resolves.toEqual({
      data: [{ id: 'rest' }],
      total: 1,
    });
    await expect(provider.getList('contacts', { filter: {} })).resolves.toEqual({
      data: [{ id: 'fake' }],
      total: 1,
    });
    await expect(
      provider.update('clients', { id: 7, data: {}, previousData: { id: 7 } }),
    ).resolves.toEqual({ data: { id: 7, source: 'rest' } });
  });

  it('rejects an unknown resource in the migration configuration', () => {
    expect(() =>
      createCompositeDataProvider({
        restProvider: createSourceProvider('rest'),
        fallbackProvider: createSourceProvider('fake'),
        restResources: ['clientz' as 'clients'],
      }),
    ).toThrow(UnknownResourceError);
  });

  it('uses the same routing decision for every allowed standard DataProvider operation', async () => {
    const provider = createCompositeDataProvider({
      restProvider: createSourceProvider('rest'),
      fallbackProvider: createSourceProvider('fake'),
      restResources: ['clients'],
    });

    const results = await Promise.all([
      provider.getList('clients', { filter: {} }),
      provider.getOne('clients', { id: 1 }),
      provider.getMany('clients', { ids: [1] }),
      provider.getManyReference('clients', {
        target: 'parent_id',
        id: 1,
        pagination: { page: 1, perPage: 10 },
        sort: { field: 'id', order: 'ASC' },
        filter: {},
      }),
      provider.create('clients', { data: {} }),
      provider.update('clients', { id: 1, data: {}, previousData: { id: 1 } }),
      provider.updateMany('clients', { ids: [1], data: {} }),
    ]);

    expect(results.map((result) => result.data)).toEqual([
      [{ id: 'rest' }],
      { id: 1, source: 'rest' },
      [{ id: 'rest' }],
      [{ id: 'rest' }],
      { id: 'rest' },
      { id: 1, source: 'rest' },
      ['rest'],
    ]);
  });

  it('rejects calls to resources outside the documented contract', () => {
    const provider = createCompositeDataProvider({
      restProvider: createSourceProvider('rest'),
      fallbackProvider: createSourceProvider('fake'),
      restResources: [],
    });

    expect(() => provider.getList('unknown', { filter: {} })).toThrow(UnknownResourceError);
  });

  it('enforces the capabilities declared by the resource contract', () => {
    const provider = createCompositeDataProvider({
      restProvider: createSourceProvider('rest'),
      fallbackProvider: createSourceProvider('fake'),
      restResources: [],
    });

    expect(() => provider.create('contacts_summary', { data: {} })).toThrow(
      UnsupportedResourceOperationError,
    );
    expect(() =>
      provider.update('customers', { id: 1, data: {}, previousData: { id: 1 } }),
    ).toThrow(UnsupportedResourceOperationError);
    expect(() => provider.delete('clients', { id: 1 })).toThrow(
      UnsupportedResourceOperationError,
    );
    expect(() => provider.deleteMany('clients', { ids: [1] })).toThrow(
      UnsupportedResourceOperationError,
    );
  });

  it('advertises abort support only when both providers support it by default', () => {
    const restProvider = createSourceProvider('rest');
    const fallbackProvider = createSourceProvider('fake');
    restProvider.supportAbortSignal = true;

    const partiallyAbortableProvider = createCompositeDataProvider({
      restProvider,
      fallbackProvider,
      restResources: ['clients'],
    });
    expect(partiallyAbortableProvider.supportAbortSignal).toBe(false);

    fallbackProvider.supportAbortSignal = true;
    const fullyAbortableProvider = createCompositeDataProvider({
      restProvider,
      fallbackProvider,
      restResources: ['clients'],
    });
    expect(fullyAbortableProvider.supportAbortSignal).toBe(true);
  });
});
