import { describe, expect, it } from 'vitest';
import { canRoleAccess } from './accessPolicy';

describe('politique d’accès CRM', () => {
  it('limite le Lecteur à la consultation', () => {
    expect(canRoleAccess('lecteur', { resource: 'clients', action: 'list' })).toBe(true);
    expect(canRoleAccess('lecteur', { resource: 'clients', action: 'show' })).toBe(true);
    expect(canRoleAccess('lecteur', { resource: 'clients', action: 'create' })).toBe(false);
    expect(canRoleAccess('lecteur', { resource: 'orders', action: 'deliver' })).toBe(false);
  });

  it("autorise l’Agent à gérer le CRM sans piloter les commandes", () => {
    expect(canRoleAccess('agent', { resource: 'contacts', action: 'create' })).toBe(true);
    expect(canRoleAccess('agent', { resource: 'notes', action: 'edit' })).toBe(true);
    expect(canRoleAccess('agent', { resource: 'tasks_with_client', action: 'create' })).toBe(true);
    expect(canRoleAccess('agent', { resource: 'tasks_with_client', action: 'edit' })).toBe(true);
    expect(canRoleAccess('agent', { resource: 'orders', action: 'edit' })).toBe(false);
    expect(canRoleAccess('agent', { resource: 'orders', action: 'cancel' })).toBe(false);
  });

  it('réserve la gestion des commandes au Responsable', () => {
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'edit' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'deliver' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'cancel' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'return' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'create' })).toBe(false);
    expect(canRoleAccess('responsable', { resource: 'orders', action: 'delete' })).toBe(false);
  });

  it('conserve les projections sans ressource de mutation en lecture seule', () => {
    expect(canRoleAccess('responsable', { resource: 'contacts_summary', action: 'list' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'contacts_summary', action: 'edit' })).toBe(false);
    expect(canRoleAccess('responsable', { resource: 'tasks_with_client', action: 'create' })).toBe(true);
  });

  it('refuse une ressource ou une action inconnue', () => {
    expect(canRoleAccess('responsable', { resource: 'invoices', action: 'list' })).toBe(false);
    expect(canRoleAccess('responsable', { resource: 'clients', action: 'archive' })).toBe(false);
  });

  it('refuse la suppression à tous les rôles car le contrat ne l’expose pas', () => {
    expect(canRoleAccess('lecteur', { resource: 'clients', action: 'delete' })).toBe(false);
    expect(canRoleAccess('agent', { resource: 'clients', action: 'delete' })).toBe(false);
    expect(canRoleAccess('responsable', { resource: 'clients', action: 'delete' })).toBe(false);
  });

  it('autorise les lectures fournisseurs à tous et réserve CREATE/EDIT aux rôles mutables', () => {
    expect(canRoleAccess('lecteur', { resource: 'fournisseurs', action: 'list' })).toBe(true);
    expect(canRoleAccess('lecteur', { resource: 'fournisseurs', action: 'create' })).toBe(false);
    expect(canRoleAccess('lecteur', { resource: 'fournisseurs', action: 'edit' })).toBe(false);
    expect(canRoleAccess('agent', { resource: 'fournisseurs', action: 'create' })).toBe(true);
    expect(canRoleAccess('agent', { resource: 'fournisseurs', action: 'edit' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'fournisseurs', action: 'create' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'fournisseurs', action: 'edit' })).toBe(true);
    expect(canRoleAccess('responsable', { resource: 'fournisseurs', action: 'delete' })).toBe(false);
  });
});
