import { describe, expect, it } from 'vitest';
import { ClientCreate } from './ClientCreate';

describe('<ClientCreate />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ClientCreate).toBeDefined();
    expect(typeof ClientCreate).toBe('function');
  });
});