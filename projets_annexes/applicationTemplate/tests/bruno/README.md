# Tests Bruno - Employee API

## 🎯 Objectif

Tests automatisés de l'API Employee REST avec Bruno CLI pour valider la conformité selon `ibmi_rest_api_instructions.md`.

## 📁 Structure

```
tests/bruno/
├── bruno.json                    # Configuration Bruno
├── environments/
│   ├── local.bru                 # Config localhost:44000
│   └── recette.bru              # Config IBM i server
└── employee-api/
    ├── collection.bru            # Headers communs
    ├── get-employee-by-id.bru    # Test GET /api/employees/{id}
    └── get-employees.bru         # Test GET /api/employees
```

## 🚀 Utilisation

### Depuis IBM i (PASE)

```bash
# Aller dans le répertoire du projet
cd /path/to/your/project

# Lancer les tests avec script
chmod +x scripts/run-bruno-tests.sh
./scripts/run-bruno-tests.sh recette html

# Ou directement avec Bruno CLI
cd tests/bruno
bru run employee-api --env recette -o ../../reports/bruno/results.html -f html
```

### Depuis Windows (local)

```powershell
# Dans le terminal PowerShell
cd tests\bruno
bru run employee-api --env local -o ..\..\reports\bruno\results.html -f html
```

## 🧪 Tests Inclus

### ✅ get-employee-by-id.bru
- Status 200 OK
- Content-Type: application/json
- Structure objet employee
- ID correspondant
- Headers CORS

### ✅ get-employees.bru
- Status 200 OK
- Réponse = tableau JSON
- Header X-Total-Count présent
- Headers CORS
- Structure employés

## 📊 Rapports

Les rapports sont générés dans `reports/bruno/` :
- **HTML** : Rapport visuel complet
- **JSON** : Données brutes pour intégration CI/CD

## 🔧 Configuration

### Modifier l'URL du serveur
Éditer `environments/recette.bru` :
```
vars {
  baseUrl: http://your-ibmi-server:44000
  apiPath: /api
}
```

### Ajouter de nouveaux tests
1. Créer un fichier `.bru` dans `employee-api/`
2. Suivre le format des tests existants
3. Lancer : `bru run employee-api --env recette`

## 🎯 Prochaines Étapes

- [ ] Tests de pagination (`_page`, `_limit`)
- [ ] Tests de filtres (`_like`, `_gte`, etc.)
- [ ] Tests CRUD (POST, PUT, DELETE)
- [ ] Tests de performance
- [ ] Intégration CI/CD

## 📝 Exemples de Commandes

```bash
# Test simple console
bru run employee-api --env recette

# Rapport HTML
bru run employee-api --env recette -o reports/test.html -f html

# Test spécifique
bru run employee-api/get-employee-by-id.bru --env recette

# Verbose pour debug
bru run employee-api --env recette --verbose
```

---

**🎯 Ces tests valident automatiquement votre checklist [`CHECKLIST_EMPLOYEE_API_CONFORMITY.md`](../CHECKLIST_EMPLOYEE_API_CONFORMITY.md)** 🚀