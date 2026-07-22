import { describe, expect, it } from 'vitest';
import { resourceContracts } from './resourceContracts';

describe('IBM i resource contracts', () => {
  it('describes every resource consumed by the administration screens', () => {
    expect(Object.keys(resourceContracts)).toEqual([
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
    ]);
  });

  it('keeps projections read-only and identifies their source resource', () => {
    expect(resourceContracts.tasks_with_client).toMatchObject({
      kind: 'projection',
      sourceResource: 'tasks',
      capabilities: ['read'],
    });
    expect(resourceContracts.contacts_summary).toMatchObject({
      kind: 'projection',
      sourceResource: 'contacts',
      capabilities: ['read'],
    });
  });

  it("expose le cycle de vie d'une commande comme actions métier plutôt que suppression", () => {
    expect(resourceContracts.orders).toMatchObject({
      kind: 'entity',
      capabilities: ['read', 'update'],
      actions: ['deliver', 'cancel', 'return'],
    });
  });

  it('documents fields, list filters and relations expected by the screens', () => {
    expect(resourceContracts.contacts).toMatchObject({
      fields: ['id', 'client_id', 'prenom', 'nom', 'email', 'telephone'],
      list: { filters: ['q', 'client_id', 'email'], sortFields: ['nom'] },
      relations: { client_id: 'clients' },
    });
    expect(resourceContracts.tasks_with_client).toMatchObject({
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
      list: {
        filters: ['q', 'contact_id', 'client_id', 'status'],
        sortFields: ['due_date'],
      },
    });
    expect(resourceContracts.orders.relations).toEqual({ customer_id: 'customers' });
  });
});
