--  Générer SQL 
--  Version :                   	V7R4M0 190621 
--  Générée le :              	04/05/26 15:23:14 
--  Base données relation :    	CMSPW7T 
--  Option normes :          	Db2 for i 
  
CREATE TABLE CMSPSGFIC.CLIENTS ( 
--  SQL150B   10   REUSEDLT(*NO) de la table CLIENTS de CMSPSGFIC ignoré. 
	ETACLI CHAR(3) CCSID 1147 NOT NULL DEFAULT '' , 
	CODCLI NUMERIC(7, 0) NOT NULL DEFAULT 0 , 
	AGECLI CHAR(3) CCSID 1147 NOT NULL DEFAULT '' , 
	FRMCLI CHAR(5) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne FRMCLI. 
	NOMCLI CHAR(38) CCSID 1147 NOT NULL DEFAULT '' , 
	PRNCLI CHAR(15) CCSID 1147 NOT NULL DEFAULT '' , 
	NEPCLI CHAR(38) CCSID 1147 NOT NULL DEFAULT '' , 
	PHVCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne PHVCLI. 
	TL1CLI NUMERIC(10, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne TL1CLI. 
	TL2CLI NUMERIC(10, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne TL2CLI. 
	TE1CLI NUMERIC(15, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne TE1CLI. 
	TE2CLI NUMERIC(15, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne TE2CLI. 
	MAICLI CHAR(70) CCSID 1147 NOT NULL DEFAULT '' , 
	DCOCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne DCOCLI. 
	DTLCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne DTLCLI. 
	DMACLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne DMACLI. 
	DSMCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne DSMCLI. 
	DRGCLI DATE NOT NULL DEFAULT CURRENT_DATE , 
--  SQL150D   10   DATFMT ignoré pour la colonne DRGCLI. 
	URGCLI CHAR(10) CCSID 1147 NOT NULL DEFAULT '' , 
	DNACLI DATE NOT NULL DEFAULT CURRENT_DATE , 
--  SQL150D   10   DATFMT ignoré pour la colonne DNACLI. 
	PNACLI CHAR(3) CCSID 1147 NOT NULL DEFAULT '' , 
	VNACLI CHAR(20) CCSID 1147 NOT NULL DEFAULT '' , 
	DDCCLI DATE NOT NULL DEFAULT CURRENT_DATE , 
--  SQL150D   10   DATFMT ignoré pour la colonne DDCCLI. 
	LSNCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
	OPJCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
	DOJCLI DATE NOT NULL DEFAULT CURRENT_DATE , 
--  SQL150D   10   DATFMT ignoré pour la colonne DOJCLI. 
	NPACLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne NPACLI. 
	ORRCLI CHAR(3) CCSID 1147 NOT NULL DEFAULT '' , 
	TIDCLI CHAR(2) CCSID 1147 NOT NULL DEFAULT '' , 
	NIDCLI CHAR(20) CCSID 1147 NOT NULL DEFAULT '' , 
	SIDCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
	NATCLI CHAR(3) CCSID 1147 NOT NULL DEFAULT '' , 
	CMTCLI CHAR(600) CCSID 1147 NOT NULL DEFAULT '' , 
	PRFCLI CHAR(40) CCSID 1147 NOT NULL DEFAULT '' , 
	CPRCLI NUMERIC(3, 0) NOT NULL DEFAULT 0 , 
	TRRCLI NUMERIC(3, 0) NOT NULL DEFAULT 0 , 
	PCBCLI NUMERIC(3, 0) NOT NULL DEFAULT 0 , 
	R01CLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne R01CLI. 
	R02CLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne R02CLI. 
	R03CLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne R03CLI. 
	TAGCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne TAGCLI. 
	XCNCLI CHAR(1) CCSID 1147 NOT NULL DEFAULT '' , 
--  SQL150D   10   VALUES ignoré pour la colonne XCNCLI. 
	DCRCLI NUMERIC(8, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne DCRCLI. 
	DMOCLI NUMERIC(8, 0) NOT NULL DEFAULT 0 , 
--  SQL150D   10   EDTWRD ignoré pour la colonne DMOCLI. 
	UMOCLI CHAR(10) CCSID 1147 NOT NULL DEFAULT '' , 
	PRIMARY KEY( ETACLI , CODCLI ) )   
	  
	RCDFMT CLIENTSF   ; 
  
LABEL ON TABLE CMSPSGFIC.CLIENTS 
	IS 'Clients' ; 
  
LABEL ON COLUMN CMSPSGFIC.CLIENTS 
( ETACLI IS 'Code établissement' , 
	CODCLI IS 'Code Client' , 
	AGECLI IS 'Code agence' , 
	FRMCLI IS 'Civilité' , 
	NOMCLI IS 'Nom Client' , 
	PRNCLI IS 'Prénom' , 
	NEPCLI IS 'Nom épouse' , 
	PHVCLI IS 'Client PHV' , 
	TL1CLI IS 'Téléphone 1' , 
	TL2CLI IS 'Téléphone 2' , 
	TE1CLI IS 'Téléphone Etranger 1' , 
	TE2CLI IS 'Téléphone Etranger 2' , 
	MAICLI IS 'Adresse mail' , 
	DCOCLI IS 'Démarchage courrier' , 
	DTLCLI IS 'Démarchage téléphone' , 
	DMACLI IS 'Démarchage mail' , 
	DSMCLI IS 'Démarchage SMS' , 
	DRGCLI IS 'Date consentmnt RGPD' , 
	URGCLI IS 'USER consentmnt RGPD' , 
	DNACLI IS 'Date naissance' , 
	PNACLI IS 'Pays de naissance' , 
	VNACLI IS 'Ville de naissance' , 
	DDCCLI IS 'Date décès' , 
	LSNCLI IS 'Liste noire' , 
	OPJCLI IS 'Opposit judiciaire' , 
	DOJCLI IS 'Date oppo judiciaire' , 
	NPACLI IS 'X=NPAI' , 
	ORRCLI IS 'Origine relation' , 
	TIDCLI IS 'Type pièce identité' , 
	NIDCLI IS 'N° pièce identité' , 
	SIDCLI IS 'Identité non scannée' , 
	NATCLI IS 'Nationalité' , 
	CMTCLI IS 'Commentaire' , 
	PRFCLI IS 'Profession' , 
	CPRCLI IS 'Code profession' , 
	TRRCLI IS 'Tranche de revenus' , 
	PCBCLI IS 'Pourcentage bijoux' , 
	R01CLI IS 'Refus profession' , 
	R02CLI IS 'Refus revenus' , 
	R03CLI IS 'Refus bijoux' , 
	TAGCLI IS 'Position client' , 
	XCNCLI IS 'Intégré connecteur' , 
	DCRCLI IS 'Date de création' , 
	DMOCLI IS 'Date de modification' , 
	UMOCLI IS 'Utilisateur Modif' ) ; 
  
LABEL ON COLUMN CMSPSGFIC.CLIENTS 
( ETACLI TEXT IS 'Code établissement' , 
	CODCLI TEXT IS 'Code Client' , 
	AGECLI TEXT IS 'Code agence' , 
	FRMCLI TEXT IS 'Civilité' , 
	NOMCLI TEXT IS 'Nom Client' , 
	PRNCLI TEXT IS 'Prénom' , 
	NEPCLI TEXT IS 'Nom épouse' , 
	PHVCLI TEXT IS 'Client PHV' , 
	TL1CLI TEXT IS 'Téléphone 1' , 
	TL2CLI TEXT IS 'Téléphone 2' , 
	TE1CLI TEXT IS 'Téléphone Etranger 1' , 
	TE2CLI TEXT IS 'Téléphone Etranger 2' , 
	MAICLI TEXT IS 'Adresse mail' , 
	DCOCLI TEXT IS 'Démarchage courrier' , 
	DTLCLI TEXT IS 'Démarchage téléphone' , 
	DMACLI TEXT IS 'Démarchage mail' , 
	DSMCLI TEXT IS 'Démarchage SMS' , 
	DRGCLI TEXT IS 'Date consentmnt RGPD' , 
	URGCLI TEXT IS 'USER consentmnt RGPD' , 
	DNACLI TEXT IS 'Date naissance' , 
	PNACLI TEXT IS 'Pays de naissance' , 
	VNACLI TEXT IS 'Ville de naissance' , 
	DDCCLI TEXT IS 'Date décès' , 
	LSNCLI TEXT IS 'Liste noire' , 
	OPJCLI TEXT IS 'Opposit judiciaire' , 
	DOJCLI TEXT IS 'Date oppo judiciaire' , 
	NPACLI TEXT IS 'X=NPAI' , 
	ORRCLI TEXT IS 'Origine relation' , 
	TIDCLI TEXT IS 'Type pièce identité' , 
	NIDCLI TEXT IS 'N° pièce identité' , 
	SIDCLI TEXT IS 'Identité non scannée' , 
	NATCLI TEXT IS 'Nationalité' , 
	CMTCLI TEXT IS 'Commentaire' , 
	PRFCLI TEXT IS 'Profession' , 
	CPRCLI TEXT IS 'Code profession' , 
	TRRCLI TEXT IS 'Tranche de revenus' , 
	PCBCLI TEXT IS 'Pourcentage bijoux' , 
	R01CLI TEXT IS 'Refus profession' , 
	R02CLI TEXT IS 'Refus revenus' , 
	R03CLI TEXT IS 'Refus bijoux' , 
	TAGCLI TEXT IS 'Position client' , 
	XCNCLI TEXT IS 'Intégré connecteur' , 
	DCRCLI TEXT IS 'Date de création' , 
	DMOCLI TEXT IS 'Date de modification' , 
	UMOCLI TEXT IS 'Utilisateur Modif' ) ; 
  
GRANT ALTER , DELETE , INDEX , INSERT , REFERENCES , SELECT , UPDATE   
ON CMSPSGFIC.CLIENTS TO CMSOWN WITH GRANT OPTION ; 
  
-- Liste des clients.
select c.agecli as agence_id,c.etacli || digits(c.codcli) as id,trim(c.nomcli) || ' ' || trim(c.prncli) as nom_complet,
c.dnacli as date_naissance,a.viladc as ville, c.tl1cli as telephone1, c.tl2cli as telephone2,c.tidcli as typeIdentit,c.nidcli as numeroIdentit,
ctr.nbrCtr, ctr.totalPretCtr
 from cmspsgfic.clients c 
 left join cmspsgfic.clieadr a on a.etaadc = c.etacli and a.cliadc = c.codcli
left join (
select etacon,clicon,count(*) nbrCtr, sum(mntcon) totalPretCtr from cmspsgfic.contrat where poscon in ('ENG','ENS','PRO','PRV','MEV') group by etacon,clicon
) ctr on ctr.etacon = c.etacli and ctr.clicon = c.codcli
 where c.etacli = 'NAN' and c.agecli = 'NAN' and c.nomcli like 'B%' order by c.nomcli limit 2;  


 select count(*) from client_liste;

select codepaysnaissance,count(*) 
  from cmspsgfic.client_liste group by codepaysnaissance;
select count(*) from cmspsgfic.client_liste 
where codepaysnaissance = 'BD';
select numeroclient  from cmspsgfic.client_liste 
order by nom;

select *  
  from cmspsgfic.client_liste where codeetablissement= 'BDX' and numeroclient = 17382;

 select count(*) from client_liste where codeetablissement= 'BDX';  
-- curl "http://cmspw7t:10074/web/services/CLIENT?page=1&perPage=3" | python3 -m json.tool 
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret from cmspsgfic.client_liste limit 3 offset 0; 
select count(*) from 
(select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret from cmspsgfic.client_liste  );  
-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&page=1&perPage=4" | python3 -m json.tool
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret from cmspsgfic.client_liste where codeetablissement= 'BDX' limit 4 offset 0;  
-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&sort=nom&order=DESC&page=1&perPage=4" | python3 -m json.tool
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' order by nom desc limit 4 offset 0;  
   select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' order by nom desc limit 8 offset 0;
-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&q=650266815&sort=nom&order=DESC&page=1&perPage=4"
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' and 
  (codeetablissement like '%650266815%' 
  or numeroclient like '%650266815%'
  or nom like '%650266815%'
  or prenom like '%650266815%'
  or datenaissance like '%650266815%'
  or codepaysnaissance like '%650266815%'
  or villenaissance like '%650266815%'
  or villeresidence like '%650266815%'
  or telephone1 like '%650266815%'
  or telephone2 like '%650266815%')

  order by nom desc limit 4 offset 0;   

  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' and 
  (codeetablissement like '%650266815%' 
  or nom like '%650266815%'
 or prenom like '%650266815%'

  or codepaysnaissance like '%650266815%'
  or villenaissance like '%650266815%'
  or villeresidence like '%650266815%'
  or telephone1 like '%650266815%'
  or telephone2 like '%650266815%'  
)

  order by nom desc limit 4 offset 0;        
-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&nom_like=ART&sort=nom&order=DESC&page=1&perPage=4" | python3 -m json.tool
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' and 
  (nom like '%ART%'
)

  order by nom desc limit 4 offset 0;     
-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&nombreContrats_gte=4&sort=nom&order=DESC&page=1&perPage=4"   
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' and nombrecontrat >= 4

  order by nom desc limit 4 offset 0;

-- curl "http://cmspw7t:10074/web/services/CLIENT?codeEtablissement=BDX&nombreContrats_gte=4&q=641932&sort=nom&order=DESC&page=1&perPage=4" | python3 -m json.tool  
  select 
  codeetablissement, numeroclient,nom, prenom, datenaissance, codepaysnaissance, villenaissance
  , villeresidence, telephone1, nombrecontrat, totalpret 
  from cmspsgfic.client_liste 
  where codeetablissement= 'BDX' and 
  (codeetablissement like '%641932%' 
  or nom like '%641932%'
 or prenom like '%641932%'

  or codepaysnaissance like '%641932%'
  or villenaissance like '%641932%'
  or villeresidence like '%641932%'
  or telephone1 like '%641932%'
  or telephone2 like '%641932%'  
)
and nombrecontrat >= 4
  order by nom desc limit 4 offset 0;   


-- test de l('udtf client_table
SELECT count(*)                 
  FROM TABLE(LSTCLIENT()) AS C ; 
  
SELECT C.CODEETABLISSEMENT,count(*)                 
  FROM TABLE(clientbin.LSTCLIENT()) AS C  group by C.CODEETABLISSEMENT;   