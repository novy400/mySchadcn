# 📋 Assets Episode 1 - TechServ Introduction

## 🎨 Wireframes Figma (À créer)

### **Dashboard React-Admin - Sarah Dispatcher**
**Fichier** : `dashboard_sarah.fig`

**Éléments** :
```
Header: TechServ Management System
├── Navigation: Dashboard | Technicians | Service Requests | Customers
├── User: Sarah Dubois (Dispatcher) | Logout

Main Dashboard:
├── KPI Cards Row:
│   ├── 15 Interventions Aujourd'hui (+2 vs hier)
│   ├── 8 Techniciens Actifs (2 en déplacement)
│   ├── 94% Taux Satisfaction Client
│   └── 2h12 Temps Moyen Intervention
│
├── Service Requests Table:
│   ├── SR-2025-0024 | Acme Corp | HVAC Maintenance | HIGH | Jean Dupont | IN_PROGRESS
│   ├── SR-2025-0025 | Durand SARL | Electrical Repair | NORMAL | Marie Martin | SCHEDULED
│   ├── SR-2025-0026 | Hotel Plaza | Plumbing Issue | URGENT | - | PENDING
│   └── [Voir tous les service requests...]
│
├── Technicians Map Widget:
│   ├── Carte avec pins géolocalisation
│   ├── Jean Dupont (En intervention - Acme Corp)
│   ├── Marie Martin (En route - Durand SARL)
│   └── Paul Leblanc (Disponible - Base)
│
└── Alerts Panel:
    ├── ⚠️ Équipement critique chez Acme Corp (garantie expire demain)
    ├── 📅 3 interventions à planifier cette semaine
    └── 📊 Rapport mensuel disponible
```

### **Mobile App - Jean Technicien**
**Fichier** : `mobile_jean.fig`

**Écrans** :

**Home Screen** :
```
TechServ Mobile
Jean Dupont - Technicien HVAC

Aujourd'hui - 24 Nov 2025
┌─────────────────────────────────┐
│ 🔴 EN COURS                     │
│ Acme Corp - Siège Social        │
│ HVAC Maintenance                │
│ Démarré: 09:15 (2h30 elapsed)   │
│ [PAUSE] [TERMINER]              │
└─────────────────────────────────┘

À FAIRE (3)
┌─────────────────────────────────┐
│ 🟡 13:30 - Durand SARL          │
│ Electrical Repair               │
│ Durée estimée: 1h30             │
│ [DÉMARRER] [DÉTAILS]            │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🟢 15:00 - Hotel Plaza          │
│ Emergency Plumbing              │  
│ URGENT - Client appelé 3x       │
│ [DÉMARRER] [DÉTAILS]            │
└─────────────────────────────────┘
```

**Détail Intervention** :
```
Intervention #INT-2025-0156
Acme Corp - Siège Social
123 Rue de la Paix, Paris 1er

HVAC Maintenance - Routine
Équipement: HVAC-PRO-500 (#EQ-2024-001)

✅ Timer: 2h30m (démarré 09:15)
📋 Checklist:
  ✅ Inspection filtres
  ✅ Vérification thermostats  
  🔄 Nettoyage conduits (en cours)
  ⏳ Test performances
  ⏳ Rapport final

📷 Photos (3)
🔧 Pièces utilisées:
  - Filtre HEPA x2 (€25.00)
  
📝 Notes client:
"Température irrégulière bureau 205"

📞 Contact: Pierre Martin (06.12.34.56.78)
✍️ [SIGNATURE CLIENT]
```

### **Architecture Technique**
**Fichier** : `architecture_schema.svg`

**Diagramme** :
```
┌─────────────────┐    ┌─────────────────┐
│   Mobile PWA    │    │  React-Admin    │
│  (Jean, Tech)   │    │ (Sarah, Disp.)  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │    HTTP/JSON         │
          │      APIs            │
          └──────┬─────┬────────────
                 │     │
         ┌───────▼─────▼───────┐
         │    ILEastic         │
         │   (RPG ILE Web      │
         │    Framework)       │
         └─────────┬───────────┘
                   │
         ┌─────────▼───────────┐
         │     IBM i OS        │
         │                     │
         │ ┌─────────────────┐ │
         │ │   RPG Programs  │ │
         │ │   (Business     │ │
         │ │    Logic)       │ │
         │ └─────────────────┘ │
         │                     │
         │ ┌─────────────────┐ │
         │ │    DB2 for i    │ │
         │ │   (Data Layer)  │ │
         │ └─────────────────┘ │
         └─────────────────────┘
```

## 📊 Slides Présentation

### **Slide 1 : Title**
```
Episode 1: Building TechServ Together
Modern IBM i API Development

La série qui transforme votre IBM i
```

### **Slide 2 : The Problem**
```
Le Défi IBM i 2025

❌ Interface 5250 peu ergonomique
❌ Pas d'accès mobile terrain  
❌ Impossible intégrer outils modernes
❌ Recrutement développeurs difficile

📊 82% entreprises IBM i veulent se moderniser
📱 Mais sans perdre 20+ ans de logique métier
```

### **Slide 3 : TechServ Use Case**
```
TechServ - PME Maintenance Technique

👩‍💼 Sarah (Dispatcher)
  • Planification interventions
  • Suivi techniciens temps réel
  • Gestion clients/équipements

👨‍🔧 Jean (Technicien Terrain)  
  • Interventions mobiles
  • Time tracking automatique
  • Photos/signatures client
```

### **Slide 4 : The Solution**
```
APIs REST + Interfaces Modernes

✅ Garder logique métier IBM i
✅ Ajouter couche API REST (ILEastic)
✅ Interfaces React-Admin + Mobile
✅ Zéro migration données

= Modernisation sans risque
```

### **Slide 5 : Tech Stack**
```
Stack Technique TechServ

Frontend:
  • React-Admin (Dashboard Sarah)
  • PWA Mobile (App Jean)

APIs:
  • RPG ILE + ILEastic
  • Standards REST (pagination, filtres)
  • JSON natif

Backend:
  • DB2 for i (données existantes)
  • BOB (build automation)
  • Bruno (tests APIs)
```

### **Slide 6 : Journey Map**
```
20 Épisodes - 4 Saisons

🌟 S1: Fondations (1-6)
   CRUD APIs + React-Admin

🔗 S2: Relations & Workflow (7-12)
   Entities complexes + Mobile

🚀 S3: Production Ready (13-16)
   Sécurité + Performance + Deploy

🎨 S4: Code Generation (17-20)
   CMagic DSL → APIs automatiques
```

### **Slide 7 : Call to Action**
```
Rejoignez l'Aventure TechServ !

🌟 Star le repository GitHub
💬 Commentez votre cas d'usage IBM i  
📺 Abonnez-vous + notifications
🤝 Contribuez code/tests/docs

Episode 2 : "Your First API - Technicians CRUD"
Live coding complet la semaine prochaine !
```

## 🔗 Liens et Ressources

### **GitHub Repository**
- Repository : https://github.com/novy400/applicationTemplate
- Branch Episode 1 : episode1_setup
- Issues : Questions et suggestions
- Discussions : Échanges communauté

### **Documentation Référence**
- `PROJET_TECHSERV_YOUTUBE.md` : Vision complète série
- `STRATEGIE_DEMO_EPISODE1.md` : Approche "Demo Vision"
- `ressources/docs/copilotInstructions/ibmi_rest_api_instructions.md` : Patterns API
- `ressources/docs/dsl/docs/dsl_langium/prd_projet.md` : CMagic DSL vision

### **Outils Utilisés**
- **Figma** : https://figma.com (wireframes)
- **OBS Studio** : https://obsproject.com (enregistrement)
- **DaVinci Resolve** : https://blackmagicdesign.com (montage)
- **ILEastic** : Framework REST IBM i
- **React-Admin** : Framework admin moderne

## 📝 Notes Production

### **Checklist Pré-tournage**
- [ ] Wireframes Figma finalisés
- [ ] Slides PowerPoint créées
- [ ] Script répété (timing 12-15 min)
- [ ] Setup OBS configuré
- [ ] Repository GitHub préparé
- [ ] Éclairage et audio testés

### **Checklist Post-tournage**
- [ ] Export vidéo HD (1080p)
- [ ] Miniature créée
- [ ] Description YouTube avec timestamps
- [ ] Tags pertinents ajoutés
- [ ] Cards fin de vidéo configurées
- [ ] Publication programmée
- [ ] Posts réseaux sociaux préparés

---

**Objectif** : Créer des assets visuels percutants qui montrent clairement la vision TechServ et engagent la communauté IBM i vers la modernisation.