import type {
    Entity,
    IleasticServer,
    Model
} from '../language/generated/ast.js';
import {
    isIbmIObjectName,
    isSameIbmIObjectName,
    normalizeIbmIObjectName
} from './ibmi-object-name.js';
import type { CatalogSpec } from './catalog-spec.js';
import type {
    CatalogServerCatalogSpec,
    CatalogServerCompilation,
    CatalogServerDiagnostic,
    CatalogServerDiagnosticCode,
    CatalogServerSpec
} from './server-spec.js';

const diagnostic = (
    code: CatalogServerDiagnosticCode,
    server: IleasticServer,
    message: string,
    entity?: Entity
): CatalogServerDiagnostic => ({
    severity: 'error',
    code,
    message,
    server: server.name,
    ...(entity === undefined ? {} : { entity: entity.name })
});

const compileServer = (
    server: IleasticServer,
    catalogsByEntity: ReadonlyMap<string, CatalogSpec>
): { spec?: CatalogServerSpec; diagnostics: CatalogServerDiagnostic[] } => {
    const diagnostics: CatalogServerDiagnostic[] = [];
    const objectName = normalizeIbmIObjectName(server.objectName);

    if (!isIbmIObjectName(objectName)) {
        diagnostics.push(
            diagnostic(
                'CATALOG_SERVER_OBJECT_INVALID',
                server,
                `L'objet du serveur ${objectName || 'vide'} doit être un nom système IBM i de 1 à 10 caractères.`
            )
        );
    }
    if (
        !Number.isInteger(server.port) ||
        server.port < 1 ||
        server.port > 65535
    ) {
        diagnostics.push(
            diagnostic(
                'CATALOG_SERVER_PORT_INVALID',
                server,
                `Le port du serveur ${server.name} doit être un entier compris entre 1 et 65535.`
            )
        );
    }
    if (server.entities.length === 0) {
        diagnostics.push(
            diagnostic(
                'CATALOG_SERVER_EMPTY',
                server,
                `Le serveur ${server.name} doit publier au moins une entité catalogue.`
            )
        );
    }

    const seenEntities = new Set<string>();
    const catalogs: CatalogServerCatalogSpec[] = [];

    for (const entityReference of server.entities) {
        const entity = entityReference.ref;
        if (!entity) {
            continue;
        }
        if (seenEntities.has(entity.name)) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_SERVER_CATALOG_DUPLICATE',
                    server,
                    `L'entité ${entity.name} ne peut être publiée qu'une fois par serveur.`,
                    entity
                )
            );
            continue;
        }
        seenEntities.add(entity.name);

        const catalog = catalogsByEntity.get(entity.name);
        if (!catalog) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_SERVER_CATALOG_REQUIRED',
                    server,
                    `L'entité ${entity.name} doit compiler vers un CatalogSpec avant d'être publiée.`,
                    entity
                )
            );
            continue;
        }
        if (!catalog.ileasticObject) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_SERVER_ILEASTIC_OBJECT_REQUIRED',
                    server,
                    `L'entité ${entity.name} doit déclarer ileasticObject pour être liée au serveur.`,
                    entity
                )
            );
            continue;
        }

        const readObject = normalizeIbmIObjectName(catalog.entity);
        if (
            isSameIbmIObjectName(objectName, readObject) ||
            isSameIbmIObjectName(objectName, catalog.ileasticObject)
        ) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_SERVER_OBJECT_COLLISION',
                    server,
                    `L'objet programme ${objectName} doit être distinct des objets de ${entity.name}.`,
                    entity
                )
            );
            continue;
        }

        catalogs.push({
            entity: catalog.entity,
            resource: catalog.resource,
            readObject,
            ileasticObject: catalog.ileasticObject
        });
    }

    if (diagnostics.length > 0) {
        return { diagnostics };
    }

    return {
        spec: {
            version: 1,
            name: server.name,
            object: objectName,
            port: server.port,
            host: server.host ?? '*ANY',
            catalogs
        },
        diagnostics
    };
};

export const buildCatalogServerSpecs = (
    model: Model,
    catalogs: readonly CatalogSpec[]
): CatalogServerCompilation => {
    const catalogsByEntity = new Map(
        catalogs.map(catalog => [catalog.entity, catalog])
    );
    const compilation = model.servers.map(server =>
        compileServer(server, catalogsByEntity)
    );

    return {
        specs: compilation.flatMap(result =>
            result.spec === undefined ? [] : [result.spec]
        ),
        diagnostics: compilation.flatMap(result => result.diagnostics)
    };
};
