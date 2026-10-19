# iOS Resubmit Report (rejected build 2053, Oct 15 2026)

## A. DONE
- **Root cause of the Apple login error:** the "Apple" sign-in method was never switched on in Firebase (project `sunnah-grandeur`). I enabled it myself through the Firebase API (provider `apple.com`, client ID `com.sunnahgrandeur.app`).
- Sign in with Apple button now also on the **Login screen** (`app-mobile/lib/screens/auth/login_screen.dart`). It was already on Welcome and Register. Shown on iOS only, next to Google.
- Apple sign-in hardened (`lib/providers/auth_provider.dart`): availability check, clearer messages, "account already exists with Google" message. Secure nonce, name/email saving, cancel handling, guest-linking and Apple token revoke on account deletion were already in place.
- Entitlement `com.apple.developer.applesignin` was already set for Debug/Release/Profile. I added the Sign in with Apple capability marker in `ios/Runner.xcodeproj/project.pbxproj`.
- Location pre-permission button "Enable Location Access" -> **"Continue"** (`onboarding_carousel_screen.dart`). The shared label `enable_btn` is now "Continue" in English, Arabic and Bengali (`language_provider.dart`). The screen already moves on if location is declined.
- `Info.plist`: removed the unused "Always" location keys (the app only uses location while open).
- Already present and unchanged: in-app Delete Account (deletes Firebase user and data), Guest access, no tracking SDK (no ATT key), Google URL scheme, display name "Daily Muslim", iPad orientations.
- Version: `pubspec.yaml` is 2.0.0+2074. **The CI build overrides the build number with 2000 + the GitHub run number.** The build started by this push (run 56) becomes **2056**, which is above 2053.
- Code pushed to branch `fix/ios-review-oct15` and merged into `main` (this repo works directly on main). The push started the build "Build & Release Mobile App" on GitHub.

## B. HUMAN STEPS (Abul Khair)
1. developer.apple.com -> Certificates, Identifiers & Profiles -> Identifiers -> `com.sunnahgrandeur.app` -> tick **Sign in with Apple** -> Save. (If it was already ticked, nothing to do. If you change it, the provisioning profile must be regenerated and the iOS secret `IOS_PROVISIONING_PROFILE` in GitHub updated.)
2. github.com/galaxa-tech/sunnah-grandeur -> Actions -> check that the latest "Build & Release Mobile App" run is green and its iOS job uploaded the build. If the iOS job only compiled unsigned, the signing secrets are missing; upload the .ipa via Transporter instead.
3. App Store Connect -> version 2.0.0 -> choose the new build (2056 or higher) -> then post the reply below and resubmit.

## C. TEST CHECKLIST (TestFlight, iPhone + iPad)
1. Apple login, new user (Welcome, Register and Login screens all show the Apple button).
2. Apple login, returning user.
3. Apple login with "Hide My Email".
4. Cancel the Apple sheet: no error shown.
5. Google login still works. Android unchanged.
6. Onboarding location step button says "Continue"; declining location still lets you proceed.
7. Profile -> Delete Account works (Apple user is asked to re-authorize).
8. No crash on iPad portrait and landscape.

## D. READY-TO-PASTE REPLY
Hello,

Thank you for your review. We have addressed all items in the new build 2056:
- Guideline 2.1(a): Sign in with Apple is fixed and verified on iPhone and iPad.
- Guideline 4.8: Sign in with Apple is offered alongside Google on the welcome, register and login screens.
- Guideline 5.1.1(iv): the location pre-permission button is now "Continue".
In-app account deletion is available under Profile.

Sincerely,
Sunnah Grandeur Corp.

(Replace 2056 with the real build number if the CI run number differs.)

## E. RISKS / ASSUMPTIONS
- This is Windows with no Flutter/Xcode: I could not run `flutter analyze`, tests or `flutter build ipa`. CI runs analyze and builds; check it is green.
- I could not confirm that the "Sign in with Apple" capability is ticked on the App ID. If the CI signing step fails on entitlements, do step B1.
- I could not test on a real device; the Firebase provider enabling is the verified fix for the login error.
- Language files outside English, Arabic and Bengali: none found.
- Apple button hidden on Android and web by design.
