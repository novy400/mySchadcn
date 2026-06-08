import { ResourceProps } from 'ra-core';
import { Truck } from 'lucide-react';
import { FournisseurList } from './FournisseurList';
import { FournisseurEdit } from './FournisseurEdit';
import { FournisseurCreate } from './FournisseurCreate';

export const fournisseurs: ResourceProps = {
  name: 'fournisseurs',
  list: FournisseurList,
  edit: FournisseurEdit,
  create: FournisseurCreate,
  recordRepresentation: 'nom',
  icon: Truck,
};
