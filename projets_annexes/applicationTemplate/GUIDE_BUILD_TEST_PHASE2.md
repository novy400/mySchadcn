# Guide Rapide - Build et Test Phase 2

*Procédures pour valider l'implémentation des Filtres Avancés*

## 🚀 **ÉTAPES DE VALIDATION**

### **1. Build sur IBM i** ⚠️ **CRITIQUE**

```bash
# Se connecter à IBM i
ssh user@your-ibmi

# Aller dans le répertoire du projet
cd /path/to/applicationTemplate

# Pull des dernières modifications
git pull origin employee_rest

# Build avec BOB
bob --build src/employee

# Vérifier le résultat
echo $?  # Doit retourner 0 si succès
```

### **2. Démarrage du Service** 

```bash
# Démarrer ILEastic si pas déjà fait
# (commande dépend de votre configuration)

# Vérifier que le service répond
curl "http://your-ibmi:44000/api/employees" || echo "Service non accessible"
```

### **3. Tests Rapides de Validation**

```bash
# Test 1: Collection de base
curl -I "http://your-ibmi:44000/api/employees"
# Vérifier: Header X-Total-Count présent

# Test 2: Filtre EQUAL
curl "http://your-ibmi:44000/api/employees?nom=HAAS"
# Vérifier: Tableau JSON retourné

# Test 3: Filtre LIKE  
curl "http://your-ibmi:44000/api/employees?nom_like=HAA"
# Vérifier: Employés avec nom contenant HAA

# Test 4: Filtre numérique
curl "http://your-ibmi:44000/api/employees?salaire_gte=50000"
# Vérifier: Employés avec salaire >= 50000

# Test 5: Recherche générale
curl "http://your-ibmi:44000/api/employees?q=HAAS"  
# Vérifier: Recherche dans nom, prénom, service

# Test 6: Filtres combinés
curl "http://your-ibmi:44000/api/employees?nom_like=A&salaire_gte=50000"
# Vérifier: Combinaison ET des filtres
```

### **4. Vérification des Logs**

```bash
# Sur IBM i, vérifier les logs CKOOL
# (commande dépend de votre configuration CKOOL)

# Chercher dans les logs :
# "=== DÉBUT setupFilters ==="
# "Filtre LIKE détecté: nom LIKE valeur"
# "=== FIN setupFilters - X filtres détectés ==="
```

## 🔧 **DÉPANNAGE RAPIDE**

### **Erreur de Compilation**

```bash
# Vérifier les includes
ls -la includes/cmagic.rpgleinc
cat includes/cmagic.rpgleinc | grep "CMAGIC_OP_"

# Vérifier les sources
ls -la src/employee/
```

### **Service ne Répond Pas**

```bash
# Vérifier le port et l'adresse
netstat -an | grep 44000

# Tester avec localhost si sur la même machine
curl "http://localhost:44000/api/employees"
```

### **Réponse Vide ou Erreur**

```bash
# Tester avec verbose pour voir les détails
curl -v "http://your-ibmi:44000/api/employees"

# Vérifier les logs d'erreurs du serveur
# (emplacement dépend de votre configuration)
```

## ✅ **CRITÈRES DE SUCCÈS RAPIDE**

### **Build OK**
- [ ] `bob --build src/employee` retourne 0
- [ ] Aucun message d'erreur de compilation
- [ ] Fichiers .so/.srvpgm générés

### **Service OK**  
- [ ] `curl http://your-ibmi:44000/api/employees` retourne JSON
- [ ] Header `X-Total-Count` présent
- [ ] Réponse est un tableau `[...]`

### **Filtres OK**
- [ ] `nom=HAAS` filtre correctement
- [ ] `nom_like=HAA` fonctionne  
- [ ] `salaire_gte=50000` fonctionne
- [ ] `q=HAAS` fonctionne

## 📋 **TESTS COMPLETS**

Pour une validation complète, utiliser :

```powershell
# Sur machine Windows avec PowerShell
.\test_phase2_filtres_avances.ps1 -ServerUrl "http://your-ibmi:44000"
```

Ou suivre la checklist détaillée :
```bash
# Voir le fichier complet
cat CHECKLIST_PHASE2_FILTRES_AVANCES.md
```

## 🎯 **RÉSULTAT ATTENDU**

Si tout fonctionne :
- ✅ **7 opérateurs** de filtrage fonctionnels
- ✅ **Recherche générale 'q'** multi-champs  
- ✅ **Filtres combinés** avec AND
- ✅ **Headers HTTP** conformes (X-Total-Count)
- ✅ **Format JSON** correct (tableau pour collection)

➡️ **Prêt pour Phase 3 : Optimisation**

---

**🚨 IMPORTANT :** Ne pas passer à Phase 3 tant que Phase 2 n'est pas 100% fonctionnelle