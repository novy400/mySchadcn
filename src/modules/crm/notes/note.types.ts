import type { Identifier, RaRecord } from 'ra-core';

export type Note = {
  contact_id: Identifier;
  contenu: string;
  date: string;
} & Pick<RaRecord, 'id'>;
