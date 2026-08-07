export const fournisseursResourceContract = {
  "kind": "entity",
  "identifier": "id",
  "fields": [
    "id",
    "nom",
    "adresse",
    "ville",
    "telephone",
    "email"
  ],
  "capabilities": [
    "read",
    "create",
    "update"
  ],
  "list": {
    "filters": [
      "q",
      "ville"
    ],
    "sortFields": [
      "nom"
    ]
  }
} as const;
