# 🏗️ Architecture Diagrammes - TechServ Episode 1

## 📊 Diagramme Principal - Architecture Complète

```
                    TechServ - Modern IBM i Architecture
                              
    ┌─────────────────────┐         ┌─────────────────────┐
    │     Mobile PWA      │         │   React-Admin       │
    │                     │         │                     │
    │  👨‍🔧 Jean (Tech)     │         │  👩‍💼 Sarah (Disp.)   │
    │                     │         │                     │
    │ • Interventions     │         │ • Dashboard         │
    │ • Time Tracking     │         │ • Planning          │
    │ • Photos/Signature  │         │ • Analytics         │
    │ • GPS Navigation    │         │ • Management        │
    └──────────┬──────────┘         └──────────┬──────────┘
              │                                │
              │                                │
              │         HTTP/JSON APIs         │
              │                                │
              └────────────┬───────────────────┘
                          │
                          │
                ┌─────────▼─────────┐
                │    ILEastic       │
                │                   │
                │  🌐 Web Framework │
                │  📡 REST Router   │
                │  🔄 JSON Parser   │
                │  🔐 HTTP Handler  │
                └─────────┬─────────┘
                          │
                          │
                ┌─────────▼─────────┐
                │     IBM i OS      │
                │                   │
                │ ┌───────────────┐ │
                │ │  RPG Programs │ │ ← Logique métier existante
                │ │               │ │   (20 ans d'historique)
                │ │ • Technicians │ │
                │ │ • Customers   │ │
                │ │ • Services    │ │
                │ │ • Billing     │ │
                │ └───────────────┘ │
                │                   │
                │ ┌───────────────┐ │
                │ │   DB2 for i   │ │ ← Données existantes
                │ │               │ │   (Aucune migration)
                │ │ • TECHNICIANS │ │
                │ │ • CUSTOMERS   │ │
                │ │ • SERVICE_REQ │ │
                │ │ • EQUIPMENT   │ │
                │ └───────────────┘ │
                └───────────────────┘
```

## 🔄 Flow de Données - Use Case Réel

```
                    Use Case: Jean démarre une intervention
                              
    Mobile Jean                API Layer              IBM i Core
    ───────────                ─────────              ──────────
         │                          │                      │
         │ POST /interventions      │                      │
         │ { "start": "09:15" }     │                      │
         ├─────────────────────────▶│                      │
         │                          │  validateInput()     │
         │                          ├─────────────────────▶│
         │                          │                      │
         │                          │  updateDB()          │
         │                          ├─────────────────────▶│
         │                          │                      │
         │                          │◀─────────────────────┤
         │                          │  201 Created         │
         │  201 + intervention{}    │                      │
         │◀─────────────────────────┤                      │
         │                          │                      │
    ─────┼──────────────────────────┼──────────────────────┼─────
         │  WebSocket notification  │                      │
         │◀─────────────────────────┤                      │
         │                          │                      │
         
    Dashboard Sarah            API Layer              IBM i Core
    ───────────────            ─────────              ──────────
         │                          │                      │
         │  Notification reçue      │                      │
         │  "Jean a démarré"        │                      │
         │                          │                      │
         │ GET /interventions       │                      │
         │ ?status=IN_PROGRESS      │                      │
         ├─────────────────────────▶│                      │
         │                          │  queryActive()       │
         │                          ├─────────────────────▶│
         │                          │◀─────────────────────┤
         │  200 + list[]           │                      │
         │◀─────────────────────────┤                      │
         │                          │                      │
         │  Mise à jour UI          │                      │
         │  automatique             │                      │
```

## 🎯 Stack Technique Détaillé

```
                         TechServ Tech Stack
                              
    Frontend Layer                    API Layer                    Data Layer
    ──────────────                    ─────────                    ──────────
                              
    ┌─────────────────┐              ┌─────────────────┐          ┌─────────────────┐
    │  React-Admin    │              │   ILEastic      │          │    DB2 for i    │
    │                 │              │                 │          │                 │
    │ • Material-UI   │◀────────────▶│ • HTTP Router   │◀────────▶│ • Tables SQL    │
    │ • DataProvider  │   REST/JSON  │ • JSON Handler  │   SQL    │ • Indexes       │
    │ • Auth Provider │              │ • Error Mgmt    │          │ • Triggers      │
    │ • CRUD Views    │              │ • Validation    │          │ • Constraints   │
    └─────────────────┘              └─────────────────┘          └─────────────────┘
            │                                 │                            │
    ┌─────────────────┐              ┌─────────────────┐          ┌─────────────────┐
    │   Mobile PWA    │              │   RPG Service   │          │  Legacy Files   │
    │                 │              │                 │          │                 │
    │ • Service Worker│◀────────────▶│ • Business Logic│◀────────▶│ • QRPGLESRC     │
    │ • Offline Cache │   REST/JSON  │ • Data Access   │   R/W    │ • Physical Files│
    │ • Push Notif    │              │ • Calculations  │          │ • Logical Files │
    │ • GPS Location  │              │ • Validations   │          │ • Copy Members  │
    └─────────────────┘              └─────────────────┘          └─────────────────┘
                              
    Build & Test                     Operations                   Legacy Integration  
    ────────────                     ──────────                   ───────────────────
                              
    ┌─────────────────┐              ┌─────────────────┐          ┌─────────────────┐
    │      Bruno      │              │      BOB        │          │  Existing RPG   │
    │                 │              │                 │          │                 │
    │ • API Testing   │              │ • Build Auto    │          │ • 20 years code │
    │ • Collections   │              │ • Dependencies  │          │ • Tested Logic  │
    │ • Environments  │              │ • Deploy Script │          │ • Domain Rules  │
    │ • CI/CD Ready   │              │ • Version Mgmt  │          │ • Calculations  │
    └─────────────────┘              └─────────────────┘          └─────────────────┘
```

## 📱 User Experience Flow

```
                    User Journey - Sarah (Dispatcher)
                              
    Morning Routine
    ───────────────
         │
         ▼
    ┌─────────────────────────────┐
    │  Login Dashboard            │
    │  ┌─────────────────────────┐│
    │  │ Today's Overview        ││
    │  │ • 15 interventions      ││
    │  │ • 8 active techs        ││
    │  │ • 3 urgent requests     ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Service Requests List      │
    │  ┌─────────────────────────┐│
    │  │ Filters: Status, Tech   ││
    │  │ Sort: Priority, Date    ││
    │  │ Pagination: 10/25       ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Assign Intervention        │
    │  ┌─────────────────────────┐│
    │  │ Drag & Drop to Tech     ││
    │  │ Auto-notify mobile      ││
    │  │ Update status           ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Real-time Monitoring       │
    │  ┌─────────────────────────┐│
    │  │ Map with GPS pins       ││
    │  │ Status updates          ││
    │  │ Time tracking           ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
```

```
                    User Journey - Jean (Technician)
                              
    Field Work Day
    ──────────────
         │
         ▼
    ┌─────────────────────────────┐
    │  Mobile App Login           │
    │  ┌─────────────────────────┐│
    │  │ Today's Schedule        ││
    │  │ • 4 interventions       ││
    │  │ • GPS navigation        ││
    │  │ • Customer contacts     ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Arrive on Site             │
    │  ┌─────────────────────────┐│
    │  │ Tap "START"             ││
    │  │ Auto GPS check-in       ││
    │  │ Timer begins            ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Work Progress              │
    │  ┌─────────────────────────┐│
    │  │ Checklist items         ││
    │  │ Photo uploads           ││
    │  │ Parts used logging      ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Complete Work              │
    │  ┌─────────────────────────┐│
    │  │ Customer signature      ││
    │  │ Final report            ││
    │  │ Tap "COMPLETE"          ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │  Next Intervention          │
    │  ┌─────────────────────────┐│
    │  │ Auto-navigate           ││
    │  │ Route optimization      ││
    │  │ Sarah notified          ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
```

## 🔧 API Endpoints Architecture

```
                         REST API Design - TechServ
                              
    Resource: Technicians                    Resource: Service Requests
    ────────────────────                     ───────────────────────────
                              
    GET    /api/technicians                  GET    /api/service-requests
    ├─ ?_page=1&_limit=10                   ├─ ?status=PENDING
    ├─ ?specialty=HVAC                      ├─ ?technician_id=5  
    ├─ ?status=ACTIVE                       ├─ ?priority=HIGH
    └─ ?_sort=lastName                      └─ ?customer_id=10
                              
    GET    /api/technicians/{id}             GET    /api/service-requests/{id}
    POST   /api/technicians                 POST   /api/service-requests
    PUT    /api/technicians/{id}            PUT    /api/service-requests/{id}
    DELETE /api/technicians/{id}            DELETE /api/service-requests/{id}
                              
                                            POST   /api/service-requests/{id}/assign
                                            POST   /api/service-requests/{id}/start
                                            POST   /api/service-requests/{id}/complete
                              
    Resource: Customers                      Resource: Interventions  
    ───────────────────                      ──────────────────────
                              
    GET    /api/customers                    GET    /api/interventions
    ├─ ?status=ACTIVE                       ├─ ?technician_id=5
    ├─ ?city=Paris                          ├─ ?date_gte=2025-11-01
    ├─ ?company_name_like=Hotel             ├─ ?status=IN_PROGRESS
    └─ ?payment_terms_gte=30                └─ ?service_request_id=15
                              
    GET    /api/customers/{id}               GET    /api/interventions/{id}
    POST   /api/customers                   POST   /api/interventions
    PUT    /api/customers/{id}              PUT    /api/interventions/{id}
    DELETE /api/customers/{id}              DELETE /api/interventions/{id}
                              
                                            POST   /api/interventions/{id}/add-part
                                            POST   /api/interventions/{id}/take-photo
                                            POST   /api/interventions/{id}/signature
```

## 📊 Data Model Relations

```
                        TechServ Data Model - Episode 4
                              
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │   TECHNICIANS   │    │   SERVICE_TYPES │    │    CUSTOMERS    │
    │                 │    │                 │    │                 │
    │ • id (PK)       │    │ • id (PK)       │    │ • id (PK)       │
    │ • first_name    │    │ • code          │    │ • company_name  │
    │ • last_name     │    │ • name          │    │ • contact_name  │
    │ • email         │    │ • description   │    │ • email         │
    │ • phone         │    │ • duration      │    │ • phone         │
    │ • specialty     │    │ • price         │    │ • address       │
    │ • status        │    │ • active        │    │ • status        │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
             │                       │                       │
             │                       │                       │
             │              ┌─────────────────┐              │
             │              │ SERVICE_REQUESTS │              │
             │              │                  │              │
             │              │ • id (PK)        │              │
             │              │ • customer_id    │──────────────┘
             │              │ • service_type_id│──────────────┐
             │              │ • technician_id  │──────────────┘
             │              │ • description    │
             │              │ • priority       │
             │              │ • status         │
             │              │ • created_at     │
             │              └─────────────────┘
                                     │
                                     │
                            ┌─────────────────┐
                            │ INTERVENTIONS   │
                            │                 │
                            │ • id (PK)       │
                            │ • sr_id (FK)    │
                            │ • tech_id (FK)  │
                            │ • start_time    │
                            │ • end_time      │
                            │ • work_done     │
                            │ • parts_used    │
                            │ • total_cost    │
                            └─────────────────┘
```

---

## 💡 Instructions Conversion Graphique

### **Outils Recommandés**
1. **Lucidchart** : Diagrammes professionnels
2. **draw.io** : Gratuit, export SVG/PNG
3. **Figma** : Design moderne, collaboratif
4. **PowerPoint** : SmartArt + formes personnalisées

### **Styles Visuels**
- **Couleurs** : Palette TechServ (bleu, vert, orange)
- **Fonts** : Roboto/Open Sans, lisible
- **Formes** : Rectangles arrondis, flèches modernes
- **Spacing** : Cohérent, aéré
- **Contrast** : Accessible, professionnel

### **Export Formats**
- **SVG** : Vectoriel, scalable
- **PNG** : High-res (300dpi)
- **PDF** : Document final
- **PowerPoint** : Éditable

---

*Diagrammes architecture Episode 1*  
*TechServ - Modern IBM i API Development*  
*Convertibles en assets graphiques*