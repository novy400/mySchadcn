import type { RaRecord } from 'ra-core';

export type Contact = {
  client_id: number;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
} & Pick<RaRecord, 'id'>;
