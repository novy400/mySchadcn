import type { CatalogSpec } from './catalog-spec.js';

export type CatalogReadProcedures = {
    hasList: boolean;
    hasGet: boolean;
    hasCreate: boolean;
    hasUpdate: boolean;
    hasDelete: boolean;
    hasCreateOrUpdate: boolean;
    hasMutation: boolean;
    rejectQuery: string;
    rejectMutation: string;
    search: string;
    getSupportedFields: string;
    get: string;
    create: string;
    update: string;
    delete: string;
    isValid: string;
    isValidBusiness: string;
    exports: string[];
};

export const catalogReadProcedures = (
    spec: CatalogSpec
): CatalogReadProcedures => {
    const prefix = spec.entity.toLowerCase();
    const hasList = spec.capabilities.includes('list');
    const hasGet = spec.capabilities.includes('get');
    const hasCreate = spec.capabilities.includes('create');
    const hasUpdate = spec.capabilities.includes('update');
    const hasDelete = spec.capabilities.includes('delete');
    const hasCreateOrUpdate = hasCreate || hasUpdate;
    const hasMutation = hasCreateOrUpdate || hasDelete;
    const search = `${prefix}_search`;
    const getSupportedFields = `${prefix}_getSupportedFields`;
    const get = `${prefix}_get`;
    const create = `${prefix}_create`;
    const update = `${prefix}_update`;
    const deleteProcedure = `${prefix}_delete`;
    const isValid = `${prefix}_isValid`;

    return {
        hasList,
        hasGet,
        hasCreate,
        hasUpdate,
        hasDelete,
        hasCreateOrUpdate,
        hasMutation,
        rejectQuery: `${prefix}_reject_query`,
        rejectMutation: `${prefix}_reject_mutation`,
        search,
        getSupportedFields,
        get,
        create,
        update,
        delete: deleteProcedure,
        isValid,
        isValidBusiness: `${prefix}_isValid_business`,
        exports: [
            ...(hasList ? [search, getSupportedFields] : []),
            ...(hasGet ? [get] : []),
            ...(hasCreate
                ? [
                      create,
                      isValid,
                      ...(hasUpdate ? [update] : []),
                      ...(hasDelete ? [deleteProcedure] : [])
                  ]
                : hasUpdate
                  ? [
                        update,
                        isValid,
                        ...(hasDelete ? [deleteProcedure] : [])
                    ]
                  : hasDelete
                    ? [deleteProcedure, isValid]
                    : [])
        ]
    };
};
