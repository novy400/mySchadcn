import {
  isResourceName,
  resourceContracts,
  type ResourceCapability,
  type ResourceName,
} from '@/app/providers/resourceContracts';

export const crmRoles = ['lecteur', 'agent', 'responsable'] as const;
export type CrmRole = (typeof crmRoles)[number];

export type AccessRequest = {
  resource: string;
  action: string;
};

const capabilityByAction = {
  list: 'read',
  show: 'read',
  create: 'create',
  edit: 'update',
  delete: 'delete',
} as const satisfies Readonly<Record<string, ResourceCapability>>;

type StandardAccessAction = keyof typeof capabilityByAction;

const isStandardAccessAction = (action: string): action is StandardAccessAction =>
  Object.hasOwn(capabilityByAction, action);

const agentMutableResources = [
  'clients',
  'contacts',
  'tasks',
  'tasks_with_client',
  'notes',
  'fournisseurs',
] as const satisfies readonly ResourceName[];

const mutableResourcesByRole = {
  lecteur: [],
  agent: agentMutableResources,
  responsable: [...agentMutableResources, 'orders'],
} as const satisfies Readonly<Record<CrmRole, readonly ResourceName[]>>;

const isDeclaredBusinessAction = (
  resource: ResourceName,
  action: string,
): boolean => {
  const contract = resourceContracts[resource];
  return 'actions' in contract && (contract.actions as readonly string[]).includes(action);
};

const resolveContractResource = (
  resource: ResourceName,
  capability: ResourceCapability,
): ResourceName => {
  const contract = resourceContracts[resource];

  if (capability !== 'read' && 'mutationResource' in contract) {
    return contract.mutationResource;
  }

  return resource;
};

export const canRoleAccess = (role: CrmRole, request: AccessRequest): boolean => {
  if (!isResourceName(request.resource)) {
    return false;
  }

  if (isDeclaredBusinessAction(request.resource, request.action)) {
    return role === 'responsable';
  }

  if (!isStandardAccessAction(request.action)) {
    return false;
  }
  const capability = capabilityByAction[request.action];

  const contractResource = resolveContractResource(request.resource, capability);
  const capabilities = resourceContracts[contractResource].capabilities as readonly ResourceCapability[];
  if (!capabilities.includes(capability)) {
    return false;
  }

  if (capability === 'read') {
    return true;
  }

  return (mutableResourcesByRole[role] as readonly ResourceName[]).includes(request.resource);
};
