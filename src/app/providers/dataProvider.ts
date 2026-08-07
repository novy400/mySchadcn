import fakeDataProvider from 'ra-data-fakerest';
import type { DataProvider, RaRecord } from 'ra-core';
import fakerestData from '../../data/fakerestData';
import {
  buildContactSummaries,
  buildTasksWithClient,
} from '@/data/projections/buildSummaries';
import type { Task } from '@/modules/crm/tasks/task.types';
import type { Contact } from '@/modules/crm/contacts/contact.types';
import type { Client } from '@/modules/crm/clients/client.types';
import type { Note } from '@/modules/crm/notes/note.types';
import type { ProjectionSourceData } from '@/data/projections/buildSummaries';
import type { ResourceName } from './resourceContracts';
import { createCompositeDataProvider } from './compositeDataProvider';
import {
  createIwsDataProvider,
  type IwsDataProvider,
} from './iwsDataProvider';
import { removeEmptyFilters } from './filterUtils';

export { removeEmptyFilters } from './filterUtils';

const baseDataProvider = fakeDataProvider(fakerestData);

const projectionSourceResources = {
  clients: true,
  contacts: true,
  tasks: true,
  notes: true,
} as const satisfies Record<keyof ProjectionSourceData, true>;

const isProjectionSourceResource = (
  resource: string,
): resource is keyof ProjectionSourceData => Object.hasOwn(projectionSourceResources, resource);

const FAKEREST_FULL_COLLECTION_LIMIT = 10_000;

const getAll = async <RecordType extends RaRecord>(
  provider: DataProvider,
  resource: string,
): Promise<RecordType[]> => {
  const result = await provider.getList<RecordType>(resource, {
    pagination: { page: 1, perPage: FAKEREST_FULL_COLLECTION_LIMIT },
    sort: { field: 'id', order: 'ASC' },
    filter: {},
  });
  return result.data;
};

const synchronizeCollection = async (
  provider: DataProvider,
  resource: string,
  nextRecords: RaRecord[],
) => {
  const currentRecords = await getAll(provider, resource);
  const currentById = new Map(currentRecords.map((record) => [record.id, record]));
  const nextIds = new Set(nextRecords.map((record) => record.id));

  await Promise.all(
    nextRecords.map((record) =>
      currentById.has(record.id)
        ? provider.update(resource, {
            id: record.id,
            data: record,
            previousData: currentById.get(record.id)!,
          })
        : provider.create(resource, { data: record }),
    ),
  );
  await Promise.all(
    currentRecords
      .filter((record) => !nextIds.has(record.id))
      .map((record) =>
        provider.delete(resource, { id: record.id, previousData: record }),
      ),
  );
};

const synchronizeProjections = async (provider: DataProvider) => {
  const [clients, contacts, tasks, notes] = await Promise.all([
    getAll<Client>(provider, 'clients'),
    getAll<Contact>(provider, 'contacts'),
    getAll<Task>(provider, 'tasks'),
    getAll<Note>(provider, 'notes'),
  ]);
  const sourceData = { clients, contacts, tasks, notes };

  const projectionPolicy = [
    { resource: 'contacts_summary', records: buildContactSummaries(sourceData) },
    { resource: 'tasks_with_client', records: buildTasksWithClient(sourceData) },
  ] as const satisfies readonly {
    resource: ResourceName;
    records: readonly RaRecord[];
  }[];

  await Promise.all(
    projectionPolicy.map(({ resource, records }) =>
      synchronizeCollection(provider, resource, [...records]),
    ),
  );
};

export const createProjectionAwareDataProvider = (
  provider: DataProvider,
): DataProvider => {
  let synchronizationQueue = Promise.resolve();

  const runMutation = async <Result>(
    resource: string,
    mutation: Promise<Result>,
  ): Promise<Result> => {
    const result = await mutation;
    if (!isProjectionSourceResource(resource)) {
      return result;
    }

    const queuedSynchronization = synchronizationQueue.then(() =>
      synchronizeProjections(provider),
    );
    synchronizationQueue = queuedSynchronization.catch(() => undefined);
    await queuedSynchronization;
    return result;
  };

  return {
    ...provider,
    create: (resource, params) =>
      runMutation(resource, provider.create(resource, params)),
    update: (resource, params) =>
      runMutation(resource, provider.update(resource, params)),
    updateMany: (resource, params) =>
      runMutation(resource, provider.updateMany(resource, params)),
  };
};

export const createMigratingDataProvider = (
  fallbackProvider: DataProvider,
  iwsProvider: IwsDataProvider,
): DataProvider =>
  createCompositeDataProvider({
    restProvider: iwsProvider,
    fallbackProvider,
    restResources: ['services', 'fournisseurs'],
    supportAbortSignal: iwsProvider.supportAbortSignal,
  });

const projectionAwareDataProvider = createProjectionAwareDataProvider({
  ...baseDataProvider,
  getList: (resource, params) =>
    baseDataProvider.getList(resource, {
      ...params,
      filter: removeEmptyFilters(params.filter),
    }),
  getManyReference: (resource, params) =>
    baseDataProvider.getManyReference(resource, {
      ...params,
      filter: removeEmptyFilters(params.filter),
    }),
});

const iwsDataProvider = createIwsDataProvider({
  apiUrls: {
    services:
      import.meta.env.VITE_IBM_I_API_URL || '/web/services/SERVIWS3',
    fournisseurs:
      import.meta.env.VITE_IBM_I_FOURNISSEURS_API_URL ||
      '/web/services/FOURIWS1',
  },
});

export const dataProvider: DataProvider = createMigratingDataProvider(
  projectionAwareDataProvider,
  iwsDataProvider,
);

export default dataProvider;
