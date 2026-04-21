import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { RecordField } from '@/components/admin/record-field';

export const CustomerGeneralTab = () => (
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
);
