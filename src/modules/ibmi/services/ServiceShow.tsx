import { RecordField } from '@/components/admin/record-field';
import { Show, type ShowProps } from '@/components/admin/show';

import type { ServiceRecord } from './service.types';

export const ServiceShow = (props: Pick<ShowProps, 'id'>) => (
  <Show {...props} actions={false}>
    <section className="flex flex-col gap-4" aria-label="Référentiel technique IBM i">
      <p className="text-sm text-muted-foreground">
        Référentiel technique IBM i exposé en lecture seule.
      </p>
      <div className="grid gap-4 md:grid-cols-2">
        <RecordField<ServiceRecord> source="id" label="Identifiant" />
        <RecordField<ServiceRecord> source="nom" label="Nom" />
        <RecordField<ServiceRecord> source="idManageur" label="Identifiant manager" />
        <RecordField<ServiceRecord> source="idServiceAdmin" label="Service administratif" />
        <RecordField<ServiceRecord> source="site" label="Site" />
      </div>
    </section>
  </Show>
);
