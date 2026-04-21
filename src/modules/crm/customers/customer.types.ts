import type { Identifier, RaRecord } from 'ra-core';

export type Customer = {
  name: string;
  type: string;
} & Pick<RaRecord, 'id'>;

export type CustomerSignalietique = {
  adresse: string;
  phone: string;
  email: string;
} & Pick<RaRecord, 'id'>;

export type CustomerRisque = {
  score: number;
  statut: string;
  lastReview: string;
} & Pick<RaRecord, 'id'>;
