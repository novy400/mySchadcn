import { describe, expect, it } from 'vitest';
import { NoteEdit } from './NoteEdit';

describe('<NoteEdit />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(NoteEdit).toBeDefined();
    expect(typeof NoteEdit).toBe('function');
  });
});