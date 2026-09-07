# Bug Report: BUG-006-admin-categories-and-residual-mock-cleanup

## 1. Bug ID
BUG-006

## 2. Bug Title
Residual Mock Data in Branch/Cart Services and Missing Admin-Side Category Endpoint Ingestion

## 3. Date
2026-09-07

## 4. Severity
High

## 5. Module
`hpcustomer/screens` & `hpcustomer/services` (Home, Explore Menu, Cart, BranchService)

## 6. Problem Description
1. In `HomeScreen` (`home_tab.dart`), the 3x2 "Explore Menu" category grid was calling `ApiService.fetchProducts()` and mapping every individual product directly into category cards. If 10 burgers were returned, 10 duplicate "Gourmet Burgers" cards appeared in the grid instead of displaying distinct categories created on the admin/backend side.
2. The customer app was not consuming the dedicated admin category REST endpoint (`GET /api/v1/categories`) for categories with defined `sortOrder`, image, title, and metadata.
3. `BranchService` contained over 150 lines of static hardcoded mock category arrays (`_f10Categories`, `_swabiCategories`, `_f7Categories`) that were bound to branches and displayed in pickup mode.
4. `CartScreen` contained a static hardcoded `_recommendedItems` array ("Thin Crust Tikka", "Beef Pepperoni Pan Pizza", "Cheezy Sticks") instead of dynamically loading actual products.
5. In `pickup_branches_screen.dart` and `branches_tab.dart`, hardcoded references accessed `BranchService().branches` rather than `BranchService().allBranches` populated from `GET /api/v1/branches`.

## 7. Symptoms
- Explore Menu on Home Tab rendered duplicated product titles instead of actual menu categories.
- Tapping on a category card navigated inconsistently to explore tab categories.
- Cart screen always showed the same hardcoded recommendations regardless of database contents.
- Pickup mode displayed outdated hardcoded menu items rather than backend-synced menus.

## 8. Root Cause
- Category ingestion was implemented as an ad-hoc product grouping in `home_tab.dart` and `explore_tab.dart` without prioritizing `GET /api/v1/categories`.
- `BranchService` was originally written with static mock categories embedded in branch instances.
- `CartScreen` had hardcoded `_recommendedItems` left over from the initial UI mockup phase.

## 9. Reproduction Steps
1. Launch `hpbackend` (`npm run dev`) and `hpcustomer` (`flutter run`).
2. Navigate to Home Tab and observe the "Explore Menu" grid.
3. Add products to cart and open Cart Screen; inspect "More Products You May Love".
4. Switch to Pickup mode and view the branch menu categories.

## 10. Expected vs Actual Behavior
- **Expected**: "Explore Menu" on Home and Explore tabs loads real categories from `GET /api/v1/categories` in the exact `sortOrder` defined by the admin, Cart screen displays live recommended items, and all branch menus use live backend categories/products with zero hardcoded arrays.
- **Actual**: Category cards showed duplicate product names, Cart screen showed hardcoded items, and branches used static mock arrays.

## 11. Architecture Diagram (ASCII)
```
+-------------------------------------------------------------------------+
|                              Admin Side                                 |
|  (POST / PUT / DELETE /api/v1/categories - Managed by Admin User)       |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                       MySQL Database (hungerpointdb)                    |
|  Category Table (id, name, description, image, sortOrder, isActive)    |
|  Product Table  (id, categoryId, name, basePrice, images, ...)          |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  hpbackend (CategoryService & Controller)               |
|  GET /api/v1/categories  ---> returns sorted active categories          |
|  GET /api/v1/products    ---> returns products linked to categoryId     |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                       hpcustomer (Flutter Mobile App)                   |
|  - ApiService.fetchCategories()                                         |
|  - ApiService.fetchProducts()                                           |
|  - home_tab.dart: Renders sorted admin categories in Explore Menu       |
|  - explore_tab.dart: Groups products under admin categories in order    |
|  - cart_screen.dart: Dynamic live recommendations from products         |
|  - branch_service.dart: Zero hardcoded mock arrays                      |
+-------------------------------------------------------------------------+
```

## 12. Request/Response Communication Flow
1. Mobile App: `GET /api/v1/categories` (with bearer token if authenticated, or public header).
2. Backend responds:
   ```json
   {
     "success": true,
     "data": [
       {
         "id": "cat_burgers",
         "name": "Gourmet Burgers",
         "description": "Juicy 100% beef and crisp chicken burgers",
         "image": "https://images.unsplash.com/...",
         "sortOrder": 1,
         "products": [...]
       },
       {
         "id": "cat_pizzas",
         "name": "Artisan Pizzas",
         "description": "Freshly baked wood-fired pizzas",
         "image": "https://images.unsplash.com/...",
         "sortOrder": 2,
         "products": [...]
       }
     ]
   }
   ```
3. Mobile App renders categories dynamically in Home Grid and Explore Tab.

## 13. Sequence of Events
1. App initializes `home_tab.dart`.
2. `initState()` triggers `_loadDynamicCategories()` and `BranchService().fetchBranchesFromBackend()`.
3. `ApiService.fetchCategories()` retrieves admin categories.
4. `_dynamicCategories` updates and triggers `setState()`.
5. User taps a category card, navigating to Explore Menu screen scrolled to that category index.

## 14. Files Modified
- `d:\HungerPoint\hpcustomer\lib\screens\home_tab.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\explore_tab.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\cart_screen.dart`
- `d:\HungerPoint\hpcustomer\lib\services\branch_service.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\branches_tab.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\pickup_branches_screen.dart`

## 15. Code Changes Summary
- **`home_tab.dart`**: Implemented priority fetching from `ApiService.fetchCategories()` so each category occupies a single card with its admin title and image. Added fallback grouping from `ApiService.fetchProducts()`. Triggered `BranchService().fetchBranchesFromBackend()` on startup.
- **`explore_tab.dart`**: Refactored `_fetchLiveMenu()` to fetch categories from `ApiService.fetchCategories()` and sort products under each admin category in their respective order.
- **`cart_screen.dart`**: Converted to `StatefulWidget`, removed static `_recommendedItems`, and implemented `_loadRecommendations()` fetching products from `ApiService.fetchProducts()`.
- **`branch_service.dart`**: Removed 150+ lines of static category arrays (`_f10Categories`, `_swabiCategories`, `_f7Categories`). Made `menuCategories` default to empty list, and populated live menus in `fetchBranchesFromBackend()`.
- **`branches_tab.dart` & `pickup_branches_screen.dart`**: Replaced direct references to static `BranchService().branches` with dynamic `BranchService().allBranches`.

## 16. Why the Fix Works
Categories created or edited by the administrator on the backend are now directly consumed by the customer app via `GET /api/v1/categories`. All residual static arrays across the customer application have been eliminated, ensuring 100% data consistency with the backend database.

## 17. Side Effects (if any)
None. A fallback to product grouping is retained in the event the backend categories table is completely empty or experiencing intermittent network connectivity.

## 18. Testing Performed
- Executed `flutter analyze lib/` with result: `No issues found! (ran in 2.5s)` with 0 errors and 0 warnings.
- Verified database models and schema relationships in `hpbackend/prisma/schema.prisma`.
- Verified category endpoints in `hpbackend/src/modules/categories/category.service.ts`.

## 19. Prevention Strategies
- Prohibit hardcoded data lists in screen widgets; all UI collections must originate from service layer API calls.
- Enforce strict typing and static analysis via `flutter analyze` prior to committing changes.

## 20. Lessons Learned
- Screen components should rely on specialized domain endpoints (`/categories` for category widgets, `/products` for product lists) rather than synthesizing category structures from unrelated endpoints.

## 21. Related Bugs
- BUG-003: Hardcoded Mock Authentication & Static Frontend Data Bypass
- BUG-004: Undefined Identifier Compilation Errors Post-Refactor

## 22. References
- `hpbackend/src/modules/categories/category.service.ts`
- `hpbackend/src/modules/products/product.service.ts`
- `hpcustomer/lib/services/api_service.dart`
