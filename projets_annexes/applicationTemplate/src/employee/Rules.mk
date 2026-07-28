# Employee business logic service program
EMPLOYEE.MODULE: employee.sqlrpgle
EMPLOYEE.SRVPGM: employee.bnd EMPLOYEE.MODULE

# Employee REST service program  
EMPREST.MODULE: employee.rest.sqlrpgle
EMPROUTE.MODULE: employee.route.sqlrpgle

 
# Display programs
INVEMP.FILE: invemp.dspf
INVEMP.PGM: invemp.pgm.sqlrpgle INVEMP.FILE
WRKEMP.FILE: wrkemp.dspf
WRKEMP.PGM: wrkemp.pgm.sqlrpgle WRKEMP.FILE EMPLOYEE.SRVPGM
WRKEMP.CMD: wrkemp.cmd WRKEMP.PGM

# Message file
EMPLOYEE.MSGF: employee.msgf