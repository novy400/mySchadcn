# 🚀 Modern IBM i API Development - ApplicationTemplate

> **Template & Learning Repository** pour la modernisation IBM i avec APIs REST  
> 🎬 **Projet TechServ** : Série YouTube "Modern IBM i API Development"

## 📖 À Propos

Ce repository contient :

### **🎯 Template Production-Ready**
- ✅ **Patterns API REST** validés avec ILEastic
- ✅ **Structure modulaire** réutilisable
- ✅ **Standards modernes** compatibles React-Admin/Appsmith/Retool
- ✅ **Build automation** avec BOB

### **🎬 Projet TechServ - Série YouTube**
- 📺 **20 épisodes** de développement API en direct
- 🏢 **Use case réel** : PME maintenance technique
- 🎓 **Pédagogie complète** : du CRUD aux APIs complexes
- 🌟 **Open Source** : code disponible pour tous

### **🔮 Vision Future : Générateur CMagic**
- 🎨 **DSL** pour génération automatique d'APIs
- ⚡ **Patterns CUA** (CREATE, UPDATE, DELETE, DISPLAY, WORK_WITH)
- 🔄 **Workflow** par statuts (State Machine)
- 🏗️ **Architecture** Entity as Object

## 🏢 TechServ - Use Case Série YouTube

**TechServ** est une PME spécialisée dans la maintenance technique qui modernise son système IBM i :

### **Problématique**
- ❌ Interface 5250 peu ergonomique
- ❌ Pas d'accès mobile pour techniciens terrain  
- ❌ Impossibilité d'intégrer outils modernes
- ❌ Difficulté recrutement développeurs RPG

### **Solution**
- ✅ APIs REST sur données IBM i existantes
- ✅ Dashboard React-Admin pour dispatcher
- ✅ App mobile pour techniciens
- ✅ Zéro migration de données

### **Architecture**
```
Mobile + React-Admin → APIs REST (ILEastic) → IBM i (RPG + DB2)
```

## 📺 Série YouTube - 20 Épisodes

### **🌟 Saison 1 : Fondations (1-6)**
1. **Introduction - Building TechServ Together** *(12-15 min)*
2. **Your First API - Technicians CRUD** *(25-30 min)*
3. **Reference Data Made Easy - Service Types** *(15-20 min)*
4. **Business Entity - Customers with Validation** *(30-35 min)*
5. **Testing Like a Pro - Automation & Quality** *(20-25 min)*
6. **First Frontend - React Admin Setup** *(30-35 min)*

### **🔗 Saison 2 : Relations & Workflow (7-12)**
7. **Relations 101 - Locations & Equipments** *(30 min)*
8. **The Core - Service Requests Entity** *(35-40 min)*
9. **Workflow Magic - Status State Machine** *(30-35 min)*
10. **Real Work - Interventions & Time Tracking** *(35 min)*
11. **Dashboard Power - Analytics & Reporting** *(30 min)*
12. **Mobile First - Technician App Concept** *(25-30 min)*

### **🚀 Saison 3 : Production Ready (13-16)**
### **🎨 Saison 4 : Code Generation (17-20)**

**[➡️ Voir planning complet](PROJET_TECHSERV_YOUTUBE.md)**

## 🛠️ Installation & Setup

### **Prérequis**
- IBM i 7.3+ avec BOB (Build automation)
- ILEastic framework installé
- Git configuré
- Accès SQL (création tables)

### **Installation Rapide**
```bash
# Cloner le repository
git clone https://github.com/novy400/applicationTemplate.git
cd applicationTemplate

# TechServ: Créer les tables (Phase 1)
db2 -f ressources/data/technicians.sql
db2 -f ressources/data/service_types.sql
db2 -f ressources/data/customers.sql

# Build des APIs
bob --build src/techserv

# Tests de validation
./tests/validate_techserv_apis.sh
```

## 📁 Structure du Projet

### **Organisation Modulaire**
```
applicationTemplate/
├── src/
│   ├── employee/              # Template de référence (validé)
│   │   ├── employee.rest.sqlrpgle
│   │   ├── employee.route.sqlrpgle
│   │   ├── employee.sqlrpgle
│   │   └── employee.bnd
│   └── techserv/             # Projet série YouTube
│       ├── technician/       # Episode 2: API Technicians
│       ├── servicetype/      # Episode 3: API ServiceTypes
│       └── customer/         # Episode 4: API Customers
│
├── includes/                 # Prototypes et structures
│   ├── cmagic.rpgleinc      # Framework CMAGIC
│   ├── employee.rpgleinc    # Template de référence
│   ├── technician.rpgleinc  # TechServ structures
│   └── ileastic/            # ILEastic framework
│
├── ressources/
│   ├── data/                # Scripts SQL tables
│   │   ├── technicians.sql
│   │   ├── service_types.sql
│   │   └── customers.sql
│   ├── docs/                # Documentation technique
│   │   ├── copilotInstructions/
│   │   └── dsl/
│   └── api/
│       └── bruno/           # Collections tests API
│
├── youtube/                 # Assets série YouTube
│   └── episodes/
│       └── ep01_intro/      # Episode 1 assets
│
├── tests/                   # Tests automatisés
│   ├── validate_techserv_apis.sh
│   └── bruno/              # Tests interactifs
│
└── frontend/               # Future: React-Admin (Episode 6)
    └── techserv-admin/
```

### **Standards Architecture**

Chaque API suit le pattern validé :
- **`.main.rpgle`** : Point d'entrée ILEastic
- **`.route.sqlrpgle`** : Configuration routes REST
- **`.rest.sqlrpgle`** : Handlers HTTP + JSON
- **`.sqlrpgle`** : Logique métier + SQL
- **`.bnd`** : Binding source
- **`.rpgleinc`** : Prototypes et structures

## 🧪 Tests & Validation

### **Tests Automatisés**
```bash
# Test complet toutes APIs
./tests/validate_all_apis.sh

# Test APIs TechServ spécifiquement
./tests/validate_techserv_apis.sh

# Test API spécifique
./tests/test_technicians_api.sh
```

### **Collection Bruno**
Tests interactifs dans `ressources/api/bruno/` :
- Employee (template validé)
- TechServ (Technicians, ServiceTypes, Customers)

### **Standards Validation**
Chaque API respecte :
- ✅ GET collection → `[...]` + header `X-Total-Count`
- ✅ GET item → `{...}`
- ✅ POST → `201 Created` + objet créé
- ✅ PUT/DELETE → `200 OK`
- ✅ Pagination : `_page`, `_limit`
- ✅ Tri : `_sort`, `_order`
- ✅ Filtres : `field=value`, `field_like`, etc.

## 📚 Documentation

### **Guides Techniques**
- **[API REST Instructions](ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md)** : Patterns complets
- **[CMagic DSL Vision](ressources/docs/dsl/docs/dsl_langium/prd_projet.md)** : Générateur futur
- **[TechServ Use Case](src/techserv/README_TECHSERV.md)** : Détails projet série

### **Épisodes YouTube**
- **[Episode 1 Assets](youtube/episodes/ep01_intro/)** : Introduction et vision
- **[Série Complète Planning](PROJET_TECHSERV_YOUTUBE.md)** : 20 épisodes détaillés

### **Templates Réutilisables**
- **Employee API** : Pattern CRUD validé
- **CMAGIC Framework** : Pagination, filtres, tri
- **Build BOB** : Automation compilation

## 🤝 Contribuer

### **Comment Participer**
1. **⭐ Star le repository** si le projet vous intéresse
2. **🐛 Reporter bugs/améliorations** via GitHub Issues
3. **💻 Contribuer code** : PRs bienvenues
4. **📝 Améliorer documentation** : typos, exemples, guides
5. **🧪 Ajouter tests** : cas de tests supplémentaires
6. **💬 Partager expérience** : commentaires YouTube, discussions

### **Types de Contributions**
- **Adaptations métier** : Garage, clinique, école, etc.
- **Patterns avancés** : Authentification, cache, optimisations
- **Frontends alternatifs** : Vue.js, Angular, mobile natif
- **Intégrations** : Power BI, Tableau, outils tiers

## 🔗 Liens Utiles

### **Projet**
- **Repository** : https://github.com/novy400/applicationTemplate
- **Issues** : Questions et suggestions
- **Discussions** : Échanges communauté
- **Wiki** : Documentation étendue

### **Série YouTube**
- **Chaîne** : [Lien à venir]
- **Playlist** : "Modern IBM i API Development"
- **Schedule** : 1 épisode/semaine, mardi 18h CET

### **Communauté IBM i**
- Common User Group
- IBM i Community Forum
- Reddit r/IBMi
- LinkedIn IBM i Developers Group

## 📈 Résultats Attendus

### **Techniques**
- ✅ 10+ APIs REST conformes standards
- ✅ Suite tests 100% automatisée
- ✅ Build BOB 100% réussi
- ✅ Compatible React-Admin/Appsmith/Retool

### **Pédagogiques**
- 📺 1000+ vues totales série
- ⭐ 100+ stars GitHub
- 💬 Engagement communauté actif
- 🤝 5+ contributeurs externes

### **Impact Business**
- 💼 Template réutilisable pour PME similaires
- 📚 Documentation patterns validés
- 🎓 Formation communauté IBM i
- 🚀 Base générateur CMagic

## 📞 Contact

**Questions/Suggestions** :
- 🐛 **GitHub Issues** : Bugs et améliorations techniques
- 💬 **YouTube Comments** : Questions sur épisodes
- 💼 **LinkedIn** : Messages professionnels

---

## 📋 Status Développement

### **✅ Template Base Validé**
- [x] Employee API (pattern de référence)
- [x] CMAGIC framework complet
- [x] Build BOB fonctionnel
- [x] Tests automatisés

### **🔄 TechServ En Cours (Série YouTube)**
- [x] Structure projet TechServ
- [x] Scripts SQL Phase 1 (tables)
- [x] Includes et prototypes
- [ ] Episode 1 : Assets visuels + script
- [ ] Episode 2 : API Technicians
- [ ] Episode 3-6 : APIs + React-Admin

### **⏳ À Venir**
- Phase 2 : Relations & Workflow
- Phase 3 : Production Ready  
- Phase 4 : Code Generation CMagic

---

*Créé le 24 novembre 2025*  
*ApplicationTemplate - Modern IBM i API Development*  
*Template Production + Série YouTube Éducative*