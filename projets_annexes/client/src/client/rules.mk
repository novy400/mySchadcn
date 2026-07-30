CLIENTLIST.FILE: clientlist.view
# client business logic client program
CLIENT.MODULE: client.sqlrpgle CLIENTLIST.FILE
CLIENT.SRVPGM: client.bnd CLIENT.MODULE

# client IWS client program
CLIENTIWS.MODULE: client.iws.sqlrpgle
CLIENTIWS.SRVPGM: client.iws.bnd CLIENTIWS.MODULE
# client REST client program  
# SERVREST.MODULE: client.rest.sqlrpgle
# SERVROUTE.MODULE: client.route.sqlrpgle

LSTCLIENT.SRVPGM: listeClient.sqludf

# Message file
# client.MSGF: client.msgf