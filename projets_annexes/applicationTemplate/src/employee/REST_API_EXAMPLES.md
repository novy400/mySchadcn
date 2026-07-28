# Employee REST API - React Admin Simple REST Provider

This document provides examples of REST API endpoints for the Employee management system, compatible with React Admin Simple REST Provider.

## Base URL

Assuming your server runs on `http://localhost:8080` and the API endpoint is `/api/employees`

## API Endpoints

### 1. Get List of Employees (with pagination)

#### Basic List

```
GET http://localhost:8080/api/employees
```

#### With Pagination (React Admin Simple REST)

```
GET http://localhost:8080/api/employees?page=1&perPage=10
```

#### With Pagination (React Admin Classic)

```
GET http://localhost:8080/api/employees?_page=1&_limit=10
```

#### With Sorting

```
GET http://localhost:8080/api/employees?page=1&perPage=10&sort=nom&order=ASC
GET http://localhost:8080/api/employees?page=1&perPage=10&sort=dateEmbauche&order=DESC
```

#### With Filtering

```
# Filter by service
GET http://localhost:8080/api/employees?page=1&perPage=10&service=IT

# Filter by multiple fields
GET http://localhost:8080/api/employees?page=1&perPage=10&service=IT&genre=M

# Filter by name
GET http://localhost:8080/api/employees?page=1&perPage=10&nom=Smith
```

#### With Search Term

```
GET http://localhost:8080/api/employees?page=1&perPage=10&q=john
```

#### Combined Parameters

```
GET http://localhost:8080/api/employees?page=2&perPage=5&sort=nom&order=ASC&service=IT&q=manager
```

### 2. Get Single Employee

#### Get by ID

```
GET http://localhost:8080/api/employees/EMP001
```

### 3. Create New Employee

#### POST Request

```
POST http://localhost:8080/api/employees
Content-Type: application/json

{
  "prenom": "John",
  "nom": "Doe",
  "initiale": "JD",
  "service": "IT",
  "dateEmbauche": "2024-01-15",
  "dateNaissance": "1990-05-20",
  "genre": "M",
  "salaire": 75000
}
```

### 4. Update Employee

#### PUT Request

```
PUT http://localhost:8080/api/employees/EMP001
Content-Type: application/json

{
  "id": "EMP001",
  "prenom": "John",
  "nom": "Smith",
  "initiale": "JS",
  "service": "IT",
  "dateEmbauche": "2024-01-15",
  "dateNaissance": "1990-05-20",
  "genre": "M",
  "salaire": 80000
}
```

### 5. Delete Employee

#### DELETE Request

```
DELETE http://localhost:8080/api/employees/EMP001
```

## Response Format

### List Response

```json
[
  {
    "id": "EMP001",
    "prenom": "John",
    "nom": "Doe",
    "initiale": "JD",
    "service": "IT"
  },
  {
    "id": "EMP002",
    "prenom": "Jane",
    "nom": "Smith",
    "initiale": "JS",
    "service": "HR"
  }
]
```

**Important Headers:**

- `X-Total-Count: 150` (total number of records for pagination)
- `Access-Control-Expose-Headers: X-Total-Count` (for CORS)

### Single Employee Response

```json
{
  "id": "EMP001",
  "prenom": "John",
  "nom": "Doe",
  "initiale": "JD",
  "service": "IT",
  "dateEmbauche": "2024-01-15",
  "dateNaissance": "1990-05-20",
  "genre": "M",
  "salaire": 75000
}
```

## Testing with curl

### Get List with Pagination

```bash
curl -X GET "http://localhost:8080/api/employees?page=1&perPage=5" \
  -H "Accept: application/json"
```

### Get List with Filtering

```bash
curl -X GET "http://localhost:8080/api/employees?service=IT&sort=nom&order=ASC" \
  -H "Accept: application/json"
```

### Create Employee

```bash
curl -X POST "http://localhost:8080/api/employees" \
  -H "Content-Type: application/json" \
  -d '{
    "prenom": "Alice",
    "nom": "Johnson",
    "initiale": "AJ",
    "service": "Marketing",
    "dateEmbauche": "2024-03-01",
    "dateNaissance": "1992-08-15",
    "genre": "F",
    "salaire": 65000
  }'
```

### Update Employee

```bash
curl -X PUT "http://localhost:8080/api/employees/EMP001" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "EMP001",
    "prenom": "John",
    "nom": "Doe-Updated",
    "initiale": "JD",
    "service": "IT",
    "salaire": 85000
  }'
```

### Delete Employee

```bash
curl -X DELETE "http://localhost:8080/api/employees/EMP001"
```

## Filter Fields Supported

Based on the `empres_supportedFields` array:

- `nom` - Last name
- `prenom` - First name
- `initiale` - Initials
- `service` - Department/Service
- `genre` - Gender
- `dateEmbauche` - Hire date
- `dateNaissance` - Birth date
- `salaire` - Salary
- `id` - Employee ID

## React Admin Integration

For React Admin, use the Simple REST Data Provider:

```javascript
import simpleRestProvider from 'ra-data-simple-rest';

const dataProvider = simpleRestProvider('http://localhost:8080/api');

// The data provider will automatically format requests like:
// GET /employees?page=1&perPage=10&sort=nom&order=ASC&service=IT
```

## Notes

- All responses include CORS headers for frontend access
- The `X-Total-Count` header is crucial for React Admin pagination
- Date formats should be ISO format (YYYY-MM-DD)
- Numeric fields (salaire) should be sent as numbers, not strings
- The API supports both React Admin simple REST and classic parameter formats
