export const catalogRpgReadSourceName = (resource: string): string =>
    `${resource}.read.sqlrpgle`;

export const catalogRpgReadInterfaceSourceName = (
    resource: string
): string => `${resource}.read.rpgleinc`;

export const catalogIleasticSourceName = (resource: string): string =>
    `${resource}.ileastic.sqlrpgle`;

export const catalogIleasticInterfaceSourceName = (
    resource: string
): string => `${resource}.ileastic.rpgleinc`;

export const catalogBinderSourceName = (resource: string): string =>
    `${resource}.bnd`;

export const catalogServerBaseName = (serverName: string): string =>
    serverName.toLowerCase();

export const catalogServerSourceName = (serverName: string): string =>
    `${catalogServerBaseName(serverName)}.main.sqlrpgle`;
