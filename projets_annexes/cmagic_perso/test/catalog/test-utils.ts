import fs from 'node:fs';
import path from 'node:path';
import {
    buildCatalogSpecs,
    type CatalogSpec
} from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

const compileCatalogFixture = async (
    fixturePath: string,
    label: string
): Promise<CatalogSpec> => {
    const source = fs.readFileSync(
        path.resolve(fixturePath),
        'utf-8'
    );
    const compilation = buildCatalogSpecs(await parseCMagicString(source));

    if (compilation.diagnostics.length > 0 || !compilation.specs[0]) {
        throw new Error(
            `${label} fixture is invalid: ${JSON.stringify(
                compilation.diagnostics
            )}`
        );
    }
    return compilation.specs[0];
};

export const compileServiceCatalog = async (): Promise<CatalogSpec> =>
    compileCatalogFixture(
        'examples/service-catalogue.cmagic',
        'Service catalogue'
    );

export const compileIwsServiceCatalog = async (): Promise<CatalogSpec> =>
    compileCatalogFixture(
        'examples/service-catalogue-iws.cmagic',
        'IWS service catalogue'
    );

export const compileFournisseurCatalog = async (): Promise<CatalogSpec> =>
    compileCatalogFixture(
        'examples/fournisseur-catalogue-iws.cmagic',
        'Fournisseur catalogue'
    );
