import { describe, test, expect } from 'vitest';
import { generateRpgServiceFromString } from './test-utils.js';

describe('Sprint 02 - Services CRUD avec Operations', () => {
    describe('Service Generation', () => {
        test('should generate service file with CREATE operation', async () => {
            const dslInput = `
entity Customer {
    id: Int required,
    name: String(80) required
}

operations for Customer {
    CREATE
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            // Vérifier les procédures API publiques
            expect(generatedRpg).toContain('dcl-proc customer_create export;');
            
            // Vérifier les procédures locales
            expect(generatedRpg).toContain('dcl-proc customer_create_local;');
        });

        test('should generate all CRUD operations in service', async () => {
            const dslInput = `
entity Customer {
    id: Int required,
    name: String(80) required
}

operations for Customer {
    CREATE,
    CHANGE,
    DELETE,
    DISPLAY,
    SEARCH
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            // Vérifier les procédures API publiques
            expect(generatedRpg).toContain('dcl-proc customer_create export;');
            expect(generatedRpg).toContain('dcl-proc customer_change export;');
            expect(generatedRpg).toContain('dcl-proc customer_delete export;');
            expect(generatedRpg).toContain('dcl-proc customer_display export;');
            expect(generatedRpg).toContain('dcl-proc customer_search export;');
            
            // Vérifier les procédures locales
            expect(generatedRpg).toContain('dcl-proc customer_create_local;');
            expect(generatedRpg).toContain('dcl-proc customer_change_local;');
            expect(generatedRpg).toContain('dcl-proc customer_delete_local;');
            expect(generatedRpg).toContain('dcl-proc customer_display_local;');
            expect(generatedRpg).toContain('dcl-proc customer_search_local;');
        });

        test('should include protected zones markers', async () => {
            const dslInput = `
entity Customer {
    id: Int required
}

operations for Customer {
    CREATE
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            expect(generatedRpg).toContain('// [CMAGIC:MANUAL_START]');
            expect(generatedRpg).toContain('// [CMAGIC:MANUAL_END]');
        });

        test('should generate delegation pattern', async () => {
            const dslInput = `
entity Customer {
    id: Int required
}

operations for Customer {
    CREATE
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            // Vérifier la délégation API publique -> locale
            expect(generatedRpg).toContain('if not customer_create_local(pDetail:lId:lErrors);');
        });

        test('should include all necessary headers', async () => {
            const dslInput = `
entity Customer {
    id: Int required
}

operations for Customer {
    CREATE
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            expect(generatedRpg).toContain("// Customer Service - Code unifié (généré + manuel)");
            expect(generatedRpg).toContain("/include 'customer.rpgleinc'");
            expect(generatedRpg).toContain("ctl-opt nomain");
            expect(generatedRpg).toContain("bnddir('QC2LE':'CKOOL');");
        });

        test('should generate valid RPG procedure structure', async () => {
            const dslInput = `
entity Customer {
    id: Int required
}

operations for Customer {
    CREATE
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            // Vérifier structure procédure RPG
            expect(generatedRpg).toContain('dcl-proc customer_create export;');
            expect(generatedRpg).toContain('dcl-pi *N ind;');
            expect(generatedRpg).toContain('end-pi;');
            expect(generatedRpg).toContain('end-proc;');
        });
    });

    describe('Pattern Convention _local', () => {
        test('should use _local suffix for internal procedures', async () => {
            const dslInput = `
entity Customer {
    id: Int required
}

operations for Customer {
    CREATE,
    DISPLAY
}`;

            const generatedRpg = await generateRpgServiceFromString(dslInput, 'Customer');
            
            // Vérifier convention nommage _local
            expect(generatedRpg).toContain('customer_create_local(');
            expect(generatedRpg).toContain('customer_display_local(');
            
            // Les procédures _local ne doivent pas être export
            expect(generatedRpg).not.toContain('dcl-proc customer_create_local export;');
            expect(generatedRpg).not.toContain('dcl-proc customer_display_local export;');
        });
    });
});
