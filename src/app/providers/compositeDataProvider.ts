import { combineDataProviders, type DataProvider } from 'ra-core';
import {
  isResourceName,
  resourceContracts,
  type ResourceCapability,
  type ResourceName,
} from './resourceContracts';

type CompositeDataProviderOptions = {
  restProvider: DataProvider;
  fallbackProvider: DataProvider;
  restResources: readonly ResourceName[];
};

export class UnknownResourceError extends Error {
  constructor(resource: string) {
    super(`Ressource absente du contrat DataProvider : ${resource}`);
    this.name = 'UnknownResourceError';
  }
}

export class UnsupportedResourceOperationError extends Error {
  constructor(resource: ResourceName, capability: ResourceCapability) {
    super(`Capacité ${capability} absente du contrat de la ressource ${resource}`);
    this.name = 'UnsupportedResourceOperationError';
  }
}

const operationCapabilities: Readonly<Record<string, ResourceCapability>> = {
  getList: 'read',
  getOne: 'read',
  getMany: 'read',
  getManyReference: 'read',
  create: 'create',
  update: 'update',
  updateMany: 'update',
  delete: 'delete',
  deleteMany: 'delete',
};

export const createCompositeDataProvider = ({
  restProvider,
  fallbackProvider,
  restResources,
}: CompositeDataProviderOptions): DataProvider => {
  for (const resource of restResources) {
    if (!isResourceName(resource)) {
      throw new UnknownResourceError(resource);
    }
  }

  const migratedResources = new Set<string>(restResources);
  const combinedProvider = combineDataProviders((resource) => {
    if (!isResourceName(resource)) {
      throw new UnknownResourceError(resource);
    }

    return migratedResources.has(resource) ? restProvider : fallbackProvider;
  });

  return new Proxy(combinedProvider, {
    get: (target, property, receiver) => {
      if (property === 'supportAbortSignal') {
        return Boolean(restProvider.supportAbortSignal && fallbackProvider.supportAbortSignal);
      }

      const providerMethod = Reflect.get(target, property, receiver);
      const capability = typeof property === 'string' ? operationCapabilities[property] : undefined;

      if (!capability || typeof providerMethod !== 'function') {
        return providerMethod;
      }

      return (resource: string, ...params: unknown[]) => {
        if (!isResourceName(resource)) {
          throw new UnknownResourceError(resource);
        }

        const capabilities = resourceContracts[resource].capabilities as readonly ResourceCapability[];
        if (!capabilities.includes(capability)) {
          throw new UnsupportedResourceOperationError(resource, capability);
        }

        return providerMethod(resource, ...params);
      };
    },
  });
};
