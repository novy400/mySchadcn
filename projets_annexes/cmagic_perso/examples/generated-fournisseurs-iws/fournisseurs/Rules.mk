# Generated from CatalogSpec with catalog.Rules.mk.hbs. Do not edit.
# Fournis catalogue read module
FOURNIS.MODULE: fournisseurs.read.sqlrpgle
# Fournis catalogue read service program
FOURNIS.SRVPGM: fournisseurs.bnd FOURNIS.MODULE
# Fournis IBM Integrated Web Services transport service program
FOURIWS.MODULE: fournisseurs.iws.sqlrpgle
FOURNIS.BNDDIR: fournisseurs.read.bnddir FOURNIS.SRVPGM
FOURIWS.SRVPGM: fournisseurs.iws.bnd FOURIWS.MODULE FOURNIS.BNDDIR
FOURIWS.BNDDIR: fournisseurs.iws.bnddir FOURIWS.SRVPGM
