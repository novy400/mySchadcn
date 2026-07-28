// tests/validation.test.ts

import { describe, it, expect } from 'vitest';
import { generateSqlFromString, generateRpgFromString } from './test-utils.js'; 

describe('DSL Validation and Error Handling - Sprint 01', () => {

    it('should handle invalid enum reference gracefully', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
                status: NonExistentEnum
            }
        `;
        
        // Pour l'instant, le système traite les types inconnus comme des références de struct/entity
        // Dans le futur, on pourrait vouloir une validation plus stricte
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'Customer');
        
        expect(generatedSql).toContain('CREATE TABLE CUSTOMERP');
        expect(generatedSql).toContain('STATUS VARCHAR(256)'); // Fallback type
        expect(generatedRpg).toContain('status LIKEDS(nonexistentenum_t);');
    });

    it('should validate required field constraints', async () => {
        const dslInput = `
            entity StrictEntity {
                id: Int required
                mandatoryCode: String(10) required
                optionalField: String(50)
            }
        `;
        
        const generatedSql = await generateSqlFromString(dslInput);
        
        expect(generatedSql).toContain('ID INTEGER NOT NULL');
        expect(generatedSql).toContain('MANDATORYCODE VARCHAR(10) NOT NULL');
        expect(generatedSql).toContain('OPTIONALFIELD VARCHAR(50),'); // Pas de NOT NULL
        expect(generatedSql).toMatchSnapshot();
    });

    it('should handle decimal precision edge cases', async () => {
        const dslInput = `
            entity PrecisionTest {
                id: Int required
                money: Decimal(15,2)
                percentage: Decimal(5,4)
                largeNumber: Decimal(20,0)
            }
        `;
        
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'PrecisionTest');
        
        expect(generatedSql).toContain('MONEY DECIMAL(15,2)');
        expect(generatedSql).toContain('PERCENTAGE DECIMAL(5,4)');
        expect(generatedSql).toContain('LARGENUMBER DECIMAL(20,0)');
        
        expect(generatedRpg).toContain('money PACKED(15:2);');
        expect(generatedRpg).toContain('percentage PACKED(5:4);');
        expect(generatedRpg).toContain('largenumber PACKED(20:0);');
        
        expect(generatedSql).toMatchSnapshot();
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should handle string length variations', async () => {
        const dslInput = `
            entity StringTest {
                id: Int required
                shortCode: String(5)
                standardName: String(50)
                longDescription: String(1000)
                defaultString: String
            }
        `;
        
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'StringTest');
        
        expect(generatedSql).toContain('SHORTCODE VARCHAR(5)');
        expect(generatedSql).toContain('STANDARDNAME VARCHAR(50)');
        expect(generatedSql).toContain('LONGDESCRIPTION VARCHAR(1000)');
        expect(generatedSql).toContain('DEFAULTSTRING VARCHAR(256)'); // Default fallback
        
        expect(generatedRpg).toContain('shortcode VARCHAR(5);');
        expect(generatedRpg).toContain('standardname VARCHAR(50);');
        expect(generatedRpg).toContain('longdescription VARCHAR(1000);');
        expect(generatedRpg).toContain('defaultstring VARCHAR(256);');
        
        expect(generatedSql).toMatchSnapshot();
        expect(generatedRpg).toMatchSnapshot();
    });

    it('should handle boolean default values correctly', async () => {
        const dslInput = `
            entity BooleanTest {
                id: Int required
                isActive: Boolean default (true)
                isDeleted: Boolean default (false)
                isOptional: Boolean
            }
        `;
        
        const generatedSql = await generateSqlFromString(dslInput);
        const generatedRpg = await generateRpgFromString(dslInput, 'BooleanTest');
        
        expect(generatedSql).toContain("ISACTIVE CHAR(1) DEFAULT 'Y'");
        expect(generatedSql).toContain("ISDELETED CHAR(1) DEFAULT 'N'");
        expect(generatedSql).toContain('ISOPTIONAL CHAR(1),');
        expect(generatedSql).toContain("CHECK (ISACTIVE IN ('Y', 'N'))");
        
        expect(generatedRpg).toContain("isactive IND INZ('true');");
        expect(generatedRpg).toContain("isdeleted IND INZ('false');");
        expect(generatedRpg).toContain("isoptional IND INZ('N');"); // Default pour Boolean sans valeur
        
        expect(generatedSql).toMatchSnapshot();
        expect(generatedRpg).toMatchSnapshot();
    });
});

describe('Complex Integration Tests - Sprint 01', () => {

    it('should generate complete customer-order system', async () => {
        const dslInput = `
            // Enums pour le système
            enum CustomerStatus {
                ACTIVE, INACTIVE, SUSPENDED, PROSPECT
            }

            enum OrderStatus {
                DRAFT, PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED, RETURNED
            }

            enum PaymentMethod {
                CASH, CREDIT_CARD, BANK_TRANSFER, CHECK
            }

            // Structures réutilisables
            struct Address {
                street: String(100) required
                city: String(50) required
                postalCode: String(10) required
                country: String(3) default ("FR")
            }

            struct ContactInfo {
                email: String(100)
                phone: String(20)
                mobile: String(20)
            }

            // Entités principales
            entity Customer {
                id: Int required
                customerCode: String(15) required unique
                companyName: String(100) required
                tradeName: String(100)
                address: Address required
                contact: ContactInfo
                status: CustomerStatus default (PROSPECT)
                creditLimit: Decimal(15,2) default (0)
                paymentTerms: Int default (30)
                isVip: Boolean default (false)
                createdDate: Date required
                lastOrderDate: Date
            }

            entity CustomerOrder {
                id: Int required
                orderNumber: String(20) required unique
                customerId: Int required
                status: OrderStatus default (DRAFT)
                orderDate: Date required
                requestedDeliveryDate: Date
                confirmedDeliveryDate: Date
                paymentMethod: PaymentMethod default (CREDIT_CARD)
                subtotal: Decimal(15,2) default (0)
                taxAmount: Decimal(15,2) default (0)
                totalAmount: Decimal(15,2) default (0)
                notes: String(1000)
                isRush: Boolean default (false)
            }
        `;
        
        const sqlResult = await generateSqlFromString(dslInput);
        const customerRpg = await generateRpgFromString(dslInput, 'Customer');
        const orderRpg = await generateRpgFromString(dslInput, 'CustomerOrder');
        
        // Validations SQL complètes
        expect(sqlResult).toContain('CREATE TABLE CUSTOMERP');
        expect(sqlResult).toContain('CREATE TABLE CUSTOMERORDERP');
        expect(sqlResult).toContain('FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMERP (ID)');
        expect(sqlResult).toContain('PRIMARY KEY (ID)');
        expect(sqlResult).toContain('UNIQUE (CUSTOMERCODE)');
        expect(sqlResult).toContain('UNIQUE (ORDERNUMBER)');
        expect(sqlResult).toContain("CHECK (ISVIP IN ('Y', 'N'))");
        expect(sqlResult).toContain("CHECK (ISRUSH IN ('Y', 'N'))");
        
        // Validations RPG complètes
        expect(customerRpg).toContain('dcl-enum customerstatus qualified;');
        expect(customerRpg).toContain('dcl-enum paymentmethod qualified;');
        expect(orderRpg).toContain('dcl-enum orderstatus qualified;');
        expect(customerRpg).toContain('dcl-ds customer_address_t qualified template;');
        expect(customerRpg).toContain('dcl-ds customer_contactinfo_t qualified template;');
        expect(customerRpg).toContain('dcl-ds customer_id_t qualified template;');
        expect(orderRpg).toContain('dcl-ds customerorder_id_t qualified template;');
        
        // Tests de cohérence des types
        expect(customerRpg).toContain('address LIKEDS(customer_address_t);');
        expect(customerRpg).toContain('contact LIKEDS(customer_contactinfo_t);');
        expect(customerRpg).toContain("status VARCHAR(20) INZ('PROSPECT');");
        expect(orderRpg).toContain("status VARCHAR(20) INZ('DRAFT');");
        expect(orderRpg).toContain("paymentmethod VARCHAR(20) INZ('CREDIT_CARD');");
        
        expect(sqlResult).toMatchSnapshot();
        expect(customerRpg).toMatchSnapshot();
        expect(orderRpg).toMatchSnapshot();
    });
});
