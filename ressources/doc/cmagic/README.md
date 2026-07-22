# Documentation CMagic

Ce dossier relie le prototype `mySchadcn` à la démarche de modernisation IBM i / Flight400.

## Référence à utiliser

- [Concepts CMagic](./concepts-cmagic.md) : vocabulaire et responsabilités normatives.
- [Architecture CMagic](./ARCHITECTURE_CMAGIC.md) : cadrage court en cours d'élaboration.
- [Synthèse](./synthese.md) : proposition de trajectoire à consolider.

## Matériaux de travail

- `patterns++.md` est une collecte exploratoire contenant répétitions, extraits de
  conversation et pseudo-code. Ce n'est pas une spécification d'implémentation.
- `ordres_status.md` décrit le prototype `orders` et recense les règles métier restant à
  décider avant d'en faire un véritable processus.
- les images `Gemini_Generated_*` sont des illustrations conceptuelles générées. Leur
  texte et leur interface ne doivent pas être considérés comme une référence fonctionnelle
  ou graphique.

## État présent et cible

| Sujet | Présent dans mySchadcn | Cible envisagée |
| --- | --- | --- |
| Données | `baseData.ts` et projections TypeScript | Db2 for i et API |
| Provider | FakeRest local | DataProvider REST IBM i |
| Catalogue | ressources CRM CRUD | ressources issues du domaine Flight400 |
| Processus | statut éditable sur certaines ressources | transitions contrôlées par actions métier |
| Saga | non implémentée | orchestration et compensations côté backend |
| DSL `.cmagic` | non implémenté dans ce dépôt | éventuelle source de génération |

Une proposition décrite dans ce dossier n'est donc pas automatiquement une fonctionnalité
du prototype.
