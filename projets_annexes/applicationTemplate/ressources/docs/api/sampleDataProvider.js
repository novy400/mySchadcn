import { fetchUtils } from 'react-admin';
import { stringify } from 'query-string';

const apiUrl = 'http://your-ibmi-server:44000/api';
const httpClient = fetchUtils.fetchJson;

export const dataProvider = {
  getList: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    
    const query = {
      _page: page,
      _limit: perPage,
      _sort: field,
      _order: order,
      ...params.filter
    };
    
    const url = `${apiUrl}/${resource}?${stringify(query)}`;
    const { headers, json } = await httpClient(url);
    
    return {
      data: json,
      total: parseInt(headers.get('x-total-count') || '0', 10)
    };
  },
  
  getOne: async (resource, params) => {
    const url = `${apiUrl}/${resource}/${params.id}`;
    const { json } = await httpClient(url);
    return { data: json };
  },
  
  getMany: async (resource, params) => {
    const requests = params.ids.map(id => 
      httpClient(`${apiUrl}/${resource}/${id}`)
    );
    const responses = await Promise.all(requests);
    return { data: responses.map(({ json }) => json) };
  },
  
  getManyReference: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    
    const query = {
      _page: page,
      _limit: perPage,
      _sort: field,
      _order: order,
      [params.target]: params.id,
      ...params.filter
    };
    
    const url = `${apiUrl}/${resource}?${stringify(query)}`;
    const { headers, json } = await httpClient(url);
    
    return {
      data: json,
      total: parseInt(headers.get('x-total-count') || '0', 10)
    };
  },
  
  create: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}`, {
      method: 'POST',
      body: JSON.stringify(params.data)
    });
    return { data: json };
  },
  
  update: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
      method: 'PUT',
      body: JSON.stringify(params.data)
    });
    return { data: json };
  },
  
  updateMany: async (resource, params) => {
    const requests = params.ids.map(id =>
      httpClient(`${apiUrl}/${resource}/${id}`, {
        method: 'PUT',
        body: JSON.stringify(params.data)
      })
    );
    await Promise.all(requests);
    return { data: params.ids };
  },
  
  delete: async (resource, params) => {
    const { json } = await httpClient(`${apiUrl}/${resource}/${params.id}`, {
      method: 'DELETE'
    });
    return { data: json };
  },
  
  deleteMany: async (resource, params) => {
    const requests = params.ids.map(id =>
      httpClient(`${apiUrl}/${resource}/${id}`, { method: 'DELETE' })
    );
    await Promise.all(requests);
    return { data: params.ids };
  }
};