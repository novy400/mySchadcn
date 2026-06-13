import { describe, expect, it } from 'vitest';
import { RichTextInput } from './rich-text-input';

describe('<RichTextInput />', () => {
  it('is defined', () => {
    expect(RichTextInput).toBeDefined();
    expect(typeof RichTextInput).toBe('function');
  });

  // Note: Les tests d'intégration nécessitent un environnement plus complexe
  // Nous nous contenterons de tests unitaires basiques pour le moment
});