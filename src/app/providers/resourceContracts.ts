import type { OrderAction } from '@/modules/crm/orders/order.lifecycle';

export type ResourceCapability = 'read' | 'create' | 'update' | 'delete';
export type ResourceKind = 'entity' | 'projection' | 'detail';

export const resourceNames = [
  'clients',
  'contacts',
  'tasks',
  'tasks_with_client',
  'notes',
  'contacts_summary',
  'fournisseurs',
  'orders',
  'customers',
  'customerSignalietiques',
  'customerRisques',
  'services',
] as const;

export type ResourceName = (typeof resourceNames)[number];

export type ResourceContract = {
  kind: ResourceKind;
  identifier: 'id';
  fields: readonly string[];
  capabilities: readonly ResourceCapability[];
  list?: {
    filters: readonly string[];
    sortFields: readonly string[];
  };
  relations?: Readonly<Record<string, ResourceName>>;
  sourceResource?: ResourceName;
  mutationResource?: ResourceName;
  actions?: readonly OrderAction[];
};

export const resourceContracts = {
  clients: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'code', 'nom', 'ville', 'statut'],
    capabilities: ['read', 'create', 'update'],
    list: { filters: ['q', 'statut', 'ville'], sortFields: ['nom'] },
  },
  contacts: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'client_id', 'prenom', 'nom', 'email', 'telephone'],
    capabilities: ['read', 'create', 'update'],
    list: { filters: ['q', 'client_id', 'email'], sortFields: ['nom'] },
    relations: { client_id: 'clients' },
  },
  tasks: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'contact_id', 'titre', 'status', 'due_date'],
    capabilities: ['read', 'create', 'update'],
    relations: { contact_id: 'contacts' },
  },
  tasks_with_client: {
    kind: 'projection',
    identifier: 'id',
    fields: [
      'id',
      'contact_id',
      'contact_name',
      'client_id',
      'client_name',
      'titre',
      'status',
      'due_date',
    ],
    capabilities: ['read'],
    list: {
      filters: ['q', 'contact_id', 'client_id', 'status'],
      sortFields: ['due_date'],
    },
    relations: { contact_id: 'contacts', client_id: 'clients' },
    sourceResource: 'tasks',
    mutationResource: 'tasks',
  },
  notes: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'contact_id', 'contenu', 'date'],
    capabilities: ['read', 'create', 'update'],
    list: { filters: ['q', 'contact_id', 'date'], sortFields: ['date'] },
    relations: { contact_id: 'contacts' },
  },
  contacts_summary: {
    kind: 'projection',
    identifier: 'id',
    fields: [
      'id',
      'prenom',
      'nom',
      'email',
      'telephone',
      'client_id',
      'client_name',
      'client_city',
      'client_status',
      'open_tasks',
      'last_note_date',
    ],
    capabilities: ['read'],
    list: {
      filters: ['q', 'client_id', 'client_status', 'client_city'],
      sortFields: ['nom'],
    },
    relations: { client_id: 'clients' },
    sourceResource: 'contacts',
  },
  fournisseurs: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'nom', 'adresse', 'ville', 'telephone', 'email'],
    capabilities: ['read', 'create', 'update'],
    list: { filters: ['q', 'ville'], sortFields: ['nom'] },
  },
  orders: {
    kind: 'entity',
    identifier: 'id',
    fields: [
      'id',
      'reference',
      'date',
      'customer_id',
      'basket',
      'total_ex_taxes',
      'delivery_fees',
      'tax_rate',
      'taxes',
      'total',
      'status',
      'returned',
    ],
    capabilities: ['read', 'update'],
    list: { filters: ['q', 'customer_id', 'status'], sortFields: ['date'] },
    relations: { customer_id: 'customers' },
    actions: ['deliver', 'cancel', 'return'],
  },
  customers: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'name', 'type'],
    capabilities: ['read'],
    list: { filters: ['q', 'type'], sortFields: ['name'] },
  },
  customerSignalietiques: {
    kind: 'detail',
    identifier: 'id',
    fields: ['id', 'adresse', 'phone', 'email'],
    capabilities: ['read'],
    sourceResource: 'customers',
  },
  customerRisques: {
    kind: 'detail',
    identifier: 'id',
    fields: ['id', 'score', 'statut', 'lastReview'],
    capabilities: ['read'],
    sourceResource: 'customers',
  },
  services: {
    kind: 'entity',
    identifier: 'id',
    fields: ['id', 'nom', 'idManageur', 'idServiceAdmin', 'site'],
    capabilities: ['read'],
    list: {
      filters: ['q', 'id', 'nom', 'idManageur', 'idServiceAdmin', 'site'],
      sortFields: ['id', 'nom'],
    },
  },
} as const satisfies Record<ResourceName, ResourceContract>;

export const isResourceName = (resource: string): resource is ResourceName =>
  Object.hasOwn(resourceContracts, resource);
