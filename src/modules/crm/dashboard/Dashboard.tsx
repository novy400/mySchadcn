import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import fakerestData from '@/data/fakerestData';

const StatCard = ({ label, value }: { label: string; value: number }) => (
  <Card>
    <CardHeader className="pb-2">
      <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
    </CardHeader>
    <CardContent>
      <p className="text-2xl font-bold">{value}</p>
    </CardContent>
  </Card>
);

export const Dashboard = () => {
  const clients = fakerestData.clients.length;
  const contacts = fakerestData.contacts.length;
  const openTasks = fakerestData.tasks.filter((task) => task.status === 'OPEN').length;

  const topContacts = fakerestData.contacts_summary
    .filter((contact) => contact.open_tasks > 0)
    .slice(0, 5);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard CRM</h1>
        <p className="text-sm text-muted-foreground">Vue rapide de votre activité commerciale.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatCard label="Clients" value={clients} />
        <StatCard label="Contacts" value={contacts} />
        <StatCard label="Tâches ouvertes" value={openTasks} />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Contacts à suivre</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-3">
            {topContacts.map((contact) => (
              <li
                key={contact.id}
                className="flex items-center justify-between rounded-md border px-3 py-2"
              >
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium">{contact.prenom} {contact.nom}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {contact.client_name} • Derniere note: {contact.last_note_date ?? 'Aucune'}
                  </p>
                </div>
                <Badge variant="secondary">{contact.open_tasks} ouverte(s)</Badge>
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  );
};
