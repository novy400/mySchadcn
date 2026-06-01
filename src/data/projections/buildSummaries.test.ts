import { describe, expect, it } from 'vitest';

import baseData from '@/data/raw/baseData';
import { buildSummaries } from './buildSummaries';

describe('buildSummaries', () => {
  it('builds contacts_summary with client info and open task count', () => {
    const result = buildSummaries(baseData);

    expect(result.contacts_summary).toHaveLength(baseData.contacts.length);

    expect(result.contacts_summary).toContainEqual(
      expect.objectContaining({
        id: 1,
        prenom: 'Jean',
        nom: 'Dupont',
        client_name: 'Dupont SA',
        open_tasks: 1,
        last_note_date: '2026-03-27',
      }),
    );
  });

  it('keeps original collections and adds contacts_summary', () => {
    const result = buildSummaries(baseData);

    expect(result.clients).toEqual(baseData.clients);
    expect(result.contacts).toEqual(baseData.contacts);
    expect(result.tasks).toEqual(baseData.tasks);
    expect(result.notes).toEqual(baseData.notes);
    expect(result).toHaveProperty('contacts_summary');
  });
});
