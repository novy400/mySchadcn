import { describe, it, expect } from 'vitest';
import { buildSummaries } from './buildSummaries';
import type { BaseData } from './buildSummaries';

describe('buildSummaries', () => {
  const baseData: BaseData = {
    clients: [
      { id: 1, code: 'CLI001', nom: 'Dupont SA', ville: 'Paris', statut: 'ACTIF' },
    ],
    contacts: [
      { id: 1, client_id: 1, prenom: 'Jean', nom: 'Dupont', email: 'jean@dupont.fr', telephone: '0102030405' },
    ],
    tasks: [
      { id: 1, contact_id: 1, titre: 'Rappeler après devis', status: 'OPEN', due_date: '2026-04-03' },
    ],
    notes: [],
    customers: [],
    customerSignalietiques: [],
    customerRisques: [],
    fournisseurs: [],
  };

  it('should enrich tasks with client information', () => {
    const result = buildSummaries(baseData);
    
    expect(result.tasks_with_client).toHaveLength(1);
    expect(result.tasks_with_client[0]).toMatchObject({
      id: 1,
      contact_id: 1,
      titre: 'Rappeler après devis',
      status: 'OPEN',
      due_date: '2026-04-03',
      contact_name: 'Jean Dupont',
      client_id: 1,
      client_name: 'Dupont SA',
    });
  });

  it('should handle tasks with no contact', () => {
    const dataWithOrphanTask: BaseData = {
      ...baseData,
      tasks: [
        { id: 2, contact_id: 999, titre: 'Task sans contact', status: 'OPEN', due_date: '2026-04-03' },
      ]
    };
    
    const result = buildSummaries(dataWithOrphanTask);
    
    expect(result.tasks_with_client).toHaveLength(1);
    expect(result.tasks_with_client[0]).toMatchObject({
      id: 2,
      contact_id: 999,
      titre: 'Task sans contact',
      status: 'OPEN',
      due_date: '2026-04-03',
      contact_name: '',
      client_id: null,
      client_name: '',
    });
  });
});