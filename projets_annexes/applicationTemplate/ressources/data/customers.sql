-- =============================================================================
-- TechServ Project - Customers Table
-- Episode 4: Business Entity - Customers with Validation
-- 
-- Table: CUSTOMERS
-- Description: Customer entities with business validation and status workflow
-- =============================================================================

-- Drop table if exists (for development)
-- DROP TABLE IF EXISTS TECHSERV.CUSTOMERS;

-- Create customers table
CREATE OR REPLACE TABLE TECHSERV.CUSTOMERS (
  -- Primary key - auto-generated
  ID INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
  
  -- Company information
  COMPANY_NAME VARCHAR(100) NOT NULL,
  CONTACT_NAME VARCHAR(100),
  
  -- Contact information
  EMAIL VARCHAR(100),
  PHONE VARCHAR(20) NOT NULL,
  MOBILE VARCHAR(20),
  
  -- Address information
  ADDRESS VARCHAR(200),
  CITY VARCHAR(50),
  POSTAL_CODE VARCHAR(10),
  COUNTRY VARCHAR(50) DEFAULT 'FR',
  
  -- Business information
  STATUS VARCHAR(20) DEFAULT 'PROSPECT' CHECK (STATUS IN ('PROSPECT', 'ACTIVE', 'SUSPENDED', 'INACTIVE')),
  PAYMENT_TERMS INTEGER DEFAULT 30, -- Days
  
  -- Audit fields
  CREATED_AT TIMESTAMP DEFAULT CURRENT TIMESTAMP,
  UPDATED_AT TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IX_CUSTOMERS_COMPANY_NAME ON TECHSERV.CUSTOMERS(COMPANY_NAME);
CREATE INDEX IX_CUSTOMERS_STATUS ON TECHSERV.CUSTOMERS(STATUS);
CREATE INDEX IX_CUSTOMERS_EMAIL ON TECHSERV.CUSTOMERS(EMAIL);
CREATE INDEX IX_CUSTOMERS_PHONE ON TECHSERV.CUSTOMERS(PHONE);
CREATE INDEX IX_CUSTOMERS_CITY ON TECHSERV.CUSTOMERS(CITY);

-- Create trigger for updated_at field
CREATE OR REPLACE TRIGGER TECHSERV.TRG_CUSTOMERS_UPDATED_AT
  BEFORE UPDATE ON TECHSERV.CUSTOMERS
  REFERENCING NEW AS N OLD AS O
  FOR EACH ROW
  SET N.UPDATED_AT = CURRENT TIMESTAMP;

-- =============================================================================
-- Sample Data for Development and Testing
-- =============================================================================

-- Insert sample customers for TechServ
INSERT INTO TECHSERV.CUSTOMERS 
  (COMPANY_NAME, CONTACT_NAME, EMAIL, PHONE, MOBILE, ADDRESS, CITY, POSTAL_CODE, COUNTRY, STATUS, PAYMENT_TERMS)
VALUES
  -- Active customers
  ('Acme Corporation', 'Pierre Martin', 'pierre.martin@acme.com', '+33144556677', '+33612345678', '123 Rue de la Paix', 'Paris', '75001', 'FR', 'ACTIVE', 30),
  ('Durand SARL', 'Marie Durand', 'marie@durand-sarl.fr', '+33145667788', '+33623456789', '45 Avenue des Champs', 'Lyon', '69001', 'FR', 'ACTIVE', 45),
  ('Hotel Plaza', 'Jean Lepetit', 'maintenance@hotelplaza.fr', '+33146778899', '+33634567890', '78 Boulevard Haussmann', 'Paris', '75008', 'FR', 'ACTIVE', 15),
  ('Garage Moderne', 'Sophie Rousseau', 'contact@garage-moderne.com', '+33147889900', '+33645678901', '12 Rue de la République', 'Marseille', '13001', 'FR', 'ACTIVE', 30),
  ('Restaurant Le Gourmet', 'Paul Blanc', 'paul@legourmet.fr', '+33148990011', '+33656789012', '89 Rue Saint-Antoine', 'Bordeaux', '33000', 'FR', 'ACTIVE', 30),
  
  -- Prospects (potential customers)
  ('Clinique Saint-Pierre', 'Dr. Anne Moreau', 'a.moreau@clinique-sp.fr', '+33149001122', '+33667890123', '34 Avenue Foch', 'Nice', '06000', 'FR', 'PROSPECT', 30),
  ('École Primaire Mozart', 'Directeur Michel Bernard', 'direction@ecole-mozart.fr', '+33150112233', '+33678901234', '56 Rue Mozart', 'Toulouse', '31000', 'FR', 'PROSPECT', 60),
  ('Cabinet Dentaire Sourire', 'Dr. Sylvie Petit', 'contact@sourire-dentaire.fr', '+33151223344', '+33689012345', '23 Place de la Liberté', 'Lille', '59000', 'FR', 'PROSPECT', 30),
  
  -- Suspended customers (temporary issues)
  ('Transport Express', 'Antoine Roux', 'antoine@transport-express.com', '+33152334455', '+33690123456', '67 Zone Industrielle', 'Nantes', '44000', 'FR', 'SUSPENDED', 30),
  ('Boulangerie Tradition', 'Nathalie Garcia', 'contact@boulangerie-tradition.fr', '+33153445566', '+33601234567', '18 Rue du Commerce', 'Strasbourg', '67000', 'FR', 'SUSPENDED', 45),
  
  -- Inactive customers (historical data)
  ('Ancienne Entreprise', 'François Lopez', 'contact@ancienne.com', '+33154556677', '+33612345600', '90 Rue Fermée', 'Montpellier', '34000', 'FR', 'INACTIVE', 30),
  
  -- International customers for testing
  ('Swiss Tech SA', 'Hans Mueller', 'hans@swisstech.ch', '+41221234567', '+41791234567', 'Rue du Lac 15', 'Geneva', '1200', 'CH', 'ACTIVE', 30),
  ('Belgian Industries', 'Marie Van Der Berg', 'marie@belgian-ind.be', '+3225551234', '+32471234567', 'Avenue Louise 200', 'Brussels', '1000', 'BE', 'PROSPECT', 45),
  
  -- Large enterprise customer
  ('Mega Corporation France', 'Directeur Général', 'facilities@megacorp.fr', '+33155667788', '+33612340000', '100 La Défense Tower', 'Paris La Défense', '92400', 'FR', 'ACTIVE', 60),
  
  -- Small local businesses
  ('Café du Coin', 'Lucie Moreau', 'lucie@cafeducoin.fr', '+33156778899', '+33623451234', '5 Place du Village', 'Versailles', '78000', 'FR', 'ACTIVE', 15),
  ('Pressing Rapide', 'Michel Simon', 'michel@pressing-rapide.com', '+33157889900', '+33634562345', '28 Rue de la Gare', 'Saint-Denis', '93200', 'FR', 'ACTIVE', 30);

-- =============================================================================
-- API Testing Queries - Episode 4 Validation
-- =============================================================================

-- Test basic selection (equivalent to GET /api/customers)
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  CITY,
  STATUS
FROM TECHSERV.CUSTOMERS
ORDER BY COMPANY_NAME;

-- Test pagination (equivalent to GET /api/customers?_page=1&_limit=5)
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  CITY,
  STATUS
FROM TECHSERV.CUSTOMERS
ORDER BY COMPANY_NAME
LIMIT 5 OFFSET 0;

-- Test count for X-Total-Count header
SELECT COUNT(*) as TOTAL_COUNT 
FROM TECHSERV.CUSTOMERS;

-- Test status filter (equivalent to GET /api/customers?status=ACTIVE)
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  CITY,
  STATUS
FROM TECHSERV.CUSTOMERS
WHERE STATUS = 'ACTIVE'
ORDER BY COMPANY_NAME;

-- Test city filter (equivalent to GET /api/customers?city=Paris)
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  CITY,
  STATUS
FROM TECHSERV.CUSTOMERS
WHERE CITY = 'Paris'
ORDER BY COMPANY_NAME;

-- Test company name search (equivalent to GET /api/customers?company_name_like=Hotel)
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  CITY,
  STATUS
FROM TECHSERV.CUSTOMERS
WHERE UPPER(COMPANY_NAME) LIKE '%HOTEL%'
ORDER BY COMPANY_NAME;

-- Test detail query (equivalent to GET /api/customers/{id})
SELECT 
  ID,
  COMPANY_NAME,
  CONTACT_NAME,
  EMAIL,
  PHONE,
  MOBILE,
  ADDRESS,
  CITY,
  POSTAL_CODE,
  COUNTRY,
  STATUS,
  PAYMENT_TERMS,
  CREATED_AT,
  UPDATED_AT
FROM TECHSERV.CUSTOMERS
WHERE ID = 1;

-- =============================================================================
-- Business Validation Queries
-- =============================================================================

-- Check email format validation (for business logic)
SELECT 
  ID,
  COMPANY_NAME,
  EMAIL,
  CASE 
    WHEN EMAIL IS NULL THEN 'No email'
    WHEN EMAIL NOT LIKE '%_@_%.__%' THEN 'Invalid format'
    ELSE 'Valid'
  END as EMAIL_STATUS
FROM TECHSERV.CUSTOMERS
WHERE EMAIL IS NOT NULL;

-- Check phone format (basic validation)
SELECT 
  ID,
  COMPANY_NAME,
  PHONE,
  CASE 
    WHEN PHONE IS NULL THEN 'Missing required phone'
    WHEN LENGTH(TRIM(PHONE)) < 10 THEN 'Too short'
    WHEN PHONE NOT LIKE '+%' THEN 'Should start with +'
    ELSE 'Valid'
  END as PHONE_STATUS
FROM TECHSERV.CUSTOMERS;

-- Status transition validation matrix
SELECT 
  'Prospect to Active' as TRANSITION,
  'Valid' as STATUS
UNION ALL
SELECT 
  'Active to Suspended' as TRANSITION,
  'Valid' as STATUS
UNION ALL
SELECT 
  'Suspended to Active' as TRANSITION,
  'Valid' as STATUS
UNION ALL
SELECT 
  'Active to Inactive' as TRANSITION,
  'Valid' as STATUS
UNION ALL
SELECT 
  'Suspended to Inactive' as TRANSITION,
  'Valid' as STATUS
UNION ALL
SELECT 
  'Inactive to Active' as TRANSITION,
  'Invalid - requires reactivation process' as STATUS;

-- =============================================================================
-- Verification & Statistics
-- =============================================================================

-- Count by status
SELECT 
  STATUS,
  COUNT(*) as COUNT,
  AVG(PAYMENT_TERMS) as AVG_PAYMENT_TERMS
FROM TECHSERV.CUSTOMERS
GROUP BY STATUS
ORDER BY STATUS;

-- Count by country
SELECT 
  COUNTRY,
  COUNT(*) as COUNT
FROM TECHSERV.CUSTOMERS
GROUP BY COUNTRY
ORDER BY COUNT DESC;

-- Count by city (top 5)
SELECT 
  CITY,
  COUNT(*) as COUNT
FROM TECHSERV.CUSTOMERS
GROUP BY CITY
HAVING COUNT(*) > 1
ORDER BY COUNT DESC;

-- Payment terms analysis
SELECT 
  PAYMENT_TERMS,
  COUNT(*) as COUNT,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM TECHSERV.CUSTOMERS), 2) as PERCENTAGE
FROM TECHSERV.CUSTOMERS
GROUP BY PAYMENT_TERMS
ORDER BY PAYMENT_TERMS;

-- Data quality checks
SELECT 
  'Total Customers' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.CUSTOMERS

UNION ALL

SELECT 
  'With Email' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.CUSTOMERS
WHERE EMAIL IS NOT NULL

UNION ALL

SELECT 
  'With Mobile' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.CUSTOMERS
WHERE MOBILE IS NOT NULL

UNION ALL

SELECT 
  'Complete Address' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.CUSTOMERS
WHERE ADDRESS IS NOT NULL 
  AND CITY IS NOT NULL 
  AND POSTAL_CODE IS NOT NULL;

-- =============================================================================
-- Episode 4 Business Logic Tests
-- =============================================================================

-- Test required field validation
SELECT 
  'Required Fields Test' as TEST,
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE CONCAT('FAIL - ', CHAR(COUNT(*)), ' customers missing required fields')
  END as RESULT
FROM TECHSERV.CUSTOMERS
WHERE COMPANY_NAME IS NULL 
   OR TRIM(COMPANY_NAME) = ''
   OR PHONE IS NULL 
   OR TRIM(PHONE) = '';

-- Test status values validation
SELECT 
  'Status Values Test' as TEST,
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE CONCAT('FAIL - ', CHAR(COUNT(*)), ' customers with invalid status')
  END as RESULT
FROM TECHSERV.CUSTOMERS
WHERE STATUS NOT IN ('PROSPECT', 'ACTIVE', 'SUSPENDED', 'INACTIVE');

-- Test payment terms reasonableness
SELECT 
  'Payment Terms Test' as TEST,
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE CONCAT('FAIL - ', CHAR(COUNT(*)), ' customers with unreasonable payment terms')
  END as RESULT
FROM TECHSERV.CUSTOMERS
WHERE PAYMENT_TERMS IS NULL 
   OR PAYMENT_TERMS < 0 
   OR PAYMENT_TERMS > 120;

-- =============================================================================
-- Comments for Episode 4 Development
-- =============================================================================

/*
API Endpoints to implement in Episode 4:

GET    /api/customers               - List with pagination, filters, sort
GET    /api/customers/{id}          - Get single customer details
POST   /api/customers               - Create new customer
PUT    /api/customers/{id}          - Update existing customer
DELETE /api/customers/{id}          - Delete customer (soft delete recommended)

Filter parameters to support:
- status=PROSPECT,ACTIVE,SUSPENDED,INACTIVE
- city=Paris (exact match)
- country=FR (exact match)
- company_name_like=Hotel (case insensitive)
- contact_name_like=Pierre (case insensitive)
- email_like=@techserv.com (pattern matching)
- payment_terms_gte=30 (minimum payment terms)
- payment_terms_lte=60 (maximum payment terms)

Sort parameters:
- company_name (default)
- contact_name
- city
- created_at
- status

Business Validation Rules to implement:
1. company_name is required and not empty
2. phone is required and not empty
3. email format validation (if provided)
4. status must be valid enum value
5. status transitions follow business rules:
   - PROSPECT → ACTIVE (valid)
   - ACTIVE → SUSPENDED (valid)
   - SUSPENDED → ACTIVE (valid)
   - ACTIVE/SUSPENDED → INACTIVE (valid)
   - INACTIVE → * (requires special reactivation process)
6. payment_terms must be between 0 and 120 days

Error Handling:
- Return 400 Bad Request for validation errors
- Return structured JSON error response with field-level details
- Log all validation failures for monitoring

Special Episode 4 Focus:
- Demonstrate comprehensive validation
- Show status workflow implementation
- Example of business entity with complex rules
- Pattern for other entities with validation needs
*/