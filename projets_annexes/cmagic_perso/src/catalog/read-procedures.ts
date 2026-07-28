import type { CatalogSpec } from './catalog-spec.js';

export type CatalogReadProcedures = {
    hasList: boolean;
    hasGet: boolean;
    rejectQuery: string;
    search: string;
    getSupportedFields: string;
    get: string;
    exports: string[];
};

export const catalogReadProcedures = (
    spec: CatalogSpec
): CatalogReadProcedures => {
    const prefix = spec.entity.toLowerCase();
    const hasList = spec.capabilities.includes('list');
    const hasGet = spec.capabilities.includes('get');
    const search = `${prefix}_search`;
    const getSupportedFields = `${prefix}_getSupportedFields`;
    const get = `${prefix}_get`;

    return {
        hasList,
        hasGet,
        rejectQuery: `${prefix}_reject_query`,
        search,
        getSupportedFields,
        get,
        exports: [
            ...(hasList ? [search, getSupportedFields] : []),
            ...(hasGet ? [get] : [])
        ]
    };
};
