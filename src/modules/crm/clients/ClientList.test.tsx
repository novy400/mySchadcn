import { describe, expect, it } from 'vitest';
import { ClientList } from './ClientList';

describe('<ClientList />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ClientList).toBeDefined();
    expect(typeof ClientList).toBe('function');
  });
});