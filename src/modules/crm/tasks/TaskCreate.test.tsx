import { describe, expect, it } from 'vitest';
import { TaskCreate } from './TaskCreate';

describe('<TaskCreate />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(TaskCreate).toBeDefined();
    expect(typeof TaskCreate).toBe('function');
  });
});