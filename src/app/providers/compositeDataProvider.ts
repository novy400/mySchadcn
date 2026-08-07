import { combineDataProviders, type DataProvider } from 'ra-core';
import {
  isResourceName,
  resourceContracts,
  type ResourceCapability,
  type ResourceName,
  type ResourceOperation,
} from './resourceContracts';

type CompositeDataProviderOptions = {
  restProvider: Partial<DataProvider>;
  fallbackProvider: DataProvider;
  restResources: readonly ResourceName[];
  supportAbortSignal?: boolean;
};

export class UnknownResourceError extends Error {
  constructor(resource: string) {
    super(`Ressource absente du contrat DataProvider : ${resource}`);
    this.name = 'UnknownResourceError';
  }
}

export class UnsupportedResourceOperationError extends Error {
  constructor(
    resource: ResourceName,
    operation: ResourceCapability | ResourceOperation,
  ) {
    super(`Opération ${operation} absente du contrat de la ressource ${resource}`);
    this.name = 'UnsupportedResourceOperationError';
  }
}

const operationCapabilities: Readonly<Record<ResourceOperation, ResourceCapability>> = {
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

const isResourceOperation = (property: string): property is ResourceOperation =>
  Object.hasOwn(operationCapabilities, property);

export const enforceResourceContracts = (provider: DataProvider): DataProvider =>
  new Proxy(provider, {
    get: (target, property, receiver) => {
      const providerMethod = Reflect.get(target, property, receiver);
      const operation =
        typeof property === 'string' && isResourceOperation(property)
          ? property
          : undefined;
      const capability = operation ? operationCapabilities[operation] : undefined;

      if (!capability || typeof providerMethod !== 'function') {
        return providerMethod;
      }

      return (resource: string, ...params: unknown[]) => {
        if (!isResourceName(resource)) {
          throw new UnknownResourceError(resource);
        }

        const contract = resourceContracts[resource];
        const operations =
          'operations' in contract
            ? (contract.operations as readonly ResourceOperation[])
            : undefined;
        if (
          operations &&
          !operations.includes(operation!)
        ) {
          throw new UnsupportedResourceOperationError(
            resource,
            operation!,
          );
        }

        const capabilities = contract.capabilities as readonly ResourceCapability[];
        if (!capabilities.includes(capability)) {
          throw new UnsupportedResourceOperationError(resource, capability);
        }

        return providerMethod(resource, ...params);
      };
    },
  });

export const createCompositeDataProvider = ({
  restProvider,
  fallbackProvider,
  restResources,
  supportAbortSignal,
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

    return (migratedResources.has(resource)
      ? restProvider
      : fallbackProvider) as DataProvider;
  });

  const advertisesAbortSignal =
    supportAbortSignal ??
    Boolean(restProvider.supportAbortSignal && fallbackProvider.supportAbortSignal);
  const contractedProvider = enforceResourceContracts(combinedProvider);

  return new Proxy(contractedProvider, {
    get: (target, property, receiver) =>
      property === 'supportAbortSignal'
        ? advertisesAbortSignal
        : Reflect.get(target, property, receiver),
  });
};
