import { describe, expect, it } from 'vitest';
import { NoteCreate } from './NoteCreate';

describe('<NoteCreate />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(NoteCreate).toBeDefined();
    expect(typeof NoteCreate).toBe('function');
  });
});