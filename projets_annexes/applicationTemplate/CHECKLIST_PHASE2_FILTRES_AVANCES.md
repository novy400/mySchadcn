# Checklist de Validation Phase 2 - Filtres Avancés

*Généré le 1er octobre 2025 - Suite du Plan de Mise en Œuvre Sprint 0*

## 🎯 **OBJECTIF PHASE 2**
Valider que tous les opérateurs de filtrage avancés fonctionnent selon les spécifications de `ibmi_rest_api_instructions.md`.

## 📋 **PRIORITÉ 4 : Tests Complets de Tous les Opérateurs**

### **Étape 1 : Compilation et Build** ⚠️ **CRITIQUE**
- [ ] **Build successful** : `bob --build src/employee` sur IBM i
- [ ] **Aucune erreur de compilation RPG**
- [ ] **Service ILEastic démarré** et accessible

### **Étape 2 : Tests Opérateurs Individuels**

#### **2.1 Opérateur EQUAL (=)**
- [ ] **Test 1.1** : `GET /api/employees?nom=HAAS`
  - Retourne uniquement les employés avec nom exactement "HAAS"
  - Réponse = tableau JSON `[...]`
  - Header `X-Total-Count` présent

- [ ] **Test 1.2** : `GET /api/employees?service=A00`
  - Retourne uniquement les employés du service "A00"

#### **2.2 Opérateur LIKE**
- [ ] **Test 2.1** : `GET /api/employees?nom_like=HAA`
  - Retourne employés avec nom contenant "HAA" (HAAS, HAAGEN, etc.)
  - Conversion automatique en `%HAA%` dans la requête SQL

- [ ] **Test 2.2** : `GET /api/employees?prenom_like=CHR`
  - Retourne employés avec prénom contenant "CHR" (CHRISTINE, CHRISTOPHER, etc.)

#### **2.3 Opérateur GREATER_EQUAL (>=)**
- [ ] **Test 3.1** : `GET /api/employees?salaire_gte=50000`
  - Retourne employés avec salaire >= 50000

#### **2.4 Opérateur LESS_EQUAL (<=)**
- [ ] **Test 4.1** : `GET /api/employees?salaire_lte=100000`
  - Retourne employés avec salaire <= 100000

#### **2.5 Opérateur GREATER (>)**
- [ ] **Test 5.1** : `GET /api/employees?salaire_gt=50000`
  - Retourne employés avec salaire > 50000 (strictement supérieur)

#### **2.6 Opérateur LESS (<)**
- [ ] **Test 6.1** : `GET /api/employees?salaire_lt=100000`
  - Retourne employés avec salaire < 100000 (strictement inférieur)

#### **2.7 Opérateur NOT_EQUAL (<>)**
- [ ] **Test 7.1** : `GET /api/employees?service_ne=A00`
  - Retourne employés avec service différent de "A00"

### **Étape 3 : Tests Fonctionnalités Spéciales**

#### **3.1 Recherche Générale 'q'**
- [ ] **Test 8.1** : `GET /api/employees?q=HAAS`
  - Recherche dans nom, prénom, service
  - Utilise LIKE avec `%HAAS%` sur plusieurs champs
  - Clause WHERE : `(lastname LIKE '%HAAS%' OR firstnme LIKE '%HAAS%' OR workdept LIKE '%HAAS%')`

#### **3.2 Filtres Combinés**
- [ ] **Test 9.1** : `GET /api/employees?nom_like=HAA&salaire_gte=50000`
  - Combine LIKE et GREATER_EQUAL avec AND

- [ ] **Test 9.2** : `GET /api/employees?nom_like=HAA&salaire_gte=50000&service_ne=A00`
  - Combine 3 filtres avec AND

#### **3.3 Pagination avec Filtres**
- [ ] **Test 10.1** : `GET /api/employees?nom_like=A&_page=1&_limit=5`
  - Filtres + pagination fonctionnent ensemble
  - X-Total-Count = nombre total AVANT pagination
  - Réponse limitée à 5 éléments max

### **Étape 4 : Tests de Conformité**

#### **4.1 Headers HTTP Obligatoires**
- [ ] **Test 11.1** : Vérifier header `X-Total-Count`
  ```bash
  curl -I "http://server:44000/api/employees?nom_like=A"
  ```
  - Header présent dans toutes les réponses GET collection

- [ ] **Test 11.2** : Vérifier header `Access-Control-Expose-Headers`
  - Contient `X-Total-Count` pour CORS

#### **4.2 Format de Réponse**
- [ ] **Test 12.1** : Collection retourne tableau
  - `GET /api/employees` → `[{...}, {...}]`
  - PAS `{data: [...], total: 123}`

- [ ] **Test 12.2** : Item unique retourne objet
  - `GET /api/employees/000010` → `{...}`

#### **4.3 Gestion des Erreurs**
- [ ] **Test 13.1** : Paramètre invalide
  - `GET /api/employees?salaire_gte=ABC` → Erreur appropriée

- [ ] **Test 13.2** : Champ inexistant
  - `GET /api/employees?champInexistant=test` → Ignoré ou erreur appropriée

### **Étape 5 : Tests de Performance**

#### **5.1 Logging et Debug**
- [ ] **Test 14.1** : Vérifier logs CKOOL
  - Messages de debug pour chaque filtre détecté
  - Format : `"Filtre LIKE détecté: nom LIKE valeur"`

- [ ] **Test 14.2** : SQL généré correct
  - Message `snd-msg *INFO` contient SQL bien formé
  - Clauses WHERE correctes selon opérateurs

#### **5.2 Performance de Base**
- [ ] **Test 15.1** : Temps de réponse < 500ms
  - Collection avec filtres simples
  - Mesurer avec `curl -w "@curl-format.txt"`

## 🛠️ **COMMANDES DE TEST RAPIDES**

### **Test Automatique**
```powershell
# Exécuter le script de test Phase 2
.\test_phase2_filtres_avances.ps1 -ServerUrl "http://your-ibmi:44000"
```

### **Tests Manuels cURL**
```bash
# Tests de base (OBLIGATOIRES)
curl "http://server:44000/api/employees?nom=HAAS"
curl "http://server:44000/api/employees?nom_like=HAA"
curl "http://server:44000/api/employees?salaire_gte=50000"
curl "http://server:44000/api/employees?salaire_lte=100000"
curl "http://server:44000/api/employees?service_ne=A00"

# Tests combinés (CRITIQUES)
curl "http://server:44000/api/employees?nom_like=HAA&salaire_gte=50000&service_ne=A00"

# Test recherche générale
curl "http://server:44000/api/employees?q=HAAS"

# Vérification headers
curl -I "http://server:44000/api/employees"
```

## ✅ **CRITÈRES DE SUCCÈS PHASE 2**

### **Succès Minimum (70%)**
- [x] Structure CMAGIC_filter modifiée avec operator ✅
- [ ] setupFilters détecte au moins 5 opérateurs sur 7
- [ ] employee_search génère SQL correct pour filtres basiques
- [ ] Tests EQUAL, LIKE, GTE, LTE passent

### **Succès Complet (100%)**
- [x] Structure CMAGIC_filter complète ✅
- [x] setupFilters détecte tous les 7 opérateurs ✅
- [x] employee_search utilise operator pour tous les cas ✅
- [ ] **TOUS** les tests individuels passent
- [ ] Filtres combinés fonctionnent
- [ ] Recherche générale 'q' fonctionne
- [ ] Headers HTTP conformes
- [ ] Performance acceptable

## 🎯 **PROCHAINES ÉTAPES**

### **Si Phase 2 = 100%**
➡️ **Démarrer Phase 3 : Optimisation**
- Validation données avancée
- Gestion erreurs métier
- Logging performance
- Investigation cache + index

### **Si Phase 2 < 100%**
➡️ **Corriger les écarts avant Phase 3**
- Analyser logs d'erreurs
- Corriger SQL généré
- Vérifier mapping champs/colonnes
- Re-tester jusqu'à 100%

## 📊 **MÉTRIQUES À COLLECTER**

- **Temps de compilation** : `bob --build src/employee`
- **Nombre de tests passants** / Total (cible 100%)
- **Temps de réponse moyen** pour chaque opérateur
- **Taille moyenne des réponses** JSON

---

**🎯 RÈGLE D'OR PHASE 2 :** Aucune Phase 3 sans 100% de réussite Phase 2. Les filtres avancés sont la base de toute API REST moderne.

**⚡ ORDRE DE PRIORITÉ :** Build → Tests individuels → Tests combinés → Performance → Phase 3