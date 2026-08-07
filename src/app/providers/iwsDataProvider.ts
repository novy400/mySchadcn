import {
  HttpError,
  type DataProvider,
  type GetListParams,
  type GetListResult,
  type GetOneParams,
  type GetOneResult,
  type RaRecord,
} from 'ra-core';
import { removeEmptyFilters } from './filterUtils';

export type IwsDataProvider = Pick<DataProvider, 'getList' | 'getOne'> & {
  supportAbortSignal: true;
};

type IwsDataProviderOptions = {
  apiUrl: string;
  fetcher?: typeof fetch;
};

type IwsListResponse = {
  items: RaRecord[];
  totalCount: number;
  errors: unknown[];
};

type IwsOneResponse = {
  item: RaRecord;
  errors: unknown[];
};

type IwsError = {
  nomZone?: string;
  code?: string;
  valeur?: unknown;
  text?: string;
  textUser?: string;
};

const httpErrorMessages: Readonly<Record<number, string>> = {
  400: 'Requête IBM i invalide',
  401: 'Authentification IBM i requise',
  403: 'Accès IBM i interdit',
  404: 'Service IBM i introuvable',
  409: 'Conflit IBM i',
  500: 'Erreur interne IBM i',
};

const readJson = async (response: Response): Promise<unknown> => {
  const text = await response.text();
  if (!text) {
    return undefined;
  }

  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
};

const getIwsErrors = (body: unknown): IwsError[] => {
  if (
    typeof body === 'object' &&
    body !== null &&
    'errors' in body &&
    Array.isArray(body.errors)
  ) {
    return body.errors;
  }

  return [];
};

const assertSuccessfulResponse = (response: Response, body: unknown) => {
  if (response.ok) {
    return;
  }

  const errors = getIwsErrors(body);
  const firstError = errors[0];
  const fallbackMessage =
    httpErrorMessages[response.status] ?? `Erreur HTTP IBM i ${response.status}`;
  const message = firstError?.textUser || firstError?.text || fallbackMessage;
  const fieldErrors = Object.fromEntries(
    errors
      .filter((error) => error.nomZone)
      .map((error) => [
        error.nomZone!,
        error.textUser || error.text || fallbackMessage,
      ]),
  );
  const correlationId = response.headers.get('X-Correlation-Id');

  throw new HttpError(message, response.status, {
    status: response.status,
    code: firstError?.code || `HTTP_${response.status}`,
    message,
    fieldErrors,
    ...(correlationId ? { correlationId } : {}),
    errors,
  });
};

const assertRecordHasId = (record: RaRecord) => {
  if (
    record.id === undefined ||
    record.id === null ||
    (typeof record.id !== 'string' && typeof record.id !== 'number') ||
    record.id === ''
  ) {
    const message = 'Réponse IBM i invalide : identifiant absent';
    throw new HttpError(message, 500, {
      status: 500,
      code: 'IWS_INVALID_RESPONSE',
      message,
    });
  }
};

const buildListUrl = (apiUrl: string, params: GetListParams) => {
  const query = new URLSearchParams();

  if (params.pagination) {
    query.set('page', String(params.pagination.page));
    query.set('perPage', String(params.pagination.perPage));
  }
  if (params.sort) {
    query.set('sort', params.sort.field);
    query.set('order', params.sort.order);
  }
  for (const [name, value] of Object.entries(
    removeEmptyFilters(params.filter ?? {}),
  )) {
    query.set(name, String(value));
  }

  const baseUrl = apiUrl.replace(/\/+$/, '');
  const queryString = query.toString();
  return queryString ? `${baseUrl}?${queryString}` : baseUrl;
};

export const createIwsDataProvider = ({
  apiUrl,
  fetcher = globalThis.fetch,
}: IwsDataProviderOptions): IwsDataProvider => ({
    supportAbortSignal: true,
    getList: async <RecordType extends RaRecord = RaRecord>(
      _resource: string,
      params: GetListParams,
    ): Promise<GetListResult<RecordType>> => {
      const response = await fetcher(buildListUrl(apiUrl, params), {
        headers: { Accept: 'application/json' },
        signal: params.signal,
      });
      const body = (await readJson(response)) as IwsListResponse;
      assertSuccessfulResponse(response, body);
      body.items.forEach(assertRecordHasId);

      return { data: body.items as RecordType[], total: body.totalCount };
    },
    getOne: async <RecordType extends RaRecord = RaRecord>(
      _resource: string,
      params: GetOneParams<RecordType>,
    ): Promise<GetOneResult<RecordType>> => {
      const baseUrl = apiUrl.replace(/\/+$/, '');
      const response = await fetcher(
        `${baseUrl}/${encodeURIComponent(String(params.id))}`,
        {
          headers: { Accept: 'application/json' },
          signal: params.signal,
        },
      );
      const body = (await readJson(response)) as IwsOneResponse;
      assertSuccessfulResponse(response, body);
      assertRecordHasId(body.item);
      if (String(body.item.id) !== String(params.id)) {
        const message = 'Réponse IBM i invalide : identifiant incohérent';
        throw new HttpError(message, 500, {
          status: 500,
          code: 'IWS_INVALID_RESPONSE',
          message,
        });
      }

      return { data: body.item as RecordType };
    },
  });
