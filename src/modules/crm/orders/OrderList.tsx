import { useListContext } from 'ra-core';
import { AutocompleteInput, DataTable, List, ReferenceInput, TextField, TextInput } from '@/components/admin';
import { ColumnsButton } from '@/components/admin/columns-button';
import { Count } from '@/components/admin/count';
import { ExportButton } from '@/components/admin/export-button';
import { ReferenceField } from '@/components/admin/reference-field';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import type { OrderStatus } from './order.types';

const ORDER_STATUS: Array<{ id: OrderStatus; name: string }> = [
  { id: 'ordered', name: 'Commandées' },
  { id: 'delivered', name: 'Livrées' },
  { id: 'canceled', name: 'Annulées' },
];

const storeKeyByStatus: Record<OrderStatus, string> = {
  ordered: 'orders.list.ordered',
  delivered: 'orders.list.delivered',
  canceled: 'orders.list.canceled',
};

const filters = [
  <TextInput source="q" placeholder="Rechercher une commande" label={false} alwaysOn />,
  <ReferenceInput
    source="customer_id"
    reference="customers"
    sort={{ field: 'name', order: 'ASC' }}
    alwaysOn
  >
    <AutocompleteInput placeholder="Filtrer par client" label={false} />
  </ReferenceInput>,
];

const ListActions = () => {
  const { filterValues } = useListContext();
  const status = (filterValues.status as OrderStatus) ?? 'ordered';

  return (
    <div className="flex items-center gap-2">
      <ColumnsButton storeKey={storeKeyByStatus[status]} />
      <ExportButton />
    </div>
  );
};

export const OrderList = () => (
  <List
    sort={{ field: 'date', order: 'DESC' }}
    filterDefaultValues={{ status: 'ordered' }}
    filters={filters}
    perPage={25}
    actions={<ListActions />}
  >
    <TabbedOrdersTable />
  </List>
);

const TabbedOrdersTable = () => {
  const { filterValues, setFilters, displayedFilters } = useListContext();
  const currentStatus = (filterValues.status as OrderStatus) ?? 'ordered';

  const handleChange = (status: OrderStatus) => () => {
    setFilters({ ...filterValues, status }, displayedFilters);
  };

  return (
    <Tabs value={currentStatus} className="mb-4 -gap-2">
      <TabsList className="w-full">
        {ORDER_STATUS.map((status) => (
          <TabsTrigger key={status.id} value={status.id} onClick={handleChange(status.id)}>
            {status.name}
            <Badge variant="outline" className="hidden md:inline-flex">
              <Count filter={{ ...filterValues, status: status.id }} />
            </Badge>
          </TabsTrigger>
        ))}
      </TabsList>
      {ORDER_STATUS.map((status) => (
        <TabsContent key={status.id} value={status.id}>
          <OrdersTable storeKey={storeKeyByStatus[status.id]} />
        </TabsContent>
      ))}
    </Tabs>
  );
};

const OrdersTable = ({ storeKey }: { storeKey: string }) => (
  <DataTable storeKey={storeKey} rowClick="edit">
    <DataTable.Col source="date" render={(record) => new Date(record.date).toLocaleDateString('fr-FR')} />
    <DataTable.Col source="reference" className="hidden md:table-cell" />
    <DataTable.Col source="customer_id" label="Client" className="hidden md:table-cell">
      <ReferenceField source="customer_id" reference="customers" link={false} />
    </DataTable.Col>
    <DataTable.NumberCol source="basket.length" label="Articles" className="hidden md:table-cell" />
    <DataTable.NumberCol source="total_ex_taxes" label="Total HT" options={{ style: 'currency', currency: 'EUR' }} className="hidden lg:table-cell" />
    <DataTable.NumberCol source="delivery_fees" label="Livraison" options={{ style: 'currency', currency: 'EUR' }} className="hidden lg:table-cell" />
    <DataTable.NumberCol source="total" label="Total TTC" options={{ style: 'currency', currency: 'EUR' }} />
    <DataTable.Col source="returned" label="Retournée" className="hidden md:table-cell">
      <TextField source="returned" />
    </DataTable.Col>
  </DataTable>
);
