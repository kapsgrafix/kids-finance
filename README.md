# Tiny Treasury (Flutter)

Phase 1 of Tiny Treasury, built from the Figma designs. It's a pocket-money fund manager where kids track
their money, earn interest on what they save, and grow it in investment jars. Parents pay all real money;
the app only does the maths. Everything is stored locally on the device.

## Run it

This folder holds the app code, fonts and images. Generate the Android/iOS platform folders once:

```bash
cd tiny_treasury
flutter create . --project-name tiny_treasury --org com.binnytechlabs --platforms android,ios
rm -f test/widget_test.dart      # the template test references a counter app that doesn't exist here
flutter pub get
flutter run
```

`flutter create .` keeps the existing `lib/`, `pubspec.yaml` and `assets/`; it only adds what's missing.
Then set the display name to "Tiny Treasury" in `android/app/src/main/AndroidManifest.xml` (`android:label`) and
`ios/Runner/Info.plist` (`CFBundleDisplayName`).

Run the logic tests with `flutter test`.

## Screens

| Figma frame | Code |
|---|---|
| Splash | `lib/screens/splash_screen.dart` |
| Welcome · Add Kid | `lib/screens/add_kid_screen.dart` (also used for "+ Kid") |
| Home, Home · Jar active, Home · 3 kids | `lib/screens/home_screen.dart` |
| Add Expense · Sheet / Note, Add Money · Sheet | `lib/screens/sheets.dart` (`showAddEntrySheet`) |
| History | `lib/screens/history_screen.dart` |
| Jars · Empty | `lib/screens/jars_screen.dart` |
| Create Jar | `lib/screens/create_jar_screen.dart` |
| Jar Detail | `lib/screens/jar_detail_screen.dart` |
| Settings | `lib/screens/settings_screen.dart` |
| Notifications | `lib/screens/notifications_screen.dart` |

Design tokens (the Figma "Tiny Treasury" colour variables, Fredoka + Nunito SemiBold) live in
`lib/theme/tokens.dart`; shared components (buttons, fields, segmented control, kid switcher) are in
`lib/widgets/common.dart`.

## How the money works

All logic is in `lib/state/app_state.dart`.

- **Setting up a kid** credits the first pocket money straight away. The next pocket-money day is the 1st of
  next month (monthly) or 7 days later (weekly).
- **Pocket-money day** runs automatically when the app opens or resumes on or after that date:
  1. Interest (default 10%, set in Settings) is paid on whatever balance is left.
  2. Each active jar takes its share.
  3. The rest of the pocket money is credited.
  4. Notifications are added: pocket money, interest, and "time to review".
- **Expenses** can't exceed the current balance.
- **Jars**: the slider sets 2–10% of pocket money per cycle, and the plan is 3, 6 or 12 months (×4 cycles when
  weekly). Bonus rates (default 4% / 8% / 12%) are set in Settings. When the last contribution lands, the jar pays
  out its savings plus the bonus. "Settle the amount and cancel" returns what was saved, without the bonus.
- One active jar per kid in phase 1.

## Fonts

Fredoka and Nunito (SIL Open Font License, licence files in `assets/fonts/`) are bundled as static SemiBold
instances, so the app works offline. Fredoka has no ₹ glyph, so headings fall back to Nunito for it.
