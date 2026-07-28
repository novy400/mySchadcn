/**
 * Tests d'intégration Phase 4 - Validation du PRD Sprint 02
 * 
 * Tests complets pour valider tous les cas d'usage PRD avec le modèle Customer complet
 */

import { afterAll, beforeAll, describe, expect, test } from 'vitest';
import fs from 'fs';
import os from 'node:os';
import path from 'node:path';
import { generateCode } from '../../src/cli/generator.js';
import { parseCMagicString } from '../generating/test-utils.js';

describe('Phase 4 - PRD Integration Tests', () => {
    const prdFile = path.resolve('prd_customer_test.cmagic');
    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'cmagic-prd-'));
    const generatedDirectory = path.join(temporaryDirectory, 'generated');
    const customerFile = (fileName: string): string =>
        path.join(generatedDirectory, 'customer', fileName);

    beforeAll(async () => {
        const model = await parseCMagicString(fs.readFileSync(prdFile, 'utf-8'));
        generateCode(model, prdFile, generatedDirectory);
    });

    afterAll(() => {
        fs.rmSync(temporaryDirectory, { recursive: true, force: true });
    });
    
    test('should have generated complete Customer model files', () => {
        // Vérifier que tous les fichiers attendus sont générés
        const expectedFiles = [
            customerFile('customer.rpgleinc'),
            customerFile('customer.sqlrpgle'),
            customerFile('customer.sql'),
            customerFile('customer.test.sqlrpgle')
        ];
        
        expectedFiles.forEach(file => {
            expect(fs.existsSync(file)).toBe(true);
            const stats = fs.statSync(file);
            expect(stats.size).toBeGreaterThan(0); // Fichier non vide
        });
    });

    test('should generate complete RPG copybook with all PRD structures', () => {
        const generatedFile = customerFile('customer.rpgleinc');
        expect(fs.existsSync(generatedFile)).toBe(true);
        
        const content = fs.readFileSync(generatedFile, 'utf-8');
        
        // Vérifier les structures Customer complètes avec TOUS les champs PRD
        expect(content).toMatch(/dcl-ds customer_t qualified template/);
        expect(content).toMatch(/id INT\(10\)/);
        expect(content).toMatch(/code VARCHAR\(10\)/);
        expect(content).toMatch(/name VARCHAR\(80\)/);
        expect(content).toMatch(/address LIKEDS\(customer_address_t\)/);
        expect(content).toMatch(/phone VARCHAR\(20\)/);
        expect(content).toMatch(/email VARCHAR\(100\)/);
        expect(content).toMatch(/status VARCHAR\(20\)/);
        expect(content).toMatch(/creationdate DATE/);
        expect(content).toMatch(/creditlimit PACKED\(15:2\)/);
        expect(content).toMatch(/isvip IND/);
        
        // Vérifier les structures Address COMPLÈTES
        expect(content).toMatch(/dcl-ds customer_address_t qualified template/);
        expect(content).toMatch(/ligne1 VARCHAR\(50\)/);
        expect(content).toMatch(/ligne2 VARCHAR\(50\)/);
        expect(content).toMatch(/codepostal VARCHAR\(10\)/);
        expect(content).toMatch(/ville VARCHAR\(50\)/);
        expect(content).toMatch(/pays VARCHAR\(3\) INZ\('FR'\)/);
        
        // Vérifier les énumérations CustomerStatus COMPLÈTES
        expect(content).toMatch(/dcl-enum customerstatus qualified/);
        expect(content).toMatch(/active 'active'/);
        expect(content).toMatch(/inactive 'inactive'/);
        expect(content).toMatch(/suspended 'suspended'/);
    });

    test('should generate complete RPG service with pattern unifié PRD', () => {
        const generatedFile = customerFile('customer.sqlrpgle');
        expect(fs.existsSync(generatedFile)).toBe(true);
        
        const content = fs.readFileSync(generatedFile, 'utf-8');
        
        // Vérifier le pattern double couche (API publique) conforme PRD
        expect(content).toMatch(/dcl-proc customer_create export/);
        expect(content).toMatch(/dcl-proc customer_display export/);
        expect(content).toMatch(/dcl-proc customer_change export/);
        expect(content).toMatch(/dcl-proc customer_delete export/);
        expect(content).toMatch(/dcl-proc customer_search export/);
        
        // Vérifier les zones protégées du pattern PRD
        expect(content).toMatch(/\[CMAGIC:MANUAL_START\]/);
        expect(content).toMatch(/\[CMAGIC:MANUAL_END\]/);
        
        // Vérifier la délégation vers les procédures locales (pattern PRD)
        expect(content).toMatch(/customer_create_local/);
        expect(content).toMatch(/customer_display_local/);
        expect(content).toMatch(/customer_change_local/);
        expect(content).toMatch(/customer_delete_local/);
        expect(content).toMatch(/customer_search_local/);
        
        // Vérifier la signature des API publiques conforme PRD
        expect(content).toMatch(/pDetail likeds\(customer_detail_t\) const/);
        expect(content).toMatch(/pId likeDS\(customer_id_t\)/);
        expect(content).toMatch(/pErrors likeDS\(GLOBAL_listError\)/);
    });

    test('should generate dynamic validation for ALL real Customer fields', () => {
        const generatedFile = customerFile('customer.sqlrpgle');
        const content = fs.readFileSync(generatedFile, 'utf-8');
        
        // Validation des champs obligatoires réels (plus de hardcodé !)
        expect(content).toMatch(/\/\/ id is mandatory/);
        expect(content).toMatch(/if pAfterDetail\.detail\.id <= 0/);
        
        expect(content).toMatch(/\/\/ code is mandatory/);
        expect(content).toMatch(/if pAfterDetail\.detail\.code = \*blanks/);
        
        expect(content).toMatch(/\/\/ name is mandatory/);
        expect(content).toMatch(/if pAfterDetail\.detail\.name = \*blanks/);
        
        expect(content).toMatch(/\/\/ creationDate is mandatory/);
        expect(content).toMatch(/if pAfterDetail\.detail\.creationDate = d'0001-01-01'/);
        
        // Validation spécialisée email (détection automatique)
        expect(content).toMatch(/\/\/ Email format validation/);
        expect(content).toMatch(/%scan\('@': pAfterDetail\.detail\.email\)/);
        
        // Validation limite de crédit (détection automatique)
        expect(content).toMatch(/\/\/ Credit limit must be positive/);
        expect(content).toMatch(/if pAfterDetail\.detail\.creditLimit < 0/);
        
        // Validation structure Address (champs obligatoires)
        expect(content).toMatch(/\/\/ address\.ligne1 is mandatory/);
        expect(content).toMatch(/if pAfterDetail\.detail\.address\.ligne1 = \*blanks/);
        
        // Validation PLUS générique : adaptée aux champs réels
        expect(content).not.toMatch(/hardcoded validation/);
        expect(content).not.toMatch(/generic field validation/);
    });

    test('should generate complete SQL DDL with expanded Address fields', () => {
        const generatedFile = customerFile('customer.sql');
        expect(fs.existsSync(generatedFile)).toBe(true);
        
        const content = fs.readFileSync(generatedFile, 'utf-8');
        
        // Vérifier la table avec tous les champs PRD (nom correct : CUSTOMER, pas CUSTOMERP)
        expect(content).toMatch(/CREATE (?:OR REPLACE )?TABLE CUSTOMER/);
        expect(content).toMatch(/ID INTEGER NOT NULL/);
        expect(content).toMatch(/CODE VARCHAR\(10\) NOT NULL/);
        expect(content).toMatch(/NAME VARCHAR\(80\) NOT NULL/);
        expect(content).toMatch(/CREATIONDATE DATE NOT NULL/);
        expect(content).toMatch(/CREDITLIMIT DECIMAL\(15,2\)/);
        expect(content).toMatch(/ISVIP CHAR\(1\)/);
        
        // Champs Address dépliés en SQL (expansion struct → champs plats)
        expect(content).toMatch(/ADDRESS_LIGNE1 VARCHAR\(50\) NOT NULL/);
        expect(content).toMatch(/ADDRESS_LIGNE2 VARCHAR\(50\)/);
        expect(content).toMatch(/ADDRESS_CODEPOSTAL VARCHAR\(10\)/);
        expect(content).toMatch(/ADDRESS_VILLE VARCHAR\(50\)/);
        expect(content).toMatch(/ADDRESS_PAYS VARCHAR\(3\) DEFAULT 'FR'/);
        
        // Contraintes business
        expect(content).toMatch(/PRIMARY KEY \(ID\)/);
        expect(content).toMatch(/CHECK \(ISVIP IN \('Y', 'N'\)\)/);
    });

    test('should generate complete unit tests with all CRUD operations', () => {
        const generatedFile = customerFile('customer.test.sqlrpgle');
        expect(fs.existsSync(generatedFile)).toBe(true);
        
        const content = fs.readFileSync(generatedFile, 'utf-8');
        
        // Vérifier les tests pour toutes les opérations CRUD (noms corrects générés)
        expect(content).toMatch(/dcl-proc test_customer_create_success export/);
        expect(content).toMatch(/dcl-proc test_customer_getByID_success export/);
        expect(content).toMatch(/dcl-proc test_customer_change_success export/);
        expect(content).toMatch(/dcl-proc test_customer_delete_success export/);
        expect(content).toMatch(/dcl-proc test_customer_search_firstPage export/);
        
        // Tests de validation métier spécialisée
        expect(content).toMatch(/dcl-proc test_customer_create_validation_error export/);
        
        // Tests cas d'erreur
        expect(content).toMatch(/dcl-proc test_customer_getByID_not_found export/);
    });

    test('should have preserved zones for manual code extensions', () => {
        const serviceFile = customerFile('customer.sqlrpgle');
        const content = fs.readFileSync(serviceFile, 'utf-8');
        
        // Vérifier que les zones protégées sont présentes et bien placées
        expect(content).toMatch(/\[CMAGIC:MANUAL_START\]/);
        expect(content).toMatch(/\[CMAGIC:MANUAL_END\]/);
        
        // Vérifier que les zones sont dans la section d'implémentation
        const manualStartIndex = content.indexOf('[CMAGIC:MANUAL_START]');
        const manualEndIndex = content.indexOf('[CMAGIC:MANUAL_END]');
        
        expect(manualStartIndex).toBeGreaterThan(-1);
        expect(manualEndIndex).toBeGreaterThan(manualStartIndex);
        
        // La zone doit être après les procédures publiques
        const publicProcIndex = content.indexOf('dcl-proc customer_create export');
        expect(manualStartIndex).toBeGreaterThan(publicProcIndex);
        
        // Et contenir les procédures locales
        const zoneManulle = content.substring(manualStartIndex, manualEndIndex);
        expect(zoneManulle).toMatch(/customer_create_local/);
        expect(zoneManulle).toMatch(/customer_display_local/);
        expect(zoneManulle).toMatch(/customer_change_local/);
        expect(zoneManulle).toMatch(/customer_delete_local/);
        expect(zoneManulle).toMatch(/customer_search_local/);
    });

    test('should validate complete conformity with PRD Sprint 02 requirements', () => {
        // Test de conformité globale : tous les critères du PRD doivent être respectés
        
        // 1. Grammaire DSL étendue ✅
        expect(fs.existsSync(prdFile)).toBe(true);
        
        // 2. Artefacts générés complets ✅ 
        const requiredFiles = [
            customerFile('customer.rpgleinc'),  // Structures + énumérations
            customerFile('customer.sqlrpgle'),  // Service unifié
            customerFile('customer.sql'),       // DDL complet
            customerFile('customer.test.sqlrpgle') // Tests unitaires
        ];
        
        requiredFiles.forEach(file => {
            expect(fs.existsSync(file)).toBe(true);
            const content = fs.readFileSync(file, 'utf-8');
            expect(content.length).toBeGreaterThan(500); // Fichiers substantiels
        });
        
        // 3. Pattern unifié conforme ✅
        const serviceContent = fs.readFileSync(customerFile('customer.sqlrpgle'), 'utf-8');
        
        // API publique customer_*
        ['customer_create', 'customer_display', 'customer_change', 'customer_delete', 'customer_search'].forEach(api => {
            expect(serviceContent).toMatch(new RegExp(`dcl-proc ${api} export`));
        });
        
        // Délégation vers procédures locales
        ['customer_create_local', 'customer_display_local', 'customer_change_local', 'customer_delete_local', 'customer_search_local'].forEach(local => {
            expect(serviceContent).toMatch(new RegExp(local));
        });
        
        // 4. Validation métier adaptée (plus de hardcodé) ✅
        expect(serviceContent).toMatch(/\/\/ id is mandatory/);
        expect(serviceContent).toMatch(/\/\/ code is mandatory/);
        expect(serviceContent).toMatch(/\/\/ name is mandatory/);
        expect(serviceContent).toMatch(/\/\/ creationDate is mandatory/);
        expect(serviceContent).toMatch(/Email format validation/);
        expect(serviceContent).toMatch(/Credit limit must be positive/);
        expect(serviceContent).toMatch(/address\.ligne1 is mandatory/);
        
        // 5. Structures complètes (plus de modèle simplifié) ✅
        const copybookContent = fs.readFileSync(customerFile('customer.rpgleinc'), 'utf-8');
        
        // Tous les champs Customer PRD (vérification plus souple)
        ['id', 'code', 'name', 'address', 'phone', 'email', 'status', 'creditlimit', 'isvip'].forEach(field => {
            expect(copybookContent).toMatch(new RegExp(`${field}\\s+[A-Z]`));
        });
        
        // Vérification spéciale pour creationdate (type DATE)
        expect(copybookContent).toMatch(/creationdate\s+DATE/);
        
        // Vérification spéciale pour address (LIKEDS)
        expect(copybookContent).toMatch(/address\s+LIKEDS/);
        
        // Structure Address complète
        ['ligne1', 'ligne2', 'codepostal', 'ville', 'pays'].forEach(field => {
            expect(copybookContent).toMatch(new RegExp(`${field}.*VARCHAR`));
        });
        
        // Énumération CustomerStatus complète  
        ['active', 'inactive', 'suspended'].forEach(status => {
            expect(copybookContent).toMatch(new RegExp(`${status} '${status}'`));
        });
    });
});
