import type { ReactNode } from "react";
import { 
  useDataTableDataContext,
  useDataTableConfigContext,
  useDataTableCallbacksContext,
  useDataTableSelectedIdsContext,
  DataTableRenderContext,
} from "ra-core";
import { Checkbox } from "@/components/ui/checkbox";
import {
  TableHead,
  TableRow,
} from "@/components/ui/table";

export const DataTableHead = ({ children }: { children: ReactNode }) => {
  const data = useDataTableDataContext();
  const { hasBulkActions = false } = useDataTableConfigContext();
  const { onSelect } = useDataTableCallbacksContext();
  const selectedIds = useDataTableSelectedIdsContext();
  
  const handleToggleSelectAll = (checked: boolean) => {
    if (!onSelect || !data || !selectedIds) return;
    onSelect(
      checked
        ? selectedIds.concat(
            data
              .filter((record) => !selectedIds.includes(record.id))
              .map((record) => record.id),
          )
        : // We should only unselect the ids present in the current page
          selectedIds.filter((id) => !data.some((record) => record.id === id)),
    );
  };
  
  const selectableIds = Array.isArray(data)
    ? data.map((record) => record.id)
    : [];
    
  return (
    <TableHead>
      <TableRow>
        {hasBulkActions ? (
          <TableHead className="w-8">
            <Checkbox
              onCheckedChange={handleToggleSelectAll}
              checked={
                selectedIds &&
                selectedIds.length > 0 &&
                selectableIds.length > 0 &&
                selectableIds.every((id) => selectedIds.includes(id))
              }
              className="mb-2"
            />
          </TableHead>
        ) : null}
        <DataTableRenderContext.Provider value="header">
          {children}
        </DataTableRenderContext.Provider>
      </TableRow>
    </TableHead>
  );
};