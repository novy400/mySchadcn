# 🗺️ **CMagic MVP - Roadmap de Développement**

**Projet :** CMagic - DSL pour Architecture IBM i  
**Version :** 1.0 (MVP)  
**Durée estimée :** 6-8 sprints  
**Objectif :** Prouver la viabilité avec une entité Customer complète

---

## 🎯 **Vision MVP Global**

Créer un générateur CMagic capable de :
1. ✅ Parser un DSL simple mais complet
2. ✅ Générer des artefacts RPG modernes et fonctionnels
3. ✅ Supporter les patterns IBM i essentiels
4. ✅ Fournir une base solide pour l'extensibilité future

**Fil Rouge :** Une entité `Customer` avec opérations CRUD et écran WORK_WITH

---

## 📋 **Découpage par Sprints**

### **🚀 Sprint 1 : Fondations + Entité Simple**
**Objectif :** Parser et générer une entité basique avec DDL et structures  
**Durée :** 2 semaines  
**Livrables :** 
- ✅ Grammaire Langium basique (entity, struct, enum)
- ✅ Générateur pour DDL SQL et copybooks RPG
- ✅ CLI basique fonctionnel
- ✅ Entité Customer avec champs simples

**Détails :** [prdSprint01.md](./prdSprint01.md)

---

### **🏗️ Sprint 2 : Services CRUD + Pattern Double Couche**
**Objectif :** Générer les services RPG avec pattern généré/manuel  
**Durée :** 2 semaines  
**Livrables :**
- ✅ Services CRUD complets pour Customer
- ✅ Pattern fichier unifié avec zones protégées
- ✅ Namespace RPG (`_Customer_*` vs `Customer_*`)
- ✅ Premiers tests d'intégration

**Détails :** [prdSprint02.md](./prdSprint02.md)

---

### **🖥️ Sprint 3 : Écrans DSPF + WORK_WITH**
**Objectif :** Générer les écrans IBM i natifs  
**Durée :** 2 semaines  
**Livrables :**
- ✅ Écran WORK_WITH avec subfile
- ✅ Écrans CREATE/CHANGE/DISPLAY
- ✅ Programmes RPG correspondants
- ✅ Navigation entre écrans

**Détails :** [prdSprint03.md](./prdSprint03.md)

---

### **🔗 Sprint 4 : Relations + Customer/Order**
**Objectif :** Supporter les relations entre entités  
**Durée :** 2 semaines  
**Livrables :**
- ✅ Entité CustomerOrder liée à Customer
- ✅ Clés étrangères et contraintes
- ✅ Vues (DTO) avec données jointes
- ✅ WORK_WITH avec données relationnelles

**Détails :** [prdSprint04.md](./prdSprint04.md)

---

### **⚡ Sprint 5 : Workflow + Machine à États**
**Objectif :** Implémenter le workflow simple  
**Durée :** 2 semaines  
**Livrables :**
- ✅ Enum OrderStatus et transitions
- ✅ Actions métier de base
- ✅ Validation des transitions d'état
- ✅ Interface utilisateur avec actions contextuelles

**Détails :** [prdSprint05.md](./prdSprint05.md)

---

### **🧪 Sprint 6 : Tests + Documentation**
**Objectif :** Consolidation et documentation  
**Durée :** 1-2 semaines  
**Livrables :**
- ✅ Tests unitaires complets
- ✅ Documentation développeur
- ✅ Exemples concrets
- ✅ Guide de prise en main

**Détails :** [prdSprint06.md](./prdSprint06.md)

---

## 📊 **Matrice de Complexité vs Impact**

| Sprint | Complexité | Impact Métier | Risque | Priorité |
|--------|------------|---------------|---------|----------|
| Sprint 1 | 🟡 Moyenne | 🟢 Élevé | 🟢 Faible | 🔴 CRITIQUE |
| Sprint 2 | 🔴 Élevée | 🟢 Élevé | 🟡 Moyen | 🔴 CRITIQUE |
| Sprint 3 | 🟡 Moyenne | 🟢 Élevé | 🟡 Moyen | 🟡 Important |
| Sprint 4 | 🔴 Élevée | 🟡 Moyen | 🔴 Élevé | 🟡 Important |
| Sprint 5 | 🔴 Élevée | 🟡 Moyen | 🔴 Élevé | 🟢 Optionnel |
| Sprint 6 | 🟢 Faible | 🟡 Moyen | 🟢 Faible | 🟡 Important |

---

## 🎯 **Définition of Done par Sprint**

### **Sprint 1 - "Hello Customer"**
- [ ] Parser correctement `customer.cmagic` avec champs simples
- [ ] Générer `CUSTOMERP.sql` valid SQL DDL
- [ ] Générer `Customer_H.rpgleinc` compilable
- [ ] CLI `cmagic generate customer.cmagic` fonctionnel
- [ ] Documentation basique utilisateur

### **Sprint 2 - "CRUD Services"**
- [ ] Générer `Customer_S.sqlrpgle` avec pattern unifié
- [ ] Zones `[CMAGIC:MANUAL_START/END]` préservées
- [ ] API publique `_Customer_*` exportée
- [ ] Implémentation interne `Customer_*` générée
- [ ] Tests de compilation sur IBM i

### **Sprint 3 - "Écrans Natifs"**
- [ ] Écran `CustomerWrk.dspf` avec subfile fonctionnel
- [ ] Navigation F6=Add, 2=Change, 5=Display
- [ ] Programmes `CustomerWrk.rpgle` et `CustomerMnt.rpgle`
- [ ] Intégration avec services Sprint 2
- [ ] Test end-to-end sur IBM i

### **Sprint 4 - "Relations"**
- [ ] `CustomerOrder` avec FK vers `Customer`
- [ ] Vue `OrderWithCustomer` jointe
- [ ] WORK_WITH Orders affichant nom client
- [ ] Contraintes référentielles SQL
- [ ] Validation des dépendances

### **Sprint 5 - "Workflow"**
- [ ] Enum `OrderStatus` et transitions
- [ ] Actions `submit`, `approve`, `cancel`
- [ ] Validation d'état avant transition
- [ ] Interface utilisateur avec boutons contextuels
- [ ] Tests des scénarios métier

### **Sprint 6 - "Polish & Doc"**
- [ ] Tests unitaires > 80% couverture
- [ ] Guide développeur complet
- [ ] Exemples prêts à l'emploi
- [ ] Performance benchmark
- [ ] Préparation v2.0

---

## 🚨 **Risques Identifiés & Mitigation**

| Risque | Impact | Probabilité | Mitigation |
|--------|---------|-------------|------------|
| **Complexité Langium** | 🔴 Élevé | 🟡 Moyen | Formation équipe + POC préalable |
| **Templates RPG** | 🟡 Moyen | 🟢 Faible | Expertise IBM i interne |
| **Pattern Double Couche** | 🔴 Élevé | 🟡 Moyen | Prototypage Sprint 1-2 |
| **Performance DSPF** | 🟡 Moyen | 🟡 Moyen | Tests précoces + optimisation |
| **Scope Creep** | 🔴 Élevé | 🔴 Élevé | ⚠️ Discipline stricte MVP |

---

## 📈 **Métriques de Succès MVP**

### **Métriques Techniques**
- ✅ Temps génération < 5s pour entité simple
- ✅ Code RPG compilable sans erreur
- ✅ SQL DDL conforme normes Db2
- ✅ 0 régression entre sprints

### **Métriques Métier**
- ✅ Développeur junior productive en < 2h
- ✅ 80% moins de code boilerplate manuel
- ✅ Pattern IBM i respectés et modernisés
- ✅ Base solide pour extensibilité v2.0

### **Métriques Qualité**
- ✅ Tests unitaires > 80% couverture
- ✅ Documentation complète et à jour
- ✅ Feedback équipe dev positif
- ✅ Architecture scalable démontrée

---

## 🔮 **Post-MVP (v2.0) - Aperçu**

**Fonctionnalités avancées reportées :**
- 🔄 Git-Based Extensibility intelligent
- 🌐 Sources de données hétérogènes (API, Legacy)
- 🛡️ Validation avancée et règles métier
- 🎨 Génération interfaces modernes (Web/Mobile)
- 🔧 Outils de migration legacy

**Architecture v2.0 :**
- Moteur de merge intelligent avec annotations CMAGIC
- Interface de résolution de conflits
- Extensibilité par plugins
- Support multi-langages (Java, .NET, Node.js)

---

## 📅 **Planning Prévisionnel**

```
Semaines    1    2    3    4    5    6    7    8    9   10   11   12
Sprint 1   [████████████]
Sprint 2            [████████████]
Sprint 3                     [████████████]
Sprint 4                              [████████████]
Sprint 5                                       [████████████]
Sprint 6                                                [████████]
```

**Jalons clés :**
- **Semaine 2 :** Sprint 1 Demo - Première génération
- **Semaine 4 :** Sprint 2 Demo - Services fonctionnels
- **Semaine 6 :** Sprint 3 Demo - Écrans natifs
- **Semaine 8 :** Sprint 4 Demo - Relations Customer/Order
- **Semaine 10 :** Sprint 5 Demo - Workflow complet
- **Semaine 12 :** MVP Release - Documentation finale

---

**✨ Cette roadmap assure une progression incrémentale et des livrables fonctionnels à chaque sprint, avec une complexité maîtrisée et des risques minimisés.**
