# 🚀 **PRD Sprint 1 - Fondations + Entité Simple**

**Sprint :** 1/6  
**Durée :** 2 semaines  
**Objectif :** Établir les fondations du générateur CMagic avec une entité Customer basique

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

**Sortie attendue : `customer.sql`**
```sql
-- ============================================
-- Table Customer - Générée par CMagic v1.0
-- Source : customer.cmagic
-- Date : 2024-12-20 14:30:00
-- ============================================

-- Table principale
CREATE TABLE CUSTOMER (
    ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    CODE VARCHAR(10) NOT NULL,
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
    CREDIT_LIMIT DECIMAL( 15, 2) NOT NULL DEFAULT 0,
    IS_VIP CHAR(1) NOT NULL DEFAULT 'N',
    
    -- Métadonnées techniques
    CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CREATED_BY VARCHAR(128) NOT NULL DEFAULT USER,
    UPDATED_AT TIMESTAMP(12) NOT NULL GENERATED ALWAYS AS ROW BEGIN,
    UPDATED_BY VARCHAR(128)  GENERATED ALWAYS AS (SESSION_USER),
    -- Contraintes
    PRIMARY KEY (ID),
    UNIQUE (CODE),
    CHECK (STATUS IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    CHECK (IS_VIP IN ('O', 'N')),
    CHECK (CREDIT_LIMIT >= 0)
) RCDFMT CUSTOMERF;

-- Index pour recherches fréquentes
CREATE INDEX CUSTOMER_CODE_IDX ON CUSTOMER (CODE);
CREATE INDEX CUSTOMER_NAME_IDX ON CUSTOMER (NAME);
CREATE INDEX CUSTOMER_STATUS_IDX ON CUSTOMER (STATUS);


-- LABELaires descriptifs
LABEL ON TABLE CUSTOMER IS 'Table des clients - Générée par CMagic';
LABEL ON COLUMN CUSTOMER.ID IS 'Identifiant unique auto-increment';
LABEL ON COLUMN CUSTOMER.CODE IS 'Code client unique métier';
LABEL ON COLUMN CUSTOMER.NAME IS 'Raison sociale du client';
LABEL ON COLUMN CUSTOMER.ADDR_LIGNE1 IS 'Adresse ligne 1';
LABEL ON COLUMN CUSTOMER.ADDR_LIGNE2 IS 'Adresse ligne 2 (optionnelle)';
LABEL ON COLUMN CUSTOMER.ADDR_CODEPOSTAL IS 'Code postal du client';
LABEL ON COLUMN CUSTOMER.ADDR_VILLE IS 'Ville du client';
LABEL ON COLUMN CUSTOMER.ADDR_PAYS IS 'Pays du client';
LABEL ON COLUMN CUSTOMER.STATUS IS 'Statut: ACTIVE, INACTIVE, SUSPENDED';
LABEL ON COLUMN CUSTOMER.CREATION_DATE IS 'Date de création du client';
LABEL ON COLUMN CUSTOMER.CREDIT_LIMIT IS 'Limite de crédit du client';  
LABEL ON COLUMN CUSTOMER.IS_VIP IS 'Indicateur VIP: O (Oui), N (Non)';
-- Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON CUSTOMER TO PUBLIC; 
-- Permissions spécifiques
GRANT ALTER, INDEX ON CUSTOMER TO GIYVOVIE WITH GRANT OPTION;

```

### **3. Génération Copybook RPG**

**Sortie attendue : `customer.rpgleinc`**
```rpgle
**free
// ============================================
// customer headers - générée par cmagic v1.0
// source : customer.cmagic  
// date : 2024-12-20 14:30:00
// ============================================

/if defined(customer_h_defined)       
/eof                               
/endif                             
/define customer_h_defined  
/// ============================================
// includes standard
/// ============================================
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'

/// ========================================
// structures communes
/// ========================================

// structure address réutilisable
dcl-ds customer_address_t qualified template;
  ligne1 varchar(50);
  ligne2 varchar(50);
  codepostal varchar(10);
  ville varchar(50);
  pays varchar(3) inz('fr');
end-ds;

// structure audit réutilisable
dcl-ds audit_t qualified template;
  createdat timestamp;
  createdby char(10);
  updatedat timestamp;
  updateby char(10);
end-ds;
/// ========================================
// constantes énumération
///========================================

dcl-enum customer_status qualified;
  active 'active';
  inactive 'inactive';
  suspended 'suspended';
end-enum;

///========================================
// structures entité
///========================================

///
// structure de base customer (données métier)
///
dcl-ds customer_t qualified template;
  id int(10);
  code varchar(10);
  name varchar(80);
  address likeds(customer_address_t);
  phone varchar(20);
  email varchar(100);
  status varchar(20) 
    inz(customer_status.active);
  creationdate date;
  creditlimit packed(15:2) inz(0);
  isvip ind inz('n');
end-ds;
///
// structure pour clé primaire
///
dcl-ds customer_id_t qualified template;
  id int(10);
end-ds;
///
// structure détaillée customer (avec métadonnées techniques)
///
dcl-ds customer_detail_t qualified template;
  // données métier héritées de customer_t
  detail likeds(customer_t);
  // métadonnées techniques
  audit likeds(audit_t);
end-ds;

```
### **4. Architecture entité**
cli/
├── src/
│   ├── customer/
│   │   ├── customer.cmagic      # dsl entité
│   │   ├── customer.table       # table customer
│   │   ├── customer.rpgleinc    # definition procédures et structures
│   │   └── Rules.mk             # Build BOB
### **5. Architecture CLI**

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
- [ ] Commentaires SQL descriptifs
- [ ] Labels descriptifs pour chaque colonne

### **3. Génération Copybook**
- [ ] RPG **FREE format compilable sans erreur
- [ ] Structures QUALIFIED TEMPLATE utilisables
- [ ] Enumération correctement définies dcl-enum
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
