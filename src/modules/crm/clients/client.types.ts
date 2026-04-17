import type { RaRecord } from 'ra-core';

export type ClientStatut = 'ACTIF' | 'PROSPECT' | 'SUSPENDU';

export type Client = {
  code: string;
  nom: string;
  ville: string;
  statut: ClientStatut;
} & Pick<RaRecord, 'id'>;
