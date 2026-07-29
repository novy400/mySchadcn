-- Generated from CatalogSpec with catalog.ddl.sql.hbs. Do not edit.
-- Table for Service.
CREATE TABLE DEPARTMENT (
    DEPTNO VARCHAR(3) NOT NULL,
    DEPTNAME VARCHAR(36) NOT NULL,
    MGRNO VARCHAR(6),
    ADMRDEPT VARCHAR(3),
    LOCATION VARCHAR(16),
    PRIMARY KEY (DEPTNO)
);
