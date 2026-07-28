select deptno,
ifnull(deptname, ''),
ifnull(mgrno, ''),
ifnull(admrdept, ''),
ifnull(location, '') from db2sample.department;