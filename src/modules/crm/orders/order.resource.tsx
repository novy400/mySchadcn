import type { ResourceProps } from 'ra-core';
import { ShoppingCart } from 'lucide-react';
import { OrderList } from './OrderList';
import { OrderEdit } from './OrderEdit';

export const orders: ResourceProps = {
  name: 'orders',
  list: OrderList,
  edit: OrderEdit,
  recordRepresentation: 'reference',
  icon: ShoppingCart,
  options: { label: 'Commandes' },
};
