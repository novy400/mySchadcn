# Generated from CatalogSpec with catalog.Rules.mk.hbs. Do not edit.
# Service catalogue read module
SERVICE.MODULE: services.read.sqlrpgle
# Service catalogue read service program
SERVICE.SRVPGM: services.bnd SERVICE.MODULE
# Service IBM Integrated Web Services transport service program
SERVIWS.MODULE: services.iws.sqlrpgle
SERVICE.BNDDIR: services.iws.bnddir SERVICE.SRVPGM CIWS.SRVPGM
SERVIWS.SRVPGM: services.iws.bnd SERVIWS.MODULE SERVICE.BNDDIR
