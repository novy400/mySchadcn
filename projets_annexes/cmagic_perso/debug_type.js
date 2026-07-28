import { services } from './out/src/cli/main.js';
import fs from 'fs';

// Lire le fichier de test
const content = fs.readFileSync('prd_customer_test.cmagic', 'utf-8');

// Parser le document
const document = services.shared.workspace.LangiumDocuments.getOrCreateDocument({
  uri: 'file:///test.cmagic',
  text: content
});

const model = document.parseResult.value;

// Analyser l'entité Customer
const customer = model.entities.find(e => e.name === 'Customer');
const addressField = customer.fields.find(f => f.name === 'address');

console.log('=== Address field type analysis ===');
console.log('Field name:', addressField.name);
console.log('Type object:', JSON.stringify(addressField.type, null, 2));
console.log('Type typename:', addressField.type.typeName);

// Analyser la structure Address
console.log('\n=== Structs in model ===');
model.structs.forEach(struct => {
  console.log(`Struct: ${struct.name}`);
  struct.fields.forEach(field => {
    console.log(`  - ${field.name}: ${field.type.typeName}`);
  });
});

console.log('\n=== Template context simulation ===');
const templateContext = {
  name: customer.name,
  fields: customer.fields.map(f => ({
    name: f.name,
    type: f.type
  }))
};

console.log('Template context:', JSON.stringify(templateContext, null, 2));
