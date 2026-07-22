import { describe, expect, it } from 'vitest';
import { DemoAuthenticationError, demoIdentityAdapter } from './demoIdentityAdapter';

describe("adapter d’identité de démonstration", () => {
  it.each([
    ['lecteur@demo.local', 'lecteur'],
    ['agent@demo.local', 'agent'],
    ['responsable@demo.local', 'responsable'],
  ] as const)('authentifie %s avec le rôle %s', async (email, role) => {
    await expect(demoIdentityAdapter.authenticate({ email, password: 'demo' })).resolves.toMatchObject({
      id: email,
      role,
    });
  });

  it('retourne une erreur générique lorsque les identifiants sont invalides', async () => {
    await expect(
      demoIdentityAdapter.authenticate({ email: 'lecteur@demo.local', password: 'incorrect' }),
    ).rejects.toEqual(new DemoAuthenticationError());
    await expect(
      demoIdentityAdapter.authenticate({ email: 'inconnu@demo.local', password: 'demo' }),
    ).rejects.toEqual(new DemoAuthenticationError());
  });
});
