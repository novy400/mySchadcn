select *
from cmspsgfic.clients c where c.etacli = 'NAN' and c.codcli = 0803671;
select *
from cmspsgfic.clients c where c.te2cli <> 0;
-- adresses
select *
from cmspsgfic.clieadr a where a.etaadc = 'NAN' and a.cliadc = 0803671;
-- courries 
SELECT * FROM cmspw7p.CMSPSGFIC.CLIECCE as a where a.etacce = 'NAN' and a.clicce = 0803671;
-- commentaires
SELECT * FROM cmspw7p.CMSPSGFIC.CLIECMT as a where a.etacmc = 'NAN' and a.clicmc = 0803671;
-- opposition 
SELECT * FROM cmspw7p.CMSPSGFIC.CLIEOPP as a where a.etaopp = 'NAN' and a.cliopp = 0803671;
SELECT max(a.dopopp) FROM cmspw7p.CMSPSGFIC.CLIEOPP as a where a.etaopp = 'NAN';

-- 
select c.etacli,c.agecli,c.codcli,trim(c.nomcli) || ' ' || trim(c.prncli) as nom_complet,c.dcrcli,C.dmocli,c.umocli 
from cmspsgfic.clients c 
where c.etacli = 'NAN' and c.codcli = 0803671; 
-- Req pour la liste des clients et leurs informations de base
select c.agecli as agence_id,c.etacli || digits(c.codcli) as id,trim(c.nomcli) || ' ' || trim(c.prncli) as nom_complet,
c.dnacli as date_naissance,a.viladc as ville, c.tl1cli as telephone1, c.tl2cli as telephone2,c.tidcli as typeIdentit,c.nidcli as numeroIdentit
from cmspsgfic.clients c 
 left join cmspsgfic.clieadr a on a.etaadc = c.etacli and a.cliadc = c.codcli
 where c.etacli = 'NAN' and c.codcli = 0803671; 
-- Req pour la liste des clients et leurs informations de base et via un contrat (==> vue client_contrat)
select c.agecli as agence_id,c.etacli || digits(c.codcli) as id,trim(c.nomcli) || ' ' || trim(c.prncli) as nom_complet,
c.dnacli as date_naissance,a.viladc as ville, c.tl1cli as telephone1, c.tl2cli as telephone2,c.tidcli as typeIdentit,c.nidcli as numeroIdentit
 from cmspsgfic.clients c 
 left join cmspsgfic.clieadr a on a.etaadc = c.etacli and a.cliadc = c.codcli
 left join cmspsgfic.contrat ctr on ctr.etacon = c.etacli and ctr.clicon = c.codcli
 where c.etacli = 'NAN' and ctr.numcon = 625003893;  
-- Requête SQL pour récupérer les informations clients p
-- signaletique client
select c.etacli,c.agecli,c.codcli,c.tagcli,c.dcrcli,C.dmocli,c.umocli from cmspsgfic.clients c; 
-- addresse, email, tel, etc
-- administratif  
-- risques,alertes,oppositions ,seuil....
-- production :contrat,operations et mouvenemts ,
-- financier : factures, paiements, etc
-- historique : historique des operations, contrats, etc
-- relation clients contact,actions, 
-- documents : contrats, factures, etc


--------------------------------------------------------------------------------------------------------------------------------------------------
-- Guichet
-------------------------------------------------------------------------------------------------------------------------------------------------
select * from cmspsgfic.guichet where utigui ='GIYVOVIE';
select * from cmspsgfic.caisage where etacau ='NAN' and AGECAU = 'NAN';
select * from cmspsgfic.caisson where etacas ='NAN' and AGECAs = 'NAN';
select * from cmspsgfic.guicnap;
select * from cmspsgfic.CAISSLD where etacsl ='NAN' and AGECsl = 'NAN' order by datcsl desc;


--------------------------------------------------------------------------------------------------------------------------------------------------
-- Liste des clients.
-------------------------------------------------------------------------------------------------------------------------------------------------
select c.agecli as agence_id,c.etacli || digits(c.codcli) as id,trim(c.nomcli) || ' ' || trim(c.prncli) as nom_complet,
c.dnacli as date_naissance,a.viladc as ville, c.tl1cli as telephone1, c.tl2cli as telephone2,c.tidcli as typeIdentit,c.nidcli as numeroIdentit,
ctr.nbrCtr, ctr.totalPretCtr
 from cmspsgfic.clients c 
 left join cmspsgfic.clieadr a on a.etaadc = c.etacli and a.cliadc = c.codcli
left join (
select etacon,clicon,count(*) nbrCtr, sum(mntcon) totalPretCtr from cmspsgfic.contrat where poscon in ('ENG','ENS','PRO','PRV','MEV') group by etacon,clicon
) ctr on ctr.etacon = c.etacli and ctr.clicon = c.codcli
 where c.etacli = 'NAN' and c.agecli = 'NAN' and c.nomcli like 'B%' order by c.nomcli;  
-- somme et nombres contrats 
select count(*), sum(mntcon) from cmspsgfic.contrat where etacon = 'NAN' and clicon = 0023988 and poscon in ('ENG','ENS','PRO','PRV','MEV'); 
select etacon,clicon,count(*), sum(mntcon) from cmspsgfic.contrat where poscon in ('ENG','ENS','PRO','PRV','MEV') group by etacon,clicon; 
-- nombre d'objet d'un contrat
select etacob,poscon,concob,
CASE
 WHEN GROUPING(concob) = 0  then sum(mntcon)/count(*)
 WHEN  GROUPING(concob) = 1  then 0
END ca,
sum(mntcon)/count(*) ,count(*) nbObjet,GROUPING(concob)  from (
select cob.*,ctr.poscon,ctr.mntcon from cmspsgfic.contobj cob  
left join cmspsgfic.contrat ctr on ctr.etacon = cob.etacob and ctr.numcon = cob.concob
where ctr.etacon = 'NAN' and ctr.clicon = 0023988)
 GROUP BY ROLLUP (etacob,poscon,concob);
-- liste des contrats
select etacon,clicon,numcon,poscon,mescon,mntcon,nbrcon,daecon from cmspsgfic.contrat where etacon = 'NAN' and clicon = 0023988;
-- liste des justificatifs de revenus 
SELECT a.*,j.libjrv FROM CMSPSGFIC.CLIEJRV as a
left join CMSPSGFIC.PARAjrv as j on a.jrvjrv =j.codjrv; 
SELECT * FROM CMSPSGFIC.PARAJCA as a;

select * from 
cmspsgfic.clieadr;

select count(*) from (
select *
 from cmspsgfic.clients c 
);

select count(*) from (
select etacon,clicon
 from cmspsgfic.contrat 
 where poscon in ('ENG','ENS','PRO','PRV','MEV') 
 group by etacon,clicon
)
 ;


      select count(*) 
            from (
            select *
            from cmspsgfic.clients c 
            left join cmspsgfic.clieadr a 
            on a.etaadc = c.etacli and a.cliadc = c.codcli and a.natadc ='R'
            left  join (
            select etacon,clicon,count(*) nbrCtr, sum(mntcon) totalPretCtr 
            from cmspsgfic.contrat where poscon in ('ENG','ENS','PRO','PRV','MEV') 
            group by etacon,clicon
            ) ctr on ctr.etacon = c.etacli and ctr.clicon = c.codcli
            ) 
            where upper(nomcli) like '%AMI%'
      ; 



     select codcli 
      from (
      select *
      from cmspsgfic.clients c 
      left join cmspsgfic.clieadr a 
      on a.etaadc = c.etacli and a.cliadc = c.codcli and a.natadc ='R'
      left  join (
      select etacon,clicon,count(*) nbrCtr, sum(mntcon) totalPretCtr 
      from cmspsgfic.contrat where poscon in ('ENG','ENS','PRO','PRV','MEV') 
      group by etacon,clicon
      ) ctr on ctr.etacon = c.etacli and ctr.clicon = c.codcli
      ) order by nomcli limit 1;        