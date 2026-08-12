# Documentation CMagic

Ce dossier relie le prototype `mySchadcn` à la démarche de modernisation IBM i / Flight400.

## Référence à utiliser

- [Concepts CMagic](./concepts-cmagic.md) : vocabulaire et responsabilités normatives.
- [Architecture CMagic](./ARCHITECTURE_CMAGIC.md) : cadrage court en cours d'élaboration.
- [Synthèse](./synthese.md) : proposition de trajectoire à consolider.
- [Catalogue v0](./catalogue-v0.md) : contrat DSL et artefacts générés.
- [Recette IBM i du catalogue](./recette-ibmi-catalogue.md) : build BOB, lancement
  ILEastic, tests HTTP et collecte des preuves.
- [Recette IBM i du catalogue avec IWS](./recette-ibmi-catalogue-iws.md) : build du
  wrapper IWS, déploiement dans IBM Web Administration, mapping PCML et tests HTTP.
- [Relevé HTTP IWS du 5 août 2026](./validation-iws-2026-08-05.md),
  [export curl du 6 août](./testCurl.html), [Swagger IWS 2.6](./swagger.json) et
  [PCML SERVIWS3](./SERVIWS3.pcml) : preuves des contrats `LIST` et `GET` déployés sur
  IBM i. La [capture HTTP](./image/recette-ibmi-catalogue-iws/http-get-200-404-success.png)
  montre `/A00 → 200`, `/ZZZ → 404` et le corps `CAT0001/id` de `/XXX`. La validation
  est acceptée avec cette distinction explicite entre les deux appels absents.

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
| DSL `.cmagic` | dépôt autonome [`cmagic_perso`](https://github.com/novy400/cmagic) | validation et industrialisation IBM i |

Une proposition décrite dans ce dossier n'est donc pas automatiquement une fonctionnalité
du prototype.
