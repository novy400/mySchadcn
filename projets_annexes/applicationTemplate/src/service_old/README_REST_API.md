# Service REST API

This REST API is compatible with React Admin's simple REST data provider and follows the pattern established by the championws.sqlrpgmod example.

## Features

- Full CRUD operations for Services
- React Admin compatible endpoints
- CORS support for web applications
- JSON request/response format
- Pagination support
- Search and filtering capabilities

## Endpoints

### GET /api/Services
List Services with pagination and filtering.

**Query Parameters:**
- `_page`: Page number (default: 1)
- `_limit`: Items per page (default: 10)
- `_sort`: Primary sort field (default: nom)
- `_order`: Primary sort order ASC/DESC (default: ASC)
- `q`: General search term

**Dynamic Filtering:**
Filter by any Service field by using the field name as parameter:
- `nom`: Filter by deptnamelast name
- `manager_id`: Filter by manager link to employee by manager_id
- `id`: Filter by Service ID (deptno)

**Multi-level Sorting:**
Support for multiple sort criteria:
- `sort1`, `order1`: Additional sort field and order
- `sort2`, `order2`: Second additional sort field and order
- `sort3`, `order3`: Third additional sort field and order
- `sort4`, `order4`: Fourth additional sort field and order

**Examples:**
- `/api/Services?nom=Smith&service=IT&_sort=dateEmbauche&_order=DESC`
- `/api/Services?q=john&_sort=nom&sort1=dateEmbauche&order1=ASC`
- `/api/Services?service=IT&genre=M&_page=2&_limit=5`

**Response Headers:**
- `X-Total-Count`: Total number of records
- `Access-Control-Expose-Headers`: X-Total-Count

### GET /api/Services/{id}
Get Service details by ID.

### POST /api/Services
Create a new Service.

**Request Body:** JSON Service object

### PUT /api/Services/{id}
Update an existing Service.

**Request Body:** JSON Service object

### DELETE /api/Services/{id}
Delete an Service by ID.

### OPTIONS /api/Services/*
CORS preflight handler.

## JSON Structure

### Service Object
```json
{
  "id": "A00",
  "nom": "SPIFFY COMPUTER SERVICE DIV.",
  "manager_id": "000010",
  "servicePrincipal_id": "C01",
}
```

## Files Structure

- `Service.rest.sqlrpgle`: REST endpoint handlers
- `Service.route.sqlrpgle`: Route definitions and prototypes
- `Service.main.sqlrpgle`: Main server program
- `Service.sqlrpgle`: Business logic procedures
- `Service.rpgleinc`: Data structures and prototypes

## Usage

1. Compile the service modules
2. Run the main program to start the HTTP server
3. Server will listen on port 35801
4. Use with React Admin simple REST data provider

## Modular Design

The `Services_list` endpoint now features a modular design that dynamically handles:

1. **Dynamic Filtering**: Automatically processes query parameters for any supported Service field
2. **Multi-level Sorting**: Supports primary sort (React Admin) plus up to 4 additional sort criteria
3. **General Search**: Special handling for the `q` parameter for cross-field searching
4. **Extensible**: Easy to add new filterable fields by updating the `supportedFields` compile-time data

### Internal Architecture

The modular design uses helper functions:
- `setupFilters()`: Dynamically processes all filter parameters
- `setupGeneralSearchFilter()`: Handles general search functionality  
- `setupSorting()`: Manages multi-level sorting criteria

This approach makes the API more flexible and maintainable while staying compatible with React Admin's simple REST data provider.
