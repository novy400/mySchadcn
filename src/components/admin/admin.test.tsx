import { describe, expect, it } from 'vitest';
import { Admin } from './admin';

describe('<Admin />', () => {
  it('is defined', () => {
    expect(Admin).toBeDefined();
    expect(typeof Admin).toBe('function');
  });
});