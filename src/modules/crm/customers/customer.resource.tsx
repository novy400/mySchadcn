import { Building } from 'lucide-react';
import type { ResourceProps } from 'ra-core';
import { CustomerList } from './CustomerList';
import { CustomerShow } from './CustomerShow';

export const customerResource: ResourceProps = {
  name: 'customers',
  list: CustomerList,
  show: CustomerShow,
  recordRepresentation: 'name',
  icon: Building,
  options: { label: 'Clients (Tabs)' },
};

export const customerSignalietiqueResource: ResourceProps = {
  name: 'customerSignalietiques',
};

export const customerRisqueResource: ResourceProps = {
  name: 'customerRisques',
};
