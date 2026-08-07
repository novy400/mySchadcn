import { describe, expect, it, vi } from 'vitest';
import fakeDataProvider from 'ra-data-fakerest';
import baseData from '@/data/raw/baseData';
import { buildSummaries } from '@/data/projections/buildSummaries';
import dataProvider, {
  createProjectionAwareDataProvider,
  createMigratingDataProvider,
  removeEmptyFilters,
} from './dataProvider';
import { UnsupportedResourceOperationError } from './compositeDataProvider';
import type { IwsDataProvider } from './iwsDataProvider';

const createFreshProvider = () =>
  createProjectionAwareDataProvider(
    fakeDataProvider(buildSummaries(structuredClone(baseData))),
  );

describe('dataProvider filter normalization', () => {
  it('routes only services to IBM i and keeps an unmigrated resource on FakeRest', async () => {
    const iwsGetList = vi.fn(async () => ({
      data: [{ id: 'A00', nom: 'Service IBM i' }],
      total: 1,
    }));
    const iwsProvider = {
      getList: iwsGetList,
      supportAbortSignal: true,
    } as unknown as IwsDataProvider;
    const provider = createMigratingDataProvider(
      createFreshProvider(),
      iwsProvider,
    );

    await expect(
      provider.getList('services', {
        pagination: { page: 1, perPage: 25 },
        sort: { field: 'nom', order: 'ASC' },
        filter: {},
      }),
    ).resolves.toEqual({
      data: [{ id: 'A00', nom: 'Service IBM i' }],
      total: 1,
    });
    await expect(
      provider.getList('fournisseurs', {
        pagination: { page: 1, perPage: 25 },
        sort: { field: 'nom', order: 'ASC' },
        filter: {},
      }),
    ).resolves.toMatchObject({ total: 2 });
    expect(iwsGetList).toHaveBeenCalledTimes(1);
  });

  it('rejects service mutations before they reach the IWS adapter', () => {
    const iwsCreate = vi.fn();
    const provider = createMigratingDataProvider(
      createFreshProvider(),
      {
        create: iwsCreate,
        supportAbortSignal: true,
      } as unknown as IwsDataProvider,
    );

    expect(() =>
      provider.create('services', { data: { id: 'A00' } }),
    ).toThrow(UnsupportedResourceOperationError);
    expect(iwsCreate).not.toHaveBeenCalled();
  });

  it('rejects service read operations outside getList and getOne', () => {
    const iwsGetMany = vi.fn();
    const provider = createMigratingDataProvider(
      createFreshProvider(),
      {
        getMany: iwsGetMany,
        supportAbortSignal: true,
      } as unknown as IwsDataProvider,
    );

    expect(() => provider.getMany('services', { ids: ['A00'] })).toThrow(
      UnsupportedResourceOperationError,
    );
    expect(iwsGetMany).not.toHaveBeenCalled();
  });

  it('exposes IWS abort support through the composite provider', async () => {
    const iwsGetList = vi.fn(async () => ({ data: [], total: 0 }));
    const provider = createMigratingDataProvider(
      createFreshProvider(),
      {
        getList: iwsGetList,
        supportAbortSignal: true,
      } as unknown as IwsDataProvider,
    );
    const controller = new AbortController();

    await provider.getList('services', {
      filter: {},
      signal: controller.signal,
    });

    expect(provider.supportAbortSignal).toBe(true);
    expect(iwsGetList).toHaveBeenCalledWith(
      'services',
      expect.objectContaining({ signal: controller.signal }),
    );
  });

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

  it('resynchronise tasks_with_client après la modification d’une tâche', async () => {
    const provider = createFreshProvider();
    const previousTask = (await provider.getOne('tasks', { id: 1 })).data;

    await provider.update('tasks', {
      id: 1,
      data: { ...previousTask, contact_id: 3, titre: 'Relancer Martin' },
      previousData: previousTask,
    });

    await expect(provider.getOne('tasks_with_client', { id: 1 })).resolves.toMatchObject({
      data: {
        id: 1,
        titre: 'Relancer Martin',
        contact_name: 'Sophie Martin',
        client_id: 2,
        client_name: 'Martin SARL',
      },
    });
    await expect(provider.getOne('contacts_summary', { id: 1 })).resolves.toMatchObject({
      data: { open_tasks: 0 },
    });
    await expect(provider.getOne('contacts_summary', { id: 3 })).resolves.toMatchObject({
      data: { open_tasks: 2 },
    });
  });

  it('ajoute une tâche créée à tasks_with_client', async () => {
    const provider = createFreshProvider();

    const created = await provider.create('tasks', {
      data: {
        id: 99,
        contact_id: 2,
        titre: 'Préparer le rendez-vous',
        status: 'OPEN',
        due_date: '2026-08-15',
      },
    });

    await expect(
      provider.getOne('tasks_with_client', { id: created.data.id }),
    ).resolves.toMatchObject({
      data: {
        id: 99,
        contact_name: 'Claire Bernard',
        client_id: 1,
        client_name: 'Dupont SA',
      },
    });
  });

  it('resynchronise les projections après une modification en masse', async () => {
    const provider = createFreshProvider();

    await provider.updateMany('tasks', {
      ids: [1],
      data: { status: 'DONE' },
    });

    await expect(provider.getOne('tasks_with_client', { id: 1 })).resolves.toMatchObject({
      data: { status: 'DONE' },
    });
    await expect(provider.getOne('contacts_summary', { id: 1 })).resolves.toMatchObject({
      data: { open_tasks: 0 },
    });
  });

  it('recalcule les libellés enrichis après la modification d’un client', async () => {
    const provider = createFreshProvider();
    const previousClient = (await provider.getOne('clients', { id: 1 })).data;

    await provider.update('clients', {
      id: 1,
      data: { ...previousClient, nom: 'Dupont Groupe' },
      previousData: previousClient,
    });

    await expect(provider.getOne('tasks_with_client', { id: 1 })).resolves.toMatchObject({
      data: { client_name: 'Dupont Groupe' },
    });
    await expect(provider.getOne('contacts_summary', { id: 1 })).resolves.toMatchObject({
      data: { client_name: 'Dupont Groupe' },
    });
  });

  it('recalcule la dernière note après la création d’une note', async () => {
    const provider = createFreshProvider();

    await provider.create('notes', {
      data: {
        id: 99,
        contact_id: 1,
        contenu: 'Rendez-vous confirmé.',
        date: '2026-08-20',
      },
    });

    await expect(provider.getOne('contacts_summary', { id: 1 })).resolves.toMatchObject({
      data: { last_note_date: '2026-08-20' },
    });
  });

  it('recalcule les deux projections après un changement de rattachement contact-client', async () => {
    const provider = createFreshProvider();
    const previousContact = (await provider.getOne('contacts', { id: 1 })).data;

    await provider.update('contacts', {
      id: 1,
      data: { ...previousContact, client_id: 2 },
      previousData: previousContact,
    });

    await expect(provider.getOne('tasks_with_client', { id: 1 })).resolves.toMatchObject({
      data: { client_id: 2, client_name: 'Martin SARL' },
    });
    await expect(provider.getOne('contacts_summary', { id: 1 })).resolves.toMatchObject({
      data: { client_id: 2, client_name: 'Martin SARL', client_city: 'Lyon' },
    });
  });

  it('sérialise deux recalculs concurrents pour conserver la projection la plus récente', async () => {
    const baseProvider = fakeDataProvider(buildSummaries(structuredClone(baseData)));
    let releaseFirstTaskRead!: () => void;
    let markFirstTaskReadStarted!: () => void;
    const firstTaskReadStarted = new Promise<void>((resolve) => {
      markFirstTaskReadStarted = resolve;
    });
    const firstTaskReadRelease = new Promise<void>((resolve) => {
      releaseFirstTaskRead = resolve;
    });
    let taskReads = 0;
    const delayedProvider = {
      ...baseProvider,
      getList: async (...args: Parameters<typeof baseProvider.getList>) => {
        const result = await baseProvider.getList(...args);
        if (args[0] === 'tasks' && taskReads++ === 0) {
          markFirstTaskReadStarted();
          await firstTaskReadRelease;
        }
        return result;
      },
    };
    const provider = createProjectionAwareDataProvider(delayedProvider);
    const previousTask = (await provider.getOne('tasks', { id: 1 })).data;

    const firstUpdate = provider.update('tasks', {
      id: 1,
      data: { ...previousTask, titre: 'Première version' },
      previousData: previousTask,
    });
    await firstTaskReadStarted;
    const secondUpdate = provider.update('tasks', {
      id: 1,
      data: { ...previousTask, titre: 'Version finale' },
      previousData: previousTask,
    });
    releaseFirstTaskRead();
    await Promise.all([firstUpdate, secondUpdate]);

    await expect(provider.getOne('tasks_with_client', { id: 1 })).resolves.toMatchObject({
      data: { titre: 'Version finale' },
    });
  });

  it('refuse toute écriture directe dans une projection', () => {
    expect(() =>
      dataProvider.create('contacts_summary', {
        data: { id: 99 },
      }),
    ).toThrow(UnsupportedResourceOperationError);
  });
});
