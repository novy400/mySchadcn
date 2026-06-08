import type { RaRecord } from 'ra-core';

export type Fournisseur = {
  nom: string;
  adresse: string;
  ville: string;
  telephone: string;
  email: string;
} & Pick<RaRecord, 'id'>;
