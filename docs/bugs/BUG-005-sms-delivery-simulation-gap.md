# BUG-005: SMS Delivery Gap & Missing In-App Verification Code Simulation

## 1. Bug ID
BUG-005

## 2. Bug Title
SMS Delivery Gap & Missing In-App Verification Code Simulation for Mobile Devices

## 3. Date
2026-09-07

## 4. Severity
High

## 5. Module
`hpbackend/modules/auth`, `hpcustomer/screens/phone_auth_screen.dart`, `hpcustomer/screens/otp_screen.dart`

## 6. Problem Description
When entering a mobile phone number and tapping "SEND CODE" on the login screen, the customer app successfully triggered `POST /api/v1/auth/send-otp` and the backend generated a 6-digit OTP. However, because no SMS gateway credentials (e.g. Twilio) were configured in `hpbackend/.env`, no physical SMS arrived on the user's mobile carrier network. Furthermore, the frontend did not display or auto-fill the backend-generated OTP code returned in the API response, leaving the user with blank input boxes and no way of knowing the generated verification code.

## 7. Symptoms
- The app navigated to `OtpScreen` with empty digit boxes.
- No cellular SMS notification was received on the user's physical smartphone SIM card.
- User was blocked at the OTP verification step unable to complete login or registration.

## 8. Root Cause
1. **Unconfigured SMS Gateway**: The backend server was logging OTP codes to the local terminal console (`[OTP SERVICE] Generated OTP for +92...`) but lacked integration with telecom carrier gateways for real-world SMS dispatch.
2. **Frontend Disconnect from API OTP Payload**: Although `POST /api/v1/auth/send-otp` returned `{ data: { otp: "..." } }`, `PhoneAuthScreen` did not forward this payload to `OtpScreen`, and `OtpScreen` had no auto-fill or in-app SMS notification simulation mechanism.

## 9. Reproduction Steps
1. Launch the app on a physical mobile device or emulator.
2. Enter a valid mobile number (e.g., `+923139804929`) and tap "SEND CODE".
3. Check the mobile device's SMS inbox: no SMS is received from the cellular carrier.
4. On `OtpScreen`, all 6 digit boxes are blank with no indication of what code the backend generated.

## 10. Expected vs Actual Behavior
- **Expected Behavior**:
  - In development/sandbox mode without active telecom contracts, the app should receive the generated code from `hpbackend`, display an incoming SMS notification banner, and auto-fill the 6 digit inputs for a frictionless login flow.
  - In production, if Twilio/carrier credentials are provided in `.env`, real cellular SMS messages should be transmitted directly to the carrier network.
- **Actual Behavior**:
  - The OTP was only visible in the server's Node.js console log, making mobile app testing on physical phones impossible without reading server logs.

## 11. Architecture Diagram (ASCII)
```
[ User Device / PhoneAuthScreen ]
               │
               ▼ 1. POST /api/v1/auth/send-otp
    [ hpbackend auth.service ]
               │
               ├── 2. Check for Twilio Credentials in .env
               │      ├── Found: Dispatch via Twilio REST API ──► [ Telecom Network ] ──► [ SIM SMS ]
               │      └── Not Found: Log simulation mode
               │
               ▼ 3. Return { success: true, data: { otp: "132368", ... } }
[ OtpScreen ]
               │
               ├── 4. Show In-App SMS Toast: "HungerPoint SMS: Your code is 132368"
               ├── 5. Auto-fill 6 digit input boxes
               └── 6. Show "SMS Code: 132368 (Auto-filled)" badge
```

## 12. Request/Response Communication Flow
1. **Send OTP**:
   `POST /api/v1/auth/send-otp`
   Payload: `{"phone": "+923139804929"}`
   Response (200 OK):
   ```json
   {
     "success": true,
     "data": {
       "phone": "+923139804929",
       "isExistingUser": true,
       "message": "OTP sent successfully",
       "otp": "132368"
     }
   }
   ```
2. **Frontend Ingestion**:
   `PhoneAuthScreen` extracts `res['data']['otp']` and passes it as `initialOtp` to `OtpScreen`.
3. **Verify OTP**:
   `POST /api/v1/auth/verify-otp` with `{"phone": "+923139804929", "otp": "132368"}`.

## 13. Sequence of Events
1. In `hpbackend/src/modules/auth/auth.service.ts`:
   - Implemented `sendSmsViaGateway` using native `fetch` against Twilio's Messages REST API.
   - Preserved fallback logging when telecom credentials are not present.
2. In `hpcustomer/lib/screens/phone_auth_screen.dart`:
   - Updated `_onSendCode()` to capture `res['data']?['otp']?.toString()` and pass `initialOtp` into `OtpScreen`.
3. In `hpcustomer/lib/screens/otp_screen.dart`:
   - Added `initialOtp` constructor parameter and `_currentOtp` state variable.
   - Populated the 6 `TextEditingController` instances automatically if `_currentOtp` is present.
   - Added in-app SMS toast banner on entry and upon clicking "RESEND".
   - Added a visible on-screen "SMS Code: XXXXXX (Auto-filled)" badge below the digit boxes.

## 14. Files Modified
- `hpbackend/src/modules/auth/auth.service.ts`
- `hpcustomer/lib/screens/phone_auth_screen.dart`
- `hpcustomer/lib/screens/otp_screen.dart`

## 15. Code Changes Summary
- `hpbackend/src/modules/auth/auth.service.ts`: Added `sendSmsViaGateway()` to dispatch real SMS via Twilio if `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_PHONE_NUMBER` are defined.
- `hpcustomer/lib/screens/phone_auth_screen.dart`: Forwarded `res['data']?['otp']` to `OtpScreen(initialOtp: otp)`.
- `hpcustomer/lib/screens/otp_screen.dart`: Added automatic digit pre-filling, in-app SMS notification toast, and on-screen badge.

## 16. Why the Fix Works
Users on physical devices now immediately see the generated verification code in an on-screen SMS notification toast and badge, and have it auto-filled into the inputs. Once Twilio credentials are added to `.env`, real telecom SMS messages will also be delivered over the air to physical SIM cards.

## 17. Side Effects (If Any)
None. The dev bypass codes (`123456`, `872305`) remain supported in `verifyOtp` alongside the dynamically generated codes.

## 18. Testing Performed
- Static analysis verified via `flutter analyze` with 0 issues found.
- Backend verification code generation confirmed via live logs.
- Auto-fill and notification pipeline verified.

## 19. Prevention Strategies
- Provide visual in-app fallback notifications for third-party external services (SMS, email verification, push notifications) during development.
- Add `.env.example` documenting SMS gateway parameters for quick production setup.

## 20. Lessons Learned
Relying solely on physical telecom SMS delivery in development blocks mobile QA whenever test devices lack SMS gateway integration. Feeding the backend's generated code back to the mobile UI simulates the SMS arrival transparently.

## 21. Related Bugs
- [BUG-003](./BUG-003-hardcoded-auth-and-mock-data.md): Hardcoded Mock Authentication & Static Frontend Data Bypass.
- [BUG-004](./BUG-004-undefined-identifiers-post-refactor.md): Undefined Identifier Compilation Errors Post-Refactor.

## 22. References
- Twilio REST API Messages Resource: https://www.twilio.com/docs/sms/api/message-resource
