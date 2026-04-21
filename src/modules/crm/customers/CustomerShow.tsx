import { Show } from '@/components/admin/show';
import { RecordField } from '@/components/admin/record-field';
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
              <div className="flex flex-col gap-4">
                <RecordField source="id" />
                <RecordField source="name" label="Raison Sociale" />
                <RecordField source="type" label="Forme Juridique" />
              </div>
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
                source="id" 
                reference="customerSignalietiques" 
                link={false}
              >
                <div className="flex flex-col gap-4">
                  <RecordField source="adresse" label="Adresse" />
                  <RecordField source="phone" label="Téléphone" />
                  <RecordField source="email" label="E-mail">
                    <EmailField source="email" />
                  </RecordField>
                </div>
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
                source="id" 
                reference="customerRisques" 
                link={false}
              >
                <div className="flex flex-col gap-4">
                  <RecordField source="score" label="Score de solvabilité">
                    <NumberField source="score" />
                  </RecordField>
                  <RecordField source="statut" label="Statut" />
                  <RecordField source="lastReview" label="Dernière révision">
                    <DateField source="lastReview" />
                  </RecordField>
                </div>
              </ReferenceField>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  </Show>
);
