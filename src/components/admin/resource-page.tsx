import type { ReactNode } from "react";
import { Link } from "react-router";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbPage,
} from "@/components/admin/breadcrumb";
import { cn } from "@/lib/utils";
import { Translate } from "ra-core";
import {
  useCreatePath,
  useGetResourceLabel,
  useHasDashboard,
  useResourceContext,
} from "ra-core";

export interface ResourcePageProps {
  children: ReactNode;
  className?: string;
  title?: ReactNode | string | false;
  actions?: ReactNode;
  disableBreadcrumb?: boolean;
  resourceLabel?: string;
  breadcrumbItems?: BreadcrumbItemProps[];
}

export interface BreadcrumbItemProps {
  label: ReactNode;
  link?: string;
  isCurrent?: boolean;
}

/**
 * A base component for resource pages (Edit, Create, Show, etc.).
 * 
 * Provides common layout elements like breadcrumb navigation, title, and actions area.
 * 
 * @internal
 */
export const ResourcePage = ({
  children,
  className,
  title,
  actions,
  disableBreadcrumb,
  resourceLabel,
  breadcrumbItems,
}: ResourcePageProps) => {
  const resource = useResourceContext();
  const getResourceLabel = useGetResourceLabel();
  const listLabel = resourceLabel || (resource ? getResourceLabel(resource, 2) : "");
  const createPath = useCreatePath();
  const listLink = resource ? createPath({
    resource,
    type: "list",
  }) : "";
  const hasDashboard = useHasDashboard();

  return (
    <>
      {!disableBreadcrumb && (
        <Breadcrumb>
          {hasDashboard && (
            <BreadcrumbItem>
              <Link to="/">
                <Translate i18nKey="ra.page.dashboard">Home</Translate>
              </Link>
            </BreadcrumbItem>
          )}
          {breadcrumbItems ? (
            breadcrumbItems.map((item, index) => (
              <BreadcrumbItem key={index}>
                {item.isCurrent ? (
                  <BreadcrumbPage>{item.label}</BreadcrumbPage>
                ) : (
                  <Link to={item.link || "#"}>{item.label}</Link>
                )}
              </BreadcrumbItem>
            ))
          ) : (
            <>
              <BreadcrumbItem>
                <Link to={listLink}>{listLabel}</Link>
              </BreadcrumbItem>
              <BreadcrumbPage>
                {title || <Translate i18nKey="ra.page.edit">Edit</Translate>}
              </BreadcrumbPage>
            </>
          )}
        </Breadcrumb>
      )}
      <div
        className={cn(
          "flex justify-between items-start flex-wrap gap-2 my-2",
          className,
        )}
      >
        <h2 className="text-2xl font-bold tracking-tight">
          {title}
        </h2>
        {actions && <div className="flex justify-end items-center gap-2">{actions}</div>}
      </div>
      <div className="my-2">{children}</div>
    </>
  );
};