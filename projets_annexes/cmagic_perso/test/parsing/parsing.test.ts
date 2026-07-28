import { beforeAll, describe, expect, test } from "vitest";
import { EmptyFileSystem, type LangiumDocument } from "langium";
import { expandToString as s } from "langium/generate";
import { parseHelper } from "langium/test";
import { createCmagicServices } from "../../src/language/cmagic-module.js";
import { Model, isModel } from "../../src/language/generated/ast.js";

let services: ReturnType<typeof createCmagicServices>;
let parse: ReturnType<typeof parseHelper<Model>>;

beforeAll(async () => {
    services = createCmagicServices(EmptyFileSystem);
    parse = parseHelper<Model>(services.Cmagic);
});

describe('Parsing tests', () => {

    test('parse empty model', async () => {
        const document = await parse('');
        
        expect(checkDocumentValid(document)).toBeUndefined();
        expect(document.parseResult.value.entities).toHaveLength(0);
    });

    test('parse single entity with no fields', async () => {
        const document = await parse(`
            entity User {
            }
        `);

        expect(
            checkDocumentValid(document) || s`
                Entity: ${document.parseResult.value.entities[0]?.name}
                Fields: ${document.parseResult.value.entities[0]?.fields?.length || 0}
            `
        ).toBe(s`
            Entity: User
            Fields: 0
        `);
    });

    test('parse single entity with multiple fields', async () => {
        const document = await parse(`
            entity User {
                name: String
                age: Int
                birthDate: Date
            }
        `);

        expect(checkDocumentValid(document)).toBeUndefined();
        
        const entity = document.parseResult.value.entities[0];
        expect(entity?.name).toBe('User');
        expect(entity?.fields).toHaveLength(3);
        expect(entity?.fields?.map(f => `${f.name}: ${f.type.typeName}`)).toEqual([
            'name: String',
            'age: Int', 
            'birthDate: Date'
        ]);
    });

    test('parse multiple entities', async () => {
        const document = await parse(`
            entity User {
                name: String
                email: String
            }
            
            entity Product {
                title: String
                price: Int
                releaseDate: Date
            }
        `);

        expect(checkDocumentValid(document)).toBeUndefined();
        
        const entities = document.parseResult.value.entities;
        expect(entities).toHaveLength(2);
        
        expect(entities[0]?.name).toBe('User');
        expect(entities[0]?.fields).toHaveLength(2);
        
        expect(entities[1]?.name).toBe('Product');
        expect(entities[1]?.fields).toHaveLength(3);
    });

    test('parse entity with all supported field types', async () => {
        const document = await parse(`
            entity Example {
                textField: String
                numberField: Int
                dateField: Date
            }
        `);

        expect(checkDocumentValid(document)).toBeUndefined();
        
        const entity = document.parseResult.value.entities[0];
        expect(entity?.name).toBe('Example');
        expect(entity?.fields).toHaveLength(3);
        expect(entity?.fields?.[0]?.type.typeName).toBe('String');
        expect(entity?.fields?.[1]?.type.typeName).toBe('Int');
        expect(entity?.fields?.[2]?.type.typeName).toBe('Date');
    });

    test('parse entity with comments', async () => {
        const document = await parse(`
            // This is a user entity
            entity User {
                name: String // User's full name
                /* Multi-line comment
                   for age field */
                age: Int
            }
        `);

        expect(checkDocumentValid(document)).toBeUndefined();
        expect(document.parseResult.value.entities[0]?.name).toBe('User');
        expect(document.parseResult.value.entities[0]?.fields).toHaveLength(2);
    });

    test('handle syntax errors gracefully', async () => {
        const document = await parse(`
            entity User {
                name: InvalidType
                age Int
            }
        `);

        expect(document.parseResult.parserErrors.length).toBeGreaterThan(0);
        expect(checkDocumentValid(document)).toContain('Parser errors:');
    });

    test('parse entity with underscore and mixed case names', async () => {
        const document = await parse(`
            entity User_Profile {
                first_name: String
                lastName: String
                user_ID: Int
            }
        `);

        expect(checkDocumentValid(document)).toBeUndefined();
        expect(document.parseResult.value.entities[0]?.name).toBe('User_Profile');
        expect(document.parseResult.value.entities[0]?.fields?.map(f => f.name)).toEqual([
            'first_name', 'lastName', 'user_ID'
        ]);
    });
});

function checkDocumentValid(document: LangiumDocument): string | undefined {
    return document.parseResult.parserErrors.length && s`
        Parser errors:
          ${document.parseResult.parserErrors.map(e => e.message).join('\n  ')}
    `
        || document.parseResult.value === undefined && `ParseResult is 'undefined'.`
        || !isModel(document.parseResult.value) && `Root AST object is a ${document.parseResult.value.$type}, expected a '${Model}'.`
        || undefined;
}
 