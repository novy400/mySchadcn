import fs from 'node:fs';
import path from 'node:path';
import Handlebars from 'handlebars';
import { resolveTemplatesDirectory } from './template-directory.js';

export const renderTemplate = <Context extends object>(
    templateName: string,
    context: Context,
    templatesDirectory?: string
): string => {
    const templatePath = path.join(
        resolveTemplatesDirectory(templatesDirectory),
        templateName
    );
    const templateSource = fs.readFileSync(templatePath, 'utf-8');
    const template = Handlebars.compile(templateSource, { noEscape: true });
    return template(context);
};
