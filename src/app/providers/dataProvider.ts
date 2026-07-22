import fakeDataProvider from 'ra-data-fakerest';
import type { DataProvider } from 'ra-core';
import fakerestData from '../../data/fakerestData';

const baseDataProvider = fakeDataProvider(fakerestData);

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
    })
  );

export const dataProvider: DataProvider = {
  ...baseDataProvider,
  getList: (resource, params) =>
    baseDataProvider.getList(resource, {
      ...params,
      filter: removeEmptyFilters(params.filter),
    }),
  getManyReference: (resource, params) =>
    baseDataProvider.getManyReference(resource, {
      ...params,
      filter: removeEmptyFilters(params.filter),
    }),
};

export default dataProvider;
