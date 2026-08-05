# Relevé HTTP IWS du 5 août 2026

Ce relevé conserve les résultats observés directement sur le service de test :

- URL : `http://cmspw7t:10074/web/services/SERVIWS3` ;
- serveur : Apache sur IBM i ;
- heure des appels initiaux : `2026-08-05 13:17:52 UTC` ;
- heure du contrôle final après redéploiement : `2026-08-05 14:46:26 UTC` ;
- transport : HTTP, environnement de test uniquement.

## Résultats

| Cas | Requête | Statut | Résultat observé |
| --- | --- | ---: | --- |
| Liste | `/SERVIWS3` | 200 | 10 éléments retournés, `totalCount: 14`, `errors: []` |
| Pagination | `?page=1&perPage=3` | 200 | 3 éléments, `totalCount: 14` |
| Tri | `?page=1&perPage=10&sort=nom&order=ASC` | 200 | noms triés par ordre croissant |
| Recherche | `?q=PLANNING` | 200 | un élément `B01`, `totalCount: 1` |
| Filtre exact | `?id=A00` | 200 | un élément `A00`, `totalCount: 1` |
| Tri inconnu | `?sort=inconnu&order=ASC` | 400 | erreur `CMG0001` sur `inconnu` |
| Identifiant trop long | `?id=A000` | 400 | erreur `CMG0003` sur `id`, valeur `A000` |
| GET par identifiant non publié | `/SERVIWS3/A00` | 404 | conforme à la limite LIST/SEARCH de la v0 |

## En-têtes nominaux

```text
HTTP/1.1 200 OK
Server: Apache
X-Powered-By: IBM i
Access-Control-Expose-Headers: X-Total-Count
X-Total-Count: 14
Content-Type: application/json;charset=utf-8
```

Corps nominal résumé :

```json
{
  "items": [
    {
      "id": "A00",
      "nom": "SPIFFY COMPUTER SERVICE DIV.",
      "idManageur": "000010",
      "idServiceAdmin": "A00",
      "site": ""
    }
  ],
  "totalCount": 14,
  "errors": []
}
```

## Réponses d'erreur contrôlées

Le tri inconnu produit bien un statut HTTP `400` et un corps exploitable :

```json
{
  "items": [],
  "totalCount": 0,
  "errors": [
    {
      "nomZone": "inconnu",
      "code": "CMG0001",
      "valeur": "inconnu",
      "text": "Champ de tri inconnu : inconnu",
      "textUser": ""
    }
  ]
}
```

Avant correction et redéploiement, la valeur trop longue produisait :

```text
HTTP/1.1 200 OK
X-Total-Count: 0
```

```json
{"items":[],"totalCount":0,"errors":[]}
```

Après compilation de `CMAGIC.0.0.2`, reconstruction de `SERVICE`/`SERVIWS` et
redéploiement, le contrôle final produit :

```text
HTTP/1.1 400 Bad Request
Content-Type: application/json;charset=utf-8
```

```json
{
  "items": [],
  "totalCount": 0,
  "errors": [
    {
      "nomZone": "id",
      "code": "CMG0003",
      "valeur": "A000",
      "text": "Valeur de filtre trop longue (maximum 3)",
      "textUser": ""
    }
  ]
}
```

Une requête `?id=A00` exécutée immédiatement après a répondu `200`, avec un élément
`A00`, `totalCount: 1` et aucune erreur. La reprise après erreur est donc validée.

## Diagnostic et correction validée

Le catalogue et le contrat OpenAPI CMagic limitent `id` à trois caractères, mais le
runtime partagé ne recevait pas cette longueur dans `CMAGIC_supportedField`. Le module
généré transmettait donc `A000` à la recherche SQL, qui répondait simplement avec zéro
ligne.

Le générateur publie désormais la longueur du CatalogSpec dans
`CMAGIC_supportedField.maxLength`. La validation reste concentrée dans
`cmagic_sanitizeContext`, qui refuse la valeur avec `CMG0003` avant la génération du
SQL. Un test RPGUnit CMagic couvre `id=A000` et un test de génération vérifie la
métadonnée `maxLength = 3`. La correction a été compilée et testée sur IBM i dans
`CMAGIC`, `SERVICE` et `SERVIWS`. Les suites RPGUnit ont été confirmées vertes et le
contrôle HTTP final valide le comportement de bout en bout.

## Contrat IWS restant à archiver

L'URL `/openapi/` du serveur de test a répondu `404`. Le fichier
`services.openapi.json` de CMagic n'est pas l'export du serveur IWS. La description
Swagger/OpenAPI issue de l'administration IWS reste donc à télécharger pour fermer la
porte documentaire correspondante.
