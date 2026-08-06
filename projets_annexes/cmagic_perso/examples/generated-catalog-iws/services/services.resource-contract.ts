export const servicesResourceContract = {
  "kind": "entity",
  "identifier": "id",
  "fields": [
    "id",
    "nom",
    "idManageur",
    "idServiceAdmin",
    "site"
  ],
  "capabilities": [
    "read",
    "create"
  ],
  "list": {
    "filters": [
      "q",
      "id",
      "nom",
      "idManageur",
      "idServiceAdmin",
      "site"
    ],
    "sortFields": [
      "id",
      "nom"
    ]
  }
} as const;
