-- Generated from CatalogSpec with catalog.ddl.sql.hbs. Do not edit.
-- Table for Fournis.
CREATE TABLE FOURNIS (
    ID VARCHAR(10) NOT NULL,
    NOM VARCHAR(100) NOT NULL,
    ADRESSE VARCHAR(160),
    VILLE VARCHAR(80),
    TELEPHONE VARCHAR(20),
    EMAIL VARCHAR(254),
    PRIMARY KEY (ID)
);
