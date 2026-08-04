import fs from 'node:fs';

const startMarker = '// [CMAGIC:MANUAL_START]';
const endMarker = '// [CMAGIC:MANUAL_END]';

export const extractManualCode = (filePath: string): string | null => {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }

        const existingContent = fs.readFileSync(filePath, 'utf-8');
        const startIndex = existingContent.indexOf(startMarker);
        const endIndex = existingContent.indexOf(endMarker, startIndex);

        if (startIndex === -1 || endIndex === -1) {
            return null;
        }

        return existingContent.substring(
            startIndex + startMarker.length,
            endIndex
        );
    } catch (error) {
        console.warn(
            `Attention: Impossible de lire le fichier existant ${filePath}:`,
            error
        );
        return null;
    }
};

export const injectManualCode = (
    generatedContent: string,
    manualCode: string
): string => {
    const startIndex = generatedContent.indexOf(startMarker);
    const endIndex = generatedContent.indexOf(endMarker, startIndex);

    if (startIndex === -1 || endIndex === -1) {
        return generatedContent;
    }

    return (
        generatedContent.substring(0, startIndex + startMarker.length) +
        manualCode +
        generatedContent.substring(endIndex)
    );
};
