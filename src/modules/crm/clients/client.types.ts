export interface Client {
  id: number;
  code: string;
  nom: string;
  ville: string;
  statut: 'ACTIF' | 'PROSPECT' | 'SUSPENDU';
}
