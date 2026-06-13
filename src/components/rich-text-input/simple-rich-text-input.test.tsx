import { describe, expect, it } from 'vitest';
import { SimpleRichTextInput } from './simple-rich-text-input';

describe('<SimpleRichTextInput />', () => {
  it('is defined', () => {
    expect(SimpleRichTextInput).toBeDefined();
    expect(typeof SimpleRichTextInput).toBe('function');
  });
});