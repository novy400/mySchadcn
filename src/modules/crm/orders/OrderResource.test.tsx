import { describe, expect, it } from 'vitest';
import { OrderEdit } from './OrderEdit';
import { OrderList } from './OrderList';
import { orders } from './order.resource';

describe('orders resource', () => {
  it('registers a list and an edit screen without exposing create', () => {
    expect(orders.name).toBe('orders');
    expect(orders.list).toBe(OrderList);
    expect(orders.edit).toBe(OrderEdit);
    expect(orders.create).toBeUndefined();
    expect(orders.recordRepresentation).toBe('reference');
  });
});
