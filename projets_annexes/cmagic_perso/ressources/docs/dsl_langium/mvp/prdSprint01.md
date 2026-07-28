# 🚀 **PRD Sprint 1 - Fondations + Entité Simple**

**Sprint :** 1/6  
**Durée :** 2 semaines  
**Objectif :** Établir les fondations du générateur CMagic avec une entité Customer basique

---

## 📊 **BILAN DE L'ÉTAT ACTUEL (Point de départ)**

### ✅ **Déjà réalisé :**
1. **Architecture Langium** : Grammaire de base avec entity/field/types
2. **CLI fonctionnel** : Commander.js + structure de base
3. **Générateur SQL** : Template Handlebars + logique de génération
4. **Tests de base** : Vitest configuré avec quelques tests
5. **Build system** : TypeScript + Langium generation pipeline
6. **Entité Customer** : Définie dans `ressources/examples/src/customer/customer.cmagic`

### ❌ **À corriger/implémenter :**
1. **Tests de parsing échouent** : Accès incorrect aux propriétés TypeDefinition
2. **Grammaire incomplète** : Manque struct, enum, view, operations du Sprint 01
3. **Générateur incomplet** : Pas de copybooks RPG, seuls templates SQL
4. **Validation manquante** : Pas de validation business rules
5. **CustomerOrder manquante** : Entité à créer selon MVP

---

## 🎯 **Objectifs du Sprint**

### **Objectif Principal**
Prouver la viabilité technique du concept en générant les artefacts de base pour une entité `Customer` simple.

### **Objectifs Spécifiques**
1. ✅ **Parser DSL** : Analyser correctement un fichier `.cmagic` avec entité, struct, enum
2. ✅ **Générer DDL** : Produire un script SQL DDL valide et compilable
3. ✅ **Générer Copybooks** : Créer des structures RPG modernes et réutilisables
4. ✅ **CLI Fonctionnel** : Interface en ligne de commande basique mais robuste
5. ✅ **Architecture Extensible** : Préparer le terrain pour les sprints suivants

---

## 📋 **Scope du Sprint 1**

### **✅ In Scope (Must Have)**

#### **1. Grammaire DSL Langium (Core)**
```typescript
// Concepts supportés dans customer.cmagic
- entity Customer { ... }
- struct Address { ... }  
- enum UserStatus { ... }
- Types : Int, String(n), Date, Decimal(p,s), Boolean
- Modificateurs : required, default(value), unique
```

#### **2. Types de Données Supportés**
| Type DSL | Type RPG | Type SQL | Description |
|----------|----------|----------|-------------|
| `Int` | `INT(10)` | `INTEGER` | Entier 32 bits |
| `String(n)` | `VARCHAR(n)` | `VARCHAR(n)` | Chaîne variable |
| `Date` | `DATE` | `DATE` | Date |
| `Decimal(p,s)` | `PACKED(p:s)` | `DECIMAL(p,s)` | Décimal |
| `Boolean` | `IND` | `CHAR(1)` | Booléen Y/N |

#### **3. Artefacts Générés**
```
src/customer/
├── Customer_H.rpgleinc       # Structures de données
├── CUSTOMERP.sql            # DDL table + contraintes
└── .cmagic/
    └── generation.log       # Log de génération
```

#### **4. CLI Interface**
```bash
# Commandes Sprint 1
cmagic generate customer.cmagic    # Génération complète
cmagic validate customer.cmagic    # Validation syntaxe
cmagic --version                   # Version
cmagic --help                      # Aide
```

### **❌ Out of Scope (Won't Have)**
- 🚫 Services RPG (Sprint 2)
- 🚫 Écrans DSPF (Sprint 3) 
- 🚫 Relations entre entités (Sprint 4)
- 🚫 Workflow et actions (Sprint 5)
- 🚫 Sources de données externes
- 🚫 Validation métier avancée

---

## 📝 **Spécifications Détaillées**

### **1. Fichier DSL `customer.cmagic` (Exemple)**

```jdl
// Fichier : src/customer.cmagic
// Description : Entité Customer basique pour MVP Sprint 1

// Structure réutilisable pour adresse
struct Address {
    ligne1: String(50) required,
    ligne2: String(50),
    codePostal: String(10) required,
    ville: String(50) required,
    pays: String(3) default("FR")
}

// Énumération pour statut client
enum CustomerStatus {
    ACTIVE,      // Client actif
    INACTIVE,    // Client inactif
    SUSPENDED    // Client suspendu
}

// Entité principale Customer
entity Customer {
    id: Int required,                           // Clé primaire auto-increment
    customerCode: String(10) required unique,   // Code client unique
    name: String(80) required,                  // Raison sociale
    address: Address required,                  // Adresse complète
    phone: String(20),                         // Téléphone
    email: String(100),                        // Email
    status: CustomerStatus default(ACTIVE),     // Statut client
    creationDate: Date required,               // Date de création
    creditLimit: Decimal(15,2) default(0),    // Limite de crédit
    isVip: Boolean default(false)              // Client VIP
}
```

### **2. Génération DDL SQL**

**Sortie attendue : `CUSTOMERP.sql`**
```sql
-- ============================================
-- Table Customer - Générée par CMagic v1.0
-- Source : customer.cmagic
-- Date : 2024-12-20 14:30:00
-- ============================================

-- Table principale
CREATE TABLE CUSTOMERP (
    ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    CUSTOMER_CODE VARCHAR(10) NOT NULL,
    NAME VARCHAR(80) NOT NULL,
    
    -- Champs Address (struct aplatie)
    ADDR_LIGNE1 VARCHAR(50) NOT NULL,
    ADDR_LIGNE2 VARCHAR(50),
    ADDR_CODEPOSTAL VARCHAR(10) NOT NULL,
    ADDR_VILLE VARCHAR(50) NOT NULL,
    ADDR_PAYS VARCHAR(3) NOT NULL DEFAULT 'FR',
    
    -- Autres champs
    PHONE VARCHAR(20),
    EMAIL VARCHAR(100),
    STATUS VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CREATION_DATE DATE NOT NULL,
    CREDIT_LIMIT DECIMAL(15,2) NOT NULL DEFAULT 0,
    IS_VIP CHAR(1) NOT NULL DEFAULT 'N',
    
    -- Métadonnées techniques
    CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    PRIMARY KEY (ID),
    UNIQUE (CUSTOMER_CODE),
    CHECK (STATUS IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    CHECK (IS_VIP IN ('Y', 'N')),
    CHECK (CREDIT_LIMIT >= 0)
);

-- Index pour recherches fréquentes
CREATE INDEX CUSTOMERP_CODE_IDX ON CUSTOMERP (CUSTOMER_CODE);
CREATE INDEX CUSTOMERP_NAME_IDX ON CUSTOMERP (NAME);
CREATE INDEX CUSTOMERP_STATUS_IDX ON CUSTOMERP (STATUS);

-- Trigger pour mise à jour automatique UPDATED_AT
CREATE TRIGGER CUSTOMERP_UPD_TRG
    BEFORE UPDATE ON CUSTOMERP
    FOR EACH ROW
    SET NEW.UPDATED_AT = CURRENT_TIMESTAMP;

-- Commentaires descriptifs
COMMENT ON TABLE CUSTOMERP IS 'Table des clients - Générée par CMagic';
COMMENT ON COLUMN CUSTOMERP.ID IS 'Identifiant unique auto-increment';
COMMENT ON COLUMN CUSTOMERP.CUSTOMER_CODE IS 'Code client unique métier';
COMMENT ON COLUMN CUSTOMERP.STATUS IS 'Statut: ACTIVE, INACTIVE, SUSPENDED';
```

---

## 🚀 **PLAN D'EXÉCUTION SPRINT 01**

### **Phase 1: Fondations & Corrections (Priorité 1) - 3 jours**

#### **Tâche 1.1: Correction des tests de parsing existants**
- **Objectif** : Corriger les 2 tests qui échouent
- **Actions** :
  - Corriger l'accès à `f.type.typeName` dans parsing.test.ts
  - Fixer la casse `string` → `String` dans test1.cmagic
- **Tests** : Les 12 tests doivent passer
- **Livrable** : Tests verts ✅

#### **Tâche 1.2: Extension de la grammaire pour Sprint 01**
- **Objectif** : Supporter struct, enum, view selon customer.cmagic
- **Actions** :
  - Ajouter `struct` à la grammaire Langium
  - Ajouter `enum` à la grammaire Langium  
  - Ajouter `view` à la grammaire Langium
  - Ajouter modifiers: `required`, `unique`, `default(value)`
  - Ajouter type `Decimal(p,s)` et `Boolean`
- **Tests** : Parser customer.cmagic sans erreur
- **Livrable** : Grammar étendue + AST généré

#### **Tâche 1.3: Création de l'entité CustomerOrder**
- **Objectif** : Créer customerOrder.cmagic selon MVP
- **Actions** :
  - Définir entity CustomerOrder avec référence Customer
  - Ajouter enum OrderStatus (DRAFT, CONFIRMED, SHIPPED, DELIVERED)
  - Ajouter struct OrderLine (produit, quantité, prix)
- **Tests** : Parser customerOrder.cmagic sans erreur
- **Livrable** : customerOrder.cmagic

### **Phase 2: Générateur SQL Complet (Priorité 1) - 2 jours**

#### **Tâche 2.1: Extension du générateur SQL pour nouveaux types**
- **Objectif** : Supporter tous les types du Sprint 01
- **Actions** :
  - Ajouter mapping Decimal(p,s) → DECIMAL(p,s)
  - Ajouter mapping Boolean → CHAR(1) CHECK (VALUE IN ('Y','N'))
  - Gérer les contraintes: NOT NULL, UNIQUE, DEFAULT
  - Ajouter génération des index automatiques
- **Tests** : Génération SQL complète pour Customer
- **Livrable** : Template SQL étendu

#### **Tâche 2.2: Génération des relations (Foreign Keys)**
- **Objectif** : Supporter les références entre entités
- **Actions** :
  - Détecter les références d'entité dans les champs
  - Générer ALTER TABLE ADD CONSTRAINT FK_xxx
  - Générer les index sur clés étrangères
- **Tests** : SQL généré pour Customer + CustomerOrder avec FK
- **Livrable** : Relations SQL fonctionnelles

### **Phase 3: Générateur RPG Copybooks (Priorité 1) - 3 jours**

#### **Tâche 3.1: Création du générateur de copybooks**
- **Objectif** : Générer les structures RPG (.rpgleinc)
- **Actions** :
  - Créer template Handlebars pour copybooks RPG
  - Mapper types DSL → types RPG (VARCHAR, INT, DATE, PACKED, IND)
  - Générer structures pour entités: Entity_t, Entity_detail_t, Entity_key_t
  - Gérer les structures embeddées (struct Address)
- **Tests** : Customer_H.rpgleinc généré et conforme
- **Livrable** : Générateur copybook fonctionnel

#### **Tâche 3.2: Génération des constantes pour enums**
- **Objectif** : Convertir enum DSL en constantes RPG
- **Actions** :
  - Générer DCL-C pour chaque valeur d'enum
  - Convention de nommage: ENTITY_ENUM_VALUE
  - Ajouter commentaires descriptifs
- **Tests** : Constantes CustomerStatus générées
- **Livrable** : Support enum complet

### **Phase 4: Tests Automatisés Complets (Priorité 2) - 2 jours**

#### **Tâche 4.1: Tests de génération SQL étendus**
- **Objectif** : Couvrir tous les cas du Sprint 01
- **Actions** :
  - Test Customer SQL avec tous les types
  - Test CustomerOrder avec relations FK
  - Test contraintes et index
  - Ajouter snapshots pour non-régression
- **Tests** : Coverage > 80% sur générateur SQL
- **Livrable** : Suite de tests SQL robuste

#### **Tâche 4.2: Tests de génération RPG**
- **Objectif** : Valider la génération copybooks
- **Actions** :
  - Test Customer_H.rpgleinc structure complète
  - Test mappings de types corrects
  - Test génération constantes enum
  - Validation syntaxe RPG générée
- **Tests** : Coverage > 80% sur générateur RPG
- **Livrable** : Suite de tests RPG robuste

### **Phase 5: Validation End-to-End (Priorité 1) - 1 jour**

#### **Tâche 5.1: Tests manuels complets**
- **Objectif** : Valider le workflow complet
- **Actions** :
  - CLI generate sur customer.cmagic → tous artefacts générés
  - CLI generate sur customerOrder.cmagic → avec FK fonctionnelle
  - Compilation SQL sur DB2 (si accessible)
  - Validation copybook RPG par inclusion dans programme test
- **Tests** : Workflow end-to-end fonctionnel
- **Livrable** : Sprint 01 validé ✅

---

## 📋 **Critères d'Acceptation Sprint 01**

### **Must Have ✅**
1. ✅ **Parser complet** : customer.cmagic + customerOrder.cmagic sans erreur
2. ✅ **Générateur SQL** : DDL complet avec contraintes et FK 
3. ✅ **Générateur RPG** : Copybooks .rpgleinc fonctionnels
4. ✅ **CLI robuste** : generate + validate + help
5. ✅ **Tests > 80%** : Coverage SQL + RPG generators
6. ✅ **Documentation** : Exemples customer + customerOrder

### **Should Have 📋**
- ⚠️ **Validation business** : règles métier de base
- ⚠️ **Error handling** : messages d'erreur clairs
- ⚠️ **Performance** : génération < 2s pour 10 entités

### **Could Have 🎯**
- 🔄 **Watch mode** : régénération automatique sur changement
- 🔄 **Template customization** : override templates utilisateur
- 🔄 **Multi-target** : génération simultanée SQL + RPG

---

### **3. Génération Copybook RPG**

**Sortie attendue : `Customer_H.rpgleinc`**
```rpgle
**FREE
// ============================================
// Customer Headers - Générée par CMagic v1.0
// Source : customer.cmagic  
// Date : 2024-12-20 14:30:00
// ============================================

/if not defined(CUSTOMER_H)
/define CUSTOMER_H

// ========================================
// STRUCTURES COMMUNES
// ========================================

// Structure Address réutilisable
DCL-DS Address_t QUALIFIED TEMPLATE;
  ligne1 VARCHAR(50);
  ligne2 VARCHAR(50);
  codePostal VARCHAR(10);
  ville VARCHAR(50);
  pays VARCHAR(3) INZ('FR');
END-DS;

// ========================================
// CONSTANTES ÉNUMÉRATION
// ========================================

// CustomerStatus enum values
dcl-enum customerstatus qualified;
  active 'ACTIVE';
  inactive 'INACTIVE';
  suspended 'SUSPENDED';
end-enum;


// ========================================
// STRUCTURES ENTITÉ
// ========================================

// Structure de base Customer (données métier)
DCL-DS Customer_t QUALIFIED TEMPLATE;
  id INT(10);
  customerCode VARCHAR(10);
  name VARCHAR(80);
  address LIKEDS(Address_t);
  phone VARCHAR(20);
  email VARCHAR(100);
  status VARCHAR(20) INZ(customerstatus.activ);
  creationDate DATE;
  creditLimit PACKED(15:2) INZ(0);
  isVip IND INZ('N');
END-DS;

// Structure détaillée Customer (avec métadonnées techniques)
DCL-DS Customer_detail_t QUALIFIED TEMPLATE;
  id INT(10);
  customerCode VARCHAR(10);
  name VARCHAR(80);
  address LIKEDS(Address_t);
  phone VARCHAR(20);
  email VARCHAR(100);
  status VARCHAR(20) INZ(CUSTOMER_STATUS_ACTIVE);
  creationDate DATE;
  creditLimit PACKED(15:2) INZ(0);
  isVip IND INZ('N');
  
  // Métadonnées techniques
  createdAt TIMESTAMP;
  updatedAt TIMESTAMP;
END-DS;

// Structure pour clé primaire
DCL-DS Customer_id_t QUALIFIED TEMPLATE;
  id INT(10);
END-DS;

// Structure pour recherche par code
DCL-DS Customer_search_t QUALIFIED TEMPLATE;
  customerCode VARCHAR(10);
  name VARCHAR(80);
  status VARCHAR(20);
END-DS;

/endif
```

### **4. Architecture CLI**

**Structure projet CLI :**
```
cli/
├── src/
│   ├── commands/
│   │   ├── generate.ts      # Commande génération
│   │   ├── validate.ts      # Commande validation
│   │   └── index.ts         # Export commandes
│   ├── generators/
│   │   ├── sql-generator.ts    # Générateur DDL
│   │   ├── rpg-generator.ts    # Générateur copybooks
│   │   └── base-generator.ts   # Classe de base
│   ├── templates/
│   │   ├── ddl.hbs            # Template SQL
│   │   └── copybook.hbs       # Template RPG
│   ├── utils/
│   │   ├── file-utils.ts      # Utilitaires fichiers
│   │   └── logger.ts          # Logger
│   └── main.ts              # Point d'entrée CLI
├── package.json
└── tsconfig.json
```

**Interface CLI `main.ts` :**
```typescript
#!/usr/bin/env node
import { Command } from 'commander';
import { generateCommand } from './commands/generate';
import { validateCommand } from './commands/validate';

const program = new Command();

program
  .name('cmagic')
  .description('CMagic DSL Code Generator for IBM i')
  .version('1.0.0-sprint1');

program
  .command('generate')
  .description('Generate artifacts from .cmagic files')
  .argument('<files...>', 'CMagic files to process')
  .option('-o, --output <dir>', 'Output directory', './src')
  .option('--dry-run', 'Show what would be generated without writing files')
  .action(generateCommand);

program
  .command('validate')
  .description('Validate .cmagic file syntax')
  .argument('<files...>', 'CMagic files to validate')
  .action(validateCommand);

program.parse();
```

---

## ✅ **Critères d'Acceptation**

### **1. Parsing DSL**
- [ ] Parse correctement `entity Customer` avec tous les types supportés
- [ ] Parse `struct Address` et l'utilise dans Customer
- [ ] Parse `enum CustomerStatus` et génère les constantes
- [ ] Validation des types et modificateurs
- [ ] Messages d'erreur clairs en cas de syntaxe invalide

### **2. Génération DDL**
- [ ] SQL DDL valide compilable sur Db2 for i
- [ ] Contraintes PRIMARY KEY, UNIQUE, CHECK générées
- [ ] Index automatiques sur champs fréquents
- [ ] Trigger UPDATE automatique pour UPDATED_AT
- [ ] Commentaires SQL descriptifs

### **3. Génération Copybook**
- [ ] RPG **FREE format compilable sans erreur
- [ ] Structures QUALIFIED TEMPLATE utilisables
- [ ] Constantes enum correctement définies
- [ ] Correspondance types DSL ↔ RPG exacte
- [ ] Headers et documentation générés

### **4. CLI Robuste**
- [ ] `cmagic generate customer.cmagic` fonctionne
- [ ] `cmagic validate customer.cmagic` détecte erreurs
- [ ] Option `--dry-run` montre aperçu sans écrire
- [ ] Messages de succès/erreur informatifs
- [ ] Gestion des chemins relatifs/absolus

### **5. Qualité Code**
- [ ] Architecture extensible pour sprints suivants
- [ ] Tests unitaires sur parseur et générateurs
- [ ] Code TypeScript typé et documenté
- [ ] Gestion d'erreurs robuste
- [ ] Logs de génération détaillés

---

## 🧪 **Plan de Test Sprint 1**

### **Tests Unitaires**
```typescript
// tests/parser.test.ts
describe('CMagic Parser', () => {
  test('should parse simple entity', () => {
    const source = 'entity Customer { id: Int required }';
    const ast = parseCMagic(source);
    expect(ast.entities).toHaveLength(1);
    expect(ast.entities[0].name).toBe('Customer');
  });
});

// tests/sql-generator.test.ts  
describe('SQL Generator', () => {
  test('should generate valid DDL for Customer', () => {
    const ddl = generateSQL(customerEntity);
    expect(ddl).toContain('CREATE TABLE CUSTOMERP');
    expect(ddl).toContain('PRIMARY KEY (ID)');
  });
});
```

### **Tests d'Intégration**
1. **Test End-to-End complet** : `customer.cmagic` → artefacts finaux
2. **Test compilation RPG** : Copybooks compilables sur IBM i
3. **Test exécution SQL** : DDL exécutable sur Db2
4. **Test CLI** : Commandes produisent résultats attendus

### **Tests Manuels**
- [ ] Tester sur différents OS (Windows, Linux, macOS)
- [ ] Validation sur IBM i réel avec compilateur RPG
- [ ] Performance sur fichiers .cmagic de taille variable
- [ ] Gestion des erreurs et edge cases

---

## 📊 **Métriques de Succès Sprint 1**

### **Métriques Techniques**
| Métrique | Cible | Mesure |
|----------|-------|--------|
| **Temps parsing** | < 100ms | Parser `customer.cmagic` |
| **Temps génération** | < 500ms | Générer tous artefacts |
| **Taille DDL** | < 200 lignes | Script SQL optimisé |
| **Couverture tests** | > 80% | Tests unitaires + intégration |

### **Métriques Qualité**
- ✅ **0 erreur compilation** RPG sur IBM i
- ✅ **0 erreur exécution** DDL sur Db2
- ✅ **Messages d'erreur** informatifs et actionnables
- ✅ **Documentation** complète et à jour

### **Métriques Utilisateur**
- ✅ **Développeur junior** génère Customer en < 30 min
- ✅ **Installation CLI** en < 5 min via npm
- ✅ **Feedback équipe** : syntaxe DSL intuitive
- ✅ **0 bug bloquant** en fin de sprint

---

## 🎯 **Livrables Sprint 1**

### **Code Source**
- [ ] **Parseur Langium** complet et testé
- [ ] **Générateurs SQL/RPG** fonctionnels
- [ ] **CLI Interface** avec commands generate/validate
- [ ] **Templates Handlebars** pour DDL et copybooks
- [ ] **Tests unitaires** > 80% couverture

### **Artefacts Générés**
- [ ] **customer.cmagic** : Exemple complet et documenté
- [ ] **CUSTOMERP.sql** : DDL prêt pour Db2
- [ ] **Customer_H.rpgleinc** : Copybook compilable
- [ ] **generation.log** : Log détaillé de génération

### **Documentation**
- [ ] **README.md** : Installation et démarrage rapide
- [ ] **User Guide** : Syntaxe DSL et exemples
- [ ] **Developer Guide** : Architecture et extension
- [ ] **CHANGELOG.md** : Évolutions Sprint 1

### **Package Distribution**
- [ ] **npm package** : `@cmagic/cli` installable
- [ ] **GitHub Release** : v1.0.0-sprint1
- [ ] **Docker Image** : Environnement préconfiguré
- [ ] **VS Code Extension** : Syntaxe highlighting (bonus)

---

## 🔮 **Préparation Sprints Suivants**

### **Architecture Extensible**
- ✅ **Plugin System** : Générateurs modulaires
- ✅ **Template Engine** : Handlebars customisable  
- ✅ **AST Structure** : Prêt pour relations et workflow
- ✅ **CLI Commands** : Extensible pour nouvelles fonctionnalités

### **Points d'Accroche Sprint 2**
- 🔗 **Service Generators** : Infrastructure prête
- 🔗 **Pattern Double Couche** : Namespace RPG défini
- 🔗 **Zone Protégées** : Marqueurs `[CMAGIC:MANUAL_*]`
- 🔗 **Tests Framework** : Base solide pour services

---

**🎯 Ce Sprint 1 pose des fondations solides tout en restant focused sur l'essentiel : prouver que l'idée fonctionne avec une entité Customer complète et utilisable.**
