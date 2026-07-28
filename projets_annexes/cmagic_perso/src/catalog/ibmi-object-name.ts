const ibmIObjectNamePattern = /^[A-Z$#@][A-Z0-9_$#@]{0,9}$/;

export const catalogObjectName = (entityName: string): string => {
    const objectName = entityName.toUpperCase();
    if (!ibmIObjectNamePattern.test(objectName)) {
        throw new Error(
            `Invalid IBM i object name "${objectName}": ` +
                'the entity name must produce a 1-10 character system name'
        );
    }
    return objectName;
};
