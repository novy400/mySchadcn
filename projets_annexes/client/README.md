# 🚀 Gestion des Clients.

## 📖 À Propos

### **Problématique**

- ❌ Interface 5250 peu ergonomique
- ❌ Pas d'accès mobile pour techniciens terrain
- ❌ Impossibilité d'intégrer outils modernes
- ❌ Difficulté recrutement développeurs RPG

### **Solution**

- ✅ APIs REST sur données IBM i existantes
- ✅ Dashboard React-Admin pour dispatcher
- ✅ App mobile pour techniciens
- ✅ Zéro migration de données

### **Architecture**

```
Mobile + React-Admin → APIs REST (ILEastic) → IBM i (RPG + DB2)
```

## 🛠️ Installation & Setup

### **Prérequis**

- IBM i 7.3+ avec BOB (Build automation)
- ILEastic framework installé
- Git configuré
- Accès SQL (création tables)

### Structure du projet

Le projet est organisé de la manière suivante :
par composants et par type de code (source, test, lib).

```
.
├── Makefile
├── README.md
├── src
│   ├── employee
│   │   ├── analyse.sql
│   │   ├── employee.bnd
│   │   ├── employee.jdl
│   │   ├── employee.sqlrpgle
│   │   ├── invemp.dspf
│   │   ├── invemp.pgm.sqlrpgle
│   │   ├── Rules.mk
│   │   ├── tstwrkemp.sqlrpgle
│   │   ├── wrkemp.dspf
│   │   └── wrkemp.pgm.sqlrpgle
│   └── inventory
│       ├── analyse.sql
```

potentiellement les tests unitaires et les règles de gestion sont dans le même répertoire que le code source.
j'attends de bien faire marcher la nouvel extension pour ce faire.pour l'instant les lancements de tests unitaires et de règles de gestion sont dans le répertoire `tests` avec un makefile particulier.
Toues les fichiers d'includes sont dans le répertoire `includes` et les fichiers de configuration dans le répertoire `configs`.

### Exemple de structure du dossier `includes`

Le dossier `includes` contient les fichiers d'inclusion nécessaires pour les programmes RPG. Par exemple :

```
includes

├── cmagic.rpgleinc
└── employee.rpgleinc
```

Chaque fichier `.rpgleinc` contient des définitions ou prototypes réutilisables dans plusieurs modules RPG.
les autres fichiers d'includes sont dans le répertoire `/usr/local/include` sur le système de build.
mais la priorité est donné pour la compilation aux includes présents dans le répertoire `includes` du projet.

```
/usr/local/include
├── ckool.rpgleinc
├── ...
└── global.rpgleinc
```

la référence aux includes sont directement intégrés à la compilation via le fichier de configuration `iproj.json` dans la section `includePath` :

```json
{
  "includePath": [
    "includes",
    "/usr/local/include"
  ]
}
```

## utilisation sur l'iBmi.

- mise en place env

```shell
addlible HABILITATI
addlible DB2SAMPLE
addlible RPGUNIT *last
```

- lancement des tests unitaires

```shell
RUCALLTST TSTPGM(CKOOLTST/EMPLOYEE)
```

- lancement de la gestion des employes.

```shell
call wrkemp
```

![picture 0](images/96f2ae13c2ac7eb6d5754c6a51259a3ebe29ed73b337f824745f4fbdbcd4684f.png)

- lancement des srvices web

ttt![1771499022242](image/README/1771499022242.png)

```shell
call srvweb
```

ADDLIBLE ILEASTIC
SBMJOB CMD(CALL PGM(GESTEMP))
 JOB(GESTEMP) JOBQ(QSYSNOMAX) ALWMLTTHD(*YES)

```

```

 curl -v 'http://localhost:44000/api/employees/000050'
 curl -v 'http://localhost:44000/api/employees?page=1&perPage=5&sort=firstnme&order=ASC'
 curl -v 'http://localhost:44000/api/employees?page=1&perPage=5&sort=workdept,firstnme&order=ASC'

```



```

gg

![1768210798542](image/README/1768210798542.png)
