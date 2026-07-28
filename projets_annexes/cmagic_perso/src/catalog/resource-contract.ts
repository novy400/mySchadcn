import type { CatalogCapability, CatalogSpec } from './catalog-spec.js';

export type GeneratedResourceCapability = 'read' | 'create' | 'update' | 'delete';

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

const toResourceCapabilities = (
    capabilities: CatalogCapability[]
): GeneratedResourceCapability[] => {
    const generated: GeneratedResourceCapability[] = [];

    if (capabilities.includes('list') || capabilities.includes('get')) {
        generated.push('read');
    }
    if (capabilities.includes('create')) {
        generated.push('create');
    }
    if (capabilities.includes('update')) {
        generated.push('update');
    }
    if (capabilities.includes('delete')) {
        generated.push('delete');
    }

    return generated;
};

export const generateResourceContract = (
    spec: CatalogSpec
): GeneratedResourceContract => {
    const contract: GeneratedResourceContract = {
        kind: 'entity',
        identifier: spec.identifier,
        fields: spec.fields.map(field => field.name),
        capabilities: toResourceCapabilities(spec.capabilities)
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
