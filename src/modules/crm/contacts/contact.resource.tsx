import { ResourceProps } from 'ra-core';
import { Users } from 'lucide-react';
import { ContactList } from './ContactList';
import { ContactEdit } from './ContactEdit';
import { ContactCreate } from './ContactCreate';

export const contacts: ResourceProps = {
  name: "contacts",
  list: ContactList,
  edit: ContactEdit,
  create: ContactCreate,
  recordRepresentation: "nom",
  icon: Users,
};
