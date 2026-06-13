import { describe, expect, it } from 'vitest';
import { NoteList } from './NoteList';

describe('<NoteList />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(NoteList).toBeDefined();
    expect(typeof NoteList).toBe('function');
  });
});