# 📁 TechServ - Modern IBM i API Development Project

> **Projet Démo** : Série YouTube "Modern IBM i API Development"  
> **Use Case** : Système de gestion de services techniques pour PME

## 🏢 À Propos de TechServ

**TechServ** est une PME fictive (mais réaliste) spécialisée dans la maintenance technique :
- 🔧 **HVAC** (Chauffage, Ventilation, Climatisation)
- ⚡ **Électricité** (Installation, Réparation, Maintenance)
- 🚰 **Plomberie** (Dépannage, Installation)
- 🔨 **Maintenance Générale**

### **Problématique Business**

TechServ utilise IBM i depuis 20 ans avec des programmes RPG legacy :

❌ **Interface 5250 peu ergonomique**  
- Sarah (dispatcher) navigue dans des écrans verts pour planifier les interventions
- Pas de vue d'ensemble, navigation lente entre les écrans

❌ **Pas d'accès mobile pour techniciens terrain**  
- Jean (technicien) doit appeler Sarah pour chaque mise à jour
- Impossible de consulter détails intervention sur site
- Time tracking manuel avec risque d'erreurs

❌ **Impossibilité d'intégrer outils modernes**  
- Pas d'API pour connecter app mobile
- Pas d'interface web pour clients
- Tableaux de bord impossibles

❌ **Difficulté recrutement développeurs**  
- Peu de développeurs connaissent RPG
- Interface 5250 rebutante pour jeunes développeurs

### **Solution : Modernisation Sans Risque**

✅ **Garder logique métier IBM i existante**  
- 20 ans de programmes RPG validés
- Aucune migration de données
- Business rules préservées

✅ **Ajouter couche API REST moderne**  
- RPG ILE + ILEastic framework
- Standards REST (pagination, filtres, tri)
- Format JSON compatible React-Admin

✅ **Créer interfaces modernes**  
- Dashboard React-Admin pour Sarah
- App mobile PWA pour Jean
- Portail client self-service (futur)

## 🎯 Objectifs Série YouTube

### **Pédagogiques**
- 📚 Démontrer modernisation IBM i étape par étape
- 🎓 Former communauté aux APIs REST sur IBM i
- 📖 Créer référence open-source réutilisable
- 🤝 Encourager adoption patterns modernes

### **Techniques**
- ✅ Valider patterns API REST avec ILEastic
- ✅ Tester intégration React-Admin + IBM i
- ✅ Créer templates réutilisables
- ✅ Préparer générateur CMagic DSL

### **Communautaires**
- 🌟 Engager communauté IBM i
- 💬 Recueillir feedback utilisateurs
- 🤝 Encourager contributions
- 📢 Montrer potentiel modernisation IBM i

## 🗂️ Modèle de Données TechServ

### **Phase 1 : Entités Fondamentales**

#### **Technicians** (Techniciens)
```sql
CREATE TABLE technicians (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  specialty VARCHAR(50), -- HVAC, ELECTRICAL, PLUMBING, GENERAL
  certification_level VARCHAR(20), -- JUNIOR, SENIOR, EXPERT
  status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, ON_LEAVE, INACTIVE
  hire_date DATE,
  hourly_rate DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### **ServiceTypes** (Types de Services)
```sql
CREATE TABLE service_types (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  estimated_duration_minutes INTEGER DEFAULT 60,
  default_price DECIMAL(10,2),
  active CHAR(1) DEFAULT 'Y',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **Customers** (Clients)
```sql
CREATE TABLE customers (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_name VARCHAR(100) NOT NULL,
  contact_name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20) NOT NULL,
  mobile VARCHAR(20),
  address VARCHAR(200),
  city VARCHAR(50),
  postal_code VARCHAR(10),
  country VARCHAR(50) DEFAULT 'FR',
  status VARCHAR(20) DEFAULT 'PROSPECT',
  payment_terms INTEGER DEFAULT 30,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

### **Phase 2 : Relations & Workflow** (Episodes 7-12)
- **Locations** : Sites clients
- **Equipments** : Équipements installés
- **ServiceRequests** : Demandes d'intervention avec workflow
- **Interventions** : Travail réalisé
- **TimeTracking** : Suivi temps détaillé

## 🏗️ Architecture Technique

### **Stack Complet**

```
┌─────────────────┐    ┌─────────────────┐
│   Mobile PWA    │    │  React-Admin    │
│  (Jean, Tech)   │    │ (Sarah, Disp.)  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │    HTTP/JSON APIs    │
          └──────┬─────┬─────────┘
                 │     │
         ┌───────▼─────▼───────┐
         │    ILEastic         │ ← RPG ILE Web Framework
         │   (API Layer)       │
         └─────────┬───────────┘
                   │
         ┌─────────▼───────────┐
         │     IBM i OS        │
         │                     │
         │ ┌─────────────────┐ │
         │ │   TechServ      │ │ ← Business Logic
         │ │   Programs      │ │   (RPG ILE)
         │ └─────────────────┘ │
         │                     │
         │ ┌─────────────────┐ │
         │ │    DB2 for i    │ │ ← Data Layer
         │ │  (Existing)     │ │   (Tables existantes)
         │ └─────────────────┘ │
         └─────────────────────┘
```

### **Patterns API REST**

**Standards Respectés** :
- ✅ GET `/api/technicians` → `[...]` + header `X-Total-Count`
- ✅ GET `/api/technicians/{id}` → `{...}`
- ✅ POST `/api/technicians` → `201 Created` + objet créé
- ✅ PUT `/api/technicians/{id}` → `200 OK` + objet modifié
- ✅ DELETE `/api/technicians/{id}` → `200 OK`

**Fonctionnalités Avancées** :
- ✅ Pagination : `_page`, `_limit`
- ✅ Tri : `_sort`, `_order`
- ✅ Filtres : `field=value`, `field_like`, `field_gte`, etc.
- ✅ Recherche : `q=terme`

## 📺 Plan Série YouTube (20 Épisodes)

### **🌟 Saison 1 : Fondations API REST (1-6)**
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
13. **Security First - Authentication & Authorization** *(35-40 min)*
14. **Performance Matters - Optimization Techniques** *(30 min)*
15. **Monitoring & Logging - Know What's Happening** *(25-30 min)*
16. **Production Deployment - Go Live!** *(30-35 min)*

### **🎨 Saison 4 : Code Generation (17-20)**
17. **Why Generate Code? - The CMagic Vision** *(20 min)*
18. **DSL in Action - Generate Your First API** *(35-40 min)*
19. **Advanced Generation - Actions & Workflows** *(35 min)*
20. **The Complete Picture - From DSL to Production** *(40-45 min)*

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

# Créer les tables (Phase 1)
db2 -f ressources/data/technicians.sql
db2 -f ressources/data/service_types.sql
db2 -f ressources/data/customers.sql

# Build des APIs
bob --build src/techserv

# Tests de validation
./tests/validate_techserv_apis.sh
```

## 🧪 Tests & Validation

### **Tests Automatisés**
```bash
# Test complet toutes APIs
./tests/validate_all_techserv_apis.sh

# Test API spécifique
./tests/test_technicians_api.sh
./tests/test_servicetypes_api.sh
./tests/test_customers_api.sh
```

### **Collection Bruno**
Tests interactifs dans `ressources/api/bruno/TechServ/` :
- Technicians CRUD
- ServiceTypes référentiel
- Customers avec validations

## 📈 Résultats Attendus

### **Métriques Techniques**
- ✅ 10+ APIs REST conformes standards
- ✅ Suite tests 100% automatisée
- ✅ Build BOB 100% réussi
- ✅ Compatible React-Admin/Appsmith/Retool

### **Métriques Pédagogiques**
- 📺 1000+ vues totales série
- ⭐ 100+ stars GitHub
- 💬 Engagement communauté actif
- 🤝 5+ contributeurs externes

### **Impact Business**
- 💼 Template réutilisable pour PME similaires
- 📚 Documentation patterns validés
- 🎓 Formation communauté IBM i
- 🚀 Base générateur CMagic

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
- **Traductions** : Documentation autres langues

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

### **Documentation**
- **Patterns API** : `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md`
- **CMagic DSL** : `ressources/docs/dsl/docs/dsl_langium/prd_projet.md`
- **Guide Build** : `GUIDE_BUILD_TEST_PHASE2.md`

### **Communauté IBM i**
- Common User Group
- IBM i Community Forum
- Reddit r/IBMi
- LinkedIn IBM i Developers Group

## 📞 Contact

**Questions/Suggestions** :
- 🐛 **GitHub Issues** : Bugs et améliorations techniques
- 💬 **YouTube Comments** : Questions sur épisodes
- 💼 **LinkedIn** : Messages professionnels
- 📧 **Email** : [À préciser]

---

## 📋 Status Développement

### **✅ Phase 1 Complète (Episodes 1-6)**
- [x] Structure projet TechServ
- [x] Includes et prototypes
- [x] Episode 1 : Setup et vision
- [ ] Episode 2 : API Technicians
- [ ] Episode 3 : API ServiceTypes
- [ ] Episode 4 : API Customers
- [ ] Episode 5 : Tests automatisés
- [ ] Episode 6 : React-Admin

### **🔄 En Cours**
- Développement API Technicians (Episode 2)
- Création wireframes Episode 1
- Setup production vidéo

### **⏳ À Venir**
- Phase 2 : Relations & Workflow
- Phase 3 : Production Ready
- Phase 4 : Code Generation

---

*Créé le 24 novembre 2025*  
*TechServ - Modern IBM i API Development*  
*Série YouTube & Open Source Project*