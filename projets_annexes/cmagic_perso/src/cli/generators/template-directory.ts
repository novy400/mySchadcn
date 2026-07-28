import fs from 'node:fs';
import path from 'node:path';

export const resolveTemplatesDirectory = (templatesDirectory?: string): string => {
    if (templatesDirectory) {
        return templatesDirectory;
    }

    const candidates = [
        path.resolve(process.cwd(), 'src', 'templates'),
        path.resolve(process.cwd(), 'out', 'templates')
    ];
    const discoveredDirectory = candidates.find(candidate => fs.existsSync(candidate));

    if (!discoveredDirectory) {
        throw new Error(
            `CMagic templates not found. Checked: ${candidates.join(', ')}`
        );
    }

    return discoveredDirectory;
};
