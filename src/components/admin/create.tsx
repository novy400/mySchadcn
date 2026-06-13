import type { CreateBaseProps } from "ra-core";
import {
  CreateBase,
  useCreateContext,
  useResourceContext,
} from "ra-core";
import type { ReactNode } from "react";
import { ResourcePage } from "./resource-page";
import { Translate } from "ra-core";

export type CreateProps = CreateViewProps & CreateBaseProps;

/**
 * A complete create page with breadcrumb, title, and actions.
 *
 * Combines data fetching, form context, and UI layout for creating new records. Renders breadcrumb
 * navigation, page title, and wraps your form components.
 *
 * @see {@link https://marmelab.com/shadcn-admin-kit/docs/create/ Create documentation}
 *
 * @example
 * import { Create, SimpleForm, TextInput } from '@/components/admin';
 *
 * export const PostCreate = () => (
 *   <Create>
 *     <SimpleForm>
 *       <TextInput source="title" />
 *       <TextInput source="body" />
 *     </SimpleForm>
 *   </Create>
 * );
 */
export const Create = ({
  actions,
  children,
  className,
  disableBreadcrumb,
  title,
  ...rest
}: CreateProps) => (
  <CreateBase {...rest}>
    <CreateView
      actions={actions}
      className={className}
      disableBreadcrumb={disableBreadcrumb}
      title={title}
    >
      {children}
    </CreateView>
  </CreateBase>
);

export type CreateViewProps = {
  actions?: ReactNode;
  disableBreadcrumb?: boolean;
  children: ReactNode;
  className?: string;
  title?: ReactNode | string | false;
};

/**
 * The view component for Create pages with layout and UI.
 *
 * @internal
 */
export const CreateView = ({
  actions,
  disableBreadcrumb,
  title,
  children,
  className,
}: CreateViewProps) => {
  const context = useCreateContext();

  const resource = useResourceContext();
  if (!resource) {
    throw new Error(
      "The CreateView component must be used within a ResourceContextProvider",
    );
  }

  return (
    <ResourcePage
      title={title !== undefined ? title : context.defaultTitle}
      actions={actions}
      disableBreadcrumb={disableBreadcrumb}
      className={className}
      breadcrumbItems={[
        {
          label: (
            <Translate i18nKey="ra.page.create">
              Create
            </Translate>
          ),
          isCurrent: true,
        },
      ]}
    >
      {children}
    </ResourcePage>
  );
};