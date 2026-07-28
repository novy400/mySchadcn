import { describe, test, expect } from 'vitest';
import { parseCMagicString } from './test-utils.js';
import { generateRpgService } from '../../src/cli/generator.js';
import fs from 'fs';
import path from 'path';

describe('Protected Zones - Code Preservation Sprint 02', () => {
    test('should preserve manual code during regeneration', async () => {
        const dslInput = `
entity TestPreservation {
    id: Int required
}

operations for TestPreservation {
    CREATE
}`;

        // Parse le DSL
        const model = await parseCMagicString(dslInput);
        const entity = model.entities[0];
        const operations = ['CREATE'];
        
        // Créer le répertoire de test qui correspond au pattern CLI
        const testDir = path.join(process.cwd(), 'generated');
        const entityDir = path.join(testDir, 'testpreservation');
        const serviceFilePath = path.join(entityDir, 'testpreservation.sqlrpgle');
        
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir, { recursive: true });
        }
        if (!fs.existsSync(entityDir)) {
            fs.mkdirSync(entityDir, { recursive: true });
        }
        
        // 1. Première génération
        const firstGeneration = generateRpgService(entity, operations, model, 'test.cmagic');
        fs.writeFileSync(serviceFilePath, firstGeneration);
        
        // 2. Modifier le code manuel
        let modifiedContent = fs.readFileSync(serviceFilePath, 'utf-8');
        
        const customCode = `
// *** CODE MANUEL PERSONNALISÉ ***
DCL-S businessVar VARCHAR(100);

DCL-PROC testpreservation_create_local;
  DCL-PI *N IND;
    detail LIKEDS(testpreservation_detail_t) CONST;
    id LIKEDS(testpreservation_id_t);
    errors LIKEDS(GLOBAL_listError);
  END-PI;
  
  businessVar = 'Custom logic added by developer';
  CLEAR id;
  CLEAR errors;
  RETURN *ON;
END-PROC;

`;
        
        const startMarker = '// [CMAGIC:MANUAL_START]';
        const endMarker = '// [CMAGIC:MANUAL_END]';
        
        const startIndex = modifiedContent.indexOf(startMarker);
        const endIndex = modifiedContent.indexOf(endMarker);
        
        modifiedContent = 
            modifiedContent.substring(0, startIndex + startMarker.length) + 
            customCode + 
            modifiedContent.substring(endIndex);
        
        fs.writeFileSync(serviceFilePath, modifiedContent);
        
        // 3. Re-génération
        const secondGeneration = generateRpgService(entity, operations, model, 'test.cmagic');
        
        // 4. Vérifications
        expect(secondGeneration).toContain('CODE MANUEL PERSONNALISÉ');
        expect(secondGeneration).toContain('businessVar VARCHAR(100)');
        expect(secondGeneration).toContain('Custom logic added by developer');
        
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true });
        }
    });
});
