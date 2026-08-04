export const catalogRpgReadSourceName = (resource: string): string =>
    `${resource}.read.sqlrpgle`;

export const catalogRpgReadInterfaceSourceName = (
    resource: string
): string => `${resource}.read.rpgleinc`;

export const catalogRpgReadTestSourceName = (entity: string): string =>
    `${entity.toLowerCase()}.test.sqlrpgle`;

export const catalogIleasticSourceName = (resource: string): string =>
    `${resource}.ileastic.sqlrpgle`;

export const catalogIleasticInterfaceSourceName = (
    resource: string
): string => `${resource}.ileastic.rpgleinc`;

export const catalogIwsSourceName = (resource: string): string =>
    `${resource}.iws.sqlrpgle`;

export const catalogIwsInterfaceSourceName = (
    resource: string
): string => `${resource}.iws.rpgleinc`;

export const catalogIwsTestSourceName = (iwsObject: string): string =>
    `${iwsObject.toLowerCase()}.test.sqlrpgle`;

export const catalogIwsBinderSourceName = (resource: string): string =>
    `${resource}.iws.bnd`;

export const catalogIwsBindingDirectorySourceName = (
    resource: string
): string => `${resource}.iws.bnddir`;

export const catalogBinderSourceName = (resource: string): string =>
    `${resource}.bnd`;

export const catalogServerBaseName = (serverName: string): string =>
    serverName.toLowerCase();

export const catalogServerSourceName = (serverName: string): string =>
    `${catalogServerBaseName(serverName)}.main.sqlrpgle`;
