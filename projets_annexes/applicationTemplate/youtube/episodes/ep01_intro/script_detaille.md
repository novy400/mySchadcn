# 🎬 Episode 1 : "Introduction - Building TechServ Together"

> **Durée** : 12-15 minutes  
> **Format** : Introduction + Demo Vision + Journey Map  
> **Approche** : "Demo Vision" avec wireframes (pas de code complet)

---

## 📝 SCRIPT COMPLET - TIMING DÉTAILLÉ

### **🎬 INTRO + HOOK (0:00 - 2:00)**

#### **[VISUEL : Logo TechServ + Générique]**

**"Bonjour et bienvenue dans cette nouvelle série YouTube dédiée à la modernisation IBM i !**

**Je suis [Nom], et aujourd'hui nous commençons ensemble un voyage de 20 épisodes qui va transformer complètement votre vision du développement sur IBM i."**

#### **[TRANSITION : Écran 5250 TechServ (mockup)]**

**"Imaginez Sarah, dispatcher chez TechServ, une PME de maintenance technique. Chaque matin, elle se connecte à des écrans verts 5250 pour planifier les interventions de ses 15 techniciens."**

**"Elle navigue péniblement entre les écrans pour :**
- **Consulter la liste des demandes d'intervention**
- **Vérifier la disponibilité des techniciens**  
- **Assigner les interventions**
- **Suivre l'avancement des travaux"**

#### **[TRANSITION : Photo technicien avec téléphone]**

**"Jean, technicien HVAC, arrive sur site chez un client. Il n'a aucun accès mobile aux informations système. Pour chaque mise à jour - intervention démarrée, pièce utilisée, temps dépassé - il doit appeler Sarah."**

**"Sarah note tout manuellement, puis ressaisit dans le système le soir. Productivité divisée par deux, erreurs fréquentes, clients frustrés."**

#### **[TRANSITION : Visuel "The Problem"]**

**"C'est LE défi de 2025 pour les entreprises IBM i :**
- **❌ Interface 5250 peu ergonomique**
- **❌ Pas d'accès mobile terrain**
- **❌ Impossible d'intégrer outils modernes**
- **❌ Difficulté à recruter des développeurs RPG**

**82% des entreprises IBM i veulent se moderniser, mais sans perdre 20 ans de logique métier !"**

#### **[TRANSITION : Solution Hero Shot]**

**"Et si je vous disais qu'on peut résoudre tout ça SANS réécrire une seule ligne de votre code métier existant ?"**

**"Restez jusqu'à la fin : vous allez voir exactement comment on transforme TechServ en 20 épisodes, avec du code réel, testé en production, et 100% open-source."**

---

### **🎨 DEMO VISION - TECHSERV MODERNISÉ (2:00 - 7:30)**

#### **[TRANSITION : "5 mois plus tard..." + Slide Timeline]**

**"Transportons-nous 5 mois dans le futur. Les 20 épisodes sont terminés. À quoi ressemble maintenant le quotidien de Sarah et Jean ?"**

#### **🖥️ Dashboard Sarah - React-Admin (2:00 - 4:00)**

#### **[VISUEL : Wireframe Dashboard React-Admin]**

**"Voici le bureau de Sarah, 8h30 un mardi matin."**

**"Elle ouvre son navigateur sur son dashboard TechServ moderne :**

**📊 Vue d'ensemble immédiate :**
- **15 interventions planifiées aujourd'hui (+2 vs hier)**
- **8 techniciens actifs (2 en déplacement)**  
- **94% taux satisfaction client ce mois**
- **2h12 temps moyen d'intervention"**

#### **[ZOOM : Section Service Requests]**

**"Sa liste des demandes d'intervention en temps réel :**
- **SR-2025-0024 | Acme Corp | HVAC Maintenance | PRIORITÉ HAUTE | Jean Dupont | EN COURS**
- **SR-2025-0025 | Durand SARL | Réparation électrique | NORMALE | Marie Martin | PLANIFIÉE**  
- **SR-2025-0026 | Hotel Plaza | Plomberie urgente | URGENTE | - | EN ATTENTE"**

**"Un clic sur une ligne, et elle voit tous les détails : historique équipement, notes précédentes, pièces en stock."**

#### **[ZOOM : Carte Techniciens]**

**"Sa carte temps réel des techniciens :**
- **Jean Dupont : PIN ROUGE - En intervention chez Acme Corp**
- **Marie Martin : PIN ORANGE - En route vers Durand SARL**
- **Paul Leblanc : PIN VERT - Disponible à la base"**

**"Plus besoin d'appeler pour savoir où sont ses équipes !"**

#### **[ZOOM : Panel Alertes]**

**"Et ses alertes business intelligentes :**
- **⚠️ Équipement critique chez Acme Corp - garantie expire demain**
- **📅 3 interventions urgentes à planifier cette semaine**
- **📊 Rapport mensuel disponible pour la direction"**

**"Sarah gagne 2 heures par jour. Plus de ressaisie, plus de confusion, plus de clients perdus."**

#### **📱 App Mobile Jean - PWA (4:00 - 6:00)**

#### **[TRANSITION : Smartphone + Visuel App Mobile]**

**"Pendant ce temps, Jean arrive chez Acme Corp. Il sort son smartphone et ouvre l'app TechServ."**

#### **[VISUEL : Écran d'accueil mobile]**

**"Son écran du jour :**

**🔴 EN COURS**
**Acme Corp - Siège Social**  
**HVAC Maintenance**
**Démarré: 09:15 (2h30 écoulées)**
**[PAUSE] [TERMINER]**

**À FAIRE (3 interventions)**
**🟡 13:30 - Durand SARL | Réparation électrique | 1h30 estimée**
**🟢 15:00 - Hotel Plaza | Plomberie urgence | URGENT - Client a appelé 3x**"**

#### **[TRANSITION : Écran Détail Intervention]**

**"Jean tape sur 'EN COURS' et voit le détail complet :**
- **Équipement : HVAC-PRO-500 #EQ-2024-001**
- **Timer automatique : 2h30 depuis le bouton 'Démarrer'**  
- **Checklist maintenance : ✅ Filtres inspectés, 🔄 Conduits en cours**
- **Photos équipement : 3 déjà prises**
- **Pièces utilisées : 2x Filtre HEPA (€25.00)**"**

#### **[ZOOM : Fonctionnalités Mobile]**

**"Jean ajoute une note : 'Température irrégulière bureau 205', prend une photo du thermostat défaillant, et marque 'Filtre supplémentaire nécessaire' dans sa checklist."**

**"Instantanément, Sarah voit ces infos sur son dashboard. Plus d'appels, plus de confusion."**

#### **[TRANSITION : Fin d'intervention]**

**"Jean termine l'intervention. Il appuie sur 'TERMINER', prend la signature électronique du client sur son écran, et automatiquement :**
- **Le timer s'arrête à 2h45**
- **Le statut passe à 'TERMINÉ' chez Sarah**  
- **La prochaine intervention (Durand SARL) s'active**
- **Jean a la navigation GPS vers le prochain site"**

**"Productivité multipliée par 2, erreurs divisées par 10, satisfaction client au maximum."**

#### **🏗️ Architecture Technique - Le Secret (6:00 - 7:30)**

#### **[TRANSITION : Schéma Architecture]**

**"Comment ça marche techniquement ? C'est là que ça devient intéressant."**

#### **[VISUEL : Diagramme Architecture]**

**"L'app mobile de Jean et le dashboard de Sarah appellent exactement les mêmes APIs REST modernes.**

**Ces APIs tournent sur le MÊME IBM i de TechServ, développées en RPG ILE avec ILEastic - le framework web IBM i le plus moderne.**

**Elles accèdent aux MÊMES fichiers, MÊMES programmes métier que depuis 20 ans.**

**ZÉRO migration de données. ZÉRO réécriture de logique. Juste une couche API REST propre au-dessus de l'existant."**

#### **[TRANSITION : Stack Technique]**

**"Notre stack complet :**
- **🖥️ Frontend : React-Admin pour Sarah + PWA Mobile pour Jean**
- **🔌 APIs : RPG ILE + ILEastic (framework REST IBM i)**  
- **💾 Data : DB2 for i existant - aucun changement**
- **🔨 Build : BOB automation IBM i**
- **🧪 Tests : Bruno collections pour validation APIs"**

**"La beauté : chaque couche peut évoluer indépendamment. Nouvelle interface ? Même APIs. Nouveau métier ? Nouvelle API, ancien code préservé."**

---

### **🗺️ JOURNEY MAP - NOTRE PLAN 20 ÉPISODES (7:30 - 10:30)**

#### **[TRANSITION : Timeline 4 Saisons]**

**"Comment on arrive de l'écran vert à cette solution moderne ? Voici notre roadmap 20 épisodes, 4 saisons."**

#### **🌟 Saison 1 : Fondations API REST (8:00 - 8:45)**

#### **[VISUEL : Episodes 1-6 Timeline]**

**"SAISON 1 - Episodes 1 à 6 : On construit les fondations.**

**Episode 2 : 'Your First API - Technicians CRUD'**  
**Live coding complet. On crée l'API qui gère nos techniciens : Jean, Marie, Paul... avec pagination, filtres, tri, selon les standards REST modernes.**

**Episode 3 : 'Reference Data Made Easy - Service Types'**  
**On attaque les données de référence : types de services, tarifs, durées. Pattern réutilisable pour tous vos référentiels.**

**Episode 4 : 'Business Entity - Customers with Validation'**  
**Nos clients TechServ avec validation métier complexe : email, téléphone, workflow statuts. Pattern pour toutes vos entités business.**

**Episode 5 : 'Testing Like a Pro'**  
**Suite de tests automatisés. Scripts de validation, collections Bruno. Votre filet de sécurité pour la production.**

**Episode 6 : 'First Frontend - React Admin Setup'**  
**Sarah voit enfin son dashboard ! React-Admin connecté à nos APIs, CRUD complet, interface moderne.**

**Fin saison 1 : Sarah a son dashboard fonctionnel avec techniciens, services, clients."**

#### **🔗 Saison 2 : Relations & Workflow (8:45 - 9:15)**

#### **[VISUEL : Episodes 7-12 Timeline]**

**"SAISON 2 - Episodes 7 à 12 : Les vraies choses complexes.**

**Episode 7 : Relations 1-N. Clients → Sites → Équipements.**  
**Episode 8 : L'entité centrale - Service Requests avec 5 relations.**  
**Episode 9 : Workflow magique - State Machine avec actions CUA.**  
**Episode 10 : Interventions réelles + Time tracking.**  
**Episode 11 : Analytics et tableaux de bord.**  
**Episode 12 : App mobile prototype pour Jean.**

**Fin saison 2 : TechServ complet avec workflow, relations, mobile."**

#### **🚀 Saisons 3-4 : Production & Génération (9:15 - 10:00)**

#### **[VISUEL : Episodes 13-20 Timeline]**

**"SAISON 3 - Episodes 13 à 16 : Production Ready**  
**Sécurité, performance, monitoring, déploiement. Votre TechServ en prod !**

**SAISON 4 - Episodes 17 à 20 : Le futur**  
**Générateur CMagic. Un fichier de config génère toutes ces APIs automatiquement. Du DSL à la production en minutes."**

#### **[TRANSITION : Commitment]**

**"Un épisode par semaine, chaque mardi 18h. En 5 mois, vous maîtrisez la modernisation IBM i complète.**

**Chaque épisode construit sur le précédent. Code testé, documenté, production-ready."**

---

### **🔧 SETUP & CALL TO ACTION (10:30 - 12:00)**

#### **[TRANSITION : GitHub Repository]**

**"Tout est open-source sur GitHub : applicationTemplate."**

#### **[VISUEL : Structure Repository]**

**"Vous y trouvez DÉJÀ :**
- **Code complet Employee API (notre pattern validé)**
- **Structure TechServ préparée pour la série**  
- **Scripts SQL pour créer les tables**
- **Documentation complète des patterns**
- **Collections Bruno pour tester les APIs**
- **Guide setup environnement"**

#### **[TRANSITION : Participation]**

**"3 façons de participer à l'aventure TechServ :**

**1️⃣ SUIVEUR : Regarder les épisodes, implémenter chez vous**  
**Tout le code sera disponible épisode par épisode. Adaptez TechServ à votre métier.**

**2️⃣ CONTRIBUTEUR : Code, tests, documentation**  
**PRs bienvenues ! Améliorations, optimisations, nouveaux patterns.**

**3️⃣ ADAPTATEUR : Votre propre use case**  
**Garage automobile ? Clinique vétérinaire ? École ? Même patterns, votre domaine."**

#### **[TRANSITION : Community]**

**"Et dites-moi en commentaire : quel est VOTRE cas d'usage IBM i à moderniser ?**

**Restaurant ? Hôtel ? Cabinet comptable ? Je veux connaître VOS défis pour adapter les exemples."**

---

### **🎯 CLOSING & NEXT EPISODE (12:00 - 13:00)**

#### **[TRANSITION : Preview Episode 2]**

**"Episode 2 mardi prochain : 'Your First API - Technicians CRUD'**

**Live coding complet, 25 minutes :**
- **Structure projet modulaire**  
- **API REST avec pagination, filtres, tri**
- **Tests validation automatisés**  
- **Build IBM i avec BOB**

**À la fin de l'épisode, vous aurez une API moderne qui gère vos techniciens selon les standards React-Admin, Appsmith, Retool."**

#### **[TRANSITION : Final CTA]**

**"3 actions maintenant :**
1. **🔔 ABONNEZ-VOUS + notifications pour ne rater aucun épisode**
2. **⭐ STAR le repository GitHub si le projet vous intéresse**  
3. **💬 COMMENTEZ votre cas d'usage IBM i à moderniser**

**On transforme TechServ ensemble, et votre entreprise sera la prochaine !**

**À mardi prochain pour notre premier live coding. Merci et à bientôt !"**

#### **[VISUEL : End Screen + Links]**

---

## 🎬 NOTES DE PRODUCTION

### **Timing Contrôle**
- **Introduction/Hook : 2 min (Max 2:30)**
- **Demo Vision : 5:30 min (Core value)**  
- **Journey Map : 3 min (Clear roadmap)**
- **Setup/CTA : 1:30 min (Action oriented)**
- **TOTAL : 12-13 min (Optimal attention span)**

### **Transitions Clés**
- **Problem → Solution** : "Et si je vous disais..."
- **Present → Future** : "5 mois plus tard..."  
- **Technical → Business** : "Comment ça marche..."
- **Vision → Action** : "Comment on y arrive..."

### **Call to Actions**
1. **Subscribe + notifications** (retention)
2. **Star GitHub repository** (community building)  
3. **Comment use case** (engagement + content ideas)

### **Hooks Engagement**
- **Question rhétorique** : "Et si on pouvait..."
- **Statistique impact** : "82% entreprises IBM i..."  
- **Promise spécifique** : "ZÉRO migration données..."
- **Social proof future** : "Production-ready, testé..."

---

*Script Episode 1 - Total : ~1200 mots*  
*Durée estimée : 12-15 minutes*  
*Approche : Demo Vision avec wireframes*