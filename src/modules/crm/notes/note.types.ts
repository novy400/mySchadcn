import type { RaRecord } from 'ra-core';

export type Note = {
  contact_id: number;
  contenu: string;
  date: string;
} & Pick<RaRecord, 'id'>;
