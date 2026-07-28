import fs from 'node:fs';
import path from 'node:path';
import {
    buildCatalogSpecs,
    type CatalogSpec
} from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

export const compileServiceCatalog = async (): Promise<CatalogSpec> => {
    const source = fs.readFileSync(
        path.resolve('examples/service-catalogue.cmagic'),
        'utf-8'
    );
    const compilation = buildCatalogSpecs(await parseCMagicString(source));

    if (compilation.diagnostics.length > 0 || !compilation.specs[0]) {
        throw new Error(
            `Service catalogue fixture is invalid: ${JSON.stringify(
                compilation.diagnostics
            )}`
        );
    }
    return compilation.specs[0];
};
