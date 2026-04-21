
import { Admin } from '@/components/admin';
import { Resource } from 'ra-core';

import dataProvider from './providers/dataProvider';
import { Dashboard } from '../modules/crm/dashboard/Dashboard';
import { clients } from '../modules/crm/clients';
import { contacts } from '../modules/crm/contacts';
import { tasks } from '../modules/crm/tasks';
import { notes } from '../modules/crm/notes';
import { contactsSummary } from '../modules/crm/contacts-summary';
import { customerResource, customerSignalietiqueResource, customerRisqueResource } from '../modules/crm/customers';

function App() {
  return (
    <Admin
      dataProvider={dataProvider}
      dashboard={Dashboard}
    >
      <Resource {...clients} />
      <Resource {...contacts} />
      <Resource {...tasks} />
      <Resource {...notes} />
      <Resource {...contactsSummary} />
      
      {/* Ressources de détail avec Tabs */}
      <Resource {...customerResource} />
      <Resource {...customerSignalietiqueResource} />
      <Resource {...customerRisqueResource} />
    </Admin>
  );
}

export default App;


