# Bug Report: BUG-007-decimal-price-type-mismatch-freeze

## 1. Bug ID
BUG-007

## 2. Bug Title
Prisma Decimal String Serialization Type Mismatch Inducing Infinite Loading Freeze on Explore Menu Screen

## 3. Date
2026-09-08

## 4. Severity
Critical

## 5. Module
`hpcustomer/screens` & `hpcustomer/services` (`explore_tab.dart`, `explore_search_tab.dart`, `cart_screen.dart`, `api_service.dart`)

## 6. Problem Description
Upon navigating to the Explore Menu page (`ExploreMenuScreen`), the screen remained permanently stuck on a yellow `CircularProgressIndicator` without ever rendering menu categories or product cards. No error screen was presented to the user, and the view never resolved, giving the impression that the app was frozen.

## 7. Symptoms
- The Explore Menu screen displays an indefinite `CircularProgressIndicator` spinner.
- No categories appear in the sticky horizontal category bar.
- No menu items or sections are populated in the continuous vertical scrollable menu.
- Searching in `ExploreSearchScreen` or loading recommendations in `CartScreen` could fail silently with empty product lists under identical conditions.

## 8. Root Cause
1. **Prisma Decimal Serialization as String**: In the MySQL schema (`schema.prisma`), `basePrice` and `price` fields are defined as `@db.Decimal(10, 2)`. When Prisma Client and Express serialize Decimal fields to JSON, they are emitted as JSON strings (e.g. `"550"` or `"790.00"`) to prevent floating-point precision loss.
2. **Dart Runtime Type Cast Failure**: In `explore_tab.dart`, `_fetchLiveMenu()` attempted direct numeric cast and method invocation on the unparsed string:
   - Line 147: `final num priceNum = p['basePrice'] ?? p['price'] ?? 0;` (threw `type 'String' is not a subtype of type 'num'`).
   - Line 164: `'price': (cp['basePrice'] ?? 0).toInt()` (threw `NoSuchMethodError: Class 'String' has no instance method 'toInt'`).
3. **Silent Exception Abort in Try-Catch**: The unhandled runtime cast exception aborted execution in the `try` block before `setState()` was invoked. Consequently, `_menuCategories` remained empty (`[]`).
4. **Lack of Loading State Flags & Empty UI**: The widget evaluated `_menuCategories.isEmpty ? CircularProgressIndicator() : ListView.builder()`. Because `_menuCategories` was never populated, the app displayed `CircularProgressIndicator` perpetually without timeout, error alert, or retry option.
5. **Orphaned Product Loss**: In `_fetchLiveMenu()`, if products had null or unmatched `categoryId`, they were excluded from `_menuCategories` when `categories.isNotEmpty` was true.

## 9. Reproduction Steps
1. Ensure `hpbackend` has seeded products with Decimal prices in MySQL (`hungerpointdb`).
2. Launch `hpbackend` (`npm run dev`) and run the Flutter customer app (`flutter run`).
3. From the bottom navigation or Home Tab Explore Menu grid, tap "Explore Menu".
4. Observe the screen stuck indefinitely on `CircularProgressIndicator`.

## 10. Expected vs Actual Behavior
- **Expected**: Explore Menu fetches categories and products, safely parses numeric and string decimal prices, populates `_menuCategories`, and renders the interactive menu sections and sticky category tabs immediately. If network fails, an informative error view with a "Try Again" button should appear.
- **Actual**: Runtime type cast exception aborted `_fetchLiveMenu()`, leaving `_menuCategories` empty and causing an infinite loading spinner loop.

## 11. Architecture Diagram (ASCII)
```
+-------------------------------------------------------------------------+
|                  MySQL Database (hungerpointdb)                         |
|  Product Table: basePrice Decimal(10, 2)  --> e.g. 550.00              |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  hpbackend (Prisma ORM + Express)                       |
|  Prisma serializes Decimal as JSON String: {"basePrice": "550.00"}      |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                hpcustomer ApiService & Normalize Helper                 |
|  - _normalizeProduct(): safely converts String/num Decimal to double   |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|               hpcustomer ExploreMenuScreen (explore_tab.dart)           |
|  - _parsePrice(dynamic raw): handles int, double, String safely        |
|  - _isLoading & _hasError state tracking                                |
|  - Categorized products + orphan products grouping                     |
|  - Empty & error state with "Try Again" retry button                   |
+-------------------------------------------------------------------------+
```

## 12. Request/Response Communication Flow
1. Mobile App issues `GET /api/v1/categories` and `GET /api/v1/products`.
2. Backend responds:
   ```json
   {
     "success": true,
     "data": [
       {
         "id": "prod_1",
         "categoryId": "cat_1",
         "name": "Classic Cheeseburger",
         "basePrice": "550.00",
         "image": "https://..."
       }
     ]
   }
   ```
3. `ApiService._normalizeProduct` and `ExploreMenuScreen._parsePrice` parse `"550.00"` to integer `550`.
4. `ExploreMenuScreen` builds category sections and updates UI with `setState()`.

## 13. Sequence of Events
1. User taps "Explore Menu".
2. `ExploreMenuScreen.initState()` sets `_isLoading = true` and triggers `_fetchLiveMenu()`.
3. `ApiService.fetchCategories()` and `ApiService.fetchProducts()` retrieve backend records.
4. Product prices are parsed via `_parsePrice` without type mismatch exceptions.
5. Products are mapped to categories; unassigned products are grouped into "Specialties".
6. `setState()` sets `_isLoading = false`, updates `_menuCategories`, and generates category keys.
7. UI immediately swaps from loading spinner to `ListView.builder` displaying all items.

## 14. Files Modified
- `d:\HungerPoint\hpcustomer\lib\services\api_service.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\explore_tab.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\explore_search_tab.dart`
- `d:\HungerPoint\hpcustomer\lib\screens\cart_screen.dart`

## 15. Code Changes Summary
- **`api_service.dart`**:
  - Added `_normalizeProduct(dynamic p)` helper supporting both `num` and `String` representations of `basePrice` and `price`.
  - Updated `fetchCategories()` and `fetchProducts()` to normalize incoming JSON items before returning.
- **`explore_tab.dart`**:
  - Implemented `_parsePrice(dynamic raw)` to defensively convert `int`, `double`, and `String` to `int` price values.
  - Added `_isLoading` and `_hasError` state booleans.
  - Added safe bounds check to `_scrollToCategory` (`if (index < 0 || index >= _categoryKeys.length) return;`).
  - Added orphan product grouping fallback so products not strictly matched to category IDs are preserved and shown under their named section.
  - Replaced ternary loading check with distinct loading spinner, informative empty/network error state with "Try Again" button, and active menu list view.
- **`explore_search_tab.dart`**:
  - Replaced rigid `num priceNum = p['basePrice'] ?? p['price']` with safe parsing handling both `num` and `String`.
- **`cart_screen.dart`**:
  - Replaced rigid `num priceNum = p['basePrice'] ?? p['price']` in recommendations with safe parsing.

## 16. Why the Fix Works
Defensive price parsing eliminates the runtime `type 'String' is not a subtype of type 'num'` and `NoSuchMethodError` crashes. Product mapping now succeeds cleanly, populating `_menuCategories` and allowing `ListView.builder` to render immediately. If an actual network or server fault occurs, explicit error handling presents a "Try Again" action instead of an infinite hang.

## 17. Side Effects (if any)
None. All existing UI styling, category tab stickiness, and cart interactions are fully preserved.

## 18. Testing Performed
- Inspected MySQL schema and Prisma model definitions for Decimal fields.
- Verified backend category and product responses.
- Verified safe price conversion with `int`, `double`, `String`, and `null` inputs.
- Verified error and empty state UI with retry capability.

## 19. Prevention Strategies
- Never assume JSON numeric fields are native `num` types in Dart when working with SQL Decimal/BigDecimal fields.
- Always use defensive parsing utilities (`double.tryParse`, helper methods) when decoding API payloads.
- Avoid using `collection.isEmpty` as the sole condition for displaying a loading spinner; maintain dedicated `_isLoading` and `_hasError` flags.

## 20. Lessons Learned
- In full-stack applications with MySQL and Prisma ORM, Decimal types serialize as strings in JSON. Client-side Dart models must defensively account for this type serialization behavior.

## 21. Related Bugs
- BUG-004: Undefined Identifier Compilation Errors Post-Refactor
- BUG-006: Residual Mock Data in Branch/Cart Services and Admin-Side Category Endpoint Ingestion

## 22. References
- `hpbackend/prisma/schema.prisma`
- `hpbackend/src/modules/categories/category.service.ts`
- `hpcustomer/lib/services/api_service.dart`
- `hpcustomer/lib/screens/explore_tab.dart`
