import { Show } from '@/components/admin/show';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

import { CustomerGeneralTab } from './tabs/CustomerGeneralTab';
import { CustomerSignalietiqueTab } from './tabs/CustomerSignalietiqueTab';
import { CustomerRisqueTab } from './tabs/CustomerRisqueTab';

export const CustomerShow = () => (
  <Show>
    <div className="p-4">
      <Tabs defaultValue="general" className="w-full">
        <TabsList className="mb-4">
          <TabsTrigger value="general">Général</TabsTrigger>
          <TabsTrigger value="signalietique">Signalétique</TabsTrigger>
          <TabsTrigger value="risque">Risque métier</TabsTrigger>
        </TabsList>

        <TabsContent value="general">
          <CustomerGeneralTab />
        </TabsContent>

        <TabsContent value="signalietique">
          <CustomerSignalietiqueTab />
        </TabsContent>

        <TabsContent value="risque">
          <CustomerRisqueTab />
        </TabsContent>
      </Tabs>
    </div>
  </Show>
);
