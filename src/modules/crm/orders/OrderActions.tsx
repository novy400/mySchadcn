import { useState } from 'react';
import { Ban, PackageCheck, Undo2 } from 'lucide-react';
import { useCanAccess, useNotify, useRecordContext, useRefresh, useUpdate } from 'ra-core';
import { Confirm } from '@/components/admin/confirm';
import { Button } from '@/components/ui/button';
import { getAvailableOrderActions, transitionOrder, type OrderAction } from './order.lifecycle';
import type { Order } from './order.types';

const statusLabels: Record<Order['status'], string> = {
  ordered: 'Commandée',
  delivered: 'Livrée',
  canceled: 'Annulée',
};

const successMessages: Record<OrderAction, string> = {
  deliver: 'Commande livrée',
  cancel: 'Commande annulée',
  return: 'Retour enregistré',
};

export const OrderActions = () => {
  const order = useRecordContext<Order>();
  const notify = useNotify();
  const refresh = useRefresh();
  const [update, { isPending }] = useUpdate<Order>();
  const [isCancelConfirmationOpen, setIsCancelConfirmationOpen] = useState(false);
  const deliverAccess = useCanAccess({ action: 'deliver', resource: 'orders', record: order });
  const cancelAccess = useCanAccess({ action: 'cancel', resource: 'orders', record: order });
  const returnAccess = useCanAccess({ action: 'return', resource: 'orders', record: order });

  if (!order) {
    return null;
  }

  const availableActions = getAvailableOrderActions(order);
  const accessByAction: Record<OrderAction, boolean> = {
    deliver: deliverAccess.canAccess === true,
    cancel: cancelAccess.canAccess === true,
    return: returnAccess.canAccess === true,
  };
  const authorizedActions = availableActions.filter((action) => accessByAction[action]);
  const isAccessPending = deliverAccess.isPending || cancelAccess.isPending || returnAccess.isPending;

  const runAction = (action: OrderAction) => {
    const nextOrder = transitionOrder(order, action);

    update(
      'orders',
      { id: order.id, data: nextOrder, previousData: order },
      {
        mutationMode: 'pessimistic',
        onSuccess: () => {
          setIsCancelConfirmationOpen(false);
          notify(successMessages[action], { type: 'success' });
          refresh();
        },
        onError: () => {
          notify("La commande n'a pas pu être mise à jour", { type: 'error' });
        },
      },
    );
  };

  return (
    <section className="w-full space-y-3 rounded-md border p-4" aria-label="Cycle de vie de la commande">
      <div className="grid gap-3 text-sm sm:grid-cols-2">
        <div>
          <span className="text-muted-foreground">Statut</span>
          <p className="font-medium">{statusLabels[order.status]}</p>
        </div>
        <div>
          <span className="text-muted-foreground">Retour</span>
          <p className="font-medium">{order.returned ? 'Enregistré' : 'Aucun'}</p>
        </div>
      </div>

      {isAccessPending ? (
        <p className="text-sm text-muted-foreground">Vérification des droits…</p>
      ) : authorizedActions.length > 0 ? (
        <div className="flex flex-wrap gap-2">
          {authorizedActions.includes('deliver') ? (
            <Button type="button" disabled={isPending} onClick={() => runAction('deliver')}>
              <PackageCheck />
              Livrer
            </Button>
          ) : null}
          {authorizedActions.includes('cancel') ? (
            <Button
              type="button"
              variant="destructive"
              disabled={isPending}
              onClick={() => setIsCancelConfirmationOpen(true)}
            >
              <Ban />
              Annuler
            </Button>
          ) : null}
          {authorizedActions.includes('return') ? (
            <Button type="button" variant="outline" disabled={isPending} onClick={() => runAction('return')}>
              <Undo2 />
              Signaler le retour
            </Button>
          ) : null}
        </div>
      ) : availableActions.length > 0 ? (
        <p className="text-sm text-muted-foreground">Aucune action autorisée.</p>
      ) : (
        <p className="text-sm text-muted-foreground">Aucune action disponible.</p>
      )}

      <Confirm
        isOpen={isCancelConfirmationOpen}
        title="Annuler cette commande ?"
        content="La commande ne pourra plus être livrée après son annulation."
        confirm="Annuler la commande"
        confirmColor="warning"
        loading={isPending}
        onClose={() => setIsCancelConfirmationOpen(false)}
        onConfirm={() => runAction('cancel')}
      />
    </section>
  );
};
