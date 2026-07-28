import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogIleasticInterfaceSourceName,
    catalogServerSourceName
} from './artifact-names.js';
import { catalogIleasticRegisterRoutesProcedure } from './ileastic.js';
import type { CatalogServerSpec } from './server-spec.js';

const mainTemplateName = 'catalog-server.main.sqlrpgle.hbs';
const rulesTemplateName = 'catalog-server.Rules.mk.hbs';
const projectRulesTemplateName = 'catalog-project.Rules.mk.hbs';

type CatalogServerMainTemplateModel = {
    objectName: string;
    port: number;
    host: string;
    catalogs: Array<{
        interfaceSource: string;
        registerRoutes: string;
    }>;
};

type CatalogServerRulesTemplateModel = {
    serverName: string;
    objectName: string;
    source: string;
    catalogs: Array<{
        ileasticObject: string;
        readObject: string;
    }>;
};

const buildMainTemplateModel = (
    spec: CatalogServerSpec
): CatalogServerMainTemplateModel => ({
    objectName: spec.object,
    port: spec.port,
    host: spec.host.replaceAll("'", "''"),
    catalogs: spec.catalogs.map(catalog => ({
        interfaceSource: catalogIleasticInterfaceSourceName(catalog.resource),
        registerRoutes: catalogIleasticRegisterRoutesProcedure(catalog.entity)
    }))
});

const buildRulesTemplateModel = (
    spec: CatalogServerSpec
): CatalogServerRulesTemplateModel => ({
    serverName: spec.name,
    objectName: spec.object,
    source: catalogServerSourceName(spec.name),
    catalogs: spec.catalogs.map(catalog => ({
        ileasticObject: catalog.ileasticObject,
        readObject: catalog.readObject
    }))
});

export const generateCatalogServerMain = (
    spec: CatalogServerSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        mainTemplateName,
        buildMainTemplateModel(spec),
        templatesDirectory
    );

export const generateCatalogServerRules = (
    spec: CatalogServerSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        rulesTemplateName,
        buildRulesTemplateModel(spec),
        templatesDirectory
    );

export const generateCatalogProjectRules = (
    subdirectories: readonly string[],
    templatesDirectory?: string
): string =>
    renderTemplate(
        projectRulesTemplateName,
        { subdirectories: [...subdirectories] },
        templatesDirectory
    );
