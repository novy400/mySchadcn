import { ServerCog } from 'lucide-react';
import type { ResourceProps } from 'ra-core';

import { ServiceList } from './ServiceList';
import { ServiceShow } from './ServiceShow';

export const services: ResourceProps = {
  name: 'services',
  list: ServiceList,
  show: ServiceShow,
  recordRepresentation: 'nom',
  icon: ServerCog,
  options: { label: 'Services IBM i' },
};
