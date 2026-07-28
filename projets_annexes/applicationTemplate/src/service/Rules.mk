# Service business logic service program
SERVICE.MODULE: service.sqlrpgle
SERVICE.SRVPGM: service.bnd SERVICE.MODULE

# Service REST service program  
SERVREST.MODULE: service.rest.sqlrpgle
SERVROUTE.MODULE: service.route.sqlrpgle

# Service IWS service program
SERVIWS.MODULE: service.iws.sqlrpgle
SERVIWS.SRVPGM: service.iws.bnd SERVIWS.MODULE

# Message file
SERVICE.MSGF: service.msgf