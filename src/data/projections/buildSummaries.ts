import type { Client } from '@/modules/crm/clients/client.types';
import type { Contact } from '@/modules/crm/contacts/contact.types';
import type { Task } from '@/modules/crm/tasks/task.types';
import type { Note } from '@/modules/crm/notes/note.types';
import type { Customer, CustomerSignalietique, CustomerRisque } from '@/modules/crm/customers/customer.types';
import type { Fournisseur } from '@/modules/crm/fournisseurs/fournisseur.types';
import type { Order } from '@/modules/crm/orders/order.types';

export type BaseData = {
  clients: Client[];
  contacts: Contact[];
  tasks: Task[];
  notes: Note[];
  customers: Customer[];
  customerSignalietiques: CustomerSignalietique[];
  customerRisques: CustomerRisque[];
  fournisseurs: Fournisseur[];
  orders: Order[];
};

export type TaskWithClient = Task & {
  contact_name: string;
  client_id: Client['id'] | null;
  client_name: string;
};

export type ProjectionSourceData = Pick<
  BaseData,
  'clients' | 'contacts' | 'tasks' | 'notes'
>;

export const buildTaskWithClient = (
  task: Task,
  contact?: Contact,
  client?: Client,
): TaskWithClient => ({
  ...task,
  contact_name: contact ? `${contact.prenom} ${contact.nom}` : '',
  client_id: client?.id ?? null,
  client_name: client?.nom ?? '',
});

export const buildContactSummaries = (data: ProjectionSourceData) =>
  data.contacts.map((contact) => {
    const client = data.clients.find(c => c.id === contact.client_id);
    const openTasks = data.tasks.filter(
      t => t.contact_id === contact.id && t.status === 'OPEN'
    ).length;

    const notes = data.notes
      .filter(n => n.contact_id === contact.id)
      .sort((a, b) => b.date.localeCompare(a.date));

    return {
      id: contact.id,
      prenom: contact.prenom,
      nom: contact.nom,
      email: contact.email,
      telephone: contact.telephone,
      client_id: contact.client_id,
      client_name: client?.nom ?? '',
      client_city: client?.ville ?? '',
      client_status: client?.statut ?? '',
      open_tasks: openTasks,
      last_note_date: notes[0]?.date ?? null,
    };
  });

export const buildTasksWithClient = (data: ProjectionSourceData) =>
  data.tasks.map((task) => {
    const contact = data.contacts.find(c => c.id === task.contact_id);
    const client = contact ? data.clients.find(c => c.id === contact.client_id) : undefined;

    return buildTaskWithClient(task, contact, client);
  });

export const buildSummaries = (data: BaseData) => {
  const contacts_summary = buildContactSummaries(data);
  const tasks_with_client = buildTasksWithClient(data);

  return {
    ...data,
    contacts_summary,
    tasks_with_client,
  };
};
