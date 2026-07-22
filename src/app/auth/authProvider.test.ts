import { afterEach, describe, expect, it } from 'vitest';
import {
  AuthenticationRequiredError,
  createAuthProvider,
  createSessionStorageSessionStore,
  type CrmIdentity,
  type IdentityAdapter,
} from './authProvider';

const sessionKey = 'myschadcn.auth.test';
const responsable: CrmIdentity = {
  id: 'responsable-demo',
  fullName: 'Responsable Démo',
  role: 'responsable',
};

const identityAdapter: IdentityAdapter = {
  authenticate: async () => responsable,
};

const createProvider = () =>
  createAuthProvider({
    identityAdapter,
    sessionStore: createSessionStorageSessionStore(sessionStorage, sessionKey),
  });

afterEach(() => sessionStorage.removeItem(sessionKey));

describe('AuthProvider CRM', () => {
  it('ouvre une session et expose l’identité et le rôle authentifiés', async () => {
    const provider = createProvider();

    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await expect(provider.checkAuth({})).resolves.toBeUndefined();
    await expect(provider.getIdentity?.()).resolves.toEqual(responsable);
    await expect(provider.getPermissions?.({})).resolves.toBe('responsable');
  });

  it('ferme la session et refuse ensuite l’authentification', async () => {
    const provider = createProvider();
    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await provider.logout({});

    await expect(provider.checkAuth({})).rejects.toBeInstanceOf(AuthenticationRequiredError);
  });

  it('applique la politique du rôle authentifié', async () => {
    const provider = createProvider();
    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await expect(provider.canAccess?.({ resource: 'orders', action: 'deliver' })).resolves.toBe(true);
    await expect(provider.canAccess?.({ resource: 'orders', action: 'delete' })).resolves.toBe(false);
  });

  it('expire la session sur 401 sans déconnecter sur 403', async () => {
    const provider = createProvider();
    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await expect(provider.checkError({ status: 403 })).resolves.toBeUndefined();
    await expect(provider.checkAuth({})).resolves.toBeUndefined();

    await expect(provider.checkError({ status: 401 })).rejects.toBeInstanceOf(AuthenticationRequiredError);
    await expect(provider.checkAuth({})).rejects.toBeInstanceOf(AuthenticationRequiredError);
  });

  it('supprime une ancienne identité avant une nouvelle tentative de connexion', async () => {
    let attempt = 0;
    const provider = createAuthProvider({
      identityAdapter: {
        authenticate: async () => {
          attempt += 1;
          if (attempt > 1) {
            throw new Error('Identifiants invalides');
          }
          return responsable;
        },
      },
      sessionStore: createSessionStorageSessionStore(sessionStorage, sessionKey),
    });
    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await expect(provider.login({ email: 'responsable@demo.local', password: 'incorrect' })).rejects.toThrow();

    await expect(provider.checkAuth({})).rejects.toBeInstanceOf(AuthenticationRequiredError);
  });

  it('permet à un adapter REST de restaurer et fermer la session serveur', async () => {
    let logoutCalled = false;
    const provider = createAuthProvider({
      identityAdapter: {
        authenticate: async () => responsable,
        getIdentity: async () => responsable,
        logout: async () => {
          logoutCalled = true;
        },
      },
      sessionStore: createSessionStorageSessionStore(sessionStorage, sessionKey),
    });

    await expect(provider.checkAuth({})).resolves.toBeUndefined();
    await expect(provider.getIdentity?.()).resolves.toEqual(responsable);
    await provider.logout({});

    expect(logoutCalled).toBe(true);
    expect(sessionStorage.getItem(sessionKey)).toBeNull();
  });

  it('efface la session locale même si la déconnexion serveur échoue', async () => {
    const provider = createAuthProvider({
      identityAdapter: {
        authenticate: async () => responsable,
        logout: async () => {
          throw new Error('Serveur indisponible');
        },
      },
      sessionStore: createSessionStorageSessionStore(sessionStorage, sessionKey),
    });
    await provider.login({ email: 'responsable@demo.local', password: 'demo' });

    await expect(provider.logout({})).rejects.toThrow('Serveur indisponible');
    expect(sessionStorage.getItem(sessionKey)).toBeNull();
  });
});
