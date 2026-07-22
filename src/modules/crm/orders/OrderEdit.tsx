import { useRecordContext } from 'ra-core';
import { AutocompleteInput, Edit, NumberField, ReferenceInput, SimpleForm, TextField } from '@/components/admin';
import { DateInput } from '@/components/admin/date-input';
import { RecordField } from '@/components/admin/record-field';
import { OrderActions } from './OrderActions';
import type { Order } from './order.types';

export const OrderEdit = () => (
  <Edit>
    <SimpleForm className="max-w-3xl">
      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-4">
          <RecordField source="reference" label="Référence" />
          <DateInput source="date" label="Date" />
          <ReferenceInput source="customer_id" reference="customers" sort={{ field: 'name', order: 'ASC' }}>
            <AutocompleteInput label="Client" />
          </ReferenceInput>
        </div>
        <div className="space-y-4 rounded-md border p-4">
          <RecordField source="total_ex_taxes" label="Total HT">
            <NumberField source="total_ex_taxes" options={{ style: 'currency', currency: 'EUR' }} />
          </RecordField>
          <RecordField source="delivery_fees" label="Frais de livraison">
            <NumberField source="delivery_fees" options={{ style: 'currency', currency: 'EUR' }} />
          </RecordField>
          <RecordField source="tax_rate" label="Taux TVA">
            <TextField source="tax_rate" />
          </RecordField>
          <RecordField source="taxes" label="Taxes">
            <NumberField source="taxes" options={{ style: 'currency', currency: 'EUR' }} />
          </RecordField>
          <RecordField source="total" label="Total TTC">
            <NumberField source="total" options={{ style: 'currency', currency: 'EUR' }} />
          </RecordField>
        </div>
      </div>
      <OrderActions />
      <BasketField />
    </SimpleForm>
  </Edit>
);

const BasketField = () => {
  const record = useRecordContext<Order>();

  if (!record?.basket?.length) {
    return null;
  }

  return (
    <section className="w-full rounded-md border p-4">
      <h3 className="mb-3 text-sm font-medium">Panier</h3>
      <div className="space-y-2 text-sm">
        {record.basket.map((item) => (
          <div key={item.product_id} className="flex justify-between border-b pb-2 last:border-b-0 last:pb-0">
            <span>Produit #{item.product_id}</span>
            <span>Quantité : {item.quantity}</span>
          </div>
        ))}
      </div>
    </section>
  );
};
