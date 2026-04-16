import { ResourceProps } from 'ra-core';
import { ClientList } from './ClientList';
import { ClientEdit } from './ClientEdit';
import { ClientCreate } from './ClientCreate';
import { Users } from 'lucide-react';
export const clients: ResourceProps = {
  name: "clients",
  list: ClientList,
  edit: ClientEdit,
  create: ClientCreate,
  recordRepresentation: (record) => `${record.first_name} ${record.last_name}`,
  icon: Users,
};

