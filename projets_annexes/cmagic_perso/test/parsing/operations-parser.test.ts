import { describe, it, expect } from 'vitest';
import { parseCMagicString } from '../generating/test-utils.js';
import type { Operations } from '../../src/language/generated/ast.js';

describe('Operations Parser - Sprint 02', () => {

    it('should parse simple operations block', async () => {
        const dslInput = `
            entity Customer {
                id: Int required,
                name: String(50)
            }

            operations for Customer {
                CREATE,
                DISPLAY
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        // Vérifier que le modèle a bien été parsé
        expect(model).toBeTruthy();
        expect(model.entities).toHaveLength(1);
        expect(model.operations).toHaveLength(1);
        
        // Vérifier les détails du bloc operations
        const operations = model.operations[0];
        expect(operations.entity.ref?.name).toBe('Customer');
        expect(operations.operations).toHaveLength(2);
        expect(operations.operations).toContain('CREATE');
        expect(operations.operations).toContain('DISPLAY');
    });

    it('should parse all supported operation types', async () => {
        const dslInput = `
            entity Product {
                id: Int required
            }

            operations for Product {
                CREATE,
                CHANGE,
                DELETE,
                DISPLAY,
                SEARCH
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        expect(model.operations).toHaveLength(1);
        const operations = model.operations[0];
        
        expect(operations.operations).toHaveLength(5);
        expect(operations.operations).toContain('CREATE');
        expect(operations.operations).toContain('CHANGE');
        expect(operations.operations).toContain('DELETE');
        expect(operations.operations).toContain('DISPLAY');
        expect(operations.operations).toContain('SEARCH');
    });

    it('should handle single operation', async () => {
        const dslInput = `
            entity Order {
                id: Int required
            }

            operations for Order {
                CREATE
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        expect(model.operations).toHaveLength(1);
        const operations = model.operations[0];
        
        expect(operations.operations).toHaveLength(1);
        expect(operations.operations[0]).toBe('CREATE');
    });

    it('should parse multiple operations blocks for different entities', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
            }

            entity Order {
                id: Int required
            }

            operations for Customer {
                CREATE,
                DISPLAY
            }

            operations for Order {
                SEARCH,
                DELETE
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        expect(model.entities).toHaveLength(2);
        expect(model.operations).toHaveLength(2);
        
        // Vérifier le premier bloc operations
        const customerOps = model.operations.find((op: Operations) => op.entity.ref?.name === 'Customer');
        expect(customerOps).toBeTruthy();
        expect(customerOps!.operations).toContain('CREATE');
        expect(customerOps!.operations).toContain('DISPLAY');
        
        // Vérifier le second bloc operations
        const orderOps = model.operations.find((op: Operations) => op.entity.ref?.name === 'Order');
        expect(orderOps).toBeTruthy();
        expect(orderOps!.operations).toContain('SEARCH');
        expect(orderOps!.operations).toContain('DELETE');
    });

    it('should handle operations mixed with other constructs', async () => {
        const dslInput = `
            struct Address {
                street: String(100),
                city: String(50)
            }

            enum Status {
                ACTIVE,
                INACTIVE
            }

            entity Customer {
                id: Int required,
                address: Address,
                status: Status
            }

            view CustomerView for Customer {
                id,
                status
            }

            operations for Customer {
                CREATE,
                CHANGE,
                DISPLAY
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        expect(model.structs).toHaveLength(1);
        expect(model.enums).toHaveLength(1);
        expect(model.entities).toHaveLength(1);
        expect(model.views).toHaveLength(1);
        expect(model.operations).toHaveLength(1);
        
        const operations = model.operations[0];
        expect(operations.entity.ref?.name).toBe('Customer');
        expect(operations.operations).toHaveLength(3);
    });

    it('should validate entity reference exists', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
            }

            operations for NonExistentEntity {
                CREATE
            }
        `;

        // Ce test doit échouer car l'entité référencée n'existe pas
        await expect(parseCMagicString(dslInput)).rejects.toThrow('Could not resolve reference');
    });

    it('should handle empty operations block', async () => {
        const dslInput = `
            entity Customer {
                id: Int required
            }

            operations for Customer {
            }
        `;

        const model = await parseCMagicString(dslInput);
        
        expect(model.operations).toHaveLength(1);
        expect(model.operations[0].operations).toHaveLength(0);
    });
});
