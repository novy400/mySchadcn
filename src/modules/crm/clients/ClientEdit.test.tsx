import { describe, expect, it } from 'vitest';
import { ClientEdit } from './ClientEdit';

describe('<ClientEdit />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(ClientEdit).toBeDefined();
    expect(typeof ClientEdit).toBe('function');
  });
});