import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { RecordField } from '@/components/admin/record-field';
import { EmailField } from '@/components/admin/email-field';
import { ReferenceField } from '@/components/admin/reference-field';

export const CustomerSignalietiqueTab = () => (
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
);