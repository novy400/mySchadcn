const sqlIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_$#@]*$/;

export const assertSqlObjectIdentifier = (identifier: string): void => {
    const parts = identifier.split('.');
    if (
        parts.length > 2 ||
        parts.some(part => !sqlIdentifierPattern.test(part))
    ) {
        throw new Error(`Unsafe SQL identifier: ${identifier}`);
    }
};

export const assertSqlColumnIdentifier = (identifier: string): void => {
    if (!sqlIdentifierPattern.test(identifier)) {
        throw new Error(`Unsafe SQL column identifier: ${identifier}`);
    }
};
