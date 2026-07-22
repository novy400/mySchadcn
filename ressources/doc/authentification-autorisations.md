# Authentification et autorisations

_État : politique du prototype implémentée ; sécurité de production à fournir par le backend IBM i._

## Objectif

Le frontend impose une connexion avant d'afficher le CRM et adapte les routes, menus et
actions au rôle de l'Utilisateur. Cette protection améliore le prototype et valide
l'expérience attendue, mais elle ne remplace jamais une autorisation côté serveur.

## Rôles

| Rôle | Consultation | Gestion CRM | Gestion des commandes |
| --- | --- | --- | --- |
| Lecteur | oui | non | non |
| Agent | oui | clients, contacts, tâches, notes et fournisseurs | non |
| Responsable | oui | mêmes droits que l'Agent | modification, livraison, annulation et retour |

La politique refuse par défaut toute ressource ou action inconnue. Les capacités du
registre `resourceContracts.ts` restent prioritaires : aucun rôle ne peut écrire une
projection ni utiliser une opération CRUD absente du contrat.

`tasks_with_client` est un cas de routage d'écran : la projection reste en lecture seule,
mais ses écrans de création et d'édition écrivent explicitement dans `tasks`.

## Fonctionnement du prototype

L'interface `IdentityAdapter` isole la vérification de l'identité. Elle expose
`authenticate` et, pour un serveur de session, les opérations optionnelles `getIdentity`
et `logout`. L'adapter actuel est une démonstration locale proposant trois comptes publics,
tous avec le mot de passe `demo` :

- `lecteur@demo.local` ;
- `agent@demo.local` ;
- `responsable@demo.local`.

Après connexion, seul l'objet `{ id, fullName, role }` est conservé dans `sessionStorage`.
Aucun mot de passe, jeton, identifiant de session ou secret n'y est stocké. La session est
limitée à l'onglet et supprimée à la déconnexion ou après une erreur HTTP `401`.

Une erreur `403` conserve la session : elle exprime un refus d'autorisation, pas une perte
d'identité.

## Limite de sécurité

Le rôle présent dans le navigateur est modifiable par l'utilisateur. Il sert uniquement à
valider l'interface du prototype. Tant que FakeRest est utilisé, les droits ne constituent
pas une barrière de sécurité réelle.

En production, le backend doit refuser par défaut et vérifier l'identité, le rôle, la
ressource, l'enregistrement et l'action à chaque requête. Le masquage d'un bouton ne suffit
jamais à autoriser ou interdire une opération.

## Contrat cible IBM i

L'adapter REST remplacera uniquement `demoIdentityAdapter` et exposera au minimum :

```http
POST /api/auth/login
GET  /api/auth/me
POST /api/auth/logout
```

Comportement recommandé :

- la connexion établit une session serveur et renvoie l'identité publique ;
- l'identifiant de session utilise un cookie `Secure`, `HttpOnly` et `SameSite` ;
- `/auth/me` renvoie `{ "id", "fullName", "role" }` sans donnée sensible ;
- la déconnexion invalide la session côté serveur ;
- toutes les réponses contenant des données privées utilisent des directives de cache
  adaptées ;
- si l'authentification repose sur un cookie, les mutations disposent aussi d'une défense
  CSRF compatible avec l'architecture retenue ;
- un changement de rôle invalide ou renouvelle la session ;
- le backend journalise les refus et conserve l'identifiant de corrélation défini dans le
  contrat du DataProvider.

Le frontend traite `401` comme une session expirée et `403` comme un accès refusé. Ces
statuts doivent être cohérents sur les endpoints CRUD, les projections et les actions
métier.

L'adapter REST implémentera `authenticate`, `getIdentity` et `logout`. Le reste de
l'AuthProvider, de la politique de rôles et des écrans reste inchangé.

## Sources de sécurité

- [OWASP — Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP — Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP — HTML5 Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html)
- [OWASP — Cross-Site Request Forgery Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
