import type { ValidationAcceptor, ValidationChecks } from 'langium';
import type { CmagicAstType, Entity } from './generated/ast.js';
import type { CmagicServices } from './cmagic-module.js';

/**
 * Register custom validation checks.
 */
export function registerValidationChecks(services: CmagicServices) {
    const registry = services.validation.ValidationRegistry;
    const validator = services.validation.CmagicValidator;
    const checks: ValidationChecks<CmagicAstType> = {
        Entity: validator.checkEntityStartsWithCapital
    };
    registry.register(checks, validator);
}

/**
 * Implementation of custom validations.
 */
export class CmagicValidator {

    checkEntityStartsWithCapital(entity: Entity, accept: ValidationAcceptor): void {
        if (entity.name) {
            const firstChar = entity.name.substring(0, 1);
            if (firstChar.toUpperCase() !== firstChar) {
                accept('warning', 'Entity name should start with a capital.', { node: entity, property: 'name' });
            }
        }
    }

}
