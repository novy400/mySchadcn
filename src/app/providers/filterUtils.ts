export const removeEmptyFilters = (filter: Record<string, unknown>) =>
  Object.fromEntries(
    Object.entries(filter).filter(([, value]) => {
      if (typeof value === 'string') {
        return value.trim() !== '';
      }

      if (Array.isArray(value)) {
        return value.length > 0;
      }

      return value !== undefined;
    }),
  );
