import { describe, expect, it } from 'vitest';

import { canRoleAccess, crmRoles } from '@/app/auth/accessPolicy';

import { ServiceList } from './ServiceList';
import { ServiceShow } from './ServiceShow';
import { services } from './service.resource';

describe('services resource', () => {
  it('déclare uniquement les écrans LIST et SHOW du référentiel IBM i', () => {
    expect(services.name).toBe('services');
    expect(services.list).toBe(ServiceList);
    expect(services.show).toBe(ServiceShow);
    expect(services.options).toEqual({ label: 'Services IBM i' });
    expect(services.recordRepresentation).toBe('nom');
    expect(services.create).toBeUndefined();
    expect(services.edit).toBeUndefined();
  });

  it('reste consultable et non modifiable pour les trois rôles', () => {
    for (const role of crmRoles) {
      expect(canRoleAccess(role, { resource: 'services', action: 'list' })).toBe(true);
      expect(canRoleAccess(role, { resource: 'services', action: 'show' })).toBe(true);
      expect(canRoleAccess(role, { resource: 'services', action: 'create' })).toBe(false);
      expect(canRoleAccess(role, { resource: 'services', action: 'edit' })).toBe(false);
      expect(canRoleAccess(role, { resource: 'services', action: 'delete' })).toBe(false);
    }
  });
});
