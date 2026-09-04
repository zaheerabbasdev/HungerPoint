# HUNGERPOINT — FINAL DEVELOPMENT MASTER PROMPT

## 1. PROJECT OVERVIEW

Build a complete, production-ready multi-branch fast-food restaurant platform called **HungerPoint**.

HungerPoint will support:

- Customer mobile ordering
- Customer web ordering
- Multiple restaurant branches
- Central administration
- Branch management
- Kitchen/KDS operations
- POS
- Rider/delivery management
- Inventory
- Menu management
- Promotions
- Coupons
- Loyalty
- Reviews and ratings
- Real-time order tracking
- Reports and analytics

HungerPoint should be an independent product with its own branding, UI, architecture, business logic, and implementation.



---

# 2. FINAL APPLICATION STRUCTURE

The project will contain exactly:

### 1. Customer Mobile App

```text
hpcustomer
```

Technology:

```text
Flutter
Dart
```

Purpose:

Customer-facing mobile ordering application.

---

### 2. Rider Mobile App

```text
hprider
```

Technology:

```text
Flutter
Dart
```

Purpose:

Delivery rider application.

---

### 3. Web Application

```text
hpweb
```

Technology:

```text
Next.js
TypeScript
React
```

This is **ONE combined web application**.

It must contain all web-based interfaces:

```text
Customer Web
Admin Dashboard
Branch Dashboard
Kitchen/KDS
POS
Inventory
Rider Management
Reports
Promotions
Loyalty
Reviews
Settings
```

Do NOT create separate projects for these.

---

### 4. Backend

```text
hpbackend
```

Technology:

```text
Node.js
Express.js
TypeScript
Prisma
Socket.IO
```

---

### 5. Database

```text
MySQL
```

ORM:

```text
Prisma
```

---

# 3. FINAL ARCHITECTURE

The final system must follow:

```text
                         HUNGERPOINT
                              │
             ┌────────────────┴────────────────┐
             │                                 │
        MOBILE APPS                         WEB APP
             │                                 │
     ┌───────┴────────┐          ┌─────────────┼─────────────┐
     │                │          │             │             │
hpcustomer         hprider   Customer       Admin        Branch
 Flutter            Flutter     Web         Dashboard     Dashboard
                                  │
                                  ├── Kitchen
                                  ├── POS
                                  ├── Inventory
                                  ├── Riders
                                  ├── Reports
                                  ├── Promotions
                                  ├── Loyalty
                                  └── Settings
             │                                 │
             └────────────────┬────────────────┘
                              │
                         hpbackend
                              │
                  ┌───────────┴───────────┐
                  │                       │
                Prisma                Socket.IO
                  │                       │
                MySQL              Real-Time Events
```

---

# 4. IMPORTANT ARCHITECTURE DECISION

Do NOT create:

```text
hpkitchen
hppos
hpadmin
hpbranch
hpinventory
hpreports
```

These are NOT separate applications.

They are modules inside:

```text
hpweb
```

For example:

```text
hpweb/

├── Customer Web
├── Admin
├── Branch
├── Kitchen
├── POS
├── Inventory
├── Rider Management
├── Reports
└── Settings
```

This architecture should be followed throughout development.

---

# 5. EXISTING PROJECTS

The following projects already exist:

```text
hpcustomer
hprider
```

An existing Next.js web project also exists.

Use the existing Next.js project as:

```text
hpweb
```

If the folder is not currently named `hpweb`, do not blindly recreate it. Inspect the project first and either continue using it or rename/reorganize it safely.

The previous:

```text
hpkitchen
```

has been deleted.

Therefore, **do not attempt to recreate the old Kitchen Flutter application**.

Kitchen will now be developed directly inside:

```text
hpweb/kitchen
```

or an equivalent Next.js route/module.

---

# 6. FIRST TASK — INSPECT EXISTING PROJECTS

Before writing implementation code:

### Inspect:

```text
hpcustomer
hprider
Existing Next.js project
```

Determine:

- Existing architecture
- Existing UI
- Existing dependencies
- Existing authentication
- Existing API integration
- Existing components
- Existing state management
- Existing routing
- Existing models
- Existing reusable code

Do not delete working code unnecessarily.

Do not recreate an existing application from scratch without first inspecting it.

Preserve useful existing functionality.

---

# 7. TECHNOLOGY STACK

## Customer Mobile

```text
Flutter
Dart
REST API
Socket.IO
```

## Rider Mobile

```text
Flutter
Dart
REST API
Socket.IO
GPS/location services
```

## Web

```text
Next.js
React
TypeScript
Responsive UI
REST API
Socket.IO
```

## Backend

```text
Node.js
Express.js
TypeScript
Prisma
Socket.IO
```

## Database

```text
MySQL
```

---

# 8. HPWEB STRUCTURE

The main Next.js application should conceptually contain:

```text
hpweb/

├── app/
│
├── customer/
│
├── admin/
│
├── branch/
│
├── kitchen/
│
├── pos/
│
├── inventory/
│
├── riders/
│
├── reports/
│
├── promotions/
│
├── loyalty/
│
├── reviews/
│
└── settings/
```

The exact Next.js App Router structure can be adjusted according to best practices, but these responsibilities must remain separated logically.

---

# 9. CUSTOMER WEB

Customer Web must provide the same HungerPoint design system as `hpcustomer`.

Features:

### Authentication

- Register
- Login
- Logout
- Forgot password
- OTP where required
- Profile

### Home

- HungerPoint branding
- Search
- Categories
- Featured products
- Popular products
- Promotions
- Branch information

### Menu

- Categories
- Products
- Product details
- Variants
- Add-ons
- Quantity
- Special instructions

### Cart

- Products
- Quantity
- Add-ons
- Subtotal
- Discount
- Delivery fee
- Tax
- Grand total

### Checkout

- Delivery address
- Pickup
- Delivery
- Coupon
- Payment
- Order summary
- Place order

### Orders

- Active orders
- Order history
- Order details
- Tracking
- Reorder
- Rating

---

# 10. KITCHEN / KDS

Kitchen will be a module inside `hpweb`.

Route:

```text
/kitchen
```

The Kitchen Display System must be optimized for:

- Tablets
- Touch screens
- Desktop monitors
- Large displays

Main columns:

```text
NEW
PREPARING
READY
```

Example:

```text
NEW
│
├── #1001
├── #1002
└── #1003

PREPARING
│
├── #998
└── #999

READY
│
└── #997
```

Kitchen actions:

```text
Accept
Start Preparing
Mark Ready
Reject
```

New orders must appear automatically through Socket.IO.

No page refresh should be required.

Kitchen staff should only see relevant branch orders.

---

# 11. POS

POS will also be a module inside `hpweb`.

Route:

```text
/pos
```

Features:

- New order
- Product selection
- Categories
- Product customization
- Add-ons
- Quantity
- Customer selection
- Walk-in customer
- Pickup
- Delivery
- Cash payment
- Discounts
- Order confirmation
- Receipt
- Order history

POS must use the same central backend Order Service.

Do NOT create separate POS order logic.

---

# 12. ADMIN

Route:

```text
/admin
```

Admin can manage:

### Dashboard

- Sales
- Orders
- Revenue
- Branch performance
- Customers
- Riders
- Inventory alerts
- Popular products

### Branches

- Create branch
- Edit branch
- Activate/deactivate
- Address
- Coordinates
- Opening hours
- Delivery radius
- Employees

### Products

- Categories
- Products
- Variants
- Add-ons
- Prices
- Images
- Availability

### Orders

View all order sources:

```text
Mobile
Website
POS
Phone
```

### Customers

- Customers
- Addresses
- Orders
- Reviews
- Loyalty

### Riders

- Riders
- Availability
- Assignments
- Performance

### Inventory

- Stock
- Transfers
- Waste
- Consumption
- Low-stock alerts

### Reports

- Sales
- Orders
- Branches
- Products
- Riders
- Customers
- Inventory

---

# 13. BRANCH DASHBOARD

Route:

```text
/branch
```

A Branch Manager should only access their assigned branch.

Dashboard:

```text
Branch Dashboard
├── Sales
├── Orders
├── Kitchen
├── Inventory
├── Employees
├── Products
└── Reports
```

Branch users must not access other branches unless explicitly authorized.

---

# 14. RIDER MANAGEMENT

Route:

```text
/riders
```

Admin/authorized branch users can:

- Create riders
- Edit riders
- Activate/deactivate
- View availability
- View current delivery
- Assign orders
- View delivery history
- View performance

The actual rider uses:

```text
hprider
```

---

# 15. INVENTORY

Route:

```text
/inventory
```

Inventory must be branch-specific.

Support:

```text
Inventory Items
Stock
Stock In
Stock Out
Consumption
Waste
Adjustment
Transfers
Low Stock
```

Prefer ingredient-based inventory.

Example:

```text
Burger
├── Bun
├── Beef Patty
├── Cheese
├── Sauce
└── Lettuce
```

Products can have recipes.

---

# 16. ORDER SOURCES

The backend must support:

```text
MOBILE_APP
WEBSITE
POS
PHONE
```

All sources use the same Order Service.

Do NOT create separate order processing logic for:

- Mobile
- Website
- POS

---

# 17. ORDER LIFECYCLE

Use a controlled state machine:

```text
PENDING
↓
CONFIRMED
↓
ACCEPTED
↓
PREPARING
↓
READY
↓
ASSIGNED
↓
PICKED_UP
↓
OUT_FOR_DELIVERY
↓
DELIVERED
↓
COMPLETED
```

Alternative statuses:

```text
CANCELLED
REJECTED
PAYMENT_FAILED
REFUNDED
```

Invalid transitions must be rejected by the backend.

Store complete order status history.

---

# 18. BRANCH ROUTING

When an order is created, the backend determines the correct branch.

Consider:

- Distance
- Delivery radius
- Branch status
- Opening hours
- Product availability
- Kitchen workload
- Estimated preparation time
- Rider availability
- Estimated delivery time

Do not simply select the nearest branch.

Backend is the source of truth.

---

# 19. MENU

Entities:

```text
Category
Product
ProductVariant
Addon
ProductAddon
BranchProduct
```

Products may be:

```text
Available
Unavailable
Out of stock
Branch-specific
```

Backend controls prices and availability.

---

# 20. PRICING

Never trust frontend prices.

Backend calculates:

```text
Product price
Variant price
Addon price
Quantity
Subtotal
Discount
Tax
Delivery fee
Grand total
```

Store historical price snapshots in orders.

Changing a product price must NOT change previous orders.

---

# 21. PAYMENT

Initially:

```text
Cash on Delivery
POS Cash
```

Design for future:

```text
Card
JazzCash
Easypaisa
Other gateways
```

Online payment must be verified server-side.

Never trust only a frontend success response.

---

# 22. RIDER APP

`hprider` must support:

### Login

- Login
- Logout
- Profile

### Availability

```text
ONLINE
OFFLINE
```

### Delivery

```text
ASSIGNED
↓
ACCEPTED
↓
PICKED_UP
↓
OUT_FOR_DELIVERY
↓
DELIVERED
```

### Location

During active delivery:

- Send GPS updates
- Update backend
- Customer can see delivery progress

Do not unnecessarily track riders when they are offline.

---

# 23. REAL-TIME SOCKET.IO

Use Socket.IO between:

```text
hpcustomer
hprider
hpweb
hpbackend
```

Events:

```text
order.created
order.confirmed
order.accepted
order.preparing
order.ready
order.assigned
order.picked_up
order.out_for_delivery
order.delivered
rider.location_updated
rider.assignment_created
inventory.low_stock
```

Kitchen should receive new orders in real time.

Customer should receive order status updates in real time.

Rider should receive assignments in real time.

---

# 24. NOTIFICATIONS

Support:

- Push notifications
- In-app notifications
- Email where appropriate

Customer:

```text
Order confirmed
Order accepted
Preparing
Ready
Rider assigned
Out for delivery
Delivered
```

Rider:

```text
New delivery assignment
```

Kitchen:

```text
New order
```

Admin:

```text
Important alerts
```

---

# 25. PROMOTIONS

Support:

```text
Percentage discounts
Fixed discounts
Minimum order amount
Maximum discount
Product-specific discounts
Category-specific discounts
Branch-specific discounts
Expiry
Usage limits
Customer-specific promotions
```

All coupon validation happens on the backend.

---

# 26. LOYALTY

Support:

```text
LoyaltyAccount
LoyaltyTransaction
```

Features:

- Earn points
- Redeem points
- Balance
- History

Loyalty must not block the core ordering flow.

---

# 27. REVIEWS

Customers can review completed orders.

Support:

```text
Order rating
Product rating
Branch rating
Comment
```

Only valid/completed orders can be reviewed.

---

# 28. DATABASE MODELS

Use Prisma + MySQL.

Core models:

```text
User
Role
Permission

Customer
Address

Employee

Branch
BranchEmployee
BranchHours
DeliveryZone

Category
Product
ProductVariant
Addon
ProductAddon
BranchProduct

Cart
CartItem

Order
OrderItem
OrderItemAddon
OrderStatusHistory

Payment
PaymentTransaction

Delivery
Rider
RiderLocation

InventoryItem
InventoryStock
InventoryTransaction

Recipe
RecipeItem
StockTransfer

Coupon
Promotion

Review
Rating

LoyaltyAccount
LoyaltyTransaction

Notification

AuditLog
SystemSetting
```

Use:

- Foreign keys
- Indexes
- Unique constraints
- Appropriate relations
- Timestamps
- Soft deletion where useful

---

# 29. BACKEND STRUCTURE

Recommended:

```text
hpbackend/

src/
├── config/
├── middleware/
├── routes/
├── controllers/
├── services/
├── repositories/
├── validators/
├── utils/
├── sockets/
├── jobs/
│
├── modules/
│   ├── auth/
│   ├── users/
│   ├── customers/
│   ├── branches/
│   ├── products/
│   ├── orders/
│   ├── payments/
│   ├── kitchen/
│   ├── riders/
│   ├── delivery/
│   ├── inventory/
│   ├── promotions/
│   ├── loyalty/
│   ├── reviews/
│   ├── notifications/
│   ├── reports/
│   └── audit/
│
└── app.ts

prisma/
└── schema.prisma
```

Business logic should live in services/modules rather than route controllers.

---

# 30. API

Use:

```text
/api/v1/auth
/api/v1/users
/api/v1/customers
/api/v1/branches
/api/v1/categories
/api/v1/products
/api/v1/cart
/api/v1/orders
/api/v1/payments
/api/v1/kitchen
/api/v1/riders
/api/v1/deliveries
/api/v1/inventory
/api/v1/promotions
/api/v1/coupons
/api/v1/reviews
/api/v1/loyalty
/api/v1/notifications
/api/v1/reports
```

Use proper HTTP status codes and consistent API responses.

---

# 31. AUTHENTICATION AND RBAC

Roles:

```text
CUSTOMER
RIDER
KITCHEN_STAFF
BRANCH_MANAGER
BRANCH_STAFF
ADMIN
SUPER_ADMIN
```

Backend must enforce permissions.

Frontend route protection alone is NOT sufficient.

For example:

```text
/kitchen
```

must only be accessible to authorized kitchen/branch/admin users.

```text
/pos
```

must only be accessible to authorized POS staff.

```text
/admin
```

must only be accessible to authorized administrators.

---

# 32. SECURITY

Implement:

- Secure password hashing
- JWT/session security
- Refresh tokens where appropriate
- RBAC
- Input validation
- Rate limiting
- CORS
- HTTPS in production
- Secure cookies where applicable
- Environment variables
- Payment webhook verification
- Audit logs

Never expose secrets in frontend applications.

---

# 33. UI/UX DESIGN SYSTEM

Create a single HungerPoint design system.

Shared design language:

```text
Colors
Typography
Spacing
Buttons
Inputs
Cards
Badges
Tables
Dialogs
Navigation
Icons
Loading states
Error states
Empty states
```

### Customer

Modern, attractive, food-focused.

### Admin

Professional, information-focused.

### Kitchen

Fast, large, touch-friendly.

### POS

Fast, touch-friendly and optimized for order entry.

### Branch

Operational and easy to understand.

All interfaces should feel like one HungerPoint ecosystem.

---

# 34. CUSTOMER APP + CUSTOMER WEB

The Flutter Customer App and Next.js Customer Web must have the same:

- Branding
- Colors
- Typography
- Product presentation
- Button style
- Card style
- Navigation language
- UX patterns

They do NOT need identical screen layouts.

Mobile should use mobile-native layouts.

Web should use responsive desktop layouts.

---

# 35. RESPONSIVE WEB

`hpweb` must support:

```text
Mobile
Tablet
Laptop
Desktop
Large displays
```

Kitchen should be optimized for large displays/tablets.

POS should support touch and desktop.

Admin should prioritize desktop/tablet.

Customer Web must be fully responsive.

---

# 36. TESTING

### Unit Tests

Test:

```text
Pricing
Coupons
Branch routing
Order state machine
Inventory
Permissions
```

### Integration Tests

Test:

```text
Authentication
Order creation
Payments
Inventory
Delivery
Notifications
```

### End-to-End Tests

Test:

```text
Customer App
↓
Backend
↓
Branch
↓
Kitchen
↓
Rider
↓
Customer
```

Also:

```text
Customer Web
↓
Backend
↓
Kitchen
↓
Rider
```

And:

```text
POS
↓
Backend
↓
Kitchen
```

---

# 37. DEVELOPMENT ORDER

Follow this sequence.

## PHASE 1

Backend foundation:

```text
Node.js
Express
TypeScript
Prisma
MySQL
Auth
Users
Roles
Permissions
Branches
Categories
Products
Addresses
```

## PHASE 2

Order system:

```text
Cart
Orders
Pricing
Order states
Order history
```

## PHASE 3

`hpweb` foundation:

```text
Authentication
Shared design system
Customer Web
Admin
Branch
```

## PHASE 4

Customer:

```text
hpcustomer
Customer Web
```

Connect both to backend.

## PHASE 5

Kitchen:

```text
hpweb/kitchen
```

Build KDS with Socket.IO.

## PHASE 6

POS:

```text
hpweb/pos
```

## PHASE 7

Rider:

```text
hprider
```

Connect:

```text
Delivery
Assignments
GPS
Socket.IO
```

## PHASE 8

Inventory:

```text
Stock
Recipes
Consumption
Transfers
Waste
Alerts
```

## PHASE 9

Business features:

```text
Coupons
Promotions
Loyalty
Reviews
Notifications
Reports
Analytics
```

## PHASE 10

Production:

```text
Security
Testing
Logging
Monitoring
Backups
Performance
CI/CD
Deployment
```

---

# 38. MVP

Do not build every feature first.

The first working MVP must support:

### Customer

```text
Register/Login
↓
Browse Menu
↓
Product
↓
Cart
↓
Checkout
↓
COD
↓
Order
↓
Track Order
```

### Kitchen

```text
Receive Order
↓
Accept
↓
Preparing
↓
Ready
```

### Rider

```text
Assignment
↓
Accept
↓
Pickup
↓
Out for Delivery
↓
Delivered
```

### Admin

```text
Branches
Products
Orders
Customers
Riders
Basic Reports
```

### POS

```text
Create Order
↓
Select Products
↓
Cash
↓
Confirm
↓
Kitchen
```

---

# 39. DO NOT START WITH AI

Do not initially implement:

- AI chatbot
- AI recommendations
- Demand prediction
- AI inventory forecasting
- Advanced route optimization

First make the core restaurant system reliable.

AI can be added later.

---

# 40. PERFORMANCE

Optimize:

- Database queries
- Prisma queries
- API responses
- Images
- Pagination
- Lazy loading
- Caching
- Socket connections
- Flutter network usage

Do not load thousands of records at once.

---

# 41. ENVIRONMENT VARIABLES

Never hardcode secrets.

Example:

```text
DATABASE_URL=
JWT_SECRET=
JWT_REFRESH_SECRET=
NEXT_PUBLIC_API_URL=
SOCKET_URL=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
GOOGLE_MAPS_API_KEY=
```

Use:

```text
development
staging
production
```

---

# 42. DOCUMENTATION

Create:

```text
README
Architecture Documentation
Database Documentation
ERD
API Documentation
Authentication Documentation
RBAC Documentation
Order Lifecycle Documentation
Socket.IO Documentation
Deployment Documentation
Environment Variables Documentation
Testing Documentation
```

---

# 43. FINAL REPOSITORY STRUCTURE

The final workspace should be:

```text
HUNGERPOINT/
│
├── hpcustomer/
│   └── Flutter Customer App
│
├── hprider/
│   └── Flutter Rider App
│
├── hpweb/
│   └── Next.js Web Platform
│       │
│       ├── Customer Web
│       ├── Admin
│       ├── Branch
│       ├── Kitchen
│       ├── POS
│       ├── Inventory
│       ├── Riders
│       ├── Promotions
│       ├── Loyalty
│       ├── Reviews
│       ├── Reports
│       └── Settings
│
├── hpbackend/
│   └── Node.js Backend
│
└── documentation/
```

There should be **no separate ****`hpkitchen`**** project**.

There should be **no separate ****`hppos`**** project**.

There should be **no separate ****`hpadmin`**** project**.

There should be **no separate ****`hpbranch`**** project**.

All web functionality belongs inside `hpweb`.

---

# 44. FIRST DEVELOPMENT TASK

Before writing large amounts of code, produce:

### 1. Architecture

Explain:

```text
hpcustomer
hprider
hpweb
hpbackend
MySQL
Prisma
Socket.IO
```

### 2. Database ERD

Show all major relationships.

### 3. Prisma Schema Plan

Define models, fields, relations, enums and indexes.

### 4. API Specification

List all API endpoints.

### 5. RBAC

Define roles and permissions.

### 6. Order State Machine

Define valid and invalid transitions.

### 7. Socket.IO Events

Define real-time events.

### 8. HPWEB Route Structure

Define:

```text
/customer
/admin
/branch
/kitchen
/pos
/inventory
/riders
/reports
/settings
```

### 9. Flutter Architecture

Define architecture for:

```text
hpcustomer
hprider
```

### 10. Development Roadmap

Break the entire implementation into small, testable milestones.

Do not start massive implementation until the architecture is consistent.

---

# 45. CORE DEVELOPMENT PRINCIPLE

The backend is the source of truth.

Never trust:

```text
Frontend prices
Frontend permissions
Frontend order status
Frontend branch selection
Frontend payment confirmation
```

All critical business logic must be validated by `hpbackend`.

Do not duplicate business logic across applications.

The final goal is a clean architecture:

```text
2 Flutter Apps
+
1 Next.js Web Platform
+
1 Node.js Backend
+
1 MySQL Database
```

This is the official HungerPoint architecture and should be followed throughout development.
