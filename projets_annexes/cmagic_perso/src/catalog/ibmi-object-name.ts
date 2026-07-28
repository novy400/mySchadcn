const ibmIObjectNamePattern = /^[A-Z$#@][A-Z0-9_$#@]{0,9}$/;

export const normalizeIbmIObjectName = (name: string): string =>
    name.toUpperCase();

export const isIbmIObjectName = (name: string): boolean =>
    ibmIObjectNamePattern.test(normalizeIbmIObjectName(name));

export const isSameIbmIObjectName = (
    leftName: string,
    rightName: string
): boolean =>
    normalizeIbmIObjectName(leftName) === normalizeIbmIObjectName(rightName);

export const catalogObjectName = (entityName: string): string => {
    const objectName = normalizeIbmIObjectName(entityName);
    if (!isIbmIObjectName(objectName)) {
        throw new Error(
            `Invalid IBM i object name "${objectName}": ` +
                'the entity name must produce a 1-10 character system name'
        );
    }
    return objectName;
};
