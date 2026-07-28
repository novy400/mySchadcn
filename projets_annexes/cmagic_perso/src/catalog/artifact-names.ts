export const catalogRpgReadSourceName = (resource: string): string =>
    `${resource}.read.sqlrpgle`;

export const catalogRpgReadInterfaceSourceName = (
    resource: string
): string => `${resource}.read.rpgleinc`;

export const catalogBinderSourceName = (resource: string): string =>
    `${resource}.bnd`;
