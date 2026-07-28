# ✅ Checklist - Validation Nouvelle Entité API

> Checklist rapide pour valider qu'une nouvelle entité (ex: Product) est correctement implémentée

---

## 📁 FICHIERS CRÉÉS

### Structure Source
- [ ] `src/[entity]/[entity].sqlrpgle` - Module métier
- [ ] `src/[entity]/[entity].rest.sqlrpgle` - Handlers REST
- [ ] `src/[entity]/[entity].route.sqlrpgle` - Configuration routes
- [ ] `src/[entity]/[entity].bnd` - Binding source
- [ ] `src/[entity]/Rules.mk` - Configuration build
- [ ] `src/[entity]/README.md` - Documentation

### Includes
- [ ] `includes/[entity].rpgleinc` - Structures et prototypes

### Tests
- [ ] `test_[entity]_api.ps1` - Script de test automatisé

---

## 🔧 CONFIGURATION GIT

### Branche
- [ ] Branche `feature/api-[entity]` créée depuis `employee_rest`
- [ ] Commit initial avec message descriptif
- [ ] Branche pushée sur origin

### Intégration
- [ ] Routes ajoutées dans `src/main/main.sqlrpgle`
- [ ] Include ajouté dans les prototypes

---

## 🏗️ BUILD ET COMPILATION

### IBM i
- [ ] `bob --build src/[entity]` réussit sans erreur
- [ ] Aucun warning critique
- [ ] Module compilé accessible

### Service
- [ ] Service ILEastic redémarré
- [ ] Routes disponibles dans le routeur

---

## 🧪 TESTS FONCTIONNELS

### Tests de Base
- [ ] `GET /api/[entities]` - Retourne un tableau JSON
- [ ] Header `X-Total-Count` présent et correct
- [ ] `GET /api/[entities]/ID` - Retourne un objet JSON
- [ ] Status codes HTTP corrects (200, 201, 404, etc.)

### Pagination
- [ ] `?_page=1&_limit=5` - Retourne 5 éléments max
- [ ] `?_page=2&_limit=5` - Retourne la page suivante
- [ ] Header `X-Total-Count` identique sur toutes les pages

### Tri
- [ ] `?_sort=[field]&_order=asc` - Tri ascendant
- [ ] `?_sort=[field]&_order=desc` - Tri descendant

### Filtres de Base
- [ ] `?[field]=valeur` - Filtre exact
- [ ] `?[field]_like=pattern` - Filtre LIKE
- [ ] `?q=terme` - Recherche globale

### CRUD Operations
- [ ] `POST /api/[entities]` - Création réussie (201)
- [ ] `PUT /api/[entities]/ID` - Modification réussie (200)
- [ ] `DELETE /api/[entities]/ID` - Suppression réussie (200)

---

## 📊 VALIDATION DONNÉES

### Format JSON
- [ ] Collection : `[{...}, {...}]` (tableau)
- [ ] Item : `{...}` (objet)
- [ ] Champs correctement typés (string, number, boolean)
- [ ] Dates au format ISO (YYYY-MM-DD)

### Structures
- [ ] `[entity]_detail_t` - Structure complète
- [ ] `[entity]_item_t` - Structure liste
- [ ] `[entity]_input_t` - Structure saisie
- [ ] Champs ID correctement mappés

---

## 🔒 SÉCURITÉ ET CORS

### Headers
- [ ] `Access-Control-Allow-Origin` configuré
- [ ] `Access-Control-Expose-Headers` inclut `X-Total-Count`
- [ ] `Content-Type: application/json` correct

### Validation
- [ ] Champs obligatoires validés
- [ ] Types de données respectés
- [ ] Gestion d'erreurs appropriée

---

## 📚 DOCUMENTATION

### README.md
- [ ] Routes documentées avec exemples
- [ ] Paramètres de requête expliqués
- [ ] Format de données décrit
- [ ] Exemples cURL fournis

### Commentaires Code
- [ ] Procédures commentées
- [ ] SQL complexe expliqué
- [ ] TODO/FIXME résolus

---

## 🚀 COMPATIBILITÉ

### React-Admin
- [ ] Format collection respecté
- [ ] Header X-Total-Count présent
- [ ] Pagination fonctionnelle
- [ ] Tri et filtres supportés

### Tests avec Outils
- [ ] cURL - Tous les endpoints testés
- [ ] Postman/Insomnia - Collection créée
- [ ] Bruno - Tests automatisés (optionnel)

---

## ⚡ SCRIPT DE VALIDATION RAPIDE

```powershell
# Test rapide avec le script généré
.\test_[entity]_api.ps1 -BaseUrl "http://your-server:44000"

# Ou test manuel
curl -I "http://your-server:44000/api/[entities]"
curl "http://your-server:44000/api/[entities]?_page=1&_limit=5"
curl "http://your-server:44000/api/[entities]/ID001"
```

---

## 🎯 CRITÈRES DE SUCCÈS

### Must Have ✅
- [x] Build BOB réussi
- [x] Collection retourne un tableau
- [x] Header X-Total-Count présent
- [x] CRUD endpoints fonctionnels

### Should Have ⭐
- [x] Pagination complète
- [x] Filtres avancés
- [x] Documentation complète
- [x] Tests automatisés

### Nice to Have 🎁
- [x] Tests Bruno
- [x] Gestion d'erreurs robuste
- [x] Logging détaillé
- [x] Métriques de performance

---

## 🔧 DÉPANNAGE RAPIDE

### Build Échoue
```bash
# Vérifier les includes
ls -la includes/[entity].rpgleinc
cat includes/[entity].rpgleinc | grep -i error
```

### API ne Répond Pas
```bash
# Vérifier le service
curl -I "http://server:44000/health" || echo "Service down"
# Vérifier les logs ILEastic
```

### Format JSON Incorrect
```bash
# Tester la structure
curl "http://server:44000/api/[entities]" | jq type  # Doit retourner "array"
curl "http://server:44000/api/[entities]/ID" | jq type  # Doit retourner "object"
```

---

**✅ RÈGLE D'OR : Si tous les points de cette checklist sont verts, votre entité est prête pour la production !**

---

*Dernière mise à jour : $(Get-Date -Format "yyyy-MM-dd")*