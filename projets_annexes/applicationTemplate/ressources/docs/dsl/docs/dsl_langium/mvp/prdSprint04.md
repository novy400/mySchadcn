# 🔗 **PRD Sprint 4 - Relations + Customer/Order (Simplifié)**

**Sprint :** 4/6  
**Durée :** 2 semaines  
**Objectif :** Supporter les relations entre entités avec Customer/CustomerOrder

---

## 🎯 **Objectifs du Sprint**

### **Objectif Principal**
Étendre CMagic pour supporter les relations entre entités en ajoutant `CustomerOrder` liée à `Customer`.

### **Objectifs Spécifiques**
1. ✅ **Relation Entity** : `CustomerOrder` avec référence vers `Customer`
2. ✅ **Clés Étrangères** : Contraintes SQL et validation RPG
3. ✅ **Vues Jointures** : DTO avec données relationnelles
4. ✅ **UI Master-Detail** : WORK_WITH Orders affichant nom client
5. ✅ **Pattern Extensible** : Base pour futures relations complexes

---

## 📋 **Scope du Sprint 4 (Simplifié)**

### **✅ In Scope (Must Have)**

#### **1. Extension Grammaire DSL - Relations**
```jdl
// Nouveau fichier: customerorder.cmagic
import './customer.cmagic'

entity CustomerOrder {
    orderId: Int required,
    orderDate: Date required,
    
    // NOUVEAU Sprint 4: Relation vers entité
    customer: Customer required,    // Référence Foreign Key
    
    description: String(200),
    totalAmount: Decimal(15,2) default(0),
    status: OrderStatus default(PENDING)
}

enum OrderStatus {
    PENDING,     // En attente
    CONFIRMED,   // Confirmée  
    SHIPPED,     // Expédiée
    DELIVERED,   // Livrée
    CANCELLED    // Annulée
}

// Vue avec jointure Customer
view OrderWithCustomer for CustomerOrder {
    orderId,
    orderDate,
    customer.customerCode,    // Jointure vers Customer
    customer.name,           // Nom client dans liste
    description,
    totalAmount,
    status
}

// Opérations CustomerOrder
operations for CustomerOrder {
    CREATE, CHANGE, DELETE, DISPLAY,
    WORK_WITH returns OrderWithCustomer {
        list_columns(orderId, orderDate, customer.name, totalAmount, status),
        filters(customer, status, orderDate),
        sort_by(orderDate desc)
    }
}
```

#### **2. Artefacts Générés CustomerOrder**
```
src/customerorder/
├── CustomerOrder_H.rpgleinc       # 🆕 Structures avec FK
├── CustomerOrder_PR.rpgleinc      # 🆕 Prototypes services
├── CustomerOrder_S.sqlrpgle       # 🆕 Services CRUD avec jointures
├── CUSTOMERORDERP.sql            # 🆕 DDL avec contraintes FK
├── CustomerOrderWrk.dspf         # 🆕 Écran liste avec nom client
├── CustomerOrderWrk.rpgle        # 🆕 Programme avec jointures
├── CustomerOrderMnt.dspf         # 🆕 Écran maintenance avec lookup
└── CustomerOrderMnt.rpgle        # 🆕 Programme avec validation FK
```

#### **3. Extensions Customer (Master-Detail)**
```
src/customer/
├── CustomerOrders.dspf           # 🆕 Écran liste ordres par client
├── CustomerOrders.rpgle          # 🆕 Programme drill-down
└── Customer_S.sqlrpgle          # 🔄 Extension: getOrders()
```

### **❌ Out of Scope (Reporté v2.0)**
- 🚫 Relations Many-to-Many complexes
- 🚫 Cascade DELETE avancé
- 🚫 Workflow inter-entités (Sprint 5)
- 🚫 Relations circulaires
- 🚫 Optimisation performance jointures
- 🚫 Relations conditionnelles

---

## 📝 **Spécifications Détaillées**

### **1. DDL avec Contraintes `CUSTOMERORDERP.sql`**

```sql
-- ============================================
-- Table CustomerOrder avec FK - CMagic v1.0
-- Source : customerorder.cmagic - Sprint 4
-- ============================================

CREATE TABLE CUSTOMERORDERP (
    ORDER_ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    ORDER_DATE DATE NOT NULL,
    
    -- Foreign Key vers Customer
    CUSTOMER_ID INTEGER NOT NULL,
    
    DESCRIPTION VARCHAR(200),
    TOTAL_AMOUNT DECIMAL(15,2) NOT NULL DEFAULT 0,
    STATUS VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    
    -- Métadonnées techniques
    CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    PRIMARY KEY (ORDER_ID),
    
    -- Contrainte Foreign Key
    CONSTRAINT FK_ORDER_CUSTOMER 
        FOREIGN KEY (CUSTOMER_ID) 
        REFERENCES CUSTOMERP (ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CHECK (STATUS IN ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    CHECK (TOTAL_AMOUNT >= 0)
);

-- Index sur FK pour performance
CREATE INDEX CUSTOMERORDERP_CUST_IDX ON CUSTOMERORDERP (CUSTOMER_ID);
CREATE INDEX CUSTOMERORDERP_DATE_IDX ON CUSTOMERORDERP (ORDER_DATE);
CREATE INDEX CUSTOMERORDERP_STATUS_IDX ON CUSTOMERORDERP (STATUS);

-- Trigger updated_at
CREATE TRIGGER CUSTOMERORDERP_UPD_TRG
    BEFORE UPDATE ON CUSTOMERORDERP
    FOR EACH ROW
    SET NEW.UPDATED_AT = CURRENT_TIMESTAMP;

-- Commentaires
COMMENT ON TABLE CUSTOMERORDERP IS 'Commandes clients avec FK vers Customer';
COMMENT ON COLUMN CUSTOMERORDERP.CUSTOMER_ID IS 'FK vers Customer.ID';
```

### **2. Structures avec Relations `CustomerOrder_H.rpgleinc`**

```rpgle
**FREE
// ============================================
// CustomerOrder Headers avec Relations
// Générée par CMagic v1.0 - Sprint 4
// ============================================

/if not defined(CUSTOMERORDER_H)
/define CUSTOMERORDER_H

/copy CUSTOMER_H

// ========================================
// CONSTANTES ÉNUMÉRATION
// ========================================
DCL-C ORDER_STATUS_PENDING 'PENDING';
DCL-C ORDER_STATUS_CONFIRMED 'CONFIRMED';
DCL-C ORDER_STATUS_SHIPPED 'SHIPPED';
DCL-C ORDER_STATUS_DELIVERED 'DELIVERED';
DCL-C ORDER_STATUS_CANCELLED 'CANCELLED';

// ========================================
// STRUCTURES ENTITÉ
// ========================================

// Structure de base CustomerOrder
DCL-DS CustomerOrder_t QUALIFIED TEMPLATE;
  orderId INT(10);
  orderDate DATE;
  customerId INT(10);           // FK vers Customer
  description VARCHAR(200);
  totalAmount PACKED(15:2) INZ(0);
  status VARCHAR(20) INZ(ORDER_STATUS_PENDING);
END-DS;

// Structure détaillée avec métadonnées
DCL-DS CustomerOrder_detail_t QUALIFIED TEMPLATE;
  orderId INT(10);
  orderDate DATE;
  customerId INT(10);
  description VARCHAR(200);
  totalAmount PACKED(15:2) INZ(0);
  status VARCHAR(20) INZ(ORDER_STATUS_PENDING);
  
  // Métadonnées techniques
  createdAt TIMESTAMP;
  updatedAt TIMESTAMP;
END-DS;

// Structure avec données Customer jointes
DCL-DS OrderWithCustomer_t QUALIFIED TEMPLATE;
  orderId INT(10);
  orderDate DATE;
  description VARCHAR(200);
  totalAmount PACKED(15:2);
  status VARCHAR(20);
  
  // Données Customer jointes
  customerId INT(10);
  customerCode VARCHAR(10);
  customerName VARCHAR(80);
  customerCity VARCHAR(50);
END-DS;

// Structure pour recherche
DCL-DS CustomerOrder_search_t QUALIFIED TEMPLATE;
  customerId INT(10);      // Filter par client
  status VARCHAR(20);      // Filter par statut
  dateFrom DATE;          // Filter date début
  dateTo DATE;            // Filter date fin
END-DS;

/endif
```

### **3. Service avec Jointures `CustomerOrder_S.sqlrpgle`**

```rpgle
**FREE
// ============================================
// CustomerOrder Service avec Relations
// Générée par CMagic v1.0 - Sprint 4
// ============================================

/copy CUSTOMERORDER_H
/copy CUSTOMERORDER_PR

// ========================================
// API PUBLIQUE - AVEC VALIDATION FK
// ========================================

DCL-PROC _CustomerOrder_create EXPORT;
  DCL-PI *N LIKEDS(CustomerOrder_detail_t);
    order LIKEDS(CustomerOrder_t) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(CustomerOrder_detail_t);
  
  // Validation Foreign Key Customer
  IF NOT _Customer_exists(order.customerId);
    // TODO: Gestion erreur FK invalide
    RETURN result;
  ENDIF;
  
  // Validation métier
  IF order.orderDate = *LOVAL OR order.totalAmount < 0;
    RETURN result;
  ENDIF;
  
  RETURN CustomerOrder_create(order);
END-PROC;

DCL-PROC _CustomerOrder_getByID EXPORT;
  DCL-PI *N LIKEDS(CustomerOrder_detail_t);
    orderId INT(10) CONST;
  END-PI;
  
  IF orderId <= 0;
    DCL-DS empty LIKEDS(CustomerOrder_detail_t);
    RETURN empty;
  ENDIF;
  
  RETURN CustomerOrder_getByID(orderId);
END-PROC;

// NOUVEAU: Récupération avec données Customer
DCL-PROC _CustomerOrder_getWithCustomer EXPORT;
  DCL-PI *N LIKEDS(OrderWithCustomer_t);
    orderId INT(10) CONST;
  END-PI;
  
  IF orderId <= 0;
    DCL-DS empty LIKEDS(OrderWithCustomer_t);
    RETURN empty;
  ENDIF;
  
  RETURN CustomerOrder_getWithCustomer(orderId);
END-PROC;

// NOUVEAU: Recherche ordres par client
DCL-PROC _CustomerOrder_getByCustomer EXPORT;
  DCL-PI *N;
    customerId INT(10) CONST;
    orders LIKEDS(OrderWithCustomer_t) DIM(100) OPTIONS(*VARSIZE);
    count INT(10);
  END-PI;
  
  IF customerId <= 0;
    count = 0;
    RETURN;
  ENDIF;
  
  CustomerOrder_getByCustomer(customerId : orders : count);
END-PROC;

// ========================================
// ZONE MANUELLE - IMPLÉMENTATIONS
// ========================================
// [CMAGIC:MANUAL_START]

DCL-PROC CustomerOrder_create;
  DCL-PI *N LIKEDS(CustomerOrder_detail_t);
    order LIKEDS(CustomerOrder_t) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(CustomerOrder_detail_t);
  DCL-S newId INT(10);
  
  EXEC SQL 
    INSERT INTO CUSTOMERORDERP (
      ORDER_DATE, CUSTOMER_ID, DESCRIPTION, TOTAL_AMOUNT, STATUS
    ) VALUES (
      :order.orderDate, :order.customerId, :order.description,
      :order.totalAmount, :order.status
    );
  
  IF SQLCODE = 0;
    EXEC SQL SET :newId = IDENTITY_VAL_LOCAL();
    result = CustomerOrder_getByID(newId);
  ENDIF;
  
  RETURN result;
END-PROC;

DCL-PROC CustomerOrder_getByID;
  DCL-PI *N LIKEDS(CustomerOrder_detail_t);
    orderId INT(10) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(CustomerOrder_detail_t);
  
  EXEC SQL 
    SELECT ORDER_ID, ORDER_DATE, CUSTOMER_ID, DESCRIPTION,
           TOTAL_AMOUNT, STATUS, CREATED_AT, UPDATED_AT
    INTO :result.orderId, :result.orderDate, :result.customerId,
         :result.description, :result.totalAmount, :result.status,
         :result.createdAt, :result.updatedAt
    FROM CUSTOMERORDERP
    WHERE ORDER_ID = :orderId;
  
  RETURN result;
END-PROC;

// NOUVEAU: Jointure avec Customer
DCL-PROC CustomerOrder_getWithCustomer;
  DCL-PI *N LIKEDS(OrderWithCustomer_t);
    orderId INT(10) CONST;
  END-PI;
  
  DCL-DS result LIKEDS(OrderWithCustomer_t);
  
  EXEC SQL 
    SELECT o.ORDER_ID, o.ORDER_DATE, o.DESCRIPTION, 
           o.TOTAL_AMOUNT, o.STATUS,
           c.ID, c.CUSTOMER_CODE, c.NAME, c.ADDR_VILLE
    INTO :result.orderId, :result.orderDate, :result.description,
         :result.totalAmount, :result.status,
         :result.customerId, :result.customerCode, 
         :result.customerName, :result.customerCity
    FROM CUSTOMERORDERP o
    INNER JOIN CUSTOMERP c ON o.CUSTOMER_ID = c.ID
    WHERE o.ORDER_ID = :orderId;
  
  RETURN result;
END-PROC;

// NOUVEAU: Ordres par client
DCL-PROC CustomerOrder_getByCustomer;
  DCL-PI *N;
    customerId INT(10) CONST;
    orders LIKEDS(OrderWithCustomer_t) DIM(100) OPTIONS(*VARSIZE);
    count INT(10);
  END-PI;
  
  DCL-S i INT(10) INZ(0);
  
  EXEC SQL 
    DECLARE order_cursor CURSOR FOR
    SELECT o.ORDER_ID, o.ORDER_DATE, o.DESCRIPTION,
           o.TOTAL_AMOUNT, o.STATUS,
           c.ID, c.CUSTOMER_CODE, c.NAME, c.ADDR_VILLE
    FROM CUSTOMERORDERP o
    INNER JOIN CUSTOMERP c ON o.CUSTOMER_ID = c.ID
    WHERE o.CUSTOMER_ID = :customerId
    ORDER BY o.ORDER_DATE DESC;
  
  EXEC SQL OPEN order_cursor;
  
  EXEC SQL FETCH order_cursor 
    INTO :orders(i+1).orderId, :orders(i+1).orderDate, 
         :orders(i+1).description, :orders(i+1).totalAmount,
         :orders(i+1).status, :orders(i+1).customerId,
         :orders(i+1).customerCode, :orders(i+1).customerName,
         :orders(i+1).customerCity;
  
  DOW SQLCODE = 0 AND i < %ELEM(orders);
    i += 1;
    EXEC SQL FETCH order_cursor 
      INTO :orders(i+1).orderId, :orders(i+1).orderDate,
           :orders(i+1).description, :orders(i+1).totalAmount,
           :orders(i+1).status, :orders(i+1).customerId,
           :orders(i+1).customerCode, :orders(i+1).customerName,
           :orders(i+1).customerCity;
  ENDDO;
  
  EXEC SQL CLOSE order_cursor;
  count = i;
END-PROC;

// [CMAGIC:MANUAL_END]
```

### **4. Écran WORK_WITH avec Jointures `CustomerOrderWrk.dspf`**

```
     A*%% Work with Customer Orders - avec nom client
     A                                             DSPSIZ(24 80 *DS3)
     A                                             CA03(03 'Exit')
     A                                             CA12(12 'Cancel')
     A                                             PRINT
     A            SFLCTL                           CF06(06 'Add Order')
     A                                             SFLSIZ(99)
     A                                             SFLPAG(14)
     A            DSPATR(UL)
     A                                             OVERLAY
     A            DSPATR(BL)
     A                                             
     A  32                                         SFLDSP
     A  32                                         SFLDSPCTL
     A  33                                         SFLCLR
     A  34                                         SFLEND(*MORE)
     A            OVERLAY
     A                                             
     A                      1  2'DSPLY03'
     A                      1 30'Work with Customer Orders'
     A                      1 71DATE
     A                      1 80DSPATR(UL)
     A                      2 71TIME
     A                      2 80DSPATR(UL)
     A                      
     A                      4  2'Type options, press Enter.'
     A                      5  2'  2=Change   4=Delete   5=Display   8=Orders'
     A                      
     A                      7  2'Filter by Customer .'
     A            CUSTFLTR  7 21A  10A  B  7 32DSPATR(UL)
     A                      8  2'Filter by Status  .'
     A            STSFLTR   8 21A   1A  B  8 32VALUES(' ','P','C','S','D','X')
     A                                             DSPATR(UL)
     A                     
     A                      10  2'Opt'
     A                      10  6'Order#'
     A                      10 14'Date'
     A                      10 25'Customer'
     A                      10 46'Description'
     A                      10 62'Amount'
     A                      10 72'Status'
     A                      11  2DSPATR(UL)
     A                      11 80DSPATR(UL)
     A            SFL
     A            OPTION    B  8Y 0B  2  2VALUES(' ','2','4','5','8')
     A                                             DSPATR(UL)
     A            ORDERID   O  8Y 0    2  6EDTCDE(4)
     A            ORDERDATE O  8Y 0    2 14EDTCDE(Y)
     A            CUSTNAME  O 20A      2 25
     A            DESCR     O 15A      2 46
     A            AMOUNT    O  9Y 2    2 62EDTCDE(J)
     A            STATUS    O  1A      2 72
     A            RRN       H  4S 0
     A                     
     A                     22  2'F3=Exit   F6=Add   F8=Customer Orders'
     A                     23  2'More...'
     A                     24  2DSPATR(BL)
```

---

## ✅ **Critères d'Acceptation Sprint 4**

### **1. Relations DSL**
- [ ] Parse `customer: Customer required` dans CustomerOrder
- [ ] Génère contrainte FK correcte dans DDL  
- [ ] Validation référentielle dans services RPG
- [ ] Import d'entités externes via `import './customer.cmagic'`

### **2. Jointures et Vues**
- [ ] Vue `OrderWithCustomer` avec champs Customer jointes
- [ ] Requêtes SQL avec INNER JOIN générées automatiquement
- [ ] Performance jointures acceptable (< 1s pour 100 ordres)
- [ ] Mapping correct structures jointures ↔ écrans

### **3. Interface Master-Detail**
- [ ] WORK_WITH Orders affiche nom client (pas ID)
- [ ] Maintenance Order avec lookup/validation Customer
- [ ] Option 8 depuis Customer → Liste ordres client
- [ ] Navigation bidirectionnelle Customer ↔ Orders

### **4. Validation Intégrité**
- [ ] Création Order impossible si Customer inexistant
- [ ] Suppression Customer bloquée si Orders existantes
- [ ] Messages d'erreur FK informatifs
- [ ] Cohérence données garantie

### **5. Extensibilité**
- [ ] Pattern réutilisable pour futures relations
- [ ] Performance évolutive (indexes automatiques)
- [ ] Architecture prête pour relations N-N complexes
- [ ] Zones manuelles préservées avec jointures

---

## 📊 **Métriques de Succès Sprint 4**

### **Métriques Relations**
| Métrique | Cible | Mesure |
|----------|-------|--------|
| **Performance jointure** | < 1s | 100 ordres avec client |
| **Validation FK** | 100% | Aucune donnée incohérente |
| **Navigation UI** | < 2 clics | Customer → Orders → Detail |
| **Temps génération** | < 5s | Entités avec relations |

### **Métriques Données**
- ✅ **Intégrité référentielle** : 0 violation FK
- ✅ **Cohérence jointures** : Données identiques vue/détail
- ✅ **Performance SQL** : Index automatiques utilisés
- ✅ **Évolutivité** : Pattern extensible autres relations

---

## 🎯 **Livrables Sprint 4**

### **Extensions Parser/Generator**
- [ ] **Relation Parser** : Support `entity: Entity` syntax
- [ ] **FK Generator** : Contraintes SQL automatiques
- [ ] **Join Generator** : Requêtes avec jointures
- [ ] **Master-Detail UI** : Templates écrans liés

### **Artefacts CustomerOrder**
- [ ] **CustomerOrder complet** : DDL, services, écrans
- [ ] **Relations fonctionnelles** : FK + jointures
- [ ] **UI Master-Detail** : Navigation Customer ↔ Orders
- [ ] **Tests intégrité** : Scénarios validation FK

### **Documentation Relations**
- [ ] **Relations Guide** : Syntaxe DSL et patterns
- [ ] **Performance Guide** : Optimisation jointures
- [ ] **Master-Detail Patterns** : Navigation entre entités

---

## 🔮 **Préparation Sprint 5**

### **Architecture Workflow**
- ✅ **Entity Relations** : Base pour workflow inter-entités
- ✅ **State Management** : Pattern prêt pour statuts Order
- ✅ **Action Triggers** : Infrastructure actions métier
- ✅ **UI Contextual** : Boutons selon état/relation

**🎯 Sprint 4 établit les fondations relationnelles du système, permettant de créer des applications multi-entités cohérentes avec intégrité référentielle garantie.**
