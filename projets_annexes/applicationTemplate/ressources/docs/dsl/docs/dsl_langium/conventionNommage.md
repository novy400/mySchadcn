# 🏗️ Convention de Nommage CMagic - Solution _local

**Version** : MVP 1.0  
**Date** : Décembre 2024  
**Statut** : ✅ Approuvé pour implémentation

---

## 🎯 Vue d'Ensemble

Cette convention de nommage distingue clairement :
- **Procédures générées** (à ne pas modifier)
- **Procédures d'extension** (personnalisables)

**Exemples :**
- `customer_getId` → Générée par CMagic (protégée)
- `customer_getId_local` → Implémentation locale personnalisable

---

## 🧠 Philosophie

| Procédure              | Rôle                | Responsabilité                                  |
|------------------------|---------------------|-------------------------------------------------|
| `customer_getId`       | Version officielle  | Générée, validation, délégation                 |
| `customer_getId_local` | Adaptation locale   | Personnalisée par l'équipe de développement     |

- **Culture IBM i Native**  
  - Respecte l'esprit IBM i : "local" vs "système"
  - Concepts *LIBL (local) vs *SYSLIBL (système)
  - Convention naturelle, sans caractères spéciaux

---

## 💡 Avantages

| Aspect        | Avantage                           | Impact                                      |
|---------------|------------------------------------|---------------------------------------------|
| Clarté        | Intention immédiatement visible    | `_local` = customisé par l'équipe           |
| Philosophie   | Respecte les concepts natifs IBM i | *LIBL vs *SYSLIBL                           |
| Simplicité    | Pas de préfixes complexes          | Suffixe cohérent                            |
| Évolutivité   | Extensions futures naturelles      | `_local`, `_test`, `_debug`...              |
| Maintenance   | Séparation nette des responsabilités | Généré vs Local vs Public                 |

---

## 🔧 Pattern de Délégation

### Architecture en Couches

#### 🏛️ Architecture Globale

| Pattern             | Visibilité | Rôle                | Exemple                |
|---------------------|------------|---------------------|------------------------|
| `customer_*`        | EXPORT     | API Publique        | `customer_getId`       |
| `customer_*_local`  | Interne    | Implémentation      | `customer_getId_local` |
| `_customer_*`       | Réservé    | Extensions futures  | `_customer_validate`   |

---

## ⚙️ Configuration du Générateur

- **Règles de Génération**
- **Template de Génération**

---

## 🚀 Évolutivité

La convention `_local` prépare l'intégration avec Git-Based Extensibility v2.0 :

- **Merge intelligent** : Reconnaissance automatique des zones locales
- **Annotations avancées** : Délimiteurs évolutifs
- **Traçabilité Git** : Historique séparé généré vs local
- **Résolution de conflits** : Interface dédiée pour zones locales

---

## ✅ Bénéfices Mesurables

### Pour les Développeurs

- Compréhension immédiate
- Sécurité : protection du code généré
- Flexibilité : personnalisation locale
- Maintenance facilitée

### Pour l'Architecture

- Évolutivité des templates
- Cohérence du projet
- Performance et testabilité accrues

### Pour l'Équipe

- Adoption facile
- Collaboration renforcée
- Productivité accrue
- Qualité garantie

---

## 📋 Implémentation dans le MVP

**Sprint 2 - Services CRUD**

- Modifier les templates pour adopter `_local`
- Implémenter la délégation automatique
- Créer des zones protégées `[CMAGIC:MANUAL_START/END]`
- Tester la préservation du code local
- Documenter la convention

**Tests d'Acceptation**

- [ ] Génération initiale crée les procédures *_local vides
- [ ] Régénération préserve le contenu des procédures *_local
- [ ] Délégation fonctionne correctement (appel + retour)
- [ ] Validation dans les procédures générées effective
- [ ] Documentation générée mentionne la convention

---

## 🎯 Conclusion

La convention `_local` est optimale pour le MVP CMagic :

- 🏆 Naturelle pour IBM i
- 🏆 Simple et claire
- 🏆 Évolutive
- 🏆 Productive
- 🏆 Maintenable

Cette solution établit un standard durable, garantissant simplicité et efficacité pour toutes les évolutions futures de CMagic.