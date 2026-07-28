-- catalogue des objets.
create table 
 SELECT S1.*
   FROM TABLE(QSYS2.OBJECT_STATISTICS('*ALLUSR', 'LIB    ')) AS S1; 