import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-testing.json.hbs';

type CatalogTestingTemplateModel = {
    codecovModules: string[];
};

type JsonObject = Record<string, unknown>;

const isJsonObject = (value: unknown): value is JsonObject =>
    typeof value === 'object' && value !== null && !Array.isArray(value);

const parseJsonObject = (content: string): JsonObject => {
    const value: unknown = JSON.parse(content);
    if (!isJsonObject(value)) {
        throw new Error('testing.json must contain a JSON object');
    }
    return value;
};

const objectProperty = (object: JsonObject, property: string): JsonObject => {
    const value = object[property];
    return isJsonObject(value) ? value : {};
};

const stringArrayProperty = (
    object: JsonObject,
    property: string
): string[] => {
    const value = object[property];
    return Array.isArray(value)
        ? value.filter((item): item is string => typeof item === 'string')
        : [];
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogTestingTemplateModel => ({
    codecovModules: [
        catalogObjectName(spec.entity),
        ...(spec.iwsObject === undefined
            ? []
            : [catalogObjectName(spec.iwsObject)])
    ]
});

export const generateCatalogTestingConfiguration = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildTemplateModel(spec),
        templatesDirectory
    );

export const mergeCatalogTestingConfiguration = (
    existingContent: string,
    generatedContent: string
): string => {
    const existing = parseJsonObject(existingContent);
    const generated = parseJsonObject(generatedContent);
    const existingRpgunit = objectProperty(existing, 'rpgunit');
    const generatedRpgunit = objectProperty(generated, 'rpgunit');
    const existingCodecov = objectProperty(existing, 'codecov');
    const generatedCodecov = objectProperty(generated, 'codecov');
    const modules = [
        ...stringArrayProperty(existingCodecov, 'module'),
        ...stringArrayProperty(generatedCodecov, 'module')
    ];

    return `${JSON.stringify(
        {
            ...generated,
            ...existing,
            rpgunit: {
                ...generatedRpgunit,
                ...existingRpgunit,
                rucrtrpg: {
                    ...objectProperty(generatedRpgunit, 'rucrtrpg'),
                    ...objectProperty(existingRpgunit, 'rucrtrpg')
                }
            },
            codecov: {
                ...generatedCodecov,
                ...existingCodecov,
                module: [...new Set(modules)]
            }
        },
        null,
        2
    )}\n`;
};
