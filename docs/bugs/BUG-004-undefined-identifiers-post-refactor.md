# BUG-004: Undefined Identifier Compilation Errors (`_proceedToWelcome`, `_allItems`) Post-Refactor

## 1. Bug ID
BUG-004

## 2. Bug Title
Undefined Identifier Compilation Errors (`_proceedToWelcome`, `_allItems`) Post-Refactor

## 3. Date
2026-09-07

## 4. Severity
High

## 5. Module
`hpcustomer/screens/splash_screen.dart`, `hpcustomer/screens/explore_search_tab.dart`

## 6. Problem Description
During `flutter run`, Gradle compilation failed with two Dart static analysis errors:
1. `The getter '_proceedToWelcome' isn't defined for the type '_SplashScreenState'` at `lib/screens/splash_screen.dart:81:16`.
2. `The getter '_allItems' isn't defined for the type '_ExploreSearchScreenState'` at `lib/screens/explore_search_tab.dart:228:46`.

## 7. Symptoms
- The Flutter application failed to assemble (`Target kernel_snapshot_program failed: Exception`).
- The Gradle task `:app:compileFlutterBuildDebug` exited with code 1.
- The app could not launch on the physical device (`RMX3834`).

## 8. Root Cause
1. **Method Renaming Residual**: In `splash_screen.dart`, the transition method was renamed from `_proceedToWelcome` to `_proceedToNextScreen` to support dynamic session restoration into `MainNavigationScreen`. However, line 81 contained a tap listener `GestureDetector(onTap: _proceedToWelcome)` that still referenced the old identifier.
2. **Static Field Removal Residual**: In `explore_search_tab.dart`, the hardcoded static `_allItems` array was removed in favor of `_liveItems` and the dynamic getter `_currentItems`. A popular-search tag tap handler at line 228 still invoked `_allItems.firstWhere(...)`.

## 9. Reproduction Steps
1. In `d:\HungerPoint\hpcustomer`, run `flutter run`.
2. Observe Dart compilation errors pointing to `splash_screen.dart:81` and `explore_search_tab.dart:228`.
3. Build fails before deploying the APK.

## 10. Expected vs Actual Behavior
- **Expected Behavior**:
  - `SplashScreen` uses `_proceedToNextScreen` uniformly across timer transitions and manual tap events.
  - `ExploreSearchScreen` searches against live backend items via `_currentItems`.
  - Application builds and compiles cleanly into `assembleDebug`.
- **Actual Behavior**:
  - Dart compiler encountered two unresolved symbol errors and aborted the build.

## 11. Architecture Diagram (ASCII)
```
[ SplashScreen ]
      │ onTap / timer
      ▼
[ _proceedToNextScreen() ] ──► Check ApiService.isLoggedIn
                                   ├── true  ──► MainNavigationScreen
                                   └── false ──► WelcomeScreen

[ ExploreSearchScreen ]
      │ popular search tag tapped
      ▼
[ _currentItems.firstWhere() ] ──► Look up product from dynamic backend cache
                                        │
                                        ▼
                                  ItemDetailScreen
```

## 12. Request/Response Communication Flow
N/A (Compile-time resolution). Both identifiers resolve internal state within their respective Flutter widget state classes.

## 13. Sequence of Events
1. Developer triggered `flutter run` in `hpcustomer`.
2. Gradle invoked `compileFlutterBuildDebug`.
3. Dart compiler detected unresolved symbol `_proceedToWelcome` at `splash_screen.dart:81`.
4. Dart compiler detected unresolved symbol `_allItems` at `explore_search_tab.dart:228`.
5. Replaced `_proceedToWelcome` with `_proceedToNextScreen` in `splash_screen.dart`.
6. Replaced `_allItems` with `_currentItems` in `explore_search_tab.dart`.
7. Re-executed build and analyzer verification.

## 14. Files Modified
- `hpcustomer/lib/screens/splash_screen.dart`
- `hpcustomer/lib/screens/explore_search_tab.dart`

## 15. Code Changes Summary
- `splash_screen.dart`:
  ```diff
  - onTap: _proceedToWelcome,
  + onTap: _proceedToNextScreen,
  ```
- `explore_search_tab.dart`:
  ```diff
  - final matchingItem = _allItems.firstWhere(
  + final matchingItem = _currentItems.firstWhere(
  ```

## 16. Why the Fix Works
Both identifiers now point to the existing, refactored symbols within the state objects (`_proceedToNextScreen` for splash navigation and `_currentItems` for products), satisfying Dart's static type checker.

## 17. Side Effects (If Any)
None. Tapping the splash screen now accurately adheres to the persistent session state, and tapping popular search tags correctly resolves to live backend products.

## 18. Testing Performed
- Static analysis verified via `flutter analyze`.
- Clean compilation verified without unresolved getter errors.

## 19. Prevention Strategies
- Always run project-wide grep searches for symbol references before removing or renaming private identifiers.
- Execute `flutter analyze` immediately after refactoring to catch dead or orphaned identifiers.

## 20. Lessons Learned
When removing static mock data arrays and renaming lifecycle methods, secondary user-interaction callbacks (such as skip-tap or tag-click handlers) must be audited alongside the primary lifecycle routines.

## 21. Related Bugs
- [BUG-003](./BUG-003-hardcoded-auth-and-mock-data.md): Hardcoded Mock Authentication & Static Frontend Data Bypass.

## 22. References
- Dart Analysis documentation: https://dart.dev/tools/analysis
- Flutter build pipeline: https://docs.flutter.dev/deployment/android
