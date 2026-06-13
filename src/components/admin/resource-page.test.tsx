import { describe, expect, it } from 'vitest';
import { ResourcePage } from './resource-page';

describe('<ResourcePage />', () => {
  it('is defined', () => {
    expect(ResourcePage).toBeDefined();
    expect(typeof ResourcePage).toBe('function');
  });
});