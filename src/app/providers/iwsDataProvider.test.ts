import { describe, expect, it, vi } from 'vitest';
import { createIwsDataProvider } from './iwsDataProvider';

describe('IWS DataProvider', () => {
  it('resolves the fournisseurs collection URL independently from services', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({
          items: [
            {
              id: 'FOU000001',
              nom: 'Fournitures Pro',
              adresse: '12 rue des Ateliers',
              ville: 'Lille',
              telephone: '0320123456',
              email: 'contact@fourniturespro.fr',
            },
          ],
          totalCount: 1,
          errors: [],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
        fournisseurs: 'https://ibmi.example/web/services/FOURIWS1',
      },
      fetcher,
    });

    const result = await provider.getList('fournisseurs', {
      pagination: { page: 1, perPage: 25 },
      sort: { field: 'nom', order: 'ASC' },
      filter: { q: 'pro', ville: 'Lille' },
    });

    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/FOURIWS1?page=1&perPage=25&sort=nom&order=ASC&q=pro&ville=Lille',
      { headers: { Accept: 'application/json' }, signal: undefined },
    );
    expect(result).toEqual({
      data: [
        {
          id: 'FOU000001',
          nom: 'Fournitures Pro',
          adresse: '12 rue des Ateliers',
          ville: 'Lille',
          telephone: '0320123456',
          email: 'contact@fourniturespro.fr',
        },
      ],
      total: 1,
    });
  });

  it('creates a fournisseur with POST and adapts the persisted IWS item', async () => {
    const fournisseur = {
      id: 'FOU000003',
      nom: 'Ateliers du Nord',
      adresse: '5 rue du Port',
      ville: 'Lille',
      telephone: '0320998877',
      email: 'contact@ateliers-nord.fr',
    };
    const fetcher = vi.fn(async () =>
      new Response(JSON.stringify({ item: fournisseur, errors: [] }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        fournisseurs: 'https://ibmi.example/web/services/FOURIWS1',
      },
      fetcher,
    });

    const result = await provider.create('fournisseurs', {
      data: fournisseur,
    });

    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/FOURIWS1',
      {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fournisseur),
      },
    );
    expect(result).toEqual({ data: fournisseur });
  });

  it('rejects a created fournisseur whose identifier differs from the input', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({
          item: { id: 'FOU999999', nom: 'Autre fournisseur' },
          errors: [],
        }),
        { status: 201, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        fournisseurs: 'https://ibmi.example/web/services/FOURIWS1',
      },
      fetcher,
    });

    await expect(
      provider.create('fournisseurs', {
        data: { id: 'FOU000003', nom: 'Ateliers du Nord' },
      }),
    ).rejects.toMatchObject({
      status: 500,
      body: {
        status: 500,
        code: 'IWS_INVALID_RESPONSE',
        message: 'Réponse IBM i invalide : identifiant incohérent',
      },
    });
  });

  it('updates a fournisseur with a complete PUT body and the route identifier', async () => {
    const previousData = {
      id: 'FOU000003',
      nom: 'Ateliers du Nord',
      adresse: '5 rue du Port',
      ville: 'Lille',
      telephone: '0320998877',
      email: 'contact@ateliers-nord.fr',
    };
    const updated = { ...previousData, nom: 'Ateliers du Nord SAS' };
    const fetcher = vi.fn(async () =>
      new Response(JSON.stringify({ item: updated, errors: [] }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        fournisseurs: 'https://ibmi.example/web/services/FOURIWS1',
      },
      fetcher,
    });

    const result = await provider.update('fournisseurs', {
      id: 'FOU000003',
      data: {
        nom: 'Ateliers du Nord SAS',
        id: 'IGNORED',
        uiOnly: 'not sent to IBM i',
      },
      previousData,
    });

    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/FOURIWS1/FOU000003',
      {
        method: 'PUT',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updated),
      },
    );
    expect(result).toEqual({ data: updated });
  });

  it('serializes a service list request and adapts the IWS collection envelope', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({
          items: [
            {
              id: 'A00',
              nom: 'SPIFFY COMPUTER SERVICE DIV.',
              idManageur: '000010',
              idServiceAdmin: 'A00',
              site: '',
            },
          ],
          totalCount: 14,
          errors: [],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3/',
      },
      fetcher,
    });

    const result = await provider.getList('services', {
      pagination: { page: 2, perPage: 25 },
      sort: { field: 'nom', order: 'DESC' },
      filter: {
        q: 'planning & contrôle',
        idServiceAdmin: 'A00',
        site: 'Paris',
        empty: '',
      },
    });

    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/SERVIWS3?page=2&perPage=25&sort=nom&order=DESC&q=planning+%26+contr%C3%B4le&idServiceAdmin=A00&site=Paris',
      { headers: { Accept: 'application/json' }, signal: undefined },
    );
    expect(result).toEqual({
      data: [
        {
          id: 'A00',
          nom: 'SPIFFY COMPUTER SERVICE DIV.',
          idManageur: '000010',
          idServiceAdmin: 'A00',
          site: '',
        },
      ],
      total: 14,
    });
  });

  it('adapts an IWS service detail without changing its stable identifier', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({
          item: {
            id: 'A00',
            nom: 'SPIFFY COMPUTER SERVICE DIV.',
            idManageur: '000010',
            idServiceAdmin: 'A00',
            site: '',
          },
          errors: [],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
      },
      fetcher,
    });

    const result = await provider.getOne('services', { id: 'A00' });

    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/SERVIWS3/A00',
      { headers: { Accept: 'application/json' }, signal: undefined },
    );
    expect(result).toEqual({
      data: {
        id: 'A00',
        nom: 'SPIFFY COMPUTER SERVICE DIV.',
        idManageur: '000010',
        idServiceAdmin: 'A00',
        site: '',
      },
    });
  });

  it.each([
    [400, 'Requête IBM i invalide'],
    [401, 'Authentification IBM i requise'],
    [403, 'Accès IBM i interdit'],
    [404, 'Ressource IBM i introuvable'],
    [409, 'Conflit IBM i'],
    [422, 'Validation IBM i échouée'],
    [500, 'Erreur interne IBM i'],
  ])(
    'converts an empty HTTP %i response into a deterministic React Admin error',
    async (status, message) => {
      const fetcher = vi.fn(async () => new Response(null, { status }));
      const provider = createIwsDataProvider({
        apiUrls: {
          services: 'https://ibmi.example/web/services/SERVIWS3',
        },
        fetcher,
      });

      await expect(
        provider.getOne('services', { id: 'A00' }),
      ).rejects.toMatchObject({
        status,
        message,
        body: {
          status,
          code: `HTTP_${status}`,
          message,
          fieldErrors: {},
          errors: [],
        },
      });
    },
  );

  it('preserves an IWS error code and maps its field to the React Admin error body', async () => {
    const iwsError = {
      nomZone: 'id',
      code: 'CMG0003',
      valeur: 'A000',
      text: 'Filter value exceeds its maximum length',
      textUser: "L'identifiant est trop long",
    };
    const fetcher = vi.fn(async () =>
      new Response(JSON.stringify({ items: [], totalCount: 0, errors: [iwsError] }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'X-Correlation-Id': 'corr-123',
        },
      }),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
      },
      fetcher,
    });

    await expect(
      provider.getList('services', { filter: { id: 'A000' } }),
    ).rejects.toMatchObject({
      status: 400,
      message: "L'identifiant est trop long",
      body: {
        status: 400,
        code: 'CMG0003',
        message: "L'identifiant est trop long",
        fieldErrors: { id: "L'identifiant est trop long" },
        correlationId: 'corr-123',
        errors: [iwsError],
      },
    });
  });

  it('rejects a list item when the IWS response does not provide an identifier', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({
          items: [{ nom: 'Service sans identifiant' }],
          totalCount: 1,
          errors: [],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
      },
      fetcher,
    });

    await expect(
      provider.getList('services', { filter: {} }),
    ).rejects.toMatchObject({
      status: 500,
      body: {
        status: 500,
        code: 'IWS_INVALID_RESPONSE',
        message: 'Réponse IBM i invalide : identifiant absent',
      },
    });
  });

  it('rejects a detail whose identifier differs from the requested service', async () => {
    const fetcher = vi.fn(async () =>
      new Response(
        JSON.stringify({ item: { id: 'B00', nom: 'Autre service' }, errors: [] }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      ),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
      },
      fetcher,
    });

    await expect(
      provider.getOne('services', { id: 'A00' }),
    ).rejects.toMatchObject({
      status: 500,
      body: {
        status: 500,
        code: 'IWS_INVALID_RESPONSE',
        message: 'Réponse IBM i invalide : identifiant incohérent',
      },
    });
  });

  it('advertises abort support and forwards the React Admin signal to fetch', async () => {
    const fetcher = vi.fn(async () =>
      new Response(JSON.stringify({ item: { id: 'A00' }, errors: [] }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
    const provider = createIwsDataProvider({
      apiUrls: {
        services: 'https://ibmi.example/web/services/SERVIWS3',
      },
      fetcher,
    });
    const controller = new AbortController();

    await provider.getOne('services', {
      id: 'A00',
      signal: controller.signal,
    });

    expect(provider.supportAbortSignal).toBe(true);
    expect(fetcher).toHaveBeenCalledWith(
      'https://ibmi.example/web/services/SERVIWS3/A00',
      { headers: { Accept: 'application/json' }, signal: controller.signal },
    );
  });
});
