import type { AuthProvider, Identifier, UserIdentity } from 'ra-core';
import { canRoleAccess, crmRoles, type CrmRole } from './accessPolicy';

export type LoginCredentials = {
  email: string;
  password: string;
};

export type CrmIdentity = UserIdentity & {
  id: Identifier;
  fullName: string;
  role: CrmRole;
};

export type IdentityAdapter = {
  authenticate: (credentials: LoginCredentials) => Promise<CrmIdentity>;
  getIdentity?: () => Promise<CrmIdentity>;
  logout?: () => Promise<void>;
};

export type AuthSessionStore = {
  read: () => CrmIdentity | null;
  write: (identity: CrmIdentity) => void;
  clear: () => void;
};

type CreateAuthProviderOptions = {
  identityAdapter: IdentityAdapter;
  sessionStore: AuthSessionStore;
};

export class AuthenticationRequiredError extends Error {
  readonly status = 401;

  constructor() {
    super('Authentification requise');
    this.name = 'AuthenticationRequiredError';
  }
}

const readIdentity = (sessionStore: AuthSessionStore): CrmIdentity => {
  const identity = sessionStore.read();
  if (!identity) {
    throw new AuthenticationRequiredError();
  }

  return identity;
};

const resolveIdentity = async (
  identityAdapter: IdentityAdapter,
  sessionStore: AuthSessionStore,
): Promise<CrmIdentity> => {
  const storedIdentity = sessionStore.read();
  if (storedIdentity) {
    return storedIdentity;
  }
  if (!identityAdapter.getIdentity) {
    return readIdentity(sessionStore);
  }

  const identity = await identityAdapter.getIdentity();
  sessionStore.write(identity);
  return identity;
};

export const createAuthProvider = ({
  identityAdapter,
  sessionStore,
}: CreateAuthProviderOptions): AuthProvider => ({
  login: async (credentials: LoginCredentials) => {
    sessionStore.clear();
    const identity = await identityAdapter.authenticate(credentials);
    sessionStore.write(identity);
  },
  logout: async () => {
    try {
      await identityAdapter.logout?.();
    } finally {
      sessionStore.clear();
    }
  },
  checkAuth: async () => {
    await resolveIdentity(identityAdapter, sessionStore);
  },
  checkError: async (error: { status?: number }) => {
    if (error.status === 401) {
      sessionStore.clear();
      throw new AuthenticationRequiredError();
    }
  },
  getIdentity: async () => resolveIdentity(identityAdapter, sessionStore),
  getPermissions: async () => (await resolveIdentity(identityAdapter, sessionStore)).role,
  canAccess: async ({ resource, action }) => {
    const identity = sessionStore.read();
    return identity ? canRoleAccess(identity.role, { resource, action }) : false;
  },
});

const isCrmIdentity = (value: unknown): value is CrmIdentity => {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const identity = value as Partial<CrmIdentity>;
  return (
    (typeof identity.id === 'string' || typeof identity.id === 'number') &&
    typeof identity.fullName === 'string' &&
    crmRoles.includes(identity.role as CrmRole)
  );
};

export const createSessionStorageSessionStore = (
  storage: Storage,
  key = 'myschadcn.auth.identity',
): AuthSessionStore => ({
  read: () => {
    const serializedIdentity = storage.getItem(key);
    if (!serializedIdentity) {
      return null;
    }

    try {
      const identity: unknown = JSON.parse(serializedIdentity);
      if (isCrmIdentity(identity)) {
        return identity;
      }
    } catch {
      // Une session illisible est traitée comme expirée.
    }

    storage.removeItem(key);
    return null;
  },
  write: (identity) => storage.setItem(key, JSON.stringify(identity)),
  clear: () => storage.removeItem(key),
});
