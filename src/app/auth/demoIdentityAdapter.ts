import type { CrmIdentity, IdentityAdapter } from './authProvider';

const demoAccounts = [
  {
    email: 'lecteur@demo.local',
    password: 'demo',
    label: 'Lecteur',
    fullName: 'Lecteur Démo',
    role: 'lecteur',
  },
  {
    email: 'agent@demo.local',
    password: 'demo',
    label: 'Agent',
    fullName: 'Agent Démo',
    role: 'agent',
  },
  {
    email: 'responsable@demo.local',
    password: 'demo',
    label: 'Responsable',
    fullName: 'Responsable Démo',
    role: 'responsable',
  },
] as const;

export const demoAccountHints = demoAccounts.map(({ email, password, label }) => ({
  email,
  password,
  label,
}));

export class DemoAuthenticationError extends Error {
  readonly status = 401;

  constructor() {
    super('Identifiants invalides');
    this.name = 'DemoAuthenticationError';
  }
}

export const demoIdentityAdapter: IdentityAdapter = {
  authenticate: async ({ email, password }) => {
    const normalizedEmail = email.trim().toLowerCase();
    const account = demoAccounts.find(
      (candidate) => candidate.email === normalizedEmail && candidate.password === password,
    );

    if (!account) {
      throw new DemoAuthenticationError();
    }

    return {
      id: account.email,
      fullName: account.fullName,
      role: account.role,
    } satisfies CrmIdentity;
  },
};
