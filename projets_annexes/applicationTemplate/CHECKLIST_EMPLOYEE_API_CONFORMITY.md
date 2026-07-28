# Checklist de Conformité API Employee - Sprint 0

## 🎯 Objectif
Valider que l'API Employee est 100% conforme au standard défini dans `ibmi_rest_api_instructions.md` avant de lancer le Sprint 1.

## ✅ Modifications Effectuées

### Structure et Routes
- [x] **employee.main.rpgle** : Utilise `employee_registerAPI()` au lieu de routes manuelles
- [x] **employee.rest.sqlrpgle** : Headers CORS ajoutés à tous les endpoints
- [x] **employee.rest.sqlrpgle** : DELETE retourne 200 OK + objet supprimé (au lieu de 204)
- [x] **employee.route.sqlrpgle** : Patterns d'URL corrects avec regex `([0-9A-Za-z]+)`

### Headers HTTP
- [x] **X-Total-Count** : Présent dans GET collection
- [x] **Access-Control-Expose-Headers** : X-Total-Count exposé pour CORS
- [x] **Access-Control-Allow-Origin** : * ajouté à tous les endpoints
- [x] **Content-Type** : application/json sur toutes les réponses

## 🧪 Tests de Validation Requis

### 1. Build et Déploiement
```bash
# Sur IBM i - Test de compilation
bob --build src/employee
```
- [ ] ✅ Build réussi sans erreur
- [ ] ✅ Modules créés correctement
- [ ] ✅ Service binding correct

### 2. Tests cURL depuis IBM i ou client

#### GET Collection (Obligatoire)
```bash
curl -i "http://ibmi:44000/api/employees"
```
**Attendu :**
- [ ] ✅ Status: 200 OK
- [ ] ✅ Content-Type: application/json
- [ ] ✅ Header X-Total-Count présent
- [ ] ✅ Header Access-Control-Expose-Headers: X-Total-Count
- [ ] ✅ Réponse = tableau JSON `[...]`

#### GET Collection avec Pagination
```bash
curl -i "http://ibmi:44000/api/employees?_page=1&_limit=5"
```
**Attendu :**
- [ ] ✅ Status: 200 OK
- [ ] ✅ Max 5 éléments dans le tableau
- [ ] ✅ X-Total-Count = total (pas seulement les 5)

#### GET Collection avec Filtres
```bash
curl -i "http://ibmi:44000/api/employees?lastname_like=HAA"
curl -i "http://ibmi:44000/api/employees?salary_gte=50000"
```
**Attendu :**
- [ ] ✅ Status: 200 OK
- [ ] ✅ Résultats filtrés correctement
- [ ] ✅ X-Total-Count = nombre d'éléments filtrés

#### GET One
```bash
curl -i "http://ibmi:44000/api/employees/000010"
```
**Attendu :**
- [ ] ✅ Status: 200 OK
- [ ] ✅ Réponse = objet JSON `{...}` (pas tableau)
- [ ] ✅ Headers CORS présents

#### POST Create
```bash
curl -i -X POST "http://ibmi:44000/api/employees" \
  -H "Content-Type: application/json" \
  -d '{"prenom":"TEST","nom":"EMPLOYEE","service":"A00","salaire":50000}'
```
**Attendu :**
- [ ] ✅ Status: 201 Created
- [ ] ✅ Réponse = objet créé avec ID généré
- [ ] ✅ Headers CORS présents

#### PUT Update
```bash
curl -i -X PUT "http://ibmi:44000/api/employees/TESTID" \
  -H "Content-Type: application/json" \
  -d '{"salaire":55000}'
```
**Attendu :**
- [ ] ✅ Status: 200 OK
- [ ] ✅ Réponse = objet mis à jour complet
- [ ] ✅ Headers CORS présents

#### DELETE
```bash
curl -i -X DELETE "http://ibmi:44000/api/employees/TESTID"
```
**Attendu :**
- [ ] ✅ Status: 200 OK (pas 204)
- [ ] ✅ Réponse = objet supprimé `{...}`
- [ ] ✅ Headers CORS présents

### 3. Tests de Performance (Optionnel)
```bash
# Collection avec 1000+ records
time curl "http://ibmi:44000/api/employees?_limit=100"
```
**Attendu :**
- [ ] ✅ Temps réponse < 200ms pour collections importantes

### 4. Tests d'Intégration Frontend (Si disponible)

#### React-Admin Simple REST
- [ ] ✅ Liste d'employés charge correctement
- [ ] ✅ Pagination fonctionne
- [ ] ✅ Filtres fonctionnent
- [ ] ✅ CRUD complet fonctionnel

## 🚨 Points Critiques Validés

### Architecture Conforme
- [x] **Séparation responsabilités** : .main.rpgle → .route.sqlrpgle → .rest.sqlrpgle → .sqlrpgle
- [x] **Patterns d'URL** : Regex corrects pour capture d'ID
- [x] **Headers standards** : CORS, Content-Type, X-Total-Count

### Format JSON Standard
- [x] **GET collection** → `[...]` + X-Total-Count
- [x] **GET item** → `{...}`
- [x] **POST** → 201 Created + objet créé
- [x] **PUT** → 200 OK + objet modifié
- [x] **DELETE** → 200 OK + objet supprimé

### Paramètres REST Standard
- [x] **Pagination** : `_page`, `_limit` 
- [x] **Tri** : `_sort`, `_order`
- [x] **Filtres** : `field_like`, `field_gte`, etc.
- [x] **Recherche** : `q=terme`

## 🎯 Validation Sprint 0 → Sprint 1

### Critères de Passage
- [ ] ✅ Tous les tests cURL passent
- [ ] ✅ Build BOB réussi sur IBM i  
- [ ] ✅ Performance < 200ms acceptable
- [ ] ✅ Documentation des éventuels écarts

### Actions Sprint 1 (si validation OK)
1. **Department API** : Créer en suivant pattern Employee validé
2. **Templates génériques** : Extraire patterns réutilisables
3. **Scripts d'automatisation** : Finaliser générateur squelette

## 📝 Notes de Test

### Environnement
- **Serveur IBM i** : `____________________`
- **Port** : 44000
- **Date test** : `____________________`
- **Testeur** : `____________________`

### Résultats
```
[Copier ici les résultats des tests cURL]
```

### Écarts Identifiés
```
[Documenter ici tout écart par rapport au standard]
```

## 🎉 Validation Finale

**Sprint 0 Employee API Conforme** : ⬜ OUI / ⬜ NON

**Prêt pour Sprint 1** : ⬜ OUI / ⬜ NON

**Signature** : `____________________` **Date** : `____________________`