import { describe, expect, it } from 'vitest';
import { ContactList } from './ContactList';

describe('<ContactList />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ContactList).toBeDefined();
    expect(typeof ContactList).toBe('function');
  });
});