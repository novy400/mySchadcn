import type { Identifier, RaRecord } from 'ra-core';

export type Contact = {
  client_id: Identifier;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
} & Pick<RaRecord, 'id'>;
