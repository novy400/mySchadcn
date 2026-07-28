# Employee REST API

This REST API is compatible with React Admin's simple REST data provider and follows the pattern established by the championws.sqlrpgmod example.

## Features

- Full CRUD operations for employees
- React Admin compatible endpoints
- CORS support for web applications
- JSON request/response format
- Pagination support
- Search and filtering capabilities

## Endpoints

### GET /api/employees
List employees with pagination and filtering.

**Query Parameters:**
- `_page`: Page number (default: 1)
- `_limit`: Items per page (default: 10)
- `_sort`: Primary sort field (default: nom)
- `_order`: Primary sort order ASC/DESC (default: ASC)
- `q`: General search term

**Dynamic Filtering:**
Filter by any employee field by using the field name as parameter:
- `nom`: Filter by last name
- `prenom`: Filter by first name
- `initiale`: Filter by initial
- `service`: Filter by department
- `genre`: Filter by gender (M/F)
- `dateEmbauche`: Filter by hire date
- `dateNaissance`: Filter by birth date
- `salaire`: Filter by salary
- `id`: Filter by employee ID

**Multi-level Sorting:**
Support for multiple sort criteria:
- `sort1`, `order1`: Additional sort field and order
- `sort2`, `order2`: Second additional sort field and order
- `sort3`, `order3`: Third additional sort field and order
- `sort4`, `order4`: Fourth additional sort field and order

**Examples:**
- `/api/employees?nom=Smith&service=IT&_sort=dateEmbauche&_order=DESC`
- `/api/employees?q=john&_sort=nom&sort1=dateEmbauche&order1=ASC`
- `/api/employees?service=IT&genre=M&_page=2&_limit=5`

**Response Headers:**
- `X-Total-Count`: Total number of records
- `Access-Control-Expose-Headers`: X-Total-Count

### GET /api/employees/{id}
Get employee details by ID.

### POST /api/employees
Create a new employee.

**Request Body:** JSON employee object

### PUT /api/employees/{id}
Update an existing employee.

**Request Body:** JSON employee object

### DELETE /api/employees/{id}
Delete an employee by ID.

### OPTIONS /api/employees/*
CORS preflight handler.

## JSON Structure

### Employee Object
```json
{
  "id": "123456",
  "prenom": "John",
  "nom": "Doe", 
  "initiale": "J",
  "service": "IT",
  "dateEmbauche": "2023-01-15",
  "dateNaissance": "1990-05-20",
  "genre": "M",
  "salaire": 75000.00
}
```

## Files Structure

- `employee.rest.sqlrpgle`: REST endpoint handlers
- `employee.route.sqlrpgle`: Route definitions and prototypes
- `employee.main.sqlrpgle`: Main server program
- `employee.sqlrpgle`: Business logic procedures
- `employee.rpgleinc`: Data structures and prototypes

## Usage

1. Compile the service modules
2. Run the main program to start the HTTP server
3. Server will listen on port 35801
4. Use with React Admin simple REST data provider

## Modular Design

The `employees_list` endpoint now features a modular design that dynamically handles:

1. **Dynamic Filtering**: Automatically processes query parameters for any supported employee field
2. **Multi-level Sorting**: Supports primary sort (React Admin) plus up to 4 additional sort criteria
3. **General Search**: Special handling for the `q` parameter for cross-field searching
4. **Extensible**: Easy to add new filterable fields by updating the `supportedFields` compile-time data

### Internal Architecture

The modular design uses helper functions:
- `setupFilters()`: Dynamically processes all filter parameters
- `setupGeneralSearchFilter()`: Handles general search functionality  
- `setupSorting()`: Manages multi-level sorting criteria

This approach makes the API more flexible and maintainable while staying compatible with React Admin's simple REST data provider.
