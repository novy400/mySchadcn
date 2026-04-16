type Client = {
  id: number;
  code: string;
  nom: string;
  ville: string;
  statut: string;
};

type Contact = {
  id: number;
  client_id: number;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
};

type Task = {
  id: number;
  contact_id: number;
  titre: string;
  status: 'OPEN' | 'DONE';
  due_date: string;
};

type Note = {
  id: number;
  contact_id: number;
  contenu: string;
  date: string;
};

export type BaseData = {
  clients: Client[];
  contacts: Contact[];
  tasks: Task[];
  notes: Note[];
};

export const buildSummaries = (data: BaseData) => {
  const contacts_summary = data.contacts.map((contact) => {
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

  return {
    ...data,
    contacts_summary,
  };
};
