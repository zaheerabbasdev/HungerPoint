# BUG-001: Google Maps directions launcher blocked by Android package visibility

- **Bug ID**: BUG-001
- **Bug Title**: Google Maps directions launcher blocked by Android package visibility
- **Date**: 2026-09-06
- **Severity**: High
- **Module**: `hpcustomer/branches`

---

## Problem Description
Clicking the "GET DIRECTIONS" button in the Branches tab did not launch Google Maps. The action failed silently with no error message shown to the user.

## Symptoms
- Tapping "GET DIRECTIONS" in the branch details sheet produced no reaction.
- No app opened, and the user remained on the bottom sheet.

## Root Cause
On Android 11+ (API 30+), strict package visibility restricts apps from querying intents via `canLaunchUrl`. Because the `geo:` and `https:` schemes and the `com.google.android.apps.maps` package were not declared inside `<queries>` in `AndroidManifest.xml`, `canLaunchUrl(geoUri)` and `canLaunchUrl(googleMapsUri)` evaluated to `false`. The previous implementation guarded `launchUrl` behind `canLaunchUrl`, completely blocking execution.

## Reproduction Steps
1. Run app on an Android 11+ device or emulator.
2. Navigate to Branches tab.
3. Tap on the nearest branch card or a map pin.
4. In the branch details sheet, tap "GET DIRECTIONS".
5. Observe that nothing happens.

## Expected vs Actual Behavior
- **Expected**: Opens Google Maps with turn-by-turn navigation or pin coordinates to the branch.
- **Actual**: Nothing happens; `canLaunchUrl` silently returns `false`.

## Architecture Diagram (ASCII)
```
[User Taps GET DIRECTIONS]
            │
            ▼
┌─────────────────────────┐
│ branches_tab.dart       │
│ _launchGoogleMaps()     │
└───────────┬─────────────┘
            │
            ▼  (Android 11+ Package Visibility)
┌─────────────────────────┐
│ Android OS Intent Check │
│ <queries> Block Check   │
└───────────┬─────────────┘
            ├─── Without <queries> ──> [canLaunchUrl = false] ──> Silent failure (OLD)
            │
            └─── With <queries> declared in AndroidManifest.xml:
                    ├── Tier 1: geo:lat,lng?q=... (Native Maps App)
                    ├── Tier 2: https://www.google.com/maps/dir/?api=1 (Maps App)
                    └── Tier 3: Browser Fallback (NEW)
```

## Request/Response Communication Flow
```
App -> Android OS Intent Manager: startActivity(Intent.ACTION_VIEW, "geo:33.7215,73.0565")
Android OS -> Google Maps App: Launched with destination coordinates
```

## Sequence of Events
1. User taps "GET DIRECTIONS".
2. `_launchGoogleMaps` attempts `launchUrl(geoUri, mode: LaunchMode.externalApplication)`.
3. If native intent fails or Maps app is missing, falls back to `https://www.google.com/maps/dir/...`.
4. If standalone app launch fails, falls back to `LaunchMode.platformDefault` in the browser.

## Files Modified
- `d:\HungerPoint\hpcustomer\lib\screens\branches_tab.dart`
- `d:\HungerPoint\hpcustomer\android\app\src\main\AndroidManifest.xml`

## Code Changes Summary
- Added `<queries>` declarations for `geo`, `https`, and `com.google.android.apps.maps` in `AndroidManifest.xml`.
- Added `INTERNET` and `ACCESS_FINE_LOCATION` permissions.
- Replaced blocking `canLaunchUrl` check with a direct multi-tier fallback launcher.

## Why the Fix Works
Declaring `<queries>` allows Android to recognize intent filters for mapping apps, and removing the blocking `canLaunchUrl` check guarantees that `launchUrl` attempts execution with a clean browser fallback.

## Side Effects
None. Backward compatible with older Android and iOS versions.

## Testing Performed
- Tested intent triggers on Android; verified `flutter analyze` completed with 0 errors.

## Prevention Strategies
- Always declare URL schemes under `<queries>` in `AndroidManifest.xml` when using `url_launcher`.
- Never rely solely on `canLaunchUrl` on modern Android versions without a try-catch launch fallback.

## Lessons Learned
`canLaunchUrl` return values can be false negatives on modern Android due to OS security sandboxing.

## Related Bugs
None.

## References
- [Flutter url_launcher Android 11+ Package Visibility Guide](https://pub.dev/packages/url_launcher#android)
