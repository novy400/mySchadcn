import type { RaRecord } from 'ra-core';

export type ServiceRecord = RaRecord<string> & {
  id: string;
  nom: string;
  idManageur: string;
  idServiceAdmin: string;
  site: string;
};
