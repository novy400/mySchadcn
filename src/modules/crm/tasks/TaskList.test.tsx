import { describe, expect, it } from 'vitest';
import { TaskList } from './TaskList';

describe('<TaskList />', () => {
  it('is defined', async () => {
    // Test très basique pour vérifier que le composant est défini
    expect(TaskList).toBeDefined();
    expect(typeof TaskList).toBe('function');
  });
});