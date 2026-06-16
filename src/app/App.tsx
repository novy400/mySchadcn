
import { Admin } from '@/components/admin';
import { Resource } from 'ra-core';

import dataProvider from './providers/dataProvider';
import { Dashboard } from '../modules/crm/dashboard/Dashboard';
import { clients } from '../modules/crm/clients';
import { contacts } from '../modules/crm/contacts';
import { tasksWithClient } from '../modules/crm/tasks';
import { notes } from '../modules/crm/notes';
import { contactsSummary } from '../modules/crm/contacts-summary';
import { fournisseurs } from '../modules/crm/fournisseurs';
import { customerResource, customerSignalietiqueResource, customerRisqueResource } from '../modules/crm/customers';
import { orders } from '../modules/crm/orders';

function App() {
  return (
    <Admin
      dataProvider={dataProvider}
      dashboard={Dashboard}
    >
      <Resource {...clients} />
      <Resource {...contacts} />
      <Resource {...tasksWithClient} />
      <Resource {...notes} />
      <Resource {...contactsSummary} />
      <Resource {...fournisseurs} />
      <Resource {...orders} />

      {/* Ressources de détail avec Tabs */}
      <Resource {...customerResource} />
      <Resource {...customerSignalietiqueResource} />
      <Resource {...customerRisqueResource} />
    </Admin>
  );
}

export default App;


