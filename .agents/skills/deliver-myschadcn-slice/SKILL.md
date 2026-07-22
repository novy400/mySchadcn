---
name: deliver-myschadcn-slice
description: Deliver the next planned mySchadcn implementation slice end to end. Use when the user asks to continue the plan, implement the next tranche, or finish a CRM change with tracking, tests, documentation, review, and Git history.
---

# Livrer une tranche mySchadcn

## 1. Cadrer la tranche

Lire `AGENTS.md`, puis le plan ou la specification citee par l'utilisateur. A defaut, consulter
`ressources/doc/PLAN_IMPLEMENTATION.md`. Lire `CONTEXT.md` si le changement touche au vocabulaire
ou aux regles metier.

Inspecter la branche, le statut Git et les changements existants. Identifier le point fixe de
revue, les criteres d'acceptation et la plus petite verticale livrable. Si le plan est termine, ne
pas inventer une tranche : demander un nouveau cadrage.

Cette etape est terminee lorsque le perimetre, les criteres et le point fixe sont explicites.

## 2. Suivre le travail

Enregistrer les etapes dans le mecanisme de suivi deja utilise par la tache. Garder exactement une
etape en cours et mettre a jour son etat pendant l'implementation.

Cette etape est terminee lorsque la tranche est visible et suivie jusqu'a sa cloture.

## 3. Implementer une verticale

Respecter les seams et les regles de `AGENTS.md`. Pour tout comportement non trivial, commencer par
un test qui echoue au seam convenu, puis passer au vert et refactorer. Executer regulierement le test
cible et la verification TypeScript pertinente.

Mettre a jour la documentation qui porte l'architecture, le contrat, le vocabulaire ou le workflow
modifie. Conserver chaque information dans une seule source de verite.

Cette etape est terminee lorsque les criteres d'acceptation sont couverts par le code, les tests et
la documentation necessaire.

## 4. Valider et revoir

Executer les tests cibles, puis `npm run check`. Corriger toutes les regressions avant de poursuivre.

Effectuer ensuite une revue depuis le point fixe selon les deux axes Standards et Spec, en utilisant
la skill `code-review` lorsqu'elle est disponible. Corriger les constats actionnables, relancer les
validations affectees, puis executer de nouveau `npm run check`.

Cette etape est terminee lorsque les trois commandes de reference sont vertes et qu'aucun constat
actionnable ne subsiste.

## 5. Clore la tranche

Mettre a jour le plan avec le resultat reel et les validations observees. Lorsque le suivi Git fait
partie du travail autorise, creer ou amender un commit cible sur la branche courante. Verifier le
statut Git final et signaler explicitement tout changement restant.

Cette etape est terminee lorsque le plan, la documentation, les validations et l'historique Git
racontent la meme livraison.
