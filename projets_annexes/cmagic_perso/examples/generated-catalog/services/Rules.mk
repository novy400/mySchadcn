# Generated from CatalogSpec with catalog.Rules.mk.hbs. Do not edit.
# Service catalogue read module
SERVICE.MODULE: services.read.sqlrpgle
# Service catalogue read service program
SERVICE.SRVPGM: services.bnd SERVICE.MODULE
# Service ILEastic transport module
SERVREST.MODULE: services.ileastic.sqlrpgle
