import type { ReactNode } from "react";
import { 
  useDataTableDataContext,
  RecordContextProvider,
  DataTableRenderContext,
} from "ra-core";
import {
  TableBody,
} from "@/components/ui/table";
import { DataTableRow } from "./data-table-row";

export const DataTableBody = <RecordType extends RaRecord = RaRecord>({
  children,
  rowClassName,
}: {
  children: ReactNode;
  rowClassName?: (record: RecordType) => string | undefined;
}) => {
  const data = useDataTableDataContext();
  return (
    <TableBody>
      {data?.map((record, rowIndex) => (
        <RecordContextProvider
          value={record}
          key={record.id ?? `row${rowIndex}`}
        >
          <DataTableRow className={rowClassName?.(record)}>
            <DataTableRenderContext.Provider value="data">
              {children}
            </DataTableRenderContext.Provider>
          </DataTableRow>
        </RecordContextProvider>
      ))}
    </TableBody>
  );
};

// Type import for RaRecord
import type { RaRecord } from "ra-core";