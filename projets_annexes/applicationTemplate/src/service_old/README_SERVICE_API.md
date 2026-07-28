# Service API REST

Cette API respecte le pattern dÃ©fini dans `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`.

## Configuration

**Table DB2:** department

## Endpoints

- `GET /api/services` - Liste avec pagination, filtres, tri
- `GET /api/services/{id}` - DÃ©tail item
- `POST /api/services` - CrÃ©ation
- `PUT /api/services/{id}` - Modification
- `DELETE /api/services/{id}` - Suppression

## Tests de Validation

``bash
# Collection avec pagination
curl "http://server:44000/api/services?_page=1&_limit=10"

# Filtres (Ã  adapter selon vos champs)
curl "http://server:44000/api/services?[champ]=valeur"
curl "http://server:44000/api/services?[champ]_gte=valeur"

# Recherche
curl "http://server:44000/api/services?q=terme"

# Tri
curl "http://server:44000/api/services?_sort=[champ]&_order=ASC"
``

## Prochaines Ã‰tapes

1. **Adapter les structures** dans `includes/service.rpgleinc` selon la table department
2. **Modifier les requÃªtes SQL** dans `service.sqlrpgle`
3. **Configurer les champs filtrables** dans la fonction `setupFilters`
4. **Tester** avec `scripts/validate_api_pattern.sh services`
5. **Compiler** avec `make -C src/service`

## ConformitÃ© Pattern

- [ ] Retourne tableau JSON pour collection
- [ ] Header X-Total-Count prÃ©sent
- [ ] Pagination (_page, _limit)
- [ ] Tri (_sort, _order)
- [ ] Filtres avec opÃ©rateurs (_gte, _like, etc.)
- [ ] CRUD complet (GET, POST, PUT, DELETE)
- [ ] Compatible React-Admin