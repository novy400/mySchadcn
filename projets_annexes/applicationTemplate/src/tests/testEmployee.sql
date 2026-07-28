SELECT * FROM DB2SAMPLE.EMPLOYEE as a;
SELECT * FROM DB2SAMPLE.EMPLOYEE as a where a.salary >= 50000;
SELECT empno, firstnme, lastname, midinit, workdept, upper(salary)  from DB2SAMPLE.employee
 WHERE upper(salary) >= '50' + 0;
 SELECT empno, firstnme, lastname, midinit, workdept, upper(salary)  from DB2SAMPLE.employee
 WHERE upper(salary) >= 50;
 SELECT empno, firstnme, lastname, midinit, workdept, upper(salary)  from DB2SAMPLE.employee
 WHERE upper(salary) >= upper(50);
SELECT empno, firstnme, lastname, midinit, workdept, upper(salary)  from DB2SAMPLE.employee
 WHERE upper(salary) like '%50%';
SELECT empno, firstnme, lastname, midinit, workdept  from db2sample.employee
 WHERE upper(salary) >= 50;
select * from db2sample.employee
                    order by lastname;
select empno
  from (
  select empno from db2sample.employee
  order by lastname ); 
select empno
  from (
  select empno from db2sample.employee
  order by lastname ) limit 1 offset 2;   

-- Test with filter on workdept
select empno,lastname from db2sample.employee
  order by lastname;      
select empno,lastname from db2sample.employee
  order by lastname limit 1 offset 3;                     