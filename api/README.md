# PharmaVault REST API

Standalone PHP/MySQL REST API for the PharmaVault Flutter mobile app.  
All responses use the same JSON envelope:

```json
{
  "status":  "success" | "error",
  "message": "Human-readable description",
  "data":    { ... } | [ ... ] | null
}
```

---

## Setup

1. Install the JWT library (one-time):
   ```bash
   composer install
   ```
2. Edit `api/config/database.php` to match your server credentials.
3. Change `JWT_SECRET` in `api/config/database.php` to a long random string before deploying to production.
4. Ensure the `uploads/prescriptions/` folder is writable by the web server.

---

## Authentication

Protected endpoints require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <token>
```

Obtain a token by calling `POST /api/v1/auth/login`.  
Tokens are signed HS256 JWTs and expire after **7 days**.

---

## Endpoints

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/auth/login` | No | Authenticate and receive a JWT token |
| `POST` | `/api/v1/auth/register` | No | Register a new customer account |

---

#### POST `/api/v1/auth/login`

**Request body (JSON):**
```json
{
  "email":    "jane@example.com",
  "password": "secret"
}
```

**Success response (200):**
```json
{
  "status": "success",
  "data": {
    "token":          "eyJ...",
    "expires_in":     604800,
    "customer_id":    1,
    "customer_name":  "Jane Doe",
    "customer_email": "jane@example.com",
    "user_role":      2
  }
}
```

**Error codes:** `401` invalid credentials · `422` missing fields · `500` server error

---

#### POST `/api/v1/auth/register`

**Request body (JSON):**
```json
{
  "customer_name":    "Jane Doe",
  "customer_email":   "jane@example.com",
  "customer_pass":    "secret123",
  "customer_contact": "+233200000000",
  "customer_country": "Ghana",
  "customer_city":    "Accra"
}
```

**Success response (201):**
```json
{ "status": "success", "data": { "customer_id": 42 } }
```

**Error codes:** `409` email already exists · `422` missing / invalid fields · `500` server error

---

### Products

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/products` | **Yes** | List all products with optional filters |
| `GET` | `/api/v1/products/show` | **Yes** | Get a single product by ID |

---

#### GET `/api/v1/products`

**Query parameters (all optional):**

| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Full-text search across title, description, keywords |
| `cat_id` | int | Filter by category ID |
| `brand_id` | int | Filter by brand ID |
| `limit` | int | Maximum number of results |

Priority when multiple params are given: `search > cat_id > brand_id > all`.

**Success response (200):** Array of product objects, each including `cat_name` and `brand_name`.

---

#### GET `/api/v1/products/show?id={product_id}`

**Query parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | int | Yes | Product ID |

**Error codes:** `404` not found · `422` missing/invalid id

---

### Categories

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/categories` | No | List all product categories |

**Success response (200):** Array of `{ cat_id, cat_name, cat_description, created_at }`.

---

### Brands

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/brands` | No | List all brands, optionally filtered by category |

**Query parameters (optional):**

| Param | Type | Description |
|-------|------|-------------|
| `cat_id` | int | Return only brands belonging to this category |

**Success response (200):** Array of `{ brand_id, brand_name, cat_id, cat_name, brand_description, created_at }`.

---

### Pharmacies

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/pharmacies` | No | List all registered pharmacies |

Returns customers with `user_role = 1`.

**Success response (200):** Array of `{ customer_id, customer_name, customer_city, customer_contact, customer_image }`.

---

### Cart

All cart endpoints require JWT.  
Cart items are identified by `product_id` (the `cart` table has no separate `cart_id` column).

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/cart` | **Yes** | Get all cart items for the logged-in customer |
| `POST` | `/api/v1/cart/add` | **Yes** | Add a product to cart (increments if already present) |
| `PUT` | `/api/v1/cart/update` | **Yes** | Update qty; set to 0 to remove |
| `DELETE` | `/api/v1/cart/remove` | **Yes** | Remove a product from cart |

---

#### GET `/api/v1/cart`

**Success response (200):**
```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "product_id": 5,
        "qty": 2,
        "product_title": "Panadol Extra",
        "product_price": "12.50",
        "product_image": "uploads/...",
        "product_stock": 20,
        "line_total": "25.00",
        "cat_name": "Pain Relief",
        "brand_name": "Panadol"
      }
    ],
    "item_count": 1,
    "cart_total": 25.0
  }
}
```

---

#### POST `/api/v1/cart/add`

**Request body (JSON):**
```json
{ "product_id": 5, "qty": 2 }
```
`qty` defaults to `1` if omitted.

**Error codes:** `404` product not found · `409` out of stock · `422` missing product_id

---

#### PUT `/api/v1/cart/update`

**Request body (JSON):**
```json
{ "product_id": 5, "qty": 3 }
```
Setting `qty` to `0` removes the item.

**Error codes:** `404` item not in cart · `422` missing/invalid fields

---

#### DELETE `/api/v1/cart/remove`

**Request body (JSON):**
```json
{ "product_id": 5 }
```

**Error codes:** `404` item not in cart · `422` missing product_id

---

### Orders

All order endpoints require JWT.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/orders` | **Yes** | List all orders for the logged-in customer |
| `GET` | `/api/v1/orders/show` | **Yes** | Full detail of a single order including items |
| `POST` | `/api/v1/orders/create` | **Yes** | Create order from current cart, then clear cart |

---

#### GET `/api/v1/orders`

**Success response (200):** Array of order summaries, each including `order_total`, `payment_amount`, `is_paid` (boolean).

---

#### GET `/api/v1/orders/show?order_id={id}`

**Query parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `order_id` | int | Yes | Order ID |

**Success response (200):**
```json
{
  "status": "success",
  "data": {
    "order": { "order_id": 1, "invoice_no": 2025041300001, "order_status": "pending", ... },
    "items": [ { "product_id": 5, "qty": 2, "line_total": 25.0, ... } ],
    "order_total": 25.0,
    "item_count": 1
  }
}
```

**Error codes:** `403` order belongs to a different customer · `404` not found · `422` missing order_id

---

#### POST `/api/v1/orders/create`

**Request body (JSON):**
```json
{
  "delivery_address": "25 Main Street",
  "delivery_city":    "Accra",
  "delivery_contact": "+233200000000"
}
```

Delivery details are stored in `delivery_notes` as a JSON string (the `orders` table has no separate address columns).  
Cart is cleared automatically after the order is created.

**Success response (201):**
```json
{
  "status": "success",
  "data": {
    "order_id":   1,
    "invoice_no": 2025041300001,
    "item_count": 3,
    "status":     "pending"
  }
}
```

**Error codes:** `409` stock shortage · `422` empty cart or missing delivery fields · `500` server error

---

### Prescriptions

All prescription endpoints require JWT.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/prescriptions` | **Yes** | List all prescriptions for the logged-in customer |
| `POST` | `/api/v1/prescriptions/upload` | **Yes** | Upload a prescription image (multipart/form-data) |

---

#### GET `/api/v1/prescriptions`

**Query parameters (optional):**

| Param | Type | Description |
|-------|------|-------------|
| `status` | string | Filter by status: `pending` · `verified` · `rejected` · `expired` |

**Success response (200):** Array of prescription records for the customer.

---

#### POST `/api/v1/prescriptions/upload`

**Content-Type:** `multipart/form-data` (not JSON — this is a file upload)

**Form fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prescription_image` | file | **Yes** | JPEG / PNG / GIF / WebP, max 5 MB |
| `doctor_name` | string | No | Name of prescribing doctor |
| `doctor_license` | string | No | Doctor's license number |
| `issue_date` | string | No | Format: `YYYY-MM-DD` |
| `expiry_date` | string | No | Format: `YYYY-MM-DD` |
| `prescription_notes` | string | No | Any additional notes |
| `allow_pharmacy_access` | int | No | `1` (default) or `0` |

**Success response (201):**
```json
{
  "status": "success",
  "data": {
    "prescription_id":     7,
    "prescription_number": "RX-20250413-00001",
    "prescription_image":  "uploads/prescriptions/4/rx_1744531200_ab12cd34.jpg",
    "status":              "pending"
  }
}
```

**Error codes:** `422` missing file or invalid format/size · `500` server error

---

## Error Response Format

All errors follow the same structure:
```json
{
  "status":  "error",
  "message": "Descriptive error message.",
  "data":    null
}
```

Common HTTP codes used:

| Code | Meaning |
|------|---------|
| `200` | OK |
| `201` | Created |
| `400` | Bad request |
| `401` | Unauthorized (missing/invalid/expired JWT) |
| `403` | Forbidden (authenticated but not allowed) |
| `404` | Not found |
| `405` | Method not allowed |
| `409` | Conflict (duplicate email, out of stock) |
| `422` | Unprocessable — validation failed |
| `500` | Server error |

---

## File Structure

```
api/
├── config/
│   ├── database.php     # PDO singleton + JWT constants
│   └── cors.php         # CORS headers + OPTIONS preflight handler
├── middleware/
│   └── auth.php         # JWT Bearer token validation
├── utils/
│   └── response.php     # Response::success() / Response::error()
└── v1/
    ├── auth/
    │   ├── login.php
    │   └── register.php
    ├── products/
    │   ├── index.php
    │   └── show.php
    ├── categories/
    │   └── index.php
    ├── brands/
    │   └── index.php
    ├── pharmacies/
    │   └── index.php
    ├── cart/
    │   ├── index.php
    │   ├── add.php
    │   ├── update.php
    │   └── remove.php
    ├── orders/
    │   ├── index.php
    │   ├── show.php
    │   └── create.php
    └── prescriptions/
        ├── index.php
        └── upload.php
```
