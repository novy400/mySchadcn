# ⚡ **PRD Sprint 5 - Workflow Simple + Machine à États**

**Sprint :** 5/6  
**Durée :** 2 semaines  
**Objectif :** Implémenter un workflow basique avec machine à états pour CustomerOrder

---

## 🎯 **Objectifs du Sprint (Simplifié MVP)**

### **Objectif Principal**
Ajouter un workflow simple à `CustomerOrder` avec transitions d'état contrôlées et interface utilisateur contextuelle.

### **Objectifs Spécifiques (Réduits MVP)**
1. ✅ **Actions Métier** : `submit`, `approve`, `ship`, `cancel` pour CustomerOrder
2. ✅ **Machine à États** : Transitions contrôlées entre statuts 
3. ✅ **Validation Workflow** : Vérification état avant transition
4. ✅ **UI Contextuelle** : Boutons d'action selon statut actuel
5. ✅ **Pattern Extensible** : Base pour workflows complexes futurs

---

## 📋 **Scope Sprint 5 (MVP Simplifié)**

### **✅ In Scope (Must Have)**

#### **1. Extension DSL - Actions et Workflow**
```jdl
// Extension customerorder.cmagic - Sprint 5
entity CustomerOrder {
    orderId: Int required,
    orderDate: Date required,
    customer: Customer required,
    description: String(200),
    totalAmount: Decimal(15,2) default(0),
    status: OrderStatus default(PENDING)  // Champ workflow
}

enum OrderStatus {
    PENDING,     // En attente → submit
    CONFIRMED,   // Confirmée → approve, cancel
    APPROVED,    // Approuvée → ship, cancel  
    SHIPPED,     // Expédiée → (final)
    CANCELLED    // Annulée → (final)
}

// NOUVEAU Sprint 5: Actions métier
action submitOrder for CustomerOrder {
    in: { orderId: Int }
    validation: { totalAmount > 0 }
}

action approveOrder for CustomerOrder {
    in: { orderId: Int, approverCode: String(10) }
    validation: { status == CONFIRMED }
}

action shipOrder for CustomerOrder {
    in: { orderId: Int, trackingNumber: String(20) }
    validation: { status == APPROVED }
}

action cancelOrder for CustomerOrder {
    in: { orderId: Int, reason: String(100) }
}

// NOUVEAU Sprint 5: Machine à états
workflow OrderLifecycle for CustomerOrder {
    status_field status,
    initial PENDING,
    
    // Transitions basiques
    transition 'submit' from PENDING to CONFIRMED
        executes(submitOrder(orderId)),
    
    transition 'approve' from CONFIRMED to APPROVED
        executes(approveOrder(orderId, approverCode)),
    
    transition 'ship' from APPROVED to SHIPPED
        executes(shipOrder(orderId, trackingNumber)),
    
    // Annulation depuis plusieurs états
    transition 'cancel' from (PENDING, CONFIRMED, APPROVED) to CANCELLED
        executes(cancelOrder(orderId, reason))
}
```

#### **2. Artefacts Workflow Générés**
```
src/customerorder/
├── CustomerOrder_Actions.rpgle    # 🆕 Actions métier
├── CustomerOrder_Workflow.rpgle   # 🆕 Machine à états
├── CustomerOrderMnt.dspf          # 🔄 Écran avec boutons workflow
├── CustomerOrderMnt.rpgle         # 🔄 Programme avec actions
└── tests/
    └── CustomerOrder_Workflow_T.rpgle # 🆕 Tests workflow
```

### **❌ Out of Scope (Reporté v2.0)**
- 🚫 Workflow inter-entités complexes
- 🚫 Conditions workflow avancées (when clauses)
- 🚫 Actions asynchrones ou batch
- 🚫 Historique des transitions
- 🚫 Workflow parallèles ou sous-workflows
- 🚫 Notifications workflow

---

## 📝 **Spécifications Détaillées (Simplifié)**

### **1. Actions Métier `CustomerOrder_Actions.rpgle`**

```rpgle
**FREE
// ============================================
// CustomerOrder Business Actions
// Générée par CMagic v1.0 - Sprint 5
// ============================================

/copy CUSTOMERORDER_H
/copy CUSTOMERORDER_PR

// ========================================
// ACTIONS MÉTIER PUBLIQUES
// ========================================

DCL-PROC customerOrder_submit EXPORT;
  DCL-PI *N IND;
    orderId INT(10) CONST;
  END-PI;
  
  // Validation état actuel
  DCL-DS currentOrder LIKEDS(CustomerOrder_detail_t);
  currentOrder = customerOrder_getByID(orderId);
  
  IF currentOrder.status <> ORDER_STATUS_PENDING;
    RETURN *OFF; // Transition invalide
  ENDIF;
  
  // Validation métier
  IF currentOrder.totalAmount <= 0;
    RETURN *OFF; // Montant obligatoire
  ENDIF;
  
  RETURN customerOrder_submitAction_local(orderId);
END-PROC;

DCL-PROC customerOrder_approve EXPORT;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    approverCode VARCHAR(10) CONST;
  END-PI;
  
  DCL-DS currentOrder LIKEDS(CustomerOrder_detail_t);
  currentOrder = customerOrder_getByID(orderId);
  
  IF currentOrder.status <> ORDER_STATUS_CONFIRMED;
    RETURN *OFF;
  ENDIF;
  
  IF approverCode = *BLANKS;
    RETURN *OFF; // Approbateur obligatoire
  ENDIF;
  
  RETURN customerOrder_approveAction_local(orderId : approverCode);
END-PROC;

DCL-PROC customerOrder_ship EXPORT;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    trackingNumber VARCHAR(20) CONST;
  END-PI;
  
  DCL-DS currentOrder LIKEDS(CustomerOrder_detail_t);
  currentOrder = customerOrder_getByID(orderId);
  
  IF currentOrder.status <> ORDER_STATUS_APPROVED;
    RETURN *OFF;
  ENDIF;
  
  RETURN customerOrder_shipAction_local(orderId : trackingNumber);
END-PROC;

DCL-PROC customerOrder_cancel EXPORT;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    reason VARCHAR(100) CONST;
  END-PI;
  
  DCL-DS currentOrder LIKEDS(CustomerOrder_detail_t);
  currentOrder = customerOrder_getByID(orderId);
  
  // Annulation possible depuis plusieurs états
  SELECT;
    WHEN currentOrder.status = ORDER_STATUS_PENDING;
    WHEN currentOrder.status = ORDER_STATUS_CONFIRMED;
    WHEN currentOrder.status = ORDER_STATUS_APPROVED;
    OTHER;
      RETURN *OFF; // État non annulable
  ENDSL;
  
  RETURN customerOrder_cancelAction_local(orderId : reason);
END-PROC;

// ========================================
// ZONE MANUELLE - IMPLÉMENTATIONS LOCALES
// ========================================
// [CMAGIC:MANUAL_START]

DCL-PROC customerOrder_submitAction_local;
  DCL-PI *N IND;
    orderId INT(10) CONST;
  END-PI;
  
  // Changement d'état vers CONFIRMED
  EXEC SQL 
    UPDATE CUSTOMERORDERP 
    SET STATUS = :ORDER_STATUS_CONFIRMED,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE ORDER_ID = :orderId;
  
  RETURN (SQLCODE = 0);
END-PROC;

DCL-PROC customerOrder_approveAction_local;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    approverCode VARCHAR(10) CONST;
  END-PI;
  
  // Changement d'état vers APPROVED
  // TODO: Enregistrer approverCode quelque part (audit)
  EXEC SQL 
    UPDATE CUSTOMERORDERP 
    SET STATUS = :ORDER_STATUS_APPROVED,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE ORDER_ID = :orderId;
  
  RETURN (SQLCODE = 0);
END-PROC;

DCL-PROC customerOrder_shipAction_local;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    trackingNumber VARCHAR(20) CONST;
  END-PI;
  
  // Changement d'état vers SHIPPED
  // TODO: Enregistrer tracking number
  EXEC SQL 
    UPDATE CUSTOMERORDERP 
    SET STATUS = :ORDER_STATUS_SHIPPED,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE ORDER_ID = :orderId;
  
  RETURN (SQLCODE = 0);
END-PROC;

DCL-PROC customerOrder_cancelAction_local;
  DCL-PI *N IND;
    orderId INT(10) CONST;
    reason VARCHAR(100) CONST;
  END-PI;
  
  // Changement d'état vers CANCELLED
  // TODO: Enregistrer raison annulation
  EXEC SQL 
    UPDATE CUSTOMERORDERP 
    SET STATUS = :ORDER_STATUS_CANCELLED,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE ORDER_ID = :orderId;
  
  RETURN (SQLCODE = 0);
END-PROC;

// [CMAGIC:MANUAL_END]
```

### **2. Écran Maintenance avec Actions `CustomerOrderMnt.dspf` (Ajouts)**

```
     A*%% Extensions Sprint 5 - Boutons workflow contextuels
     
     A                     21  2'Available Actions:'
     A            ACTSUBMIT 21 20A   1A  B 21 22VALUES(' ','S')
     A                                             DSPATR(UL)
     A                     21 24'S=Submit'
     A            ACTAPPRV  21 35A   1A  B 21 37VALUES(' ','A') 
     A                                             DSPATR(UL)
     A                     21 39'A=Approve'
     A            ACTSHIP   21 50A   1A  B 21 52VALUES(' ','H')
     A                                             DSPATR(UL)
     A                     21 54'H=Ship'
     A            ACTCANCEL 21 62A   1A  B 21 64VALUES(' ','C')
     A                                             DSPATR(UL)
     A                     21 66'C=Cancel'
     A                     
     A                     22  2'F3=Exit   F4=Prompt   F12=Cancel'
     A            ERRMSG   23  2A  78A  DSPATR(BL)
```

### **3. Extension Programme Maintenance (Actions UI)**

```rpgle
// Ajout dans CustomerOrderMnt.rpgle - Sprint 5

// Gestion des actions workflow
DCL-PROC handleWorkflowActions;
  
  DCL-S actionPerformed IND INZ(*OFF);
  
  SELECT;
    WHEN ACTSUBMIT = 'S';
      IF _CustomerOrder_submit(currentOrderId);
        ERRMSG = 'Order submitted successfully';
        actionPerformed = *ON;
      ELSE;
        ERRMSG = 'Cannot submit order in current status';
      ENDIF;
      ACTSUBMIT = ' ';
      
    WHEN ACTAPPRV = 'A';
      IF _CustomerOrder_approve(currentOrderId : getCurrentUser());
        ERRMSG = 'Order approved successfully';
        actionPerformed = *ON;
      ELSE;
        ERRMSG = 'Cannot approve order in current status';
      ENDIF;
      ACTAPPRV = ' ';
      
    WHEN ACTSHIP = 'H';
      // TODO: Prompt pour tracking number
      IF _CustomerOrder_ship(currentOrderId : 'TRK123456');
        ERRMSG = 'Order shipped successfully';
        actionPerformed = *ON;
      ELSE;
        ERRMSG = 'Cannot ship order in current status';
      ENDIF;
      ACTSHIP = ' ';
      
    WHEN ACTCANCEL = 'C';
      // TODO: Prompt pour raison
      IF _CustomerOrder_cancel(currentOrderId : 'User cancellation');
        ERRMSG = 'Order cancelled successfully';
        actionPerformed = *ON;
      ELSE;
        ERRMSG = 'Cannot cancel order in current status';
      ENDIF;
      ACTCANCEL = ' ';
  ENDSL;
  
  // Rechargement données si action exécutée
  IF actionPerformed;
    loadOrderData();
    updateWorkflowButtons();
  ENDIF;
  
END-PROC;

// Mise à jour boutons selon statut
DCL-PROC updateWorkflowButtons;
  
  // Désactiver tous les boutons par défaut
  ACTSUBMIT = ' ';
  ACTAPPRV = ' ';
  ACTSHIP = ' ';
  ACTCANCEL = ' ';
  
  // [CMAGIC:MANUAL_START]
  // Activer boutons selon statut actuel
  SELECT;
    WHEN currentOrder.status = ORDER_STATUS_PENDING;
      // Peut soumettre ou annuler
      // ACTSUBMIT activé
      // ACTCANCEL activé
      
    WHEN currentOrder.status = ORDER_STATUS_CONFIRMED;
      // Peut approuver ou annuler
      // ACTAPPRV activé
      // ACTCANCEL activé
      
    WHEN currentOrder.status = ORDER_STATUS_APPROVED;
      // Peut expédier ou annuler
      // ACTSHIP activé
      // ACTCANCEL activé
      
    OTHER;
      // États finaux : aucune action
      
  ENDSL;
  // [CMAGIC:MANUAL_END]
  
END-PROC;
```

---

## ✅ **Critères d'Acceptation Sprint 5 (Simplifié)**

### **1. Actions et Workflow DSL**
- [ ] Parse `action submitOrder for CustomerOrder { ... }`
- [ ] Parse `workflow OrderLifecycle { ... }`
- [ ] Génère actions métier avec validation d'état
- [ ] Validation cohérence transitions workflow

### **2. Machine à États**
- [ ] Transitions autorisées uniquement selon état actuel
- [ ] Actions métier changent statut correctement
- [ ] Validation état avant exécution action
- [ ] Messages d'erreur si transition invalide

### **3. Interface Utilisateur Workflow**
- [ ] Boutons actions contextuels selon statut
- [ ] Exécution actions depuis écran maintenance
- [ ] Messages succès/erreur informatifs
- [ ] Mise à jour interface après action

### **4. Tests Workflow**
- [ ] Tests cycle complet : PENDING → CONFIRMED → APPROVED → SHIPPED
- [ ] Tests annulation depuis différents états
- [ ] Tests transitions invalides (erreurs attendues)
- [ ] Tests validation métier actions

---

## 📊 **Métriques Sprint 5 (Simplifié)**

| Métrique | Cible | Mesure |
|----------|-------|--------|
| **Actions workflow** | 4/4 | submit, approve, ship, cancel |
| **Transitions testées** | 100% | Tous chemins workflow validés |
| **Performance action** | < 200ms | Changement statut + UI update |
| **Validation métier** | 100% | Aucune transition invalide possible |

---

## 🎯 **Livrables Sprint 5 (Simplifié)**

### **Code Workflow**
- [ ] **Action Generator** : Générateur actions métier
- [ ] **Workflow Generator** : Machine à états
- [ ] **UI Workflow** : Boutons contextuels écrans
- [ ] **Validation Engine** : Contrôle transitions

### **Artefacts CustomerOrder Workflow**
- [ ] **Actions complètes** : 4 actions métier fonctionnelles
- [ ] **UI contextuelle** : Boutons selon statut
- [ ] **Tests workflow** : Scénarios cycle de vie
- [ ] **Documentation** : Guide workflow utilisateur

---

**🎯 Sprint 5 ajoute la dimension temporelle et métier au système, transformant les entités statiques en processus métier vivants avec contrôle d'intégrité.**
