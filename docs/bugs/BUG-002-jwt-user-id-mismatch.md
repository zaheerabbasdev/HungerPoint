# BUG-002: JWT Payload Field Mismatch in Customer & Order Controllers

## Bug ID
BUG-002

## Bug Title
JWT Payload Field Mismatch (`userId` vs `id`) Causing Undefined Customer IDs in Controllers

## Date
2026-09-07

## Severity
High

## Module
`hpbackend/modules/customers`, `hpbackend/modules/orders`

## Problem Description
Authenticated API endpoints under `/api/v1/customers/profile`, `/api/v1/customers/addresses`, and `/api/v1/orders` were returning 404 or creating records with `customerId: undefined` because the controllers were extracting `(req as any).user?.id` instead of `(req as any).user?.userId`.

## Symptoms
- Calling `GET /api/v1/customers/profile` with a valid customer Bearer token resulted in `404 Customer profile not found`.
- Calling `GET /api/v1/customers/addresses` returned an empty list or errored out with Prisma `where: { customerId: undefined }`.
- Order placement assigned orders to an undefined customer or failed foreign key constraints.

## Root Cause
In `src/middlewares/auth.middleware.ts`, when generating or verifying the JWT token, the decoded payload assigns:
```ts
req.user = {
  userId: user.id,
  role: user.role,
  branchId: user.branchId,
};
```
Notice the key name is `userId`. However, the newly developed customer controller (`customer.controller.ts`) and order controller (`order.controller.ts`) were expecting:
```ts
const customerId = (req as any).user?.id;
```
Because `req.user.id` was not defined on the JWT object, `customerId` evaluated to `undefined`.

## Reproduction Steps
1. Send `POST /api/v1/auth/login` with valid customer credentials (`+923139804929` / `Customer@123456`).
2. Copy the returned `accessToken`.
3. Send `GET /api/v1/customers/profile` with `Authorization: Bearer <accessToken>`.
4. Observe HTTP 404 response: `{"success": false, "message": "Customer profile not found"}` despite the customer existing in the database.

## Expected vs Actual Behavior
- **Expected Behavior**: Controller extracts the authenticated user's ID from the JWT token and fetches/modifies their customer record in MySQL.
- **Actual Behavior**: Controller evaluated `userId` as `undefined`, querying `WHERE userId = undefined` which returned `null`.

## Architecture Diagram (ASCII)
```
+-------------------------------------------------------------+
|                     Flutter Customer App                    |
+-------------------------------------------------------------+
                              |
                     HTTP Bearer Token
                              v
+-------------------------------------------------------------+
|              Express Middleware: auth.middleware            |
|              req.user = { userId: "...", role: "..." }      |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|             Customer / Order Controller                      |
|             OLD: const id = req.user?.id (UNDEFINED!)       |
|             NEW: const id = req.user?.userId                |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|               Prisma ORM -> MySQL (hungerpointdb)            |
|               prisma.customer.findUnique({ userId })        |
+-------------------------------------------------------------+
```

## Request/Response Communication Flow
```
Client                          Server (hpbackend)
  |                                     |
  |--- GET /api/v1/customers/profile -->|
  |    Authorization: Bearer <token>    |
  |                                     |-- Verify JWT: req.user.userId = "usr_123"
  |                                     |-- Read Customer where userId == "usr_123"
  |<-- 200 OK (Customer profile data) --|
```

## Sequence of Events
1. Authentication middleware successfully decrypts JWT token.
2. Token attaches `{ userId, role }` to `req.user`.
3. Controller attempts to read `req.user.id` which yields `undefined`.
4. Database lookup fails or throws error.
5. Fix applied: updated controller to read `req.user.userId ?? req.user.id`.

## Files Modified
- `d:\HungerPoint\hpbackend\src\modules\customers\customer.controller.ts`
- `d:\HungerPoint\hpbackend\src\modules\orders\order.controller.ts`

## Code Changes Summary
```ts
// Before
const userId = (req as any).user?.id;

// After
const userId = (req as any).user?.userId ?? (req as any).user?.id;
```

## Why the Fix Works
Checking both `req.user.userId` and `req.user.id` guarantees that regardless of whether the JWT middleware or custom mock test harness populates `userId` or `id`, the controller always receives a valid, non-null user identifier.

## Side Effects (if any)
None. The change is strictly backward-compatible and additive.

## Testing Performed
1. Tested `GET /api/v1/customers/profile` via HTTP curl against `http://localhost:5000/api/v1/customers/profile`:
   - Received `200 OK` with full customer profile for Zaheer Abbas.
2. Tested `POST /api/v1/customers/addresses` and `GET /api/v1/customers/addresses`:
   - Received `200 OK` with saved addresses matching `customerId`.

## Prevention Strategies
- Define a strict TypeScript interface `AuthenticatedRequest extends Request` with a strongly typed `user: JwtPayload` object so property access errors are caught at compile time.
- Standardize JWT token payload schema across all services in `hpbackend`.

## Lessons Learned
Never rely on loose `(req as any).user` casting without checking the exact payload shape defined in the auth middleware.

## Related Bugs
- BUG-001 (Maps intent package visibility)

## References
- `d:\HungerPoint\hpbackend\src\middlewares\auth.middleware.ts`
- `d:\HungerPoint\hpbackend\src\modules\customers\customer.controller.ts`
