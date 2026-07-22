import type { Order } from './order.types';

export type OrderAction = 'deliver' | 'cancel' | 'return';

export class OrderTransitionError extends Error {
  constructor(action: OrderAction, order: Order) {
    super(`Action ${action} interdite pour la commande ${order.reference} au statut ${order.status}`);
    this.name = 'OrderTransitionError';
  }
}

export const getAvailableOrderActions = (order: Order): OrderAction[] => {
  if (order.status === 'ordered') {
    return ['deliver', 'cancel'];
  }

  if (order.status === 'delivered' && !order.returned) {
    return ['return'];
  }

  return [];
};

export const transitionOrder = (order: Order, action: OrderAction): Order => {
  if (!getAvailableOrderActions(order).includes(action)) {
    throw new OrderTransitionError(action, order);
  }

  if (action === 'deliver') {
    return { ...order, status: 'delivered' };
  }

  if (action === 'cancel') {
    return { ...order, status: 'canceled' };
  }

  return { ...order, returned: true };
};
