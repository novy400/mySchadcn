import { describe, expect, it } from 'vitest';
import type { Order } from './order.types';
import {
  getAvailableOrderActions,
  OrderTransitionError,
  transitionOrder,
} from './order.lifecycle';

const order = (overrides: Partial<Order> = {}): Order => ({
  id: 1,
  reference: 'CMD-2026-0001',
  date: '2026-04-01',
  customer_id: 1,
  basket: [{ product_id: 101, quantity: 2 }],
  total_ex_taxes: 580,
  delivery_fees: 24,
  tax_rate: 0.2,
  taxes: 120.8,
  total: 724.8,
  status: 'ordered',
  returned: false,
  ...overrides,
});

describe('order lifecycle', () => {
  it('allows delivery or cancellation for an order in progress', () => {
    expect(getAvailableOrderActions(order())).toEqual(['deliver', 'cancel']);
  });

  it('delivers an order without mutating the original record', () => {
    const original = order();

    const delivered = transitionOrder(original, 'deliver');

    expect(delivered).toEqual({ ...original, status: 'delivered' });
    expect(original.status).toBe('ordered');
  });

  it('cancels an order in progress', () => {
    expect(transitionOrder(order(), 'cancel').status).toBe('canceled');
  });

  it('only allows a return once on a delivered order', () => {
    const delivered = order({ status: 'delivered' });

    expect(getAvailableOrderActions(delivered)).toEqual(['return']);
    expect(transitionOrder(delivered, 'return').returned).toBe(true);
    expect(getAvailableOrderActions(order({ status: 'delivered', returned: true }))).toEqual([]);
  });

  it.each([
    ['deliver', order({ status: 'delivered' })],
    ['cancel', order({ status: 'delivered' })],
    ['return', order({ status: 'ordered' })],
    ['return', order({ status: 'canceled' })],
  ] as const)('rejects action %s when the transition is not allowed', (action, record) => {
    expect(() => transitionOrder(record, action)).toThrow(OrderTransitionError);
  });
});
