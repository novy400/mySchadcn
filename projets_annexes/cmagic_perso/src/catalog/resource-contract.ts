import type { CatalogSpec } from './catalog-spec.js';

export type GeneratedResourceCapability = 'read';

export type GeneratedResourceContract = {
    kind: 'entity';
    identifier: 'id';
    fields: string[];
    capabilities: GeneratedResourceCapability[];
    list?: {
        filters: string[];
        sortFields: string[];
    };
};

const hasReadCapability = (spec: CatalogSpec): boolean =>
    spec.capabilities.includes('list') || spec.capabilities.includes('get');

export const generateResourceContract = (
    spec: CatalogSpec
): GeneratedResourceContract => {
    const contract: GeneratedResourceContract = {
        kind: 'entity',
        identifier: spec.identifier,
        fields: spec.fields.map(field => field.name),
        capabilities: hasReadCapability(spec) ? ['read'] : []
    };

    if (spec.list) {
        contract.list = {
            filters: [
                ...(spec.list.searchFields.length > 0 ? ['q'] : []),
                ...spec.list.filterFields
            ],
            sortFields: [...spec.list.sortFields]
        };
    }

    return contract;
};

export const generateResourceContractSource = (spec: CatalogSpec): string => {
    const exportName = `${spec.resource.replace(
        /[^a-zA-Z0-9_$]/g,
        '_'
    )}ResourceContract`;
    const contract = JSON.stringify(generateResourceContract(spec), null, 2);

    return `export const ${exportName} = ${contract} as const;\n`;
};
