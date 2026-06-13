import {
  CoreAdminUI,
  type CoreAdminUIProps,
  CoreAdminContext,
  type CoreAdminContextProps,
  type CoreAdminProps,
  localStorageStore,
} from "ra-core";
import { i18nProvider as defaultI18nProvider } from "@/lib/i18nProvider";
import { Layout } from "@/components/admin/layout";
import { LoginPage } from "@/components/admin/login-page";
import { NotFound } from "@/components/admin/not-found";
import { Ready } from "@/components/admin/ready";
import { ThemeProvider } from "@/components/admin/theme-provider";
import { AuthCallback } from "@/components/admin/authentication";

// Configuration par défaut
const defaultStore = localStorageStore();
const defaultTitle = "Shadcn Admin";

/**
 * Context provider for the Admin component.
 *
 * Wraps CoreAdminContext to provide core admin functionality including data provider,
 * auth provider, i18n provider, and store access to child components.
 *
 * @internal
 */
const AdminContext = (props: CoreAdminContextProps) => (
  <CoreAdminContext {...props} />
);

/**
 * UI component for the Admin application.
 *
 * Wraps CoreAdminUI with theme provider.
 * Provides the main layout, login page, ready page, and authentication callback.
 *
 * @internal
 */
const AdminUI = (props: CoreAdminUIProps) => {
  return (
    <ThemeProvider>
      <CoreAdminUI
        layout={Layout}
        loginPage={LoginPage}
        ready={Ready}
        authCallbackPage={AuthCallback}
        {...props}
      />
    </ThemeProvider>
  );
};

export interface AdminOptions {
  /**
   * Disable telemetry reporting
   * @default false
   */
  disableTelemetry?: boolean;
}

/**
 * Root component of a shadcn-admin-kit application.
 *
 * Creates context providers to allow its children to access the app configuration.
 * Renders the main routes and layout, and delegates content area rendering to Resource children.
 * Combines AdminContext and AdminUI to provide a complete admin interface.
 *
 * @see {@link https://marmelab.com/shadcn-admin-kit/docs/admin/ Admin documentation}
 *
 * @example
 * // Basic usage with dataProvider and Resources
 * import { Admin } from "@/components/admin";
 * import { Resource } from 'ra-core';
 * import simpleRestProvider from 'ra-data-simple-rest';
 *
 * const App = () => (
 *   <Admin dataProvider={simpleRestProvider('http://path.to.my.api')}>
 *     <Resource name="posts" list={PostList} />
 *   </Admin>
 * );
 */
export const Admin = ({
  accessDenied,
  authCallbackPage = AuthCallback,
  authenticationError,
  authProvider,
  basename,
  catchAll = NotFound,
  children,
  dashboard,
  dataProvider,
  disableTelemetry = false,
  error,
  i18nProvider = defaultI18nProvider,
  layout = Layout,
  loading,
  loginPage = LoginPage,
  queryClient,
  ready = Ready,
  requireAuth,
  store = defaultStore,
  title = defaultTitle,
}: CoreAdminProps & AdminOptions) => {
  // Gestion de la télémétrie simplifiée
  if (!disableTelemetry && import.meta.env.PROD) {
    // En production, on envoie une requête de télémétrie
    fetch(`https://shadcn-admin-kit-telemetry.marmelab.com/shadcn-admin-kit-telemetry?domain=${window.location.hostname}`)
      .catch(() => {
        // Silencieux en cas d'erreur de télémétrie
      });
  }

  return (
    <AdminContext
      authProvider={authProvider}
      basename={basename}
      dataProvider={dataProvider}
      i18nProvider={i18nProvider}
      queryClient={queryClient}
      store={store}
    >
      <AdminUI
        accessDenied={accessDenied}
        authCallbackPage={authCallbackPage}
        authenticationError={authenticationError}
        catchAll={catchAll}
        dashboard={dashboard}
        error={error}
        layout={layout}
        loading={loading}
        loginPage={loginPage}
        ready={ready}
        requireAuth={requireAuth}
        title={title}
      >
        {children}
      </AdminUI>
    </AdminContext>
  );
};