import { describe, expect, it } from 'vitest';
import { TaskEdit } from './TaskEdit';

describe('<TaskEdit />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(TaskEdit).toBeDefined();
    expect(typeof TaskEdit).toBe('function');
  });
});