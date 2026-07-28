# 🎬 Projet TechServ - Série YouTube "Modern IBM i API Development"

> **Tagline** : *Build a Complete Service Management System - From Legacy RPG to Modern REST APIs*

📋 **Document Complémentaire** : Voir [`STRATEGIE_DEMO_EPISODE1.md`](STRATEGIE_DEMO_EPISODE1.md) pour la stratégie détaillée "Demo Vision" Episode 1.

---

## 📖 VISION DU PROJET

### **Objectifs Multiples**

1. **🎥 Série YouTube Pédagogique**
   - Démontrer modernisation IBM i concrète
   - Accompagner communauté IBM i vers APIs REST
   - Créer référence open-source

2. **💻 Développement Réel**
   - Template API REST production-ready
   - Patterns validés et réutilisables
   - Base pour générateur CMagic

3. **📚 Documentation Vivante**
   - Chaque épisode = chapitre documentation
   - Code commenté et expliqué
   - Best practices IBM i modernes

4. **🌐 Communication & Communauté**
   - Visibilité projet ArchiAPI/CMagic
   - Feedback communauté
   - Contributions open-source

---

## 🏢 USE CASE : TechServ - Service Management System

### **Contexte Business**

**TechServ** est une PME fictive (mais réaliste) spécialisée dans la maintenance technique (HVAC, électricité, plomberie). Elle utilise IBM i depuis 20 ans avec des programmes RPG legacy.

**Problématique** :
- ❌ Pas d'accès mobile pour techniciens terrain
- ❌ Interface verte 5250 peu ergonomique
- ❌ Impossibilité d'intégrer outils modernes
- ❌ Difficulté à recruter développeurs connaissant RPG

**Solution** :
- ✅ Créer APIs REST sur données IBM i existantes
- ✅ Interface moderne (React-Admin)
- ✅ App mobile pour techniciens
- ✅ Portail client self-service

### **Proposition de Valeur**

**Pour les viewers** : Apprendre à moderniser leur système IBM i sans tout réécrire

**Pour TechServ (fictif)** : Garder logique métier IBM i + UIs modernes

**Pour nous** : Valider patterns avant générateur CMagic

---

## 🗂️ MODÈLE DE DONNÉES PROGRESSIF

### **Phase 1 : Fondations (⭐ Simple)**

#### **1.1 Technicians** (Équivalent Employee)
```sql
CREATE TABLE technicians (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  specialty VARCHAR(50), -- HVAC, Electrical, Plumbing, General
  certification_level VARCHAR(20), -- JUNIOR, SENIOR, EXPERT
  status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, ON_LEAVE, INACTIVE
  hire_date DATE,
  hourly_rate DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

**API Endpoints** :
- `GET /api/technicians` - Liste avec pagination/filtres/tri
- `GET /api/technicians/{id}` - Détail technicien
- `POST /api/technicians` - Créer technicien
- `PUT /api/technicians/{id}` - Modifier technicien
- `DELETE /api/technicians/{id}` - Supprimer (soft delete)

**Complexité** : ⭐ Simple (CRUD standard, pas de relations)

---

#### **1.2 ServiceTypes** (Table de référence)
```sql
CREATE TABLE service_types (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code VARCHAR(20) UNIQUE NOT NULL, -- HVAC-MAINT, ELEC-REPAIR, etc.
  name VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  estimated_duration_minutes INTEGER DEFAULT 60,
  default_price DECIMAL(10,2),
  active CHAR(1) DEFAULT 'Y',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Données Exemple** :
```sql
INSERT INTO service_types (code, name, estimated_duration_minutes, default_price) VALUES
  ('HVAC-MAINT', 'HVAC Maintenance', 120, 150.00),
  ('HVAC-REPAIR', 'HVAC Emergency Repair', 180, 250.00),
  ('ELEC-INSTALL', 'Electrical Installation', 240, 300.00),
  ('PLUMB-REPAIR', 'Plumbing Repair', 90, 120.00);
```

**Complexité** : ⭐ Simple (référentiel read-only principalement)

---

#### **1.3 Customers** (Clients)
```sql
CREATE TABLE customers (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  company_name VARCHAR(100) NOT NULL,
  contact_name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20) NOT NULL,
  mobile VARCHAR(20),
  address VARCHAR(200),
  city VARCHAR(50),
  postal_code VARCHAR(10),
  country VARCHAR(50) DEFAULT 'FR',
  status VARCHAR(20) DEFAULT 'PROSPECT', -- PROSPECT, ACTIVE, SUSPENDED, INACTIVE
  payment_terms INTEGER DEFAULT 30, -- Jours
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Validations Business** :
- Email format valide
- Phone obligatoire
- Transition statuts : PROSPECT → ACTIVE → SUSPENDED/INACTIVE

**Complexité** : ⭐⭐ Moyen (validations + workflow statuts)

---

### **Phase 2 : Relations (⭐⭐ Moyen)**

#### **2.1 Locations** (Sites clients)
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  name VARCHAR(100) NOT NULL, -- "Siège", "Entrepôt Nord", etc.
  address VARCHAR(200) NOT NULL,
  city VARCHAR(50),
  postal_code VARCHAR(10),
  contact_name VARCHAR(100),
  contact_phone VARCHAR(20),
  access_instructions VARCHAR(500), -- "Code portail: 1234"
  active CHAR(1) DEFAULT 'Y',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Relation** : Customer 1-N Locations

**JSON GET /api/locations/{id}** :
```json
{
  "id": 1,
  "name": "Siège Social",
  "address": "123 Rue Example",
  "customer": {
    "id": 10,
    "companyName": "Acme Corp",
    "phone": "+33123456789"
  }
}
```

---

#### **2.2 Equipments** (Équipements installés)
```sql
CREATE TABLE equipments (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  location_id INTEGER REFERENCES locations(id),
  serial_number VARCHAR(50) UNIQUE NOT NULL,
  equipment_type VARCHAR(50), -- HVAC, BOILER, GENERATOR, etc.
  brand VARCHAR(50),
  model VARCHAR(100),
  install_date DATE,
  warranty_until DATE,
  last_maintenance_date DATE,
  status VARCHAR(20) DEFAULT 'OPERATIONAL', -- OPERATIONAL, MAINTENANCE, BROKEN, RETIRED
  notes VARCHAR(1000),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Relations** :
- Equipment N-1 Customer
- Equipment N-1 Location (optionnel)

**Filtres Avancés** :
- `GET /api/equipments?customer_id=10` - Équipements d'un client
- `GET /api/equipments?status=BROKEN` - Équipements en panne
- `GET /api/equipments?warranty_until_gte=2025-01-01` - Sous garantie

---

#### **2.3 ServiceRequests** (Demandes d'intervention)
```sql
CREATE TABLE service_requests (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  request_number VARCHAR(20) UNIQUE, -- SR-2025-0001
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  location_id INTEGER REFERENCES locations(id),
  equipment_id INTEGER REFERENCES equipments(id),
  service_type_id INTEGER REFERENCES service_types(id),
  priority VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
  status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
  description VARCHAR(1000) NOT NULL,
  reported_by VARCHAR(100), -- Nom personne qui signale
  reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  requested_date DATE, -- Date souhaitée par client
  scheduled_date TIMESTAMP, -- Date planifiée
  assigned_technician_id INTEGER REFERENCES technicians(id),
  estimated_duration_minutes INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Relations Multiples** :
- ServiceRequest N-1 Customer
- ServiceRequest N-1 Location (optionnel)
- ServiceRequest N-1 Equipment (optionnel)
- ServiceRequest N-1 ServiceType
- ServiceRequest N-1 Technician (assigned)

**Complexité** : ⭐⭐⭐ Complexe (multiples FK, workflow statuts)

---

### **Phase 3 : Business Complexe (⭐⭐⭐)**

#### **3.1 Interventions** (Travail réalisé)
```sql
CREATE TABLE interventions (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  intervention_number VARCHAR(20) UNIQUE, -- INT-2025-0001
  service_request_id INTEGER NOT NULL REFERENCES service_requests(id),
  technician_id INTEGER NOT NULL REFERENCES technicians(id),
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  actual_duration_minutes INTEGER, -- Calculé : end_time - start_time
  travel_time_minutes INTEGER DEFAULT 0,
  work_done VARCHAR(2000), -- Description travail effectué
  parts_used VARCHAR(2000), -- JSON: [{"part": "Filter X", "qty": 2, "price": 25.00}]
  additional_costs DECIMAL(10,2) DEFAULT 0, -- Frais supplémentaires
  technician_notes VARCHAR(1000),
  customer_signature VARCHAR(100), -- Nom signataire
  signature_date TIMESTAMP,
  status VARCHAR(20) DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, COMPLETED, CANCELLED
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Calculs Automatiques** :
- `actual_duration_minutes = TIMESTAMPDIFF(MINUTE, start_time, end_time)`
- `total_labor_cost = (actual_duration_minutes / 60) * technician.hourly_rate`
- `total_parts_cost = SUM(parts_used[].price * parts_used[].qty)`

**Validations** :
- `end_time > start_time`
- `service_request.status = 'IN_PROGRESS'` pour créer intervention
- Technician doit être ACTIVE

---

#### **3.2 TimeTracking** (Suivi temps détaillé)
```sql
CREATE TABLE time_tracking (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  technician_id INTEGER NOT NULL REFERENCES technicians(id),
  intervention_id INTEGER REFERENCES interventions(id),
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME,
  duration_minutes INTEGER,
  activity_type VARCHAR(20), -- TRAVEL, WORK, BREAK, ADMINISTRATIVE
  notes VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Use Case** : Planning techniciens, heures facturables, reporting

---

#### **3.3 Invoices** (Facturation - optionnel Phase 4)
```sql
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  invoice_number VARCHAR(20) UNIQUE, -- INV-2025-0001
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  service_request_id INTEGER REFERENCES service_requests(id),
  invoice_date DATE NOT NULL,
  due_date DATE,
  subtotal DECIMAL(10,2),
  tax_rate DECIMAL(5,2) DEFAULT 20.00, -- TVA %
  tax_amount DECIMAL(10,2),
  total_amount DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, SENT, PAID, OVERDUE, CANCELLED
  payment_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE invoice_lines (
  id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  invoice_id INTEGER NOT NULL REFERENCES invoices(id),
  intervention_id INTEGER REFERENCES interventions(id),
  description VARCHAR(200) NOT NULL,
  quantity DECIMAL(10,2) DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  line_total DECIMAL(10,2), -- quantity * unit_price
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🎥 PLAN SÉRIE YOUTUBE - 20 ÉPISODES

### **🌟 SAISON 1 : Fondations API REST (Épisodes 1-6)**

#### **Episode 1 : "Introduction - Building TechServ Together"**
📅 *Durée : 12-15 min*

**Contenu** :
- 🎯 **Hook (1 min)** : Problème IBM i modernization
- 🎬 **Vision Demo (5 min)** : Wireframes + Architecture + Use cases narratifs
- 📅 **Journey Map (3 min)** : Plan 20 épisodes, progression
- 🔧 **Setup (3 min)** : Repository, outils, prérequis
- 📢 **CTA (1 min)** : Subscribe, star repo, feedback

**Approche "Demo Vision"** :
- ✅ Wireframes React-Admin + Mobile (mockups Figma)
- ✅ Architecture schématique (pas code complet)
- ✅ Use cases narratifs (Sarah dispatcher, Jean technicien)
- ✅ Code samples preview (extraits finaux)
- ✅ Lancement rapide (2 semaines vs 4 mois)

**Livrables** :
- Repository GitHub public
- README.md avec vision projet
- Structure dossiers initiale
- Wireframes TechServ interfaces
- Assets visuels (slides architecture)

**Code Focus** :
```bash
# Structure projet
applicationTemplate/
├── src/
│   └── techserv/
├── includes/
├── tests/
├── ressources/
│   ├── data/
│   └── docs/
└── youtube/
    └── episodes/
```

**Script Vidéo** : [`youtube/episodes/ep01_intro/script.md`](youtube/episodes/ep01_intro/script.md)

---

#### **Episode 2 : "Your First API - Technicians CRUD"**
📅 *Durée : 25-30 min*

**Contenu** :
- 📚 Pattern REST standard selon `ibmi_rest_api_instructions.md`
- 🏗️ Structure CMAGIC (pagination, filtres, tri)
- 💻 Live coding : API Technicians complète
- ✅ Tests curl en direct
- 🔨 Build BOB

**Structure Code** :
```
src/technician/
├── technician.main.rpgle        # Point entrée ILEastic
├── technician.route.sqlrpgle    # Routes REST
├── technician.rest.sqlrpgle     # Handlers HTTP/JSON
├── technician.sqlrpgle          # Logique métier SQL
└── technician.bnd               # Binding

includes/
└── technician.rpgleinc          # Structures et prototypes
```

**Checklist Validation** :
- [ ] GET `/api/technicians` retourne `[...]` + `X-Total-Count`
- [ ] GET `/api/technicians/{id}` retourne `{...}`
- [ ] POST crée technicien (201 Created)
- [ ] PUT modifie technicien (200 OK)
- [ ] DELETE supprime technicien (200 OK)
- [ ] Pagination `_page`/`_limit` fonctionne
- [ ] Tri `_sort`/`_order` fonctionnel
- [ ] Build BOB réussit

**Tests Live** :
```bash
# Collection
curl -i "http://server:44000/api/technicians"

# Pagination
curl "http://server:44000/api/technicians?_page=1&_limit=5" | jq

# Filtres
curl "http://server:44000/api/technicians?specialty=HVAC" | jq

# Tri
curl "http://server:44000/api/technicians?_sort=lastName&_order=asc" | jq

# Item
curl "http://server:44000/api/technicians/1" | jq

# Create
curl -X POST "http://server:44000/api/technicians" \
  -H "Content-Type: application/json" \
  -d '{"firstName":"John","lastName":"Doe","email":"john@example.com","specialty":"HVAC"}' | jq
```

**Livrables** :
- ✅ API Technicians fonctionnelle
- ✅ Tests automatisés ([`tests/ep02_technicians.sh`](tests/ep02_technicians.sh))
- ✅ Documentation API ([`ressources/docs/api_technicians.md`](ressources/docs/api_technicians.md))

---

#### **Episode 3 : "Reference Data Made Easy - Service Types"**
📅 *Durée : 15-20 min*

**Contenu** :
- 🗂️ Pattern table de référence
- 🔄 Template réutilisable pour futurs référentiels
- 📊 Données de démo
- 📝 Documentation pattern

**Use Case** :
- API simple read-only (principalement GET)
- Données stables (peu de modifications)
- Base pour autres entités

**Code Focus** :
```rpg
// Pattern référentiel simplifié
dcl-proc servicetype_getlist_rest;
  // Pas de filtres complexes nécessaires
  // Tri par code par défaut
  // Cache possible (données stables)
end-proc;
```

**Livrables** :
- ✅ API ServiceTypes
- ✅ Template référentiel réutilisable
- ✅ Script données démo

---

#### **Episode 4 : "Business Entity - Customers with Validation"**
📅 *Durée : 30-35 min*

**Contenu** :
- 🏢 Première vraie entité business
- ✅ Validations métier (email, phone format)
- 🔄 Workflow statuts (PROSPECT → ACTIVE → INACTIVE)
- 📝 Logging CKOOL
- 🎨 Gestion erreurs enrichie

**Validations** :
```rpg
dcl-proc validateCustomerInput;
  dcl-pi *n ind;
    pInput likeds(customer_input_t);
  end-pi;
  
  // Email format
  if not isValidEmail(pInput.email);
    CKOOL_logError('Email invalide: ' + pInput.email);
    return *OFF;
  endif;
  
  // Phone obligatoire
  if %len(%trim(pInput.phone)) = 0;
    CKOOL_logError('Téléphone obligatoire');
    return *OFF;
  endif;
  
  // Status valide
  if pInput.status <> 'PROSPECT' 
     and pInput.status <> 'ACTIVE'
     and pInput.status <> 'SUSPENDED'
     and pInput.status <> 'INACTIVE';
    CKOOL_logError('Status invalide: ' + pInput.status);
    return *OFF;
  endif;
  
  return *ON;
end-proc;
```

**Gestion Erreurs JSON** :
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation échouée",
    "fields": {
      "email": "Format email invalide",
      "phone": "Téléphone obligatoire"
    }
  }
}
```

**Livrables** :
- ✅ API Customers avec validations complètes
- ✅ Pattern validation réutilisable
- ✅ Tests validations

---

#### **Episode 5 : "Testing Like a Pro - Automation & Quality"**
📅 *Durée : 20-25 min*

**Contenu** :
- 🧪 Scripts tests automatisés
- 📮 Collection Bruno/Postman
- ⚡ Tests performance
- 📊 Coverage validation

**Tests Scripts** :
```bash
#!/bin/bash
# tests/validate_all_apis.sh

echo "🧪 Testing TechServ APIs..."

# Technicians
./tests/ep02_technicians.sh || exit 1

# ServiceTypes
./tests/ep03_servicetypes.sh || exit 1

# Customers
./tests/ep04_customers.sh || exit 1

echo "✅ All tests passed!"
```

**Collection Bruno** :
```
ressources/api/bruno/TechServ/
├── Technicians/
│   ├── List.bru
│   ├── Get.bru
│   ├── Create.bru
│   ├── Update.bru
│   └── Delete.bru
├── ServiceTypes/
└── Customers/
```

**Livrables** :
- ✅ Suite tests complète
- ✅ Collection Bruno
- ✅ Scripts CI/CD basics

---

#### **Episode 6 : "First Frontend - React Admin Setup"**
📅 *Durée : 30-35 min*

**Contenu** :
- ⚛️ Setup React-Admin
- 🔌 DataProvider custom pour nos APIs
- 🎨 CRUD sur Technicians
- 📊 Liste Customers
- 🎬 Demo interface complète

**DataProvider** :
```typescript
// techserv-admin/src/dataProvider.ts
import { fetchUtils, DataProvider } from 'react-admin';

const httpClient = (url: string, options: any = {}) => {
    if (!options.headers) {
        options.headers = new Headers({ Accept: 'application/json' });
    }
    return fetchUtils.fetchJson(url, options);
};

const apiUrl = 'http://server:44000/api';

export const dataProvider: DataProvider = {
    getList: async (resource, params) => {
        const { page, perPage } = params.pagination;
        const { field, order } = params.sort;
        
        const query = {
            _page: page,
            _limit: perPage,
            _sort: field,
            _order: order.toLowerCase(),
            ...params.filter
        };
        
        const url = `${apiUrl}/${resource}?${stringify(query)}`;
        const { headers, json } = await httpClient(url);
        
        return {
            data: json,
            total: parseInt(headers.get('x-total-count') || '0', 10),
        };
    },
    // ... getOne, create, update, delete
};
```

**Livrables** :
- ✅ React-Admin fonctionnel
- ✅ CRUD Technicians + Customers
- ✅ Template réutilisable

---

### **🔗 SAISON 2 : Relations & Workflow (Épisodes 7-12)**

#### **Episode 7 : "Relations 101 - Locations & Equipments"**
📅 *Durée : 30 min*

**Contenu** :
- 🔗 Relations 1-N (Customer → Locations, Customer → Equipments)
- 📦 GET avec données relatées (embedded)
- 🔍 Filtres sur relations
- 🎨 Affichage relations dans React-Admin

**JSON avec Relations** :
```json
// GET /api/equipments/1
{
  "id": 1,
  "serialNumber": "EQ-2024-001",
  "model": "HVAC-Pro-500",
  "status": "OPERATIONAL",
  "customer": {
    "id": 10,
    "companyName": "Acme Corp",
    "phone": "+33123456789"
  },
  "location": {
    "id": 5,
    "name": "Siège Social",
    "city": "Paris"
  }
}
```

**Livrables** :
- ✅ APIs Locations + Equipments
- ✅ Pattern relations réutilisable
- ✅ React-Admin avec relations

---

#### **Episode 8 : "The Core - Service Requests Entity"**
📅 *Durée : 35-40 min*

**Contenu** :
- 🎯 Entité centrale multiples relations
- 🔗 Customer + ServiceType + Equipment + Technician
- 📊 Numérotation automatique (SR-2025-0001)
- ✅ Validations complexes

**Validations** :
```rpg
dcl-proc validateServiceRequest;
  // Customer doit être ACTIVE
  // Equipment doit appartenir au Customer
  // ServiceType doit être active
  // Technician doit être ACTIVE si assigné
  // scheduled_date >= requested_date
end-proc;
```

**Livrables** :
- ✅ API ServiceRequests complète
- ✅ Validations référentielles
- ✅ Tests relations

---

#### **Episode 9 : "Workflow Magic - Status State Machine"**
📅 *Durée : 30-35 min*

**Contenu** :
- 🔄 State Machine selon `prd_projet.md`
- 🎬 Actions business CUA
- ✅ Validations transitions
- 📝 Logging transitions

**State Machine** :
```
PENDING → SCHEDULED → IN_PROGRESS → COMPLETED
   ↓                                     ↑
   └─────────────→ CANCELLED ←───────────┘
```

**Actions** :
```bash
POST /api/service-requests/{id}/schedule   # PENDING → SCHEDULED
POST /api/service-requests/{id}/assign     # Assigner technicien
POST /api/service-requests/{id}/start      # SCHEDULED → IN_PROGRESS
POST /api/service-requests/{id}/complete   # IN_PROGRESS → COMPLETED
POST /api/service-requests/{id}/cancel     # * → CANCELLED
```

**Code Pattern** :
```rpg
dcl-proc canTransitionTo;
  dcl-pi *n ind;
    pFromStatus varchar(20);
    pToStatus varchar(20);
  end-pi;
  
  select;
    when pFromStatus = 'PENDING';
      return pToStatus = 'SCHEDULED' or pToStatus = 'CANCELLED';
      
    when pFromStatus = 'SCHEDULED';
      return pToStatus = 'IN_PROGRESS' or pToStatus = 'CANCELLED';
      
    when pFromStatus = 'IN_PROGRESS';
      return pToStatus = 'COMPLETED' or pToStatus = 'CANCELLED';
      
    other;
      return *OFF;
  endsl;
end-proc;
```

**Livrables** :
- ✅ State Machine implémentée
- ✅ Actions CUA fonctionnelles
- ✅ Tests transitions

---

#### **Episode 10 : "Real Work - Interventions & Time Tracking"**
📅 *Durée : 35 min*

**Contenu** :
- 💼 Intervention = travail réalisé
- ⏱️ Time tracking détaillé
- 🧮 Calculs automatiques (durée, coûts)
- 📦 Parts used en JSON

**Calculs** :
```rpg
dcl-proc calculateInterventionCosts;
  dcl-pi *n;
    pIntervention likeds(intervention_t);
  end-pi;
  
  dcl-s lTechRate decimal(10:2);
  dcl-s lLaborCost decimal(10:2);
  dcl-s lPartsCost decimal(10:2);
  
  // Récupérer taux horaire technicien
  exec sql SELECT hourly_rate INTO :lTechRate 
           FROM technicians WHERE id = :pIntervention.technician_id;
  
  // Calcul coût main d'oeuvre
  lLaborCost = (pIntervention.actual_duration_minutes / 60.0) * lTechRate;
  
  // Calcul coût pièces (parser JSON parts_used)
  lPartsCost = calculatePartsCost(pIntervention.parts_used);
  
  // Total
  pIntervention.total_cost = lLaborCost + lPartsCost + pIntervention.additional_costs;
end-proc;
```

**Livrables** :
- ✅ API Interventions
- ✅ API TimeTracking
- ✅ Calculs automatiques

---

#### **Episode 11 : "Dashboard Power - Analytics & Reporting"**
📅 *Durée : 30 min*

**Contenu** :
- 📊 Endpoints analytics
- 📈 KPIs métier
- 🎨 Widgets React-Admin
- 📉 Graphiques

**Endpoints Stats** :
```bash
GET /api/analytics/service-requests/by-status
GET /api/analytics/technicians/workload
GET /api/analytics/revenue/monthly
```

**Livrables** :
- ✅ APIs analytics
- ✅ Dashboard React-Admin
- ✅ Graphiques temps réel

---

#### **Episode 12 : "Mobile First - Technician App Concept"**
📅 *Durée : 25-30 min*

**Contenu** :
- 📱 Concept app mobile technicien
- 🔌 Mêmes APIs utilisées
- 🎨 Wireframes/mockups
- 🚀 Démo avec outil no-code (Appsmith/Retool)

**Fonctionnalités Mobile** :
- Liste interventions du jour
- Détail intervention + navigation
- Start/Stop timer
- Ajouter notes/photos
- Signature client
- Marquer complété

**Livrables** :
- ✅ Wireframes app mobile
- ✅ Prototype Appsmith
- ✅ Doc API pour mobile

---

### **🚀 SAISON 3 : Production Ready (Épisodes 13-16)**

#### **Episode 13 : "Security First - Authentication & Authorization"**
📅 *Durée : 35-40 min*

**Contenu** :
- 🔐 JWT authentication
- 👤 Roles & permissions
- 🛡️ Middleware sécurité
- 🔑 API keys

**Roles** :
- ADMIN : Tout
- DISPATCHER : Gérer service requests, assigner techniciens
- TECHNICIAN : Voir ses interventions, time tracking
- CUSTOMER : Voir ses demandes uniquement

---

#### **Episode 14 : "Performance Matters - Optimization Techniques"**
📅 *Durée : 30 min*

**Contenu** :
- 🚄 Indexes SQL optimaux
- 💾 Caching strategies
- 🔍 Query optimization
- 📊 Benchmarking

---

#### **Episode 15 : "Monitoring & Logging - Know What's Happening"**
📅 *Durée : 25-30 min*

**Contenu** :
- 📝 CKOOL logging avancé
- 📊 Métriques APIs (temps réponse, erreurs)
- 🚨 Alerting basique
- 📈 Dashboard monitoring

---

#### **Episode 16 : "Production Deployment - Go Live!"**
📅 *Durée : 30-35 min*

**Contenu** :
- 🚀 Build automatisé BOB
- 📦 Packaging
- 🔄 CI/CD basics
- 🎯 Checklist go-live

---

### **🎨 SAISON 4 : Code Generation (Épisodes 17-20)**

#### **Episode 17 : "Why Generate Code? - The CMagic Vision"**
📅 *Durée : 20 min*

**Contenu** :
- 🎯 Problématique : Patterns répétitifs
- 💡 Solution : Génération depuis DSL
- 📖 Intro CMagic DSL selon `prd_projet.md`
- 🎬 Demo : Générer Technicians depuis DSL

---

#### **Episode 18 : "DSL in Action - Generate Your First API"**
📅 *Durée : 35-40 min*

**Contenu** :
- 📝 Écrire fichier `.cmagic`
- 🔧 Générateur prototype
- ⚙️ Générer CRUD complet
- ✅ Comparer généré vs manuel

**Exemple DSL** :
```cmagic
entity Technician {
  fields {
    id: integer primary auto
    firstName: string(50) required
    lastName: string(50) required
    email: string(100) unique required
    specialty: enum(HVAC, Electrical, Plumbing)
    status: enum(ACTIVE, ON_LEAVE, INACTIVE) default ACTIVE
  }
  
  api {
    crud: all
    filters: [specialty, status]
    sorts: [lastName, firstName]
  }
}
```

---

#### **Episode 19 : "Advanced Generation - Actions & Workflows"**
📅 *Durée : 35 min*

**Contenu** :
- 🔄 Générer State Machine
- 🎬 Générer actions CUA
- ✅ Générer validations
- 📝 Générer documentation

---

#### **Episode 20 : "The Complete Picture - From DSL to Production"**
📅 *Durée : 40-45 min*

**Contenu** :
- 🎯 Recap complet série
- 📊 Métriques projet (LOC économisé, temps gagné)
- 🚀 TechServ final démo
- 🌐 Roadmap future (frontend generation, etc.)
- 🙏 Remerciements communauté
- 📢 Call to action (contribuer, utiliser)

---

## 📂 STRUCTURE REPOSITORY

```
applicationTemplate/
├── README.md                           # Index général + lien série YouTube
├── PROJET_TECHSERV_YOUTUBE.md         # Ce document
├── STRATEGIE_DEMO_EPISODE1.md         # Stratégie "Demo Vision" Episode 1
├── ROADMAP_DETAILLEE.md                # Planning technique détaillé
│
├── src/
│   └── techserv/
│       ├── technician/                 # Episode 2
│       │   ├── technician.main.rpgle
│       │   ├── technician.route.sqlrpgle
│       │   ├── technician.rest.sqlrpgle
│       │   ├── technician.sqlrpgle
│       │   └── technician.bnd
│       ├── servicetype/                # Episode 3
│       ├── customer/                   # Episode 4
│       ├── location/                   # Episode 7
│       ├── equipment/                  # Episode 7
│       ├── servicerequest/             # Episodes 8-9
│       ├── intervention/               # Episode 10
│       └── timetracking/               # Episode 10
│
├── includes/
│   ├── technician.rpgleinc
│   ├── servicetype.rpgleinc
│   ├── customer.rpgleinc
│   └── ...
│
├── ressources/
│   ├── data/
│   │   ├── technicians.sql             # Données démo
│   │   ├── service_types.sql
│   │   ├── customers.sql
│   │   └── ...
│   ├── docs/
│   │   ├── use_case_techserv.md        # Story complète
│   │   ├── model_donnees.md            # Modèle données détaillé
│   │   ├── api_reference/              # Doc API par entité
│   │   │   ├── technicians.md
│   │   │   ├── customers.md
│   │   │   └── ...
│   │   └── patterns/
│   │       ├── crud_standard.md
│   │       ├── relations.md
│   │       ├── state_machine.md
│   │       └── validations.md
│   └── api/
│       └── bruno/
│           └── TechServ/               # Collections tests API
│
├── tests/
│   ├── ep02_technicians.sh             # Tests par épisode
│   ├── ep03_servicetypes.sh
│   ├── ep04_customers.sh
│   ├── validate_all_apis.sh            # Test global
│   └── performance/
│       └── benchmark_apis.sh
│
├── youtube/
│   ├── README_YOUTUBE.md               # Guide création contenu
│   └── episodes/
│       ├── ep01_intro/
│       │   ├── script.md               # Script détaillé
│       │   ├── slides.pdf              # Support visuel
│       │   ├── demo_commands.sh        # Commandes démo
│       │   └── links.md                # Liens ressources
│       ├── ep02_technicians/
│       │   ├── script.md
│       │   ├── code_samples/           # Code montré à l'écran
│       │   └── tests_demo.sh
│       └── .../
│
├── frontend/
│   └── techserv-admin/                 # React-Admin (Episode 6)
│       ├── package.json
│       ├── src/
│       │   ├── App.tsx
│       │   ├── dataProvider.ts
│       │   └── resources/
│       │       ├── technicians/
│       │       ├── customers/
│       │       └── ...
│       └── README.md
│
├── cmagic/
│   ├── dsl/
│   │   ├── technician.cmagic           # Episode 18
│   │   ├── customer.cmagic
│   │   └── ...
│   ├── generator/
│   │   ├── src/
│   │   └── templates/
│   └── README_GENERATOR.md
│
└── docs/
    ├── CONTRIBUTING.md                 # Guide contributeurs
    ├── DEVELOPMENT.md                  # Setup environnement dev
    └── DEPLOYMENT.md                   # Guide déploiement
```

---

## 📊 PLANNING RÉALISTE

### **Phase 1 : Setup & Premiers Épisodes (4 semaines)**

**Semaine 1 : Préparation**
- [ ] Setup repository GitHub
- [ ] Structure dossiers complète
- [ ] **Wireframes TechServ** (Figma) - approche "Demo Vision"
- [ ] **Slides architecture** (diagrammes, pas code complet)
- [ ] Scripts SQL tables
- [ ] Documentation use case

**Semaine 2 : Episodes 1-2** 
- [ ] Enregistrer Episode 1 (intro avec wireframes/vision)
- [ ] Développer API Technicians (parallèle)
- [ ] Tests complets
- [ ] Enregistrer Episode 2
- [ ] Publier Episodes 1-2

> 🎯 **Note** : Episode 1 utilise approche "Demo Vision" selon `STRATEGIE_DEMO_EPISODE1.md` - mockups/wireframes au lieu de demo complète

**Semaine 3 : Episodes 3-4**
- [ ] API ServiceTypes
- [ ] API Customers avec validations
- [ ] Enregistrer Episodes 3-4
- [ ] Publier

**Semaine 4 : Episode 5-6**
- [ ] Suite tests automatisés
- [ ] Setup React-Admin
- [ ] Enregistrer Episodes 5-6
- [ ] Publier

### **Phase 2 : Relations & Workflow (6 semaines)**
- Episodes 7-12
- Rythme : 1-2 épisodes/semaine

### **Phase 3 : Production Ready (4 semaines)**
- Episodes 13-16
- Rythme : 1 épisode/semaine

### **Phase 4 : Génération (4 semaines)**
- Episodes 17-20
- Rythme : 1 épisode/semaine

**TOTAL : ~18 semaines (4-5 mois)**

---

## 🎬 FORMAT VIDÉO STANDARD

### **Template Épisode**

**Structure Type (25-35 min) :**

1. **Intro (2 min)**
   - Générique
   - Recap épisode précédent
   - Objectifs épisode

2. **Théorie (3-5 min)**
   - Concept à implémenter
   - Architecture/design
   - Patterns utilisés

3. **Live Coding (15-20 min)**
   - Développement en direct
   - Explications au fil du code
   - Tips & tricks

4. **Tests & Validation (3-5 min)**
   - Tests curl/Postman
   - Vérification résultats
   - Build BOB

5. **Demo UI (3-5 min - si applicable)**
   - Test dans React-Admin
   - Use case concret

6. **Recap & Next (2-3 min)**
   - Résumé accomplissements
   - Preview épisode suivant
   - CTA (like, subscribe, GitHub)

### **Style & Ton**

- 🎯 **Pédagogique** mais pas condescendant
- 💡 **Pragmatique** : vraies solutions, vrais problèmes
- 🚀 **Énergique** : montrer l'enthousiasme pour IBM i moderne
- 🤝 **Collaboratif** : inviter feedback communauté
- 🇫🇷/🇬🇧 **Bilingue** : Français principal, sous-titres anglais (ou inverse)

### **Outils Technique**

**Enregistrement :**
- OBS Studio (gratuit, open-source)
- Micro qualité (Blue Yeti ou équivalent)
- 1080p minimum

**Montage :**
- DaVinci Resolve (gratuit)
- Ou Kdenlive (Linux)

**Slides :**
- Google Slides ou LibreOffice Impress
- Template consistant

---

## 📢 STRATÉGIE COMMUNICATION

### **Canaux**

1. **YouTube (Principal)**
   - Série complète
   - Shorts pour quick tips
   - Community posts pour updates

2. **GitHub (Code)**
   - Repository public
   - Issues pour questions
   - Discussions pour feedback
   - Wiki pour doc étendue

3. **LinkedIn (Professionnel)**
   - Annonces épisodes
   - Articles techniques
   - Engagement communauté IBM i

4. **Twitter/X (Temps Réel)**
   - Live tweets pendant tournage
   - Behind the scenes
   - Polls pour choix communauté

5. **Reddit (Communauté)**
   - r/IBMi
   - r/programming
   - Posts par épisode

6. **Blog (Optionnel)**
   - Articles approfondis
   - Transcriptions épisodes
   - Tutorials écrits

### **Planning Publication**

**Rythme** : 1 épisode/semaine (mardi ou jeudi)

**Heure** : 18h00 CET (optimal pour France + reach international)

**Promotion** :
- J-3 : Teaser LinkedIn + Twitter
- J-1 : Preview YouTube Community
- J : Publication + posts tous réseaux
- J+1 : Réponse commentaires
- J+3 : Thread technique sur Reddit/LinkedIn

### **Métriques Succès**

**YouTube** :
- Views : 500+ par épisode (objectif initial)
- Watch time : >40% (retention)
- Subscribers : +50 par épisode
- Comments : Engagement actif

**GitHub** :
- Stars : 100+ (fin série)
- Forks : 20+
- Contributors : 5+
- Issues : Questions qualité

**Communauté** :
- Testimonials d'utilisation
- Pull requests externes
- Articles/videos communauté
- Adoption en entreprise

---

## 🎯 OBJECTIFS PROJET

### **Court Terme (3 mois)**

✅ **Technique**
- 10+ APIs REST complètes
- Suite tests automatisés
- Frontend React-Admin fonctionnel
- Build BOB automatisé

✅ **YouTube**
- 10 premiers épisodes publiés
- 1000+ vues totales
- 100+ subscribers
- Communauté engagée (commentaires)

✅ **Documentation**
- Use case complet documenté
- Patterns catalogués
- Guide développeur

### **Moyen Terme (6 mois)**

✅ **Technique**
- Série complète (20 épisodes)
- Générateur CMagic prototype
- Template projet production-ready
- Contributions externes

✅ **YouTube**
- 5000+ vues totales
- 500+ subscribers
- Playlist complète
- Cas d'usage communauté

✅ **Impact**
- Adoptions réelles en entreprise
- Talks/conférences (meetups, User Groups)
- Articles techniques publiés

### **Long Terme (1 an+)**

✅ **Technique**
- CMagic générateur stable v1.0
- Marketplace templates
- Plugins IDE (VS Code)
- Intégration CI/CD majeurs

✅ **Communauté**
- 2000+ subscribers YouTube
- 500+ stars GitHub
- Communauté contributeurs active
- Formations/workshops basés sur projet

✅ **Business**
- Support/conseil autour CMagic
- Formations entreprises
- Conférences internationales IBM i

---

## 💡 IDÉES CONTENU BONUS

### **Shorts YouTube (1-2 min)**
- "Did you know? X-Total-Count in 30 seconds"
- "RPG Tips: CMAGIC structures explained"
- "Before/After: Legacy vs Modern API"
- "Quick Fix: Common API errors"

### **Séries Complémentaires**
- **"Ask Me Anything"** : Q&A communauté mensuel
- **"Code Review"** : Analyser contributions externes
- **"Pattern of the Week"** : Deep dive pattern spécifique
- **"Production Stories"** : Interviews utilisateurs

### **Collaborations**
- Inviter experts IBM i
- Collab avec autres YouTubers tech
- Sessions avec créateurs ILEastic/noxDB
- Interviews entreprises ayant modernisé

---

## 📝 CHECKLIST LANCEMENT

### **Avant Episode 1**

**Technique** :
- [ ] Repository GitHub créé et public
- [ ] Structure dossiers complète
- [ ] README.md avec vision
- [ ] LICENSE (MIT ou Apache 2.0)
- [ ] CONTRIBUTING.md
- [ ] Scripts SQL données démo
- [ ] Build BOB fonctionnel

**YouTube** :
- [ ] Chaîne créée/optimisée
- [ ] Banner personnalisé
- [ ] Description chaîne complète
- [ ] Playlist "Modern IBM i API Development" créée
- [ ] Trailer chaîne (30-60s)

**Communication** :
- [ ] Comptes LinkedIn/Twitter actifs
- [ ] Templates posts réseaux sociaux
- [ ] Liste hashtags pertinents
- [ ] Contacts communauté IBM i

**Production** :
- [ ] Setup OBS configuré
- [ ] Template slides créé
- [ ] Générique intro/outro
- [ ] Musique libre de droits
- [ ] Checklist tournage

### **Avant Chaque Épisode**

- [ ] Script écrit
- [ ] Code testé et fonctionnel
- [ ] Slides finalisées
- [ ] Démo préparée
- [ ] Backup code (git tags)
- [ ] Miniature créée
- [ ] Description YouTube rédigée
- [ ] Timestamps préparés
- [ ] Liens ressources listés

### **Après Chaque Épisode**

- [ ] Montage et export
- [ ] Upload YouTube (programmé)
- [ ] Sous-titres (auto ou manuels)
- [ ] Miniature uploadée
- [ ] Description avec timestamps
- [ ] Cartes fin de vidéo
- [ ] Posts réseaux sociaux
- [ ] Commit code GitHub avec tag
- [ ] Réponse premiers commentaires

---

## 🤝 CONTRIBUTIONS COMMUNAUTÉ

### **Comment Contribuer**

1. **Code** : PRs sur GitHub
2. **Documentation** : Améliorer docs/exemples
3. **Tests** : Ajouter cas de tests
4. **Traductions** : Sous-titres autres langues
5. **Use Cases** : Partager adaptations projet
6. **Feedback** : Issues GitHub, commentaires YouTube

### **Reconnaissance**

- Hall of Fame dans README
- Mentions dans épisodes
- Crédits fin de vidéo
- Co-auteur documentation
- Invitations sessions live

---

## 📚 RESSOURCES & RÉFÉRENCES

### **Documentation Projet**

- `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md` : Patterns API REST standard
- `ressources/docs/dsl/docs/dsl_langium/prd_projet.md` : CMagic DSL vision
- `PLAN_MISE_EN_OEUVRE.md` : Roadmap technique
- `EXECUTIVE_SUMMARY.md` : Vision stratégique

### **Technologies**

- **ILEastic** : Framework REST IBM i
- **noxDB** : JSON parsing RPG
- **CKOOL** : Logging utilities
- **BOB** : Build automation IBM i
- **React-Admin** : Framework admin frontend
- **Bruno** : API testing tool

### **Communauté IBM i**

- IBM i Community Forum
- Common User Group
- Midrange Computing
- Reddit r/IBMi
- LinkedIn IBM i Developers Group

---

## 🎯 NEXT STEPS IMMÉDIATS

### **Cette Semaine**

1. **✅ Valider ce document** avec ajustements si nécessaire
2. **📂 Créer structure repository** complète
3. **🎨 Créer wireframes TechServ** (Figma 3-4h) - selon `STRATEGIE_DEMO_EPISODE1.md`
4. **🎨 Créer slides architecture** (PowerPoint 2h) - diagrammes et flow
5. **📝 Écrire script Episode 1** détaillé avec narrative use cases
6. **💻 Développer API Technicians** (Episode 2) en parallèle

### **Semaine Prochaine**

6. **🎬 Enregistrer Episode 1**
7. **✂️ Montage Episode 1**
8. **🚀 Publier Episode 1**
9. **📝 Préparer Episode 2**
10. **📢 Communication lancement**

---

## 📞 CONTACT & FEEDBACK

**Repository** : https://github.com/novy400/applicationTemplate

**Questions/Suggestions** : 
- GitHub Issues
- YouTube Comments
- LinkedIn Messages

---

## ✨ CONCLUSION

Ce projet **TechServ** combine :
- ✅ **Apprentissage progressif** : Du simple au complexe
- ✅ **Cas réel applicable** : Patterns réutilisables
- ✅ **Contenu pédagogique** : Série YouTube structurée
- ✅ **Impact communauté** : Open-source, contributions
- ✅ **Vision long terme** : Vers générateur CMagic

**L'aventure commence maintenant !** 🚀

---

*Document créé le 14 novembre 2025*  
*Dernière mise à jour : 20 novembre 2025*  
*Version : 1.1*

---

## 📋 CHANGELOG

### Version 1.1 (20 nov 2025)
- 🎬 **Mise à jour Episode 1** : Approche "Demo Vision" 
- 📋 **Référence** `STRATEGIE_DEMO_EPISODE1.md`
- 🎨 **Planning révisé** : Wireframes/mockups au lieu de demo complète
- ⚡ **Lancement accéléré** : 2 semaines vs 4 mois

### Version 1.0 (14 nov 2025)
- ✨ Création document initial
- 📖 Use case TechServ défini
- 🎥 Plan 20 épisodes YouTube
- 📂 Structure repository
- 🎯 Objectifs et métriques
- 📢 Stratégie communication
