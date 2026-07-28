# Plan de Mise en Œuvre - Repositionnement API REST

*Généré le 30 septembre 2025*

## 🎯 **Documents Créés**

### **Documentation Stratégique**
- ✅ `ressources/docs/strategique/analyse_repositionnement_sept2024.md`
- ✅ `ressources/docs/strategique/roadmap_technique_v2.md` 
- ✅ `ressources/docs/guides/guide_nouvelle_api_rest.md`
- ✅ `ressources/docs/guides/guide_bob_build.md` - **Guide BOB pour IBM i**

### **Scripts d'Automatisation**
- ✅ `scripts/validate_api_pattern.sh` - Validation pattern API REST
- ✅ `scripts/generate_api_skeleton.sh` - Générateur squelette API
- ⚠️ **Note** : Scripts utilitaires, build réel via BOB sur IBM i

### **Mise à Jour Existants**
- ✅ `ressources/docs/dsl/docs/dsl_langium/prd_projet.md` - Ajout évolution stratégique

## 🚀 **Actions Immédiates (Cette Semaine)**

### **1. Validation Pattern Employee (Aujourd'hui)**
```bash
# Build Employee API avec BOB sur IBM i
cd /home/[user]/projects/applicationTemplate
makei build -l src/employee

# Tests API (depuis machine cliente ou IBM i)
curl "http://your-ibmi:44000/api/employees"
curl -I "http://your-ibmi:44000/api/employees"  # Vérifier X-Total-Count
curl "http://your-ibmi:44000/api/employees?lastname_like=HAA"
curl "http://your-ibmi:44000/api/employees?salary_gte=50000"

# Script validation (à adapter pour votre environnement)
# scripts/validate_api_pattern.sh employees
```

### **2. Mise à Jour Employee API (Si Nécessaire)**
Si des tests échouent, référez-vous à `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md` pour corriger.

### **3. Test Génération Customer API**
```bash
# Générer Customer API comme exemple (machine de développement)
scripts/generate_api_skeleton.sh customer CUSTOMER

# Adapter sur IBM i puis build
ssh user@your-ibmi
cd /home/[user]/projects/applicationTemplate
git pull origin employee_rest
makei build -l src/customer

# Suivre le TODO généré
cat src/customer/TODO_CUSTOMER.md
```

## 📋 **Plan Sprint 0 (2 semaines) - ALIGNED avec Roadmap ibmi_rest_api_instructions.md** 

> 🎯 **RESPECT STRICT de la roadmap Point 14 - ibmi_rest_api_instructions.md**

### **Semaine 1 : Finalisation Phase 1 + Phase 2 (Filtres Avancés)** ⚠️ **EN COURS**
- [x] **Phase 1 : Fondations - VALIDÉES** (01 Oct 2025)
  - [x] Structure de base avec ILEastic ✅
  - [x] GET collection avec pagination basique ✅
  - [x] GET one ✅
  - [x] Header X-Total-Count ✅
  - [x] POST, PUT, DELETE ✅
  - [x] Plugin CORS officiel ILEastic intégré ✅

- [ ] **Phase 2 : Filtres Avancés** ⚠️ **IMPLÉMENTÉE - EN ATTENTE TESTS**
  - [x] 🚨 **PRIORITÉ 1** : Modifier CMAGIC_filter pour ajouter operator ✅ **TERMINÉ**
  - [x] 🚨 **PRIORITÉ 2** : setupFilters complet avec tous les opérateurs ✅ **TERMINÉ**
  - [x] 🚨 **PRIORITÉ 3** : Adapter employee_search pour utiliser operator ✅ **TERMINÉ**
  - [ ] 🚨 **PRIORITÉ 4** : Tests complets de tous les opérateurs ⚠️ **EN ATTENTE BUILD IBM i**

### **Semaine 2 : Phase 3 (Optimisation)**
- [ ] **Validation complète des données**
  - [ ] Validation email format
  - [ ] Validation ranges salaires/âges
  - [ ] Messages d'erreur standardisés JSON
- [ ] **Gestion erreurs métier détaillée**
  - [ ] Codes d'erreur business standardisés
  - [ ] Stack trace en mode debug
  - [ ] Logging erreurs avec CKOOL
- [ ] **Logging performance sur chaque endpoint**
  - [ ] Temps de réponse par endpoint
  - [ ] Monitoring requêtes lentes
  - [ ] Statistiques d'utilisation
- [ ] **Investigation Cache + Index DB2**
  - [ ] Analyse performance requêtes actuelles
  - [ ] Proposition index optimaux
  - [ ] POC cache simple (si temps)

## 🎯 **Critères de Succès Sprint 0 - BASÉS sur Roadmap ibmi_rest_api_instructions.md**

### **Phase 2 - Tests Filtres Avancés OBLIGATOIRES**
- [ ] **CMAGIC_filter modifié** : Structure avec champ `operator`
- [ ] **Tous les opérateurs fonctionnels** :
  - [ ] `=` (égal) : `?lastname=HAAS`
  - [ ] `LIKE` (contient) : `?lastname_like=HAA`
  - [ ] `>=` (supérieur égal) : `?salary_gte=50000`
  - [ ] `<=` (inférieur égal) : `?salary_lte=100000`
  - [ ] `<>` (différent) : `?department_ne=A00`
  - [ ] `>` (supérieur) : `?salary_gt=50000`
  - [ ] `<` (inférieur) : `?salary_lt=100000`
- [ ] **Tests combinés** : `?lastname_like=HAA&salary_gte=50000&department_ne=A00`
- [ ] **Build réussi** : `makei build -l src/employee` sur IBM i

### **Phase 3 - Tests Optimisation**
- [ ] **Validation données** : Erreurs JSON bien formatées pour données invalides
- [ ] **Gestion erreurs** : Codes HTTP appropriés (400, 404, 500)
- [ ] **Logging performance** : Temps réponse loggé pour chaque requête
- [ ] **Performance < 200ms** pour collections 1000+ records

### **Livrables Sprint 0**
- [ ] **Employee API Phase 2 complète** : Tous filtres avancés fonctionnels
- [ ] **Employee API Phase 3 démarrée** : Validation et logging implémentés
- [ ] **Documentation** : Écarts vs roadmap documentés
- [ ] **Tests** : Suite de tests cURL complète pour tous les opérateurs

### **🚫 NON Priorité Sprint 0**
- ❌ Customer API (sera Sprint 1 après finalisation Employee)
- ❌ Actions métier (Phase 4 - Sprint 2)
- ❌ Documentation OpenAPI (Phase 5 - Sprint 3)

## 📊 **Métriques à Collecter**

### **Performance**
- Temps réponse GET /api/employees (collection)
- Temps réponse GET /api/employees/{id} (item)
- Temps réponse avec filtres complexes
- Temps réponse avec pagination

### **Développement**
- Temps création Customer API (baseline pour optimisation)
- % code réutilisable entre Employee et Customer
- Nombre d'écarts vs pattern de référence

### **Adoption**
- Tests passants/totaux
- Compatibilité frontend (React-Admin, etc.)
- Feedback développeurs sur facilité d'usage

## 🛠️ **Commandes Utiles - FOCUS Phase 2 & 3**

### **Phase 2 - Tests Filtres Avancés**
```bash
# Build Employee API
makei build -l src/employee

# Tests filtres obligatoires selon roadmap
curl "http://server:44000/api/employees?lastname=HAAS"
curl "http://server:44000/api/employees?lastname_like=HAA" 
curl "http://server:44000/api/employees?salary_gte=50000"
curl "http://server:44000/api/employees?salary_lte=100000"
curl "http://server:44000/api/employees?department_ne=A00"
curl "http://server:44000/api/employees?salary_gt=50000"
curl "http://server:44000/api/employees?salary_lt=100000"

# Tests combinés (requis Phase 2)
curl "http://server:44000/api/employees?lastname_like=HAA&salary_gte=50000&department_ne=A00"
```

### **Phase 3 - Tests Optimisation**
```bash
# Tests validation données
curl -X POST "http://server:44000/api/employees" -d '{"email":"invalid-email"}' # Doit retourner 400
curl "http://server:44000/api/employees/INEXISTANT" # Doit retourner 404

# Tests performance (logging automatique requis)
curl -w "@curl-format.txt" "http://server:44000/api/employees?_page=1&_limit=100"

# Vérification logs performance
# Doit logger temps réponse pour chaque requête
```

### **🚫 Commandes NON Prioritaires Sprint 0**
```bash
# Customer API - Reporter à Sprint 3
# scripts/generate_api_skeleton.sh customer CUSTOMER
# curl "http://server:44000/api/customers"
```
curl "http://server:44000/api/customers?_page=1&_limit=5"
curl "http://server:44000/api/customers?custname_like=DUPONT"
```

## 📚 **Références**

### **Documentation Principale**
- **Pattern de référence** : `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- **Analyse stratégique** : `ressources/docs/strategique/analyse_repositionnement_sept2024.md`
- **Guide pratique** : `ressources/docs/guides/guide_nouvelle_api_rest.md`
- **Guide BOB** : `ressources/docs/guides/guide_bob_build.md` - **Pour build IBM i**

### **Roadmap**
- **Technique v2.0** : `ressources/docs/strategique/roadmap_technique_v2.md`
- **PRD mis à jour** : `ressources/docs/dsl/docs/dsl_langium/prd_projet.md`

## 🏆 **Vision Long Terme - ALIGNÉE avec Roadmap ibmi_rest_api_instructions.md**

### **Sprint 1 (3 semaines)** - Phase 4 : Actions Métier
- **Employee Actions Business**
  - [ ] POST /employees/{id}/increase-salary
  - [ ] POST /employees/{id}/promote  
  - [ ] POST /employees/{id}/transfer
  - [ ] Historique des actions
- **Pattern actions métier standardisé**
- **Tests unitaires actions**

### **Sprint 2 (2 semaines)** - Phase 5 : Documentation et Tests
- **Documentation OpenAPI/Swagger complète**
- **Tests automatisés RPG** pour toutes les APIs
- **Tests d'intégration** avec outils frontend
- **Guide déploiement** production

### **Sprint 3 (3 semaines)** - Généralisation (APRÈS Phases 1-5 complètes)
- **Customer API** (réplication pattern Employee finalisé)
- **Department API** + 1 autre API
- **Templates génériques** basés sur pattern validé
- **Guide création API < 2h**

### **Phase 2 (6+ mois)** - CMagic DSL
```cmagic
entity Customer {
    custno: String(6) required,
    custname: String(50),
    // → Génère automatiquement API REST conforme aux Phases 1-5
}
```

### **🎯 Principe Directeur**
> **Une seule API parfaite (Employee) avant toute généralisation**
> 
> Respecter scrupuleusement les 5 phases de la roadmap ibmi_rest_api_instructions.md

## 🎖️ **Conclusion - Alignement Roadmap Respecté**

Cette mise en œuvre CORRIGÉE respecte maintenant :
- ✅ **Roadmap ibmi_rest_api_instructions.md Point 14** : Phases 1-5 dans l'ordre
- ✅ **Phase 2 prioritaire** : Filtres avancés AVANT toute autre API
- ✅ **Phase 3 critique** : Optimisation et performance
- ✅ **Approche "Une API parfaite d'abord"** : Employee complète Phases 1-5
- ✅ **Générateur CMagic** : Basé sur pattern Employee validé toutes phases

**🚨 CHANGEMENT MAJEUR : Customer API reportée à Sprint 3 (après Employee Phases 1-5 complètes)**

**La roadmap ibmi_rest_api_instructions.md est désormais la référence absolue pour tous les sprints !** 🎯

---

*Pour toute question sur la mise en œuvre, référez-vous aux documents créés ou aux scripts fournis.*