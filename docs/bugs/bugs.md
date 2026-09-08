# HungerPoint Bug Tracking & Resolution Index

This document tracks all identified and resolved bugs across the HungerPoint Customer App (`hpcustomer`) and HungerPoint Backend (`hpbackend`).

---

## 📋 Bug Resolution Log

| Bug ID | Title | Module | Severity | Date | Status |
| :--- | :--- | :--- | :---: | :---: | :---: |
| [BUG-001](./BUG-001-maps-intent-blocked.md) | Google Maps directions launcher blocked by Android package visibility | `hpcustomer/branches` | High | 2026-09-06 | **Resolved** |
| [BUG-002](./BUG-002-jwt-user-id-mismatch.md) | JWT Payload Field Mismatch (`userId` vs `id`) in Customer & Order Controllers | `hpbackend/auth` | High | 2026-09-07 | **Resolved** |
| [BUG-003](./BUG-003-hardcoded-auth-and-mock-data.md) | Hardcoded Mock Authentication & Static Frontend Data Bypass | `hpcustomer/auth` | Critical | 2026-09-07 | **Resolved** |
| [BUG-004](./BUG-004-undefined-identifiers-post-refactor.md) | Undefined Identifier Compilation Errors (`_proceedToWelcome`, `_allItems`) | `hpcustomer/screens` | High | 2026-09-07 | **Resolved** |
| [BUG-005](./BUG-005-sms-delivery-simulation-gap.md) | SMS Delivery Gap & Missing In-App Verification Code Simulation | `hpbackend/auth` | High | 2026-09-07 | **Resolved** |
| [BUG-006](./BUG-006-admin-categories-and-residual-mock-cleanup.md) | Residual Mock Data in Branch/Cart Services and Admin-Side Category Endpoint Ingestion | `hpcustomer/screens` | High | 2026-09-07 | **Resolved** |
| [BUG-007](./BUG-007-decimal-price-type-mismatch-freeze.md) | Prisma Decimal String Serialization Type Mismatch Inducing Infinite Loading Freeze | `hpcustomer/screens` | Critical | 2026-09-08 | **Resolved** |

---

## 📝 Bug Report Standard Template

Whenever a bug is fixed, a dedicated report is generated in `docs/bugs/BUG-XXX-<short-name>.md` following this structure:

1. **Bug ID & Title**
2. **Date, Severity & Affected Module**
3. **Problem Description & Symptoms**
4. **Root Cause Analysis**
5. **Reproduction Steps**
6. **Expected vs Actual Behavior**
7. **Architecture Diagram (ASCII)**
8. **Request/Response Communication Flow**
9. **Sequence of Events**
10. **Files Modified & Code Changes Summary**
11. **Why the Fix Works & Side Effects**
12. **Testing Performed & Verification**
13. **Prevention Strategies & Lessons Learned**
14. **Related Bugs & References**
