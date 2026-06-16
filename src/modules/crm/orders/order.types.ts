import type { RaRecord } from 'ra-core';

export type OrderStatus = 'ordered' | 'delivered' | 'canceled';

export type OrderBasketItem = {
  product_id: number;
  quantity: number;
};

export type Order = {
  reference: string;
  date: string;
  customer_id: number;
  basket: OrderBasketItem[];
  total_ex_taxes: number;
  delivery_fees: number;
  tax_rate: number;
  taxes: number;
  total: number;
  status: OrderStatus;
  returned: boolean;
} & Pick<RaRecord, 'id'>;
