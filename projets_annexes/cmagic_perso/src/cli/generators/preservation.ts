
import * as fs from 'node:fs';

/**
 * Extrait le code manuel d'un fichier existant entre les marqueurs CMAGIC:MANUAL_START et CMAGIC:MANUAL_END
 * @param filePath Chemin vers le fichier existant
 * @returns Le code manuel existant ou null si pas trouvé
 */
export function extractManualCode(filePath: string): string | null {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }

        const existingContent = fs.readFileSync(filePath, 'utf-8');

        const startMarker = '// [CMAGIC:MANUAL_START]';
        const endMarker = '// [CMAGIC:MANUAL_END]';

        const startIndex = existingContent.indexOf(startMarker);
        const endIndex = existingContent.indexOf(endMarker);

        if (startIndex === -1 || endIndex === -1) {
            return null;
        }

        // Extraire le contenu entre les marqueurs (sans inclure les marqueurs eux-mêmes)
        const manualCode = existingContent.substring(
            startIndex + startMarker.length,
            endIndex
        );

        return manualCode;
    } catch (error) {
        console.warn(`Attention: Impossible de lire le fichier existant ${filePath}:`, error);
        return null;
    }
}

/**
 * Injecte le code manuel dans le contenu généré
 * @param generatedContent Contenu généré par le template
 * @param manualCode Code manuel à préserver
 * @returns Contenu avec le code manuel injecté
 */
export function injectManualCode(generatedContent: string, manualCode: string): string {
    const startMarker = '// [CMAGIC:MANUAL_START]';
    const endMarker = '// [CMAGIC:MANUAL_END]';

    const startIndex = generatedContent.indexOf(startMarker);
    const endIndex = generatedContent.indexOf(endMarker);

    if (startIndex === -1 || endIndex === -1) {
        return generatedContent;
    }

    // Remplacer le contenu entre les marqueurs par le code manuel
    const before = generatedContent.substring(0, startIndex + startMarker.length);
    const after = generatedContent.substring(endIndex);

    return before + manualCode + after;
}
