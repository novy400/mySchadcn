// Debug test for boolean values
import { EmptyFileSystem } from "langium";
import { createCmagicServices } from "./out/language/cmagic-module.js";
import { Model } from './out/language/generated/ast.js';
import { parseHelper } from "langium/test";

const services = createCmagicServices(EmptyFileSystem);
const parse = parseHelper<Model>(services.Cmagic);

const dslInput = `
    entity BooleanTest {
        id: Int required
        isActive: Boolean default (true)
        isDeleted: Boolean default (false)
    }
`;

const document = await parse(dslInput);
await services.shared.workspace.DocumentBuilder.build([document], { validation: true });

const model = document.parseResult.value;
const entity = model.entities[0];
const boolField = entity.fields.find(f => f.name === 'isActive');

if (boolField && boolField.default && boolField.default.value) {
    const defaultVal = boolField.default.value;
    console.log('booleanValue:', JSON.stringify(defaultVal.booleanValue));
    console.log('typeof booleanValue:', typeof defaultVal.booleanValue);
    console.log('booleanValue.toString():', defaultVal.booleanValue?.toString());
}
