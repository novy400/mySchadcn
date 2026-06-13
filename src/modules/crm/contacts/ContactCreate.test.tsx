import { describe, expect, it } from 'vitest';
import { ContactCreate } from './ContactCreate';

describe('<ContactCreate />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ContactCreate).toBeDefined();
    expect(typeof ContactCreate).toBe('function');
  });
});