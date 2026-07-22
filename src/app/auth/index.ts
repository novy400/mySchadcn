import { createAuthProvider, createSessionStorageSessionStore } from './authProvider';
import { demoIdentityAdapter } from './demoIdentityAdapter';

export const authProvider = createAuthProvider({
  identityAdapter: demoIdentityAdapter,
  sessionStore: createSessionStorageSessionStore(window.sessionStorage),
});

export { DemoLoginPage } from './DemoLoginPage';
