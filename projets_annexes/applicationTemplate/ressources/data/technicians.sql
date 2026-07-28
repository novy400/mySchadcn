-- =============================================================================
-- TechServ Project - Technicians Table
-- Episode 2: Your First API - Technicians CRUD
-- 
-- Table: TECHNICIANS
-- Description: Manages technicians/field workers for TechServ maintenance company
-- =============================================================================

-- Drop table if exists (for development)
-- DROP TABLE IF EXISTS TECHSERV.TECHNICIANS;

-- Create schema if not exists
-- CREATE SCHEMA IF NOT EXISTS TECHSERV;

-- Create technicians table
CREATE OR REPLACE TABLE TECHSERV.TECHNICIANS (
  -- Primary key - auto-generated
  ID INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
  
  -- Personal information
  FIRST_NAME VARCHAR(50) NOT NULL,
  LAST_NAME VARCHAR(50) NOT NULL,
  EMAIL VARCHAR(100) NOT NULL UNIQUE,
  PHONE VARCHAR(20),
  
  -- Professional information
  SPECIALTY VARCHAR(50) NOT NULL CHECK (SPECIALTY IN ('HVAC', 'ELECTRICAL', 'PLUMBING', 'GENERAL')),
  CERTIFICATION_LEVEL VARCHAR(20) DEFAULT 'JUNIOR' CHECK (CERTIFICATION_LEVEL IN ('JUNIOR', 'SENIOR', 'EXPERT')),
  STATUS VARCHAR(20) DEFAULT 'ACTIVE' CHECK (STATUS IN ('ACTIVE', 'ON_LEAVE', 'INACTIVE')),
  
  -- Employment details
  HIRE_DATE DATE,
  HOURLY_RATE DECIMAL(10,2),
  
  -- Audit fields
  CREATED_AT TIMESTAMP DEFAULT CURRENT TIMESTAMP,
  UPDATED_AT TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IX_TECHNICIANS_SPECIALTY ON TECHSERV.TECHNICIANS(SPECIALTY);
CREATE INDEX IX_TECHNICIANS_STATUS ON TECHSERV.TECHNICIANS(STATUS);
CREATE INDEX IX_TECHNICIANS_EMAIL ON TECHSERV.TECHNICIANS(EMAIL);
CREATE INDEX IX_TECHNICIANS_NAME ON TECHSERV.TECHNICIANS(LAST_NAME, FIRST_NAME);

-- Create trigger for updated_at field
CREATE OR REPLACE TRIGGER TECHSERV.TRG_TECHNICIANS_UPDATED_AT
  BEFORE UPDATE ON TECHSERV.TECHNICIANS
  REFERENCING NEW AS N OLD AS O
  FOR EACH ROW
  SET N.UPDATED_AT = CURRENT TIMESTAMP;

-- =============================================================================
-- Sample Data for Development and Testing
-- =============================================================================

-- Insert sample technicians for TechServ
INSERT INTO TECHSERV.TECHNICIANS 
  (FIRST_NAME, LAST_NAME, EMAIL, PHONE, SPECIALTY, CERTIFICATION_LEVEL, STATUS, HIRE_DATE, HOURLY_RATE)
VALUES
  -- HVAC Specialists
  ('Jean', 'Dupont', 'jean.dupont@techserv.com', '+33123456789', 'HVAC', 'SENIOR', 'ACTIVE', '2020-03-15', 35.00),
  ('Marie', 'Martin', 'marie.martin@techserv.com', '+33123456790', 'HVAC', 'EXPERT', 'ACTIVE', '2018-09-01', 42.50),
  ('Pierre', 'Moreau', 'pierre.moreau@techserv.com', '+33123456791', 'HVAC', 'JUNIOR', 'ACTIVE', '2023-01-10', 28.00),
  
  -- Electrical Specialists  
  ('Sophie', 'Dubois', 'sophie.dubois@techserv.com', '+33123456792', 'ELECTRICAL', 'SENIOR', 'ACTIVE', '2019-06-20', 38.00),
  ('Paul', 'Leblanc', 'paul.leblanc@techserv.com', '+33123456793', 'ELECTRICAL', 'EXPERT', 'ACTIVE', '2017-02-14', 45.00),
  ('Lucie', 'Rousseau', 'lucie.rousseau@techserv.com', '+33123456794', 'ELECTRICAL', 'JUNIOR', 'ON_LEAVE', '2022-11-05', 30.00),
  
  -- Plumbing Specialists
  ('Michel', 'Bernard', 'michel.bernard@techserv.com', '+33123456795', 'PLUMBING', 'SENIOR', 'ACTIVE', '2019-04-18', 36.00),
  ('Sylvie', 'Petit', 'sylvie.petit@techserv.com', '+33123456796', 'PLUMBING', 'EXPERT', 'ACTIVE', '2016-08-30', 43.00),
  
  -- General Maintenance
  ('Antoine', 'Roux', 'antoine.roux@techserv.com', '+33123456797', 'GENERAL', 'SENIOR', 'ACTIVE', '2021-05-12', 32.00),
  ('Nathalie', 'Garcia', 'nathalie.garcia@techserv.com', '+33123456798', 'GENERAL', 'JUNIOR', 'ACTIVE', '2023-03-20', 26.00),
  
  -- Inactive/On Leave for testing
  ('François', 'Lopez', 'francois.lopez@techserv.com', '+33123456799', 'HVAC', 'SENIOR', 'INACTIVE', '2015-12-01', 37.00),
  ('Isabelle', 'Simon', 'isabelle.simon@techserv.com', '+33123456800', 'ELECTRICAL', 'JUNIOR', 'ON_LEAVE', '2022-07-15', 29.00);

-- =============================================================================
-- API Testing Queries - Episode 2 Validation
-- =============================================================================

-- Test basic selection (equivalent to GET /api/technicians)
SELECT 
  ID,
  FIRST_NAME,
  LAST_NAME, 
  EMAIL,
  PHONE,
  SPECIALTY,
  STATUS
FROM TECHSERV.TECHNICIANS
ORDER BY LAST_NAME, FIRST_NAME;

-- Test pagination (equivalent to GET /api/technicians?_page=1&_limit=5)
SELECT 
  ID,
  FIRST_NAME,
  LAST_NAME,
  EMAIL,
  SPECIALTY,
  STATUS
FROM TECHSERV.TECHNICIANS
ORDER BY LAST_NAME, FIRST_NAME
LIMIT 5 OFFSET 0;

-- Test count for X-Total-Count header
SELECT COUNT(*) as TOTAL_COUNT 
FROM TECHSERV.TECHNICIANS;

-- Test filters (equivalent to GET /api/technicians?specialty=HVAC)
SELECT 
  ID,
  FIRST_NAME,
  LAST_NAME,
  EMAIL,
  SPECIALTY,
  STATUS
FROM TECHSERV.TECHNICIANS
WHERE SPECIALTY = 'HVAC'
ORDER BY LAST_NAME, FIRST_NAME;

-- Test status filter (equivalent to GET /api/technicians?status=ACTIVE)
SELECT 
  ID,
  FIRST_NAME,
  LAST_NAME,
  EMAIL,
  SPECIALTY,
  STATUS
FROM TECHSERV.TECHNICIANS
WHERE STATUS = 'ACTIVE'
ORDER BY LAST_NAME, FIRST_NAME;

-- Test detail query (equivalent to GET /api/technicians/{id})
SELECT 
  ID,
  FIRST_NAME,
  LAST_NAME,
  EMAIL,
  PHONE,
  SPECIALTY,
  CERTIFICATION_LEVEL,
  STATUS,
  HIRE_DATE,
  HOURLY_RATE,
  CREATED_AT,
  UPDATED_AT
FROM TECHSERV.TECHNICIANS
WHERE ID = 1;

-- =============================================================================
-- Verification & Statistics
-- =============================================================================

-- Count by specialty
SELECT 
  SPECIALTY,
  COUNT(*) as COUNT,
  AVG(HOURLY_RATE) as AVG_RATE
FROM TECHSERV.TECHNICIANS
GROUP BY SPECIALTY
ORDER BY SPECIALTY;

-- Count by status
SELECT 
  STATUS,
  COUNT(*) as COUNT
FROM TECHSERV.TECHNICIANS
GROUP BY STATUS
ORDER BY STATUS;

-- Count by certification level
SELECT 
  CERTIFICATION_LEVEL,
  COUNT(*) as COUNT,
  AVG(HOURLY_RATE) as AVG_RATE
FROM TECHSERV.TECHNICIANS
GROUP BY CERTIFICATION_LEVEL
ORDER BY CERTIFICATION_LEVEL;

-- Verify constraints and data integrity
SELECT 
  'Total Records' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.TECHNICIANS

UNION ALL

SELECT 
  'Unique Emails' as METRIC,
  COUNT(DISTINCT EMAIL) as VALUE
FROM TECHSERV.TECHNICIANS

UNION ALL

SELECT 
  'Active Technicians' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.TECHNICIANS
WHERE STATUS = 'ACTIVE';

-- Performance test for API endpoints
-- This simulates the queries that will be run by the REST API
SELECT 
  'Performance Test - List Query' as TEST,
  CURRENT TIMESTAMP as EXECUTED_AT;

SELECT COUNT(*) FROM TECHSERV.TECHNICIANS;
SELECT * FROM TECHSERV.TECHNICIANS ORDER BY LAST_NAME LIMIT 10;

SELECT 
  'Performance Test Complete' as TEST,
  CURRENT TIMESTAMP as EXECUTED_AT;

-- =============================================================================
-- Comments for Episode 2 Development
-- =============================================================================

/*
API Endpoints to implement in Episode 2:

GET    /api/technicians              - List with pagination, filters, sort
GET    /api/technicians/{id}         - Get single technician details  
POST   /api/technicians              - Create new technician
PUT    /api/technicians/{id}         - Update existing technician
DELETE /api/technicians/{id}         - Delete technician (soft delete recommended)

Filter parameters to support:
- specialty=HVAC,ELECTRICAL,PLUMBING,GENERAL
- status=ACTIVE,ON_LEAVE,INACTIVE
- certification_level=JUNIOR,SENIOR,EXPERT
- first_name_like=Jean
- last_name_like=Dupont
- email_like=@techserv.com

Sort parameters:
- last_name (default)
- first_name  
- hire_date
- hourly_rate
- specialty

Pagination:
- _page=1 (starts at 1)
- _limit=10 (default, max 100)
- X-Total-Count header required
*/