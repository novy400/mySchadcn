# 📊 Slides Architecture Episode 1 - Contenus Détaillés

## 🎨 Slide 1 : Title / Intro

### **Contenu**
```
Episode 1: Building TechServ Together
Modern IBM i API Development

La série qui transforme votre IBM i
20 épisodes | Open Source | Production Ready
```

### **Éléments Visuels**
- Logo TechServ (simple, moderne)
- Background dégradé bleu/vert technologique
- Icônes : IBM i + API + Mobile + React

### **Notes Speaker**
"Bienvenue dans Modern IBM i API Development, la série qui va transformer votre vision du développement sur IBM i."

---

## 🎨 Slide 2 : Le Problème IBM i 2025

### **Contenu**
```
Le Défi IBM i 2025

❌ Interface 5250 peu ergonomique
❌ Pas d'accès mobile terrain  
❌ Impossible intégrer outils modernes
❌ Recrutement développeurs difficile

📊 82% entreprises IBM i veulent se moderniser
📱 Mais sans perdre 20+ ans de logique métier
```

### **Éléments Visuels**
- Split screen : Écran 5250 vs Interface moderne
- Statistiques en highlight
- Icônes problèmes : 📱❌ 💻❌ 👥❌
- Graphique circulaire : 82% vs 18%

### **Notes Speaker**
"C'est LE défi 2025 : 82% des entreprises IBM i veulent se moderniser, mais sans perdre leur précieux heritage métier."

---

## 🎨 Slide 3 : TechServ Use Case

### **Contenu**
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

💼 20 ans d'historique IBM i
🔧 HVAC | Électricité | Plomberie
```

### **Éléments Visuels**
- Photos personas : Sarah (bureau) + Jean (terrain)
- Logo entreprise TechServ
- Icônes métiers : 🔧 ⚡ 🚰
- Timeline : "IBM i depuis 2004"

### **Notes Speaker**
"Prenons TechServ, PME maintenance technique avec 20 ans d'historique IBM i. Sarah dispatche, Jean intervient sur le terrain."

---

## 🎨 Slide 4 : La Solution

### **Contenu**
```
APIs REST + Interfaces Modernes

✅ Garder logique métier IBM i
✅ Ajouter couche API REST (ILEastic)
✅ Interfaces React-Admin + Mobile
✅ Zéro migration données

= Modernisation sans risque
```

### **Éléments Visuels**
- Schéma en couches :
  ```
  [React-Admin] [Mobile PWA]
         ↕️
      [API REST]
         ↕️
  [IBM i RPG + DB2] ← Inchangé
  ```
- Checkmarks verts pour chaque point
- Badge "ZERO RISK" en highlight

### **Notes Speaker**
"La solution : une couche API REST moderne au-dessus de votre existant. Zéro migration, zéro risque."

---

## 🎨 Slide 5 : Architecture Technique

### **Contenu**
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

### **Éléments Visuels**
- Diagramme architecture détaillé :
  ```
  ┌─────────────────┐    ┌─────────────────┐
  │   Mobile PWA    │    │  React-Admin    │
  │  (Jean, Tech)   │    │ (Sarah, Disp.)  │
  └─────────┬───────┘    └─────────┬───────┘
            │                      │
            │    HTTP/JSON         │
            │      APIs            │
            └──────┬─────┬─────────┘
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
- Logos technologies : React, ILEastic, IBM i
- Flèches de communication bidirectionnelle

### **Notes Speaker**
"Voici notre stack complet. Mobile et React-Admin parlent aux mêmes APIs REST tournant sur IBM i avec ILEastic."

---

## 🎨 Slide 6 : Journey Map - 4 Saisons

### **Contenu**
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

1 épisode/semaine = 5 mois complets
```

### **Éléments Visuels**
- Timeline horizontale avec 4 sections colorées
- Progress bar : 20 épisodes
- Icônes par saison :
  - S1 : 🌟 (fondations)
  - S2 : 🔗 (relations)
  - S3 : 🚀 (production)
  - S4 : 🎨 (génération)
- Calendrier : "5 mois | Mardi 18h"

### **Notes Speaker**
"Notre roadmap 20 épisodes en 4 saisons. Un épisode par semaine, chaque mardi 18h."

---

## 🎨 Slide 7 : Saison 1 Détail

### **Contenu**
```
🌟 Saison 1: Fondations API REST (1-6)

Episode 1: Introduction + Vision ✨
Episode 2: API Technicians CRUD 👨‍🔧
Episode 3: Service Types (Référentiel) 📋
Episode 4: Customers + Validation 🏢
Episode 5: Tests Automatisés 🧪
Episode 6: React-Admin Setup ⚛️

Résultat: Dashboard Sarah fonctionnel
```

### **Éléments Visuels**
- Liste épisodes avec icônes
- Screenshots preview :
  - Dashboard wireframe
  - Collection Bruno tests
  - Code RPG sample
- Badge "YOU ARE HERE" sur Episode 1

### **Notes Speaker**
"Saison 1 : on construit les fondations. Episode 6, Sarah aura son dashboard fonctionnel."

---

## 🎨 Slide 8 : Call to Action

### **Contenu**
```
Rejoignez l'Aventure TechServ !

🌟 Star le repository GitHub
💬 Commentez votre cas d'usage IBM i  
📺 Abonnez-vous + notifications
🤝 Contribuez code/tests/docs

Episode 2 : "Your First API - Technicians CRUD"
Live coding complet mardi prochain !

github.com/novy400/applicationTemplate
```

### **Éléments Visuels**
- QR code vers repository GitHub
- Boutons call-to-action stylisés
- Preview Episode 2 :
  - Screenshot VSCode avec RPG
  - Terminal avec curl commands
  - Résultat JSON
- Logo GitHub + YouTube + LinkedIn

### **Notes Speaker**
"3 actions maintenant : Star GitHub, abonnez-vous, commentez votre use case. Mardi prochain : live coding Episode 2 !"

---

## 🎨 Slide 9 : End Screen

### **Contenu**
```
Modern IBM i API Development

Episode 1: Building TechServ Together ✅

Next: Episode 2 - Your First API
Mardi 18h | Live Coding 25min

Abonnez-vous 🔔
Star GitHub ⭐
Commentez 💬
```

### **Éléments Visuels**
- Logo série + TechServ
- Miniature Episode 2 preview
- Éléments d'engagement :
  - Bell icon (notifications)
  - Star icon (GitHub)
  - Comment icon (engagement)
- Background : code RPG flouté
- CTA buttons animés

### **Notes Speaker**
"Merci d'avoir suivi ce premier épisode ! Rendez-vous mardi pour notre premier live coding. À bientôt !"

---

## 📐 Spécifications Techniques Slides

### **Format & Dimensions**
- **Résolution** : 1920x1080 (16:9 Full HD)
- **Format** : PowerPoint (.pptx) + PDF export
- **Template** : Professionnel, tech-oriented
- **Fonts** : Roboto/Open Sans (lisible, moderne)

### **Palette Couleurs**
- **Primaire** : #2E5BBA (Bleu IBM i)
- **Secondaire** : #28A745 (Vert succès)
- **Accent** : #FF6B35 (Orange énergique)
- **Neutre** : #F8F9FA (Background clair)
- **Texte** : #343A40 (Gris foncé)

### **Éléments Graphiques**
- **Icons** : Font Awesome ou Heroicons
- **Illustrations** : Style flat design, cohérent
- **Logos** : Vectoriels (SVG), haute qualité
- **Diagrammes** : draw.io ou Lucidchart style

### **Animations** (si PowerPoint)
- **Transitions** : Subtiles (fade, slide)
- **Apparitions** : Éléments un par un
- **Timing** : Synchronisé avec script
- **Export** : Vidéo MP4 si nécessaire

---

## 📝 Instructions Création

### **Ordre de Création**
1. **Template PowerPoint** : Couleurs, fonts, master slide
2. **Slide par slide** : Contenu + visuels
3. **Animations** : Transitions et timing
4. **Export** : PDF + PNG individuel
5. **Test** : Lisibilité et cohérence

### **Validation**
- ✅ Lisible sur mobile/tablet
- ✅ Cohérent avec brand TechServ
- ✅ Synchronisé avec script
- ✅ Professional looking
- ✅ Accessible (contraste couleurs)

### **Livrables**
- `slides_ep01.pptx` : Fichier source
- `slides_ep01.pdf` : Version export
- `slides/` : PNG individuels
- `assets/` : Éléments graphiques sources

---

*Contenus slides Episode 1*  
*Modern IBM i API Development*  
*9 slides + end screen*