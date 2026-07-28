# Roadmap Technique v2.0 - Post Repositionnement API REST

*Mis à jour le 30 septembre 2025 suite au repositionnement stratégique*

## 🚀 **SPRINTS REDÉFINIS**

### **Sprint 0 : Validation Pattern API REST (2 semaines)**
**Objectif** : Prouver la viabilité du pattern `ibmi_rest_api_instructions.md`

**Livrables :**
- [ ] Employee API complète selon documentation
- [ ] Tests cURL exhaustifs (tous opérateurs)
- [ ] Data Provider React-Admin fonctionnel
- [ ] Documentation points de friction
- [ ] Métriques performance (temps réponse, mémoire)
- [ ] Script validation automatique

**Critères succès :**
- ✅ Tous les tests cURL passent
- ✅ React-Admin affiche/modifie données
- ✅ X-Total-Count correctement implémenté
- ✅ Pagination + filtres + tri fonctionnels
- ✅ Performance < 200ms pour 10k records
- ✅ Build réussi avec BOB sur IBM i

**Tests de validation :**
```bash
# Build avec BOB sur IBM i
bob --build src/employee

# Tests depuis machine cliente ou IBM i
curl "http://server:44000/api/employees"                    # Collection
curl -I "http://server:44000/api/employees"                 # Header X-Total-Count
curl "http://server:44000/api/employees?_page=1&_limit=5"   # Pagination
curl "http://server:44000/api/employees?lastname_like=HAA"  # Filtres avancés
curl "http://server:44000/api/employees?salary_gte=50000"   # Opérateurs
curl "http://server:44000/api/employees?q=CHRISTINE"        # Recherche
```

### **Sprint 1 : Généralisation Pattern (3 semaines)**
**Objectif** : Créer template réutilisable

**Livrables :**
- [ ] Customer API avec même pattern
- [ ] Department API avec même pattern
- [ ] Guide `guide_nouvelle_api_rest.md`
- [ ] Templates RPGLE génériques
- [ ] Checklist validation nouvelle API
- [ ] Script génération squelette API

**Critères succès :**
- ✅ 3 APIs similaires fonctionnelles
- ✅ Temps création nouvelle API < 2 jours
- ✅ 90% code réutilisable identifié
- ✅ Templates validés par 2 développeurs

**Structure template :**
```
src/[resource]/
├── [resource].main.rpgle
├── [resource].route.sqlrpgle  
├── [resource].rest.sqlrpgle
├── [resource].sqlrpgle
└── [resource].bnd

includes/
└── [resource].rpgleinc
```

### **Sprint 2 : Actions Métier (2 semaines)**
**Objectif** : Enrichir APIs avec logique métier

**Livrables :**
- [ ] POST /employees/{id}/increase-salary
- [ ] POST /employees/{id}/promote
- [ ] POST /customers/{id}/update-credit-limit
- [ ] Pattern actions métier documenté
- [ ] Tests unitaires actions métier

**Pattern actions métier :**
```rpg
// Actions métier standardisées
dcl-pr [resource]_action export;
  actionName varchar(50) const;
  resourceId likeds(GLOBAL_id) const;
  actionData varchar(1000) const options(*nopass);
  result likeds([resource]_detail_t);
end-pr;
```

### **Sprint 3 : Préparation Générateur (3 semaines)**
**Objectif** : Préparer l'automatisation

**Livrables :**
- [ ] Templates RPG paramétrisés
- [ ] Analyseur AST tables DB2
- [ ] Générateur prototype (CLI)
- [ ] Tests génération Employee vs manuel
- [ ] Documentation générateur

**Architecture générateur :**
```
tools/generator/
├── analyze_db2_table.js      # Analyse structure table
├── generate_api_skeleton.js  # Génère fichiers squelette
├── templates/               # Templates paramétrisés
│   ├── resource.main.rpgle.template
│   ├── resource.rest.sqlrpgle.template
│   └── resource.rpgleinc.template
└── tests/                   # Tests génération
```

## 🎯 **PARALLÉLISME DSL + API**

### **Développement Parallèle Recommandé**
```
Timeline (semaines):
0----2----4----6----8----10----12
|    |    |    |    |     |     |
Sprint 0  |    Sprint 2   |     |
     Sprint 1        Sprint 3   |
                              Convergence

API Standard:    [====Validation====][==Généralisation==][===Templates===]
DSL CMagic:           [==Recherche==][====Parser====][=Générateur=]
                                                           ↓
                                                    Convergence
```

### **Points de Convergence**
- **Semaine 7** : Templates API validés → Input générateur
- **Semaine 10** : Prototype générateur → Test Employee
- **Semaine 12** : CMagic génère API identique au manuel

## 📊 **MÉTRIQUES TECHNIQUES**

### **Phase API Standard (Sprint 0-2)**
| Métrique | Objectif | Sprint 0 | Sprint 1 | Sprint 2 |
|----------|----------|----------|----------|----------|
| **APIs créées** | 3+ | 1 (Employee) | +2 (Customer, Dept) | Actions |
| **Temps création** | < 2 jours | Baseline | Optimisation | Validation |
| **Performance** | < 200ms | Mesure | Validation | Stable |
| **Compatibilité** | 100% | React-Admin | +Appsmith | +Retool |
| **Tests passants** | 100% | Employee | Tous | Actions |

### **Phase Générateur DSL (Sprint 3+)**
| Métrique | Objectif | Sprint 3 | Sprint 4+ |
|----------|----------|----------|-----------|
| **Temps génération** | < 30 sec | Prototype | Production |
| **Code généré conforme** | 100% | 80% | 100% |
| **Tables supportées** | Toutes | Tables simples | Complexes |
| **Maintenance** | Auto | Semi-auto | Auto |

## 🛠️ **OUTILS ET SCRIPTS**

### **Script Validation API (Sprint 0)**
```bash
#!/bin/bash
# validate_api_pattern.sh - Validation pattern API REST

echo "🔍 Validation Pattern API REST"
echo "=============================="

IBMI_HOST=${IBMI_HOST:-"your-ibmi-server"}
PORT=${PORT:-"44000"}

# Test 1: Header X-Total-Count présent
echo "Test 1: Header X-Total-Count..."
HEADERS=$(curl -s -I "http://$IBMI_HOST:$PORT/api/employees")
if echo "$HEADERS" | grep -i "x-total-count" > /dev/null; then
    echo "✅ X-Total-Count présent"
else
    echo "❌ X-Total-Count manquant"
fi

# Test 2: Format JSON tableau pour collection
echo "Test 2: Format JSON collection..."
RESPONSE=$(curl -s "http://$IBMI_HOST:$PORT/api/employees?_limit=1")
if echo "$RESPONSE" | grep -E '^\[.*\]$' > /dev/null; then
    echo "✅ Format tableau JSON correct"
else
    echo "❌ Format JSON incorrect (doit être un tableau)"
fi

# Test 3: Pagination fonctionne
echo "Test 3: Pagination..."
RESPONSE1=$(curl -s "http://$IBMI_HOST:$PORT/api/employees?_page=1&_limit=2")
RESPONSE2=$(curl -s "http://$IBMI_HOST:$PORT/api/employees?_page=2&_limit=2")
if [ "$RESPONSE1" != "$RESPONSE2" ]; then
    echo "✅ Pagination fonctionnelle"
else
    echo "❌ Pagination ne fonctionne pas"
fi

echo ""
echo "🎯 Validation terminée!"
echo "Pour plus de détails, voir: ibmi_rest_api_instructions.md"
```

### **Générateur Squelette API (Sprint 1)**
```javascript
// generate_api_skeleton.js
const fs = require('fs');
const path = require('path');

function generateApiSkeleton(resourceName, tableName, fields) {
    const templates = {
        main: fs.readFileSync('templates/resource.main.rpgle.template', 'utf8'),
        rest: fs.readFileSync('templates/resource.rest.sqlrpgle.template', 'utf8'),
        route: fs.readFileSync('templates/resource.route.sqlrpgle.template', 'utf8'),
        include: fs.readFileSync('templates/resource.rpgleinc.template', 'utf8')
    };
    
    // Remplacer variables template
    Object.keys(templates).forEach(key => {
        templates[key] = templates[key]
            .replace(/\{RESOURCE_NAME\}/g, resourceName)
            .replace(/\{TABLE_NAME\}/g, tableName)
            .replace(/\{FIELDS\}/g, generateFields(fields));
    });
    
    // Créer structure dossiers et fichiers
    const srcDir = `src/${resourceName}`;
    fs.mkdirSync(srcDir, { recursive: true });
    
    fs.writeFileSync(`${srcDir}/${resourceName}.main.rpgle`, templates.main);
    fs.writeFileSync(`${srcDir}/${resourceName}.rest.sqlrpgle`, templates.rest);
    fs.writeFileSync(`${srcDir}/${resourceName}.route.sqlrpgle`, templates.route);
    fs.writeFileSync(`includes/${resourceName}.rpgleinc`, templates.include);
    
    console.log(`✅ API ${resourceName} générée dans ${srcDir}`);
}
```

## 🎯 **CRITÈRES DE RÉUSSITE GLOBAUX**

### **Sprint 0 (Validation)**
- [ ] Employee API 100% conforme `ibmi_rest_api_instructions.md`
- [ ] Tous tests cURL passent
- [ ] React-Admin fonctionnel
- [ ] Performance validée

### **Sprint 1 (Généralisation)**
- [ ] 3 APIs avec pattern identique
- [ ] Guide création API réutilisable
- [ ] Templates validés
- [ ] Temps création < 2 jours

### **Sprint 2 (Actions Métier)**
- [ ] Pattern actions métier standardisé
- [ ] 3+ actions implémentées
- [ ] Tests unitaires complets

### **Sprint 3 (Automatisation)**
- [ ] Générateur prototype fonctionnel
- [ ] APIs générées = APIs manuelles
- [ ] Foundation pour CMagic DSL

## 🏆 **LIVRAISON CONTINUE**

### **Releases Intermédiaires**
- **v0.1.0** (Sprint 0) : Employee API de référence
- **v0.2.0** (Sprint 1) : Pattern généralisé + Templates
- **v0.3.0** (Sprint 2) : Actions métier intégrées
- **v1.0.0** (Sprint 3) : Générateur opérationnel

### **Déploiement**
- **Environnement Dev** : Tests continus
- **Environnement Test** : Validation utilisateurs
- **Environnement Prod** : Rollout progressif

---

**Cette roadmap est alignée avec l'analyse stratégique de repositionnement (Sept 2024) et capitalise sur l'excellente documentation `ibmi_rest_api_instructions.md`.**