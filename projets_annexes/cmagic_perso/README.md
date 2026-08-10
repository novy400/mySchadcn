# CMagic - Générateur de Code RPG/SQL

CMagic est un générateur de code pour créer automatiquement des services RPG et des schémas SQL à partir d'une définition d'entité en langage DSL.

## 🚀 Installation et Build

```bash
# Installation des dépendances
npm install

# Génération des parseurs Langium
npm run langium:generate

# Build du projet
npm run build

# ou tout en une fois
npm run langium:generate && npm run build
```

### Installation de l'extension VS Code

```bash
# Reconstruire la grammaire, l'extension et le serveur, puis créer le VSIX
npm run package:vsix

# Vérifier le manifeste et le serveur LSP réellement empaquetés
npm run test:vsix

# Installer l'extension packagée et recharger la fenêtre VS Code
code --install-extension cmagic-0.0.3.vsix --force
```

### Lancer l'IHM Monaco

Depuis le répertoire `projets_annexes/cmagic_perso` :

```powershell
npm run dev
```

Vite démarre l'IHM sur <http://localhost:5173>. La page d'accueil donne accès aux deux
configurations disponibles :

- [Monaco classique avec coloration Monarch](http://localhost:5173/static/monacoClassic.html) ;
- [Monaco étendu avec coloration TextMate](http://localhost:5173/static/monacoExtended.html).

Pour vérifier le build de production :

```powershell
npm run bundle
npm run bundle:serve
```

Le build est alors servi sur <http://localhost:5175>. Utiliser `Ctrl+C` dans le terminal
pour arrêter le serveur de développement ou le serveur de production.

## 📋 Commandes de Génération

### Génération basique
```bash
# Générer à partir d'un fichier .cmagic
node .\bin\cli.js generate .\prd_customer_test.cmagic

# Avec destination personnalisée
node .\bin\cli.js generate .\prd_customer_test.cmagic -d .\output
```

### Exemples de génération
```bash
# Générer customer depuis le fichier de test
node .\bin\cli.js generate .\prd_customer_test.cmagic

# Générer depuis un exemple existant
node .\bin\cli.js generate .\examples\customer_order.cmagic

# Générer depuis les ressources
node .\bin\cli.js generate .\ressources\examples\src\customer\customer.cmagic
```

## 🧪 Tests

### Tests unitaires
```bash
# Lancer tous les tests
npm test

# Lancer un test spécifique
npx vitest run -t "should generate a correct CREATE TABLE statement for a simple entity"

# Tests en mode watch
npm run test:watch
```

### Tests de génération manuelle

1. **Nettoyer les fichiers générés**
```bash
Remove-Item -Path ".\generated\customer" -Recurse -Force -ErrorAction SilentlyContinue
```

2. **Générer le code**
```bash
node .\bin\cli.js generate .\prd_customer_test.cmagic
```

3. **Vérifier les fichiers générés**
```bash
Get-ChildItem -Path ".\generated\customer" -Name "*.sqlrpgle"
```

4. **Vérifier qu'il n'y a plus de TODO**
```bash
Select-String -Path ".\generated\customer\customer.sqlrpgle" -Pattern "TODO"
```

## 📁 Structure des Fichiers Générés

Pour une entité `Customer`, la génération produit :

```
generated/
└── customer/
    ├── customer.rpgleinc      # Headers RPG (structures, prototypes)
    ├── customer.sqlrpgle      # Service RPG avec procédures métier
    ├── customer.test.sqlrpgle # Tests unitaires RPG
    └── customer.sql           # Schéma SQL (CREATE TABLE)
```

## 🔍 Vérifications de Qualité

### Vérifier les implémentations complètes
```bash
# Vérifier que customer_search_local est implémenté
Select-String -Path ".\generated\customer\customer.sqlrpgle" -Pattern "lLimit int\(10\)"

# Vérifier que customer_change_local est implémenté  
Select-String -Path ".\generated\customer\customer.sqlrpgle" -Pattern "UPDATE customer"

# Vérifier que customer_delete_local est implémenté
Select-String -Path ".\generated\customer\customer.sqlrpgle" -Pattern "DELETE FROM customer"
```

### Compter les lignes générées
```bash
Get-Content ".\generated\customer\customer.sqlrpgle" | Measure-Object -Line
```

## 📝 Exemple de Fichier DSL

Voici un exemple de fichier `customer.cmagic` :

```cmagic
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
    id: Int required,
    code: String(10) required unique,
    name: String(80) required,
    address: Address required,
    phone: String(20),
    email: String(100),
    status: CustomerStatus default(ACTIVE),
    creationDate: Date required,
    creditLimit: Decimal(15,2) default(0),
    isVip: Boolean default(false)
}

// Vue pour la liste
view item for Customer {
    id,
    name,
    status,
    creationDate
}

// Opérations supportées
operations for Customer {
    CREATE,
    DISPLAY,
    CHANGE,
    DELETE,
    SEARCH
}
```

## 🔧 Fonctionnalités Générées

### Procédures RPG Publiques
- `customer_create()` - Création d'un nouveau client
- `customer_display()` - Affichage des détails
- `customer_change()` - Modification d'un client existant
- `customer_delete()` - Suppression d'un client
- `customer_search()` - Recherche avec pagination
- `customer_getByID()` - Récupération par ID
- `customer_isValid()` - Validation métier

### Procédures RPG Locales (Implémentées)
- `customer_create_local()` - Insertion SQL avec gestion d'erreurs
- `customer_display_local()` - Affichage formaté
- `customer_change_local()` - Mise à jour SQL complète
- `customer_delete_local()` - Suppression SQL avec vérifications
- `customer_search_local()` - Recherche avancée avec pagination, filtres, tri
- `customer_getByID_local()` - Récupération avec mapping complet
- `customer_isValid_local()` - Validation métier par action

### Fonctionnalités Avancées
- ✅ **Gestion d'erreurs SQL** complète avec diagnostics
- ✅ **Conversion de types** automatique (RPG ↔ SQL)
- ✅ **Pagination dynamique** (LIMIT/OFFSET)
- ✅ **Filtrage dynamique** (WHERE clauses construites)
- ✅ **Tri dynamique** (ORDER BY configurable)
- ✅ **Requêtes SQL paramétrées** sécurisées
- ✅ **Logging et traçabilité** intégrés
- ✅ **Validation métier** par contexte d'action
- ✅ **Gestion des curseurs** SQL optimisée

## 🐛 Débogage

### Afficher les détails de génération
```bash
node .\bin\cli.js generate .\prd_customer_test.cmagic --verbose
```

### Vérifier la syntaxe du DSL
```bash
# Le générateur indique automatiquement les erreurs de syntaxe
node .\bin\cli.js generate .\votre_fichier.cmagic
```

### Nettoyer complètement
```bash
# Nettoyer tous les fichiers générés
Remove-Item -Path ".\generated" -Recurse -Force -ErrorAction SilentlyContinue

# Nettoyer et rebuilder
npm run clean && npm run build
```

## 📈 Performance

Un fichier `customer.cmagic` typique génère :
- ~870 lignes de code RPG service
- ~200 lignes de headers RPG  
- ~150 lignes de tests RPG
- ~50 lignes de SQL

**Temps de génération** : < 1 seconde

## 🔄 Workflow de Développement

1. **Modifier le fichier DSL** (`*.cmagic`)
2. **Supprimer les anciens fichiers** (optionnel)
3. **Générer le nouveau code**
4. **Vérifier la qualité** (pas de TODO, syntaxe correcte)
5. **Tester** le code généré

```bash
# Script complet de test
Remove-Item -Path ".\generated\customer" -Recurse -Force -ErrorAction SilentlyContinue
node .\bin\cli.js generate .\prd_customer_test.cmagic
Get-ChildItem -Path ".\generated\customer"
Select-String -Path ".\generated\customer\customer.sqlrpgle" -Pattern "TODO"
```
