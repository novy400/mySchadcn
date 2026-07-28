-- insertion de données de test.
select etacon,oppcon,count(*) from cmspsgfic.contrat where oppcon <> '' 
group by etacon,oppcon order by etacon,oppcon;
select poscon,count(*) from cmspsgfic.contrat 
group by poscon order by poscon;
 select etacon,numcon from cmspsgfic.contrat where oppcon >= 'DCD' and etacon ='NAN';
insert into giyvovie.contfigdat (codeetablissement,numerocontrat,datefigementcontrat,motiffigement)
select etacon,numcon,dopcon,oppcon from cmspsgfic.contrat where oppcon >= 'DCD' and etacon ='NAN'; 
select * from giyvovie.contfigdat;
-- Requete liste de Contfigdat.
select fig.id,fig.codeetablissement,fig.numerocontrat,fig.datefigementcontrat 
from giyvovie.contfigdat fig;
select ctr.etacon,ctr.agecon,ctr.clicon,ctr.numcon,ctr.poscon,ctr.mntcon,
  ctr.oppcon
 from cmspsgfic.contrat ctr; 
select cli.etacli,cli.codcli,cli.nomcli from cmspsgfic.clients cli;
select age.codeta,age.codage,age.nomage from cmspsgfic.agences age; 
select fig.id,fig.codeetablissement,fig.numerocontrat,fig.datefigementcontrat,
ctr.etacon,ctr.agecon,ctr.clicon,ctr.numcon,ctr.poscon,ctr.mntcon,
  ctr.oppcon,
cli.etacli,cli.codcli,cli.nomcli,
age.codeta,age.codage,age.nomage 
from giyvovie.contfigdat fig 
left join
 cmspsgfic.contrat ctr
 on fig.codeetablissement = ctr.etacon and fig.numerocontrat = ctr.numcon
left join
 cmspsgfic.clients cli
on cli.etacli = fig.codeetablissement and cli.codcli = ctr.clicon
left join 
  cmspsgfic.agences age
on age.codeta = fig.codeetablissement and age.codage = ctr.agecon  
 ;
-- req finale pour la liste des contrats figés.
select fig.id,fig.codeetablissement,ctr.agecon,
  ctr.clicon,cli.nomcli,
  ctr.numcon,ctr.poscon,ctr.mntcon,ctr.daecon,
  ctr.oppcon,
  fig.datefigementcontrat
from giyvovie.contfigdat fig 
left join
 cmspsgfic.contrat ctr
 on fig.codeetablissement = ctr.etacon and fig.numerocontrat = ctr.numcon
left join
 cmspsgfic.clients cli
on cli.etacli = fig.codeetablissement and cli.codcli = ctr.clicon
left join 
  cmspsgfic.agences age
on age.codeta = fig.codeetablissement and age.codage = ctr.agecon  
 ; 
SELECT pos.codcop,pos.libcop FROM CMSPSGFIC.OPERCOD as pos;
-- req finale pour le détails des contrats figés.
select fig.id,
  fig.codeetablissement,ets.nometa,
  ctr.agecon,age.nomage,
  ctr.clicon,cli.nomcli,
  ctr.numcon,ctr.poscon, ctr.daecon,ctr.mntcon,
  ctr.oppcon,opp.libopm,
  fig.datefigementcontrat,
  fig.motiffigement
from giyvovie.contfigdat fig 
left join
 cmspsgfic.contrat ctr
 on fig.codeetablissement = ctr.etacon and fig.numerocontrat = ctr.numcon
left join
 cmspsgfic.clients cli
on cli.etacli = fig.codeetablissement and cli.codcli = ctr.clicon
left join 
  cmspsgfic.etablis ets
on ets.codeta = fig.codeetablissement 
left join 
  cmspsgfic.agences age
on age.codeta = fig.codeetablissement and age.codage = ctr.agecon  
left join 
  cmspsgfic.opmotif opp
on opp.codopm = ctr.oppcon  
;  

select * from giyvovie.contrat_date_figement_calcul;
select * from giyvovie.contfigdat f where f.numerocontrat= 6; 
             select id,
                  codeetablissement,nomEtablissement,
                  codeAgence,nomAgence,
                  numeroClient,nomClient,
                  numeroContrat,positionContrat,
                  dateEcheanceContrat,montantContrat,
                  codeOpposition,libelleOpposition,
                  datefigementcontrat,
                  motiffigement

                from contfigdav
                WHERE id = 6;

select nomage from cmspsgfic.agences where codeta='TOU' and codage ='AJA';  

select ctr.etacon, ets.nometa,
ctr.clicon, cli.nomcli,
ctr.numcon,ctr.poscon, ctr.daecon,ctr.mntcon,
ctr.oppcon,opp.libopm,ctr.dopcon
from cmspsgfic.contrat ctr 
left join cmspsgfic.etablis ets
on ets.codeta = ctr.etacon
left join cmspsgfic.clients cli
on cli.etacli = ctr.etacon and cli.codcli = ctr.clicon
left join cmspsgfic.opmotif opp
on opp.codopm = ctr.oppcon
where ctr.etacon='TOU' and ctr.numcon= 180033890;   

        select ctr.etacon, ets.nometa,
        ctr.clicon, cli.nomcli,
        ctr.numcon,ctr.poscon, ctr.daecon,ctr.mntcon,
        ctr.oppcon,opp.libopm,ctr.dopcon 
        from cmspsgfic.contrat ctr 
        left join cmspsgfic.etablis ets
        on ets.codeta = ctr.etacon
        left join cmspsgfic.clients cli
        on cli.etacli = ctr.etacon and cli.codcli = ctr.clicon
        left join cmspsgfic.opmotif opp
        on opp.codopm = ctr.oppcon
        where ctr.etacon= 'TOU' 
        and ctr.numcon= 180088438; 


select                                                            
    id,codeetablissement,codeAgence,numeroClient,nomClient,numeroContrat,
    positionContrat,montantContrat,dateEcheanceContrat,codeOpposition,
    datefigementcontrat,motiffigement  
    from giyvovie.contfigdav WHERE  id = 165 AND           
    upper(codeetablissement) = 'TOU' AND upper(codeAgence) = 'TOU';     

select datefigementcontrat 
from giyvovie.contrat_date_figement_calcul 
where codeetablissement='TOU' 
and numeroContrat=180088438;        

