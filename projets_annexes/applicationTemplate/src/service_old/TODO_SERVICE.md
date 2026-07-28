# TODO Service API

## âœ… GÃ©nÃ©ration Automatique TerminÃ©e

- [x] Structure de fichiers crÃ©Ã©e
- [x] Renommage des fichiers effectuÃ©
- [x] Adaptations de base appliquÃ©es

## ðŸ”„ Adaptations Manuelles Requises

### 1. Structures de DonnÃ©es (30 min)
- [ ] Modifier `includes/service.rpgleinc`
- [ ] Adapter `service_detail_t` selon table department
- [ ] Adapter `service_item_t` (version optimisÃ©e)
- [ ] Adapter `service_input_t` (crÃ©ation/modification)

### 2. RequÃªtes SQL (45 min)
- [ ] Modifier SELECT dans `service_search`
- [ ] Adapter requÃªte complÃ¨te dans `service_getById`
- [ ] Configurer `supportedFields` pour filtres
- [ ] Configurer `sortableFields` pour tri
- [ ] Configurer `searchableFields` pour recherche

### 3. Validation (15 min)
- [ ] Compiler: `make -C src/service`
- [ ] Tester: `scripts/validate_api_pattern.sh services`
- [ ] VÃ©rifier tous les endpoints
- [ ] Tester avec React-Admin si disponible

### 4. Documentation (10 min)
- [ ] ComplÃ©ter README avec exemples rÃ©els
- [ ] Documenter champs spÃ©cifiques
- [ ] Ajouter exemples cURL avec vraies donnÃ©es

## ðŸ“‹ Checklist ConformitÃ©

- [ ] GET /api/services retourne tableau JSON
- [ ] Header X-Total-Count prÃ©sent
- [ ] Pagination fonctionne
- [ ] Filtres simples fonctionnent
- [ ] OpÃ©rateurs avancÃ©s fonctionnent
- [ ] Recherche textuelle fonctionne
- [ ] Tri fonctionne
- [ ] CRUD complet fonctionne

## ðŸš€ Actions MÃ©tier Futures

- [ ] Identifier actions spÃ©cifiques Ã  service
- [ ] ImplÃ©menter endpoints d'actions
- [ ] Documenter logique mÃ©tier