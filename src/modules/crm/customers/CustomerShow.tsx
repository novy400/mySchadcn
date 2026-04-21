import { Show } from '@/components/admin/show';
import { SimpleShowLayout } from '@/components/admin/simple-show-layout';
import { TextField } from '@/components/admin/text-field';
import { DateField } from '@/components/admin/date-field';
import { NumberField } from '@/components/admin/number-field';
import { EmailField } from '@/components/admin/email-field';
import { ReferenceField } from '@/components/admin/reference-field';

import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

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
          <Card>
            <CardHeader>
              <CardTitle>Général</CardTitle>
              <CardDescription>Données de base de l'entité de référence.</CardDescription>
            </CardHeader>
            <CardContent>
              <SimpleShowLayout>
                <TextField source="id" />
                <TextField source="name" label="Raison Sociale" />
                <TextField source="type" label="Forme Juridique" />
              </SimpleShowLayout>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="signalietique">
          <Card>
            <CardHeader>
              <CardTitle>Signalétique</CardTitle>
              <CardDescription>Informations de contact de l'entité.</CardDescription>
            </CardHeader>
            <CardContent>
              <ReferenceField 
                label="" 
                source="id" 
                reference="customerSignalietiques" 
                link={false}
              >
                <SimpleShowLayout>
                  <TextField source="adresse" label="Adresse" />
                  <TextField source="phone" label="Téléphone" />
                  <EmailField source="email" label="E-mail" />
                </SimpleShowLayout>
              </ReferenceField>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="risque">
          <Card>
            <CardHeader>
              <CardTitle>Analyse Risque</CardTitle>
              <CardDescription>Indicateurs de solvabilité et suivi.</CardDescription>
            </CardHeader>
            <CardContent>
              <ReferenceField 
                label="" 
                source="id" 
                reference="customerRisques" 
                link={false}
              >
                <SimpleShowLayout>
                  <NumberField source="score" label="Score de solvabilité" />
                  <TextField source="statut" label="Statut" />
                  <DateField source="lastReview" label="Dernière révision" />
                </SimpleShowLayout>
              </ReferenceField>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  </Show>
);
