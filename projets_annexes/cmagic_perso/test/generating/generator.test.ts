// tests/generator.test.ts

// Vitest rend ces fonctions globales, pas besoin d'import si configuré
import { describe, it, expect } from 'vitest';

// On va créer cette fonction helper juste après
import { generateSqlFromString, generateRpgFromString } from './test-utils.js'; 

describe('SQL Generator - Sprint 01', () => {

    it('should generate a correct CREATE TABLE statement for a simple entity', async () => {
        // 1. INPUT: Le DSL que l'on veut tester
        const dslInput = `
            entity Tiers {
                id: Int
                nom: String
            }
        `;

        // 2. ACTION: On appelle notre générateur
        const generatedSql = await generateSqlFromString(dslInput);

        // 3. EXPECTATION: On utilise un snapshot pour vérifier le résultat
        expect(generatedSql).toMatchSnapshot();
    });

    // On pourrait ajouter d'autres tests ici plus tard
    it('should handle multiple entities correctly', async () => {
        const dslInput = `
            entity Produit { ref: String }
            entity Commande { num: Int }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        expect(generatedSql).toMatchSnapshot();
    });

    // Tests Sprint 01 - Cas complets avec tous les types
    it('should generate SQL for Customer entity with all types and constraints', async () => {
        const dslInput = `
            enum CustomerStatus {
                ACTIVE, INACTIVE, SUSPENDED
            }

            struct Address {
                ligne1: String(50)
                ligne2: String(50)
                codePostal: String(10)
                ville: String(50)
                pays: String(3) default ("FR")
            }

            entity Customer {
                id: Int required
                code: String(10) required unique
                name: String(80) required
                address: Address
                phone: String(20)
                email: String(100)
                status: CustomerStatus default (ACTIVE)
                creationDate: Date
                creditLimit: Decimal(15,2) default (0)
                isVip: Boolean default (false)
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        expect(generatedSql).toMatchSnapshot();
    });

    it('should generate SQL for CustomerOrder with foreign keys', async () => {
        const dslInput = `
            enum OrderStatus {
                PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
            }

            entity Customer {
                id: Int required
                code: String(10) required unique
                name: String(80) required
            }

            entity CustomerOrder {
                id: Int required
                orderNumber: String(20) required unique
                customerId: Int required
                status: OrderStatus default (PENDING)
                orderDate: Date required
                deliveryDate: Date
                totalAmount: Decimal(15,2) default (0)
                notes: String(500)
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        expect(generatedSql).toMatchSnapshot();
    });

    it('should handle all primitive types correctly', async () => {
        const dslInput = `
            entity TypeTest {
                id: Int required
                textShort: String(10)
                textLong: String(255)
                textDefault: String
                number: Int
                price: Decimal(10,2)
                birthDate: Date
                isActive: Boolean
                isActiveDefault: Boolean default (true)
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        expect(generatedSql).toMatchSnapshot();
    });

    it('should generate proper constraints and indexes', async () => {
        const dslInput = `
            entity ConstraintTest {
                id: Int required
                uniqueCode: String(20) required unique
                email: String(100) unique
                optionalField: String(50)
                defaultValue: String(30) default ("test")
                booleanField: Boolean default (false)
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        expect(generatedSql).toMatchSnapshot();
    });
});

describe('RPG Generator - Sprint 01', () => {

    it('should generate RPG copybook for Customer with enum support', async () => {
        const dslInput = `
            enum CustomerStatus {
                ACTIVE, INACTIVE, SUSPENDED
            }

            struct Address {
                ligne1: String(50)
                ligne2: String(50)
                ville: String(50)
                pays: String(3) default ("FR")
            }

            entity Customer {
                id: Int required
                code: String(10) required unique
                name: String(80) required
                address: Address
                status: CustomerStatus default (ACTIVE)
                creditLimit: Decimal(15,2) default (0)
                isVip: Boolean default (false)
            }
        `;
        const generatedRpg = await generateRpgFromString(dslInput, 'Customer');
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should generate RPG with multiple enums and constants', async () => {
        const dslInput = `
            enum CustomerStatus {
                ACTIVE, INACTIVE, SUSPENDED
            }

            enum OrderStatus {
                PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
            }

            entity CustomerOrder {
                id: Int required
                customerId: Int required
                customerStatus: CustomerStatus default (ACTIVE)
                orderStatus: OrderStatus default (PENDING)
                totalAmount: Decimal(15,2) default (0)
            }
        `;
        const generatedRpg = await generateRpgFromString(dslInput, 'CustomerOrder');
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should map all types correctly to RPG types', async () => {
        const dslInput = `
            entity TypeMapping {
                id: Int
                text: String(100)
                amount: Decimal(10,2)
                date: Date
                flag: Boolean
            }
        `;
        const generatedRpg = await generateRpgFromString(dslInput, 'TypeMapping');
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should generate proper Customer_id_t structure', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
                name: String(80) required
            }
        `;
        const generatedRpg = await generateRpgFromString(dslInput, 'Customer');
        expect(generatedRpg).toContain('dcl-ds customer_id_t qualified template;');
        expect(generatedRpg).toContain('  id INT(10);');
        expect(generatedRpg).toMatchSnapshot();
    });
});

describe('Edge Cases and Validation - Sprint 01', () => {

    it('should handle empty enum values gracefully', async () => {
        const dslInput = `
            enum EmptyEnum {
                VALUE1
            }

            entity TestEntity {
                id: Int required
                status: EmptyEnum
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'TestEntity');
        
        expect(generatedSql).toContain('CREATE TABLE TESTENTITYP');
        expect(generatedRpg).toContain('dcl-enum emptyenum qualified;');
        expect(generatedRpg).toContain("value1 'value1';");
    });

    it('should handle complex struct nesting', async () => {
        const dslInput = `
            struct ContactInfo {
                email: String(100)
                phone: String(20)
            }

            struct FullAddress {
                street: String(100)
                city: String(50)
                contact: ContactInfo
            }

            entity Company {
                id: Int required
                name: String(100) required
                address: FullAddress
            }
        `;
        const generatedRpg = await generateRpgFromString(dslInput, 'Company');
        
        expect(generatedRpg).toContain('dcl-ds company_contactinfo_t qualified template;');
        expect(generatedRpg).toContain('dcl-ds company_fulladdress_t qualified template;');
        expect(generatedRpg).toContain('address LIKEDS(company_fulladdress_t);');
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should generate foreign key constraints correctly', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
                name: String(80) required
            }

            entity Order {
                id: Int required
                customerId: Int required
                orderNumber: String(20) unique
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        
        expect(generatedSql).toContain('FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMERP (ID)');
        expect(generatedSql).toContain('CREATE INDEX ORDERP_CUSTOMERID_IDX ON ORDERP (CUSTOMERID)');
        expect(generatedSql).toMatchSnapshot();
    });

    it('should handle all constraint combinations', async () => {
        const dslInput = `
            entity FullConstraints {
                id: Int required
                uniqueRequired: String(50) required unique
                uniqueOptional: String(50) unique
                defaultRequired: String(30) required default ("test")
                defaultOptional: String(30) default ("optional")
                booleanDefault: Boolean default (true)
                decimalDefault: Decimal(10,2) default (99.99)
            }
        `;
        const generatedSql = await generateSqlFromString(dslInput);
        
        expect(generatedSql).toContain('UNIQUEREQUIRED VARCHAR(50) NOT NULL');
        expect(generatedSql).toContain('UNIQUE (UNIQUEREQUIRED)');
        expect(generatedSql).toContain("DEFAULT 'test'");
        expect(generatedSql).toContain('DEFAULT 99.99');
        expect(generatedSql).toContain("DEFAULT 'Y'");
        expect(generatedSql).toMatchSnapshot();
    });
});

describe('Performance and Robustness - Sprint 01', () => {

    it('should generate large entities efficiently', async () => {
        const fields = Array.from({length: 20}, (_, i) => `field${i}: String(50)`).join('\n                ');
        const dslInput = `
            entity LargeEntity {
                id: Int required
                ${fields}
            }
        `;
        
        const startTime = Date.now();
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'LargeEntity');
        const endTime = Date.now();
        
        expect(endTime - startTime).toBeLessThan(1000); // Moins d'1 seconde
        expect(generatedSql).toContain('CREATE TABLE LARGEENTITYP');
        expect(generatedRpg).toContain('dcl-ds largeentity_t qualified template;');
    });

    it('should handle multiple entities with complex relationships', async () => {
        const dslInput = `
            enum Status { ACTIVE, INACTIVE }
            enum Priority { LOW, MEDIUM, HIGH, URGENT }

            struct Address {
                street: String(100)
                city: String(50)
                country: String(3) default ("FR")
            }

            entity Customer {
                id: Int required
                code: String(10) required unique
                name: String(80) required
                address: Address
                status: Status default (ACTIVE)
            }

            entity Product {
                id: Int required
                code: String(20) required unique
                name: String(100) required
                price: Decimal(10,2)
                active: Boolean default (true)
            }

            entity Order {
                id: Int required
                orderNumber: String(20) required unique
                customerId: Int required
                productId: Int required
                priority: Priority default (MEDIUM)
                orderDate: Date required
                deliveryDate: Date
                amount: Decimal(15,2) default (0)
                notes: String(500)
            }
        `;
        
        const sqlResult = await generateSqlFromString(dslInput);
        const customerRpg = await generateRpgFromString(dslInput, 'Customer');
        const orderRpg = await generateRpgFromString(dslInput, 'Order');
        
        // Vérifications SQL
        expect(sqlResult).toContain('CREATE TABLE CUSTOMERP');
        expect(sqlResult).toContain('CREATE TABLE PRODUCTP');
        expect(sqlResult).toContain('CREATE TABLE ORDERP');
        expect(sqlResult).toContain('FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMERP (ID)');
        expect(sqlResult).toContain('FOREIGN KEY (PRODUCTID) REFERENCES PRODUCTP (ID)');
        
        // Vérifications RPG
        expect(customerRpg).toContain('dcl-enum status qualified;');
        expect(orderRpg).toContain('dcl-enum priority qualified;');
        expect(customerRpg).toContain('dcl-ds customer_id_t qualified template;');
        expect(orderRpg).toContain('dcl-ds order_id_t qualified template;');
        
        expect(sqlResult).toMatchSnapshot();
        expect(customerRpg).toMatchSnapshot();
        expect(orderRpg).toMatchSnapshot();
    });
});
