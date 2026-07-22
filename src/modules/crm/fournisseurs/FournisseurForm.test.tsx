import { describe, expect, it } from 'vitest';
import { FournisseurCreate } from './FournisseurCreate';
import { FournisseurEdit } from './FournisseurEdit';
import { fournisseurs } from './fournisseur.resource';

describe('fournisseurs resource', () => {
  it('registers its list, create and edit screens', () => {
    expect(fournisseurs.name).toBe('fournisseurs');
    expect(fournisseurs.list).toBeDefined();
    expect(fournisseurs.create).toBe(FournisseurCreate);
    expect(fournisseurs.edit).toBe(FournisseurEdit);
    expect(fournisseurs.recordRepresentation).toBe('nom');
  });
});
