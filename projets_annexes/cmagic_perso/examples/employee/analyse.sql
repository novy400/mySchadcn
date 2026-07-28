select * from db2sample.employee;
-- liste des employéés
select count(*) from db2sample.employee;
select ROW_NUMBER() over (),empno, lastname,workdept from db2sample.employee;
select ROW_NUMBER() over (),empno, lastname,workdept from db2sample.employee 
where workdept = 'A00';
select ROW_NUMBER() over (),empno, lastname,workdept from db2sample.employee 
where workdept = 'A00' order by lastname;

select ROW_NUMBER() over (),empno, lastname,workdept from db2sample.employee 
order by lastname;
select empno from(
select empno, lastname,workdept from db2sample.employee 
order by lastname ) limit 1 offset 3;

select ROW_NUMBER() over (),empno, lastname,workdept from db2sample.employee 
where workdept = 'A00' order by lastname;

VALUES REGEXP_SUBSTR(msg , '(\w+\.)+((org)|(com)|(gouv)|(fr))'); 
values REGEXP_INSTR('AA','^%[A-Z]*$');
values REGEXP_INSTR('%AA','^%[A-Z]*$');
values REGEXP_INSTR(upper(trim('  %a')),'^%[A-Z]*$');
  values upper(trim(' %a'));
values REGEXP_INSTR(upper(trim('  %a')),'^%[A-Z]*$|^[A-Z]*%$|^%[A-Z]*%$');
values REGEXP_INSTR(upper(trim('  A a')),'^%[A-Z]*$|^[A-Z]*%$|^%[A-Z]*%$');
values REGEXP_INSTR(upper(trim('  %a%')),'^%[A-Z]*$|^[A-Z]*%$|^%[A-Z]*%$');

values REGEXP_INSTR(upper(trim('  a%   ')),'^%[A-Z]*$|^[A-Z]*%$|^%[A-Z]*%$');
select empno,edlevel from db2sample.employee;
select empno,edlevel from db2sample.employee where edlevel > '18';

select count(*) from db2sample.employee where workdept like '%E1%';

values REGEXP_INSTR(upper(trim('E1%')),'^%|\\%$');

select empno,  lastname, workdept  from  db2sample.employee Where lastname = 
  '%SET%'; 
  select empno,  lastname, workdept  from  db2sample.employee order by lastname; 
values ( CASE 
        WHEN REGEXP_INSTR('SET%', '^%') > 0 THEN 1  -- Début par %
        WHEN REGEXP_INSTR('SET%', '%$') > 0 THEN 2  -- Fin par %
        ELSE 0 
    END ) ;

 select sex from db2sample.employee group by sex;

     SELECT empno, firstnme, lastname, midinit, workdept, 
                hiredate, birthdate, sex, salary
         FROM db2sample.employee
         WHERE empno = '000010';
select max(empno) + 10 from db2sample.employee;         
