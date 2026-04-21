import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { RecordField } from '@/components/admin/record-field';
import { NumberField } from '@/components/admin/number-field';
import { DateField } from '@/components/admin/date-field';
import { ReferenceField } from '@/components/admin/reference-field';

export const CustomerRisqueTab = () => (
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
);