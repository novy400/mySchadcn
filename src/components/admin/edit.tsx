import type { EditBaseProps } from "ra-core";
import {
  EditBase,
  useEditContext,
  useResourceContext,
  useResourceDefinition,
} from "ra-core";
import type { ReactNode } from "react";
import { ResourcePage } from "./resource-page";
import { ShowButton } from "@/components/admin/show-button";
import { DeleteButton } from "./delete-button";

export interface EditProps extends EditViewProps, EditBaseProps {}

/**
 * A complete edit page with breadcrumb, title, and default actions.
 *
 * Combines data fetching, form context, and UI layout for editing records. Renders breadcrumb,
 * page title, Show and Delete buttons, and wraps your form components.
 *
 * @see {@link https://marmelab.com/shadcn-admin-kit/docs/edit/ Edit documentation}
 *
 * @example
 * import { Edit, SimpleForm, BooleanInput, TextInput } from "@/components/admin";
 * import { required } from 'ra-core';
 *
 * export const CustomerEdit = () => (
 *   <Edit>
 *     <SimpleForm>
 *       <TextInput source="first_name" validate={required()} />
 *       <TextInput source="last_name" validate={required()} />
 *       <TextInput source="email" validate={required()} />
 *       <BooleanInput source="has_ordered" />
 *       <TextInput multiline source="notes" />
 *     </SimpleForm>
 *   </Edit>
 * );
 */
export const Edit = ({
  actions,
  children,
  className,
  disableBreadcrumb,
  title,
  ...rest
}: EditProps) => (
  <EditBase {...rest}>
    <EditView
      actions={actions}
      className={className}
      disableBreadcrumb={disableBreadcrumb}
      title={title}
    >
      {children}
    </EditView>
  </EditBase>
);

export interface EditViewProps {
  disableBreadcrumb?: boolean;
  title?: ReactNode | string | false;
  actions?: ReactNode;
  children?: ReactNode;
  className?: string;
}

/**
 * The view component for Edit pages with layout and UI.
 *
 * @internal
 */
export const EditView = ({
  disableBreadcrumb,
  title,
  actions,
  className,
  children,
}: EditViewProps) => {
  const context = useEditContext();

  const resource = useResourceContext();
  if (!resource) {
    throw new Error(
      "The EditView component must be used within a ResourceContextProvider",
    );
  }

  // const getRecordRepresentation = useGetRecordRepresentation(resource);
  // const _recordRepresentation = getRecordRepresentation(context.record);

  const { hasShow } = useResourceDefinition({ resource });

  if (context.isLoading || !context.record) {
    return null;
  }

  const defaultActions = (
    <>
      {hasShow ? <ShowButton /> : null}
      <DeleteButton />
    </>
  );

  return (
    <ResourcePage
      title={title !== undefined ? title : context.defaultTitle}
      actions={actions ?? defaultActions}
      disableBreadcrumb={disableBreadcrumb}
      className={className}
    >
      {children}
    </ResourcePage>
  );
};