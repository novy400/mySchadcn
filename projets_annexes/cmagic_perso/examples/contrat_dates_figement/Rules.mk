# Table des dates de figement des contrats 
CONTFIGDAT.FILE: contfigdat.table
CONTFIGDAV.FILE: contfigdav.view
# business logic service program
CONTFIGDAT.MODULE: contfigdat.sqlrpgle
CONTFIGDAT.SRVPGM: contfigdat.bnd CONTFIGDAT.MODULE

# CONTFIGDAT REST service program  
# EMPREST.MODULE: CONTFIGDAT.rest.sqlrpgle

# Display programs
# INVEMP.FILE: invemp.dspf
# INVEMP.PGM: invemp.pgm.sqlrpgle INVEMP.FILE
WRKCFGDAT.FILE: wrkcfgdat.dspf
WRKCFGDAT.PGM: wrkcfgdat.pgm.sqlrpgle WRKCFGDAT.FILE CONTFIGDAT.SRVPGM
WRKCFGDAT.CMD: wrkcfgdat.cmd WRKCFGDAT.PGM

# Message file
CONTFIGDAT.MSGF: contfigdat.msgf