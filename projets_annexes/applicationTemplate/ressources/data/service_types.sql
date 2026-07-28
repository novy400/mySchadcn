-- =============================================================================
-- TechServ Project - Service Types Table
-- Episode 3: Reference Data Made Easy - Service Types
-- 
-- Table: SERVICE_TYPES
-- Description: Reference data for types of services offered by TechServ
-- =============================================================================

-- Drop table if exists (for development)
-- DROP TABLE IF EXISTS TECHSERV.SERVICE_TYPES;

-- Create service_types table
CREATE OR REPLACE TABLE TECHSERV.SERVICE_TYPES (
  -- Primary key - auto-generated
  ID INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
  
  -- Service identification
  CODE VARCHAR(20) NOT NULL UNIQUE,
  NAME VARCHAR(100) NOT NULL,
  DESCRIPTION VARCHAR(500),
  
  -- Service parameters
  ESTIMATED_DURATION_MINUTES INTEGER DEFAULT 60,
  DEFAULT_PRICE DECIMAL(10,2),
  
  -- Status
  ACTIVE CHAR(1) DEFAULT 'Y' CHECK (ACTIVE IN ('Y', 'N')),
  
  -- Audit fields
  CREATED_AT TIMESTAMP DEFAULT CURRENT TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IX_SERVICE_TYPES_CODE ON TECHSERV.SERVICE_TYPES(CODE);
CREATE INDEX IX_SERVICE_TYPES_ACTIVE ON TECHSERV.SERVICE_TYPES(ACTIVE);
CREATE INDEX IX_SERVICE_TYPES_NAME ON TECHSERV.SERVICE_TYPES(NAME);

-- =============================================================================
-- Sample Data for Development and Testing
-- =============================================================================

-- Insert service types for TechServ
INSERT INTO TECHSERV.SERVICE_TYPES 
  (CODE, NAME, DESCRIPTION, ESTIMATED_DURATION_MINUTES, DEFAULT_PRICE, ACTIVE)
VALUES
  -- HVAC Services
  ('HVAC-MAINT', 'HVAC Maintenance', 'Routine maintenance of heating, ventilation, and air conditioning systems. Includes filter replacement, system inspection, and performance testing.', 120, 150.00, 'Y'),
  ('HVAC-REPAIR', 'HVAC Emergency Repair', 'Emergency repair services for HVAC systems. Available 24/7 for critical heating/cooling failures.', 180, 250.00, 'Y'),
  ('HVAC-INSTALL', 'HVAC Installation', 'Complete installation of new HVAC systems including ductwork, thermostats, and commissioning.', 480, 800.00, 'Y'),
  ('HVAC-INSPECT', 'HVAC Inspection', 'Annual inspection and certification of HVAC systems for regulatory compliance.', 90, 120.00, 'Y'),
  
  -- Electrical Services
  ('ELEC-INSTALL', 'Electrical Installation', 'Installation of electrical systems, wiring, outlets, switches, and electrical panels.', 240, 300.00, 'Y'),
  ('ELEC-REPAIR', 'Electrical Repair', 'Repair of electrical faults, troubleshooting, and replacement of defective components.', 120, 180.00, 'Y'),
  ('ELEC-EMERGENCY', 'Electrical Emergency', '24/7 emergency electrical services for power outages, dangerous faults, and urgent repairs.', 90, 220.00, 'Y'),
  ('ELEC-INSPECT', 'Electrical Inspection', 'Safety inspection and certification of electrical installations per building codes.', 60, 100.00, 'Y'),
  ('ELEC-UPGRADE', 'Electrical Upgrade', 'Upgrade of electrical panels, circuits, and systems to modern standards.', 360, 450.00, 'Y'),
  
  -- Plumbing Services
  ('PLUMB-REPAIR', 'Plumbing Repair', 'General plumbing repairs including leaks, clogs, pipe replacement, and fixture repairs.', 90, 120.00, 'Y'),
  ('PLUMB-INSTALL', 'Plumbing Installation', 'Installation of new plumbing systems, fixtures, water heaters, and pipe networks.', 300, 400.00, 'Y'),
  ('PLUMB-EMERGENCY', 'Plumbing Emergency', '24/7 emergency plumbing for burst pipes, major leaks, and sewer backups.', 120, 200.00, 'Y'),
  ('PLUMB-MAINT', 'Plumbing Maintenance', 'Preventive maintenance including drain cleaning, water heater service, and pipe inspection.', 60, 80.00, 'Y'),
  ('PLUMB-INSPECT', 'Plumbing Inspection', 'Inspection of plumbing systems for leaks, compliance, and preventive maintenance needs.', 45, 75.00, 'Y'),
  
  -- General Maintenance Services
  ('GEN-MAINT', 'General Maintenance', 'General building maintenance including minor repairs, painting, and facility upkeep.', 120, 100.00, 'Y'),
  ('GEN-CLEAN', 'Equipment Cleaning', 'Professional cleaning of industrial equipment, machinery, and building systems.', 180, 140.00, 'Y'),
  ('GEN-INSPECT', 'General Inspection', 'General facility inspection for maintenance needs, safety compliance, and system status.', 90, 90.00, 'Y'),
  
  -- Specialized Services
  ('SPEC-COMMISSIONING', 'System Commissioning', 'Complete commissioning of new building systems including testing, documentation, and training.', 480, 600.00, 'Y'),
  ('SPEC-ENERGY-AUDIT', 'Energy Audit', 'Comprehensive energy efficiency audit with recommendations for improvements and cost savings.', 240, 350.00, 'Y'),
  ('SPEC-CONSULTATION', 'Technical Consultation', 'Expert consultation on system design, troubleshooting, and optimization.', 60, 150.00, 'Y'),
  
  -- Inactive service (for testing)
  ('OLD-SERVICE', 'Deprecated Service', 'This service is no longer offered but kept for historical records.', 60, 50.00, 'N');

-- =============================================================================
-- API Testing Queries - Episode 3 Validation  
-- =============================================================================

-- Test basic selection (equivalent to GET /api/service-types)
SELECT 
  ID,
  CODE,
  NAME,
  ESTIMATED_DURATION_MINUTES,
  DEFAULT_PRICE,
  ACTIVE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'
ORDER BY CODE;

-- Test count for X-Total-Count header
SELECT COUNT(*) as TOTAL_COUNT 
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y';

-- Test all records including inactive (for admin interface)
SELECT 
  ID,
  CODE,
  NAME,
  ESTIMATED_DURATION_MINUTES,
  DEFAULT_PRICE,
  ACTIVE
FROM TECHSERV.SERVICE_TYPES
ORDER BY CODE;

-- Test detail query (equivalent to GET /api/service-types/{id})  
SELECT 
  ID,
  CODE,
  NAME,
  DESCRIPTION,
  ESTIMATED_DURATION_MINUTES,
  DEFAULT_PRICE,
  ACTIVE,
  CREATED_AT
FROM TECHSERV.SERVICE_TYPES
WHERE ID = 1;

-- Test filtering by code pattern (equivalent to GET /api/service-types?code_like=HVAC)
SELECT 
  ID,
  CODE,
  NAME,
  ESTIMATED_DURATION_MINUTES,
  DEFAULT_PRICE
FROM TECHSERV.SERVICE_TYPES
WHERE CODE LIKE 'HVAC%'
  AND ACTIVE = 'Y'
ORDER BY CODE;

-- Test filtering by name (equivalent to GET /api/service-types?name_like=Emergency)
SELECT 
  ID,
  CODE,
  NAME,
  ESTIMATED_DURATION_MINUTES,
  DEFAULT_PRICE
FROM TECHSERV.SERVICE_TYPES
WHERE UPPER(NAME) LIKE '%EMERGENCY%'
  AND ACTIVE = 'Y'
ORDER BY NAME;

-- =============================================================================
-- Verification & Statistics
-- =============================================================================

-- Count by service category (derived from code prefix)
SELECT 
  SUBSTR(CODE, 1, LOCATE('-', CODE) - 1) as CATEGORY,
  COUNT(*) as SERVICE_COUNT,
  AVG(DEFAULT_PRICE) as AVG_PRICE,
  AVG(ESTIMATED_DURATION_MINUTES) as AVG_DURATION
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'
GROUP BY SUBSTR(CODE, 1, LOCATE('-', CODE) - 1)
ORDER BY CATEGORY;

-- Price range analysis
SELECT 
  'Service Count' as METRIC,
  COUNT(*) as VALUE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'

UNION ALL

SELECT 
  'Average Price' as METRIC,
  ROUND(AVG(DEFAULT_PRICE), 2) as VALUE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'

UNION ALL

SELECT 
  'Min Price' as METRIC,
  MIN(DEFAULT_PRICE) as VALUE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'

UNION ALL

SELECT 
  'Max Price' as METRIC,
  MAX(DEFAULT_PRICE) as VALUE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y';

-- Duration analysis
SELECT 
  CASE 
    WHEN ESTIMATED_DURATION_MINUTES <= 60 THEN 'Quick (≤1h)'
    WHEN ESTIMATED_DURATION_MINUTES <= 180 THEN 'Standard (1-3h)'
    WHEN ESTIMATED_DURATION_MINUTES <= 360 THEN 'Long (3-6h)'
    ELSE 'Extended (>6h)'
  END as DURATION_CATEGORY,
  COUNT(*) as SERVICE_COUNT,
  AVG(DEFAULT_PRICE) as AVG_PRICE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'
GROUP BY 
  CASE 
    WHEN ESTIMATED_DURATION_MINUTES <= 60 THEN 'Quick (≤1h)'
    WHEN ESTIMATED_DURATION_MINUTES <= 180 THEN 'Standard (1-3h)'
    WHEN ESTIMATED_DURATION_MINUTES <= 360 THEN 'Long (3-6h)'
    ELSE 'Extended (>6h)'
  END
ORDER BY MIN(ESTIMATED_DURATION_MINUTES);

-- Find most expensive services
SELECT 
  CODE,
  NAME,
  DEFAULT_PRICE,
  ESTIMATED_DURATION_MINUTES,
  ROUND(DEFAULT_PRICE * 60.0 / ESTIMATED_DURATION_MINUTES, 2) as HOURLY_RATE
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y'
ORDER BY DEFAULT_PRICE DESC
LIMIT 5;

-- =============================================================================
-- Business Logic Validation
-- =============================================================================

-- Validate all codes are unique
SELECT 
  'Unique Codes Check' as TEST,
  CASE 
    WHEN COUNT(*) = COUNT(DISTINCT CODE) THEN 'PASS'
    ELSE 'FAIL - Duplicate codes found'
  END as RESULT
FROM TECHSERV.SERVICE_TYPES;

-- Validate all active services have prices
SELECT 
  'Price Validation' as TEST,
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE CONCAT('FAIL - ', CHAR(COUNT(*)), ' services without price')
  END as RESULT
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y' 
  AND (DEFAULT_PRICE IS NULL OR DEFAULT_PRICE <= 0);

-- Validate all services have reasonable durations
SELECT 
  'Duration Validation' as TEST,
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE CONCAT('FAIL - ', CHAR(COUNT(*)), ' services with invalid duration')
  END as RESULT
FROM TECHSERV.SERVICE_TYPES
WHERE ACTIVE = 'Y' 
  AND (ESTIMATED_DURATION_MINUTES IS NULL OR ESTIMATED_DURATION_MINUTES <= 0);

-- =============================================================================
-- Comments for Episode 3 Development
-- =============================================================================

/*
API Endpoints to implement in Episode 3:

GET    /api/service-types            - List active service types (default filter ACTIVE='Y')
GET    /api/service-types/{id}       - Get single service type details
POST   /api/service-types            - Create new service type (admin only)
PUT    /api/service-types/{id}       - Update service type (admin only)
DELETE /api/service-types/{id}       - Deactivate service type (set ACTIVE='N')

Filter parameters to support:
- active=Y,N (default Y for public API)
- code_like=HVAC (pattern matching)
- name_like=Emergency (case insensitive)
- price_gte=100 (minimum price)
- price_lte=500 (maximum price)
- duration_gte=60 (minimum duration in minutes)
- duration_lte=300 (maximum duration in minutes)

Sort parameters:
- code (default)
- name
- default_price
- estimated_duration_minutes

Special considerations for Episode 3:
- Primarily read-only for end users
- Simple caching possible (data changes infrequently)
- Template for other reference data tables
- Good example of business validation rules
*/