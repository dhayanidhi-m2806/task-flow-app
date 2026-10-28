# TaskFlow Flutter App

Premium yellow-and-black local task manager built with Flutter.

## Demo login
- Username: `demo`
- Password: `1234`

## Features
- Login session saved locally
- Create, edit, complete, reopen and delete tasks
- All / Pending / Completed filters
- Dashboard counts and completion progress
- Edit profile display name
- Choose a profile photo from the gallery and copy it into app documents
- Bottom navigation between Tasks and Profile
- No backend or online database

## Requirements
- Flutter SDK (stable channel)
- Android Studio (Android SDK/emulator) or a connected Android phone
- Windows users can also run `flutter run -d windows` after enabling Windows desktop development

## Run on Windows
1. Extract this ZIP.
2. Open PowerShell or Command Prompt in the `taskflow_flutter_app` folder.
3. Check Flutter: `flutter doctor`
4. Download dependencies: `flutter pub get`
5. List available devices: `flutter devices`
6. Run on the selected Android emulator/phone: `flutter run`
   - For Windows desktop (if enabled): `flutter run -d windows`

If no Android device appears, open Android Studio > Device Manager, start an emulator, then run `flutter devices` again.

## Notes
- This is a demo login, not secure authentication. The username/password are hardcoded in the app.
- Data is stored on the current device using SharedPreferences. Uninstalling the app or clearing app storage can erase it.
- Photo picker behaviour is handled by `image_picker`; the selected image is copied to the app's documents directory so the profile can keep using it.
- No camera permission is needed because the app selects existing gallery images only.


## If task Add/Edit previously showed a Flutter assertion
The task editor is now a separate `StatefulWidget`. Its `TextEditingController`
is created in `initState()` and disposed in `dispose()`, matching the dialog's
widget lifecycle. This avoids disposing the text controller immediately after
the dialog result returns while the dialog route may still be closing.


## App icon and logo
- `assets/icons/app_icon.png` is the launcher icon source.
- `assets/images/app_logo.png` is used on the login screen and app bar.
- Both are editable PNG assets; replace them with your own images while keeping the same paths, or update the paths in `pubspec.yaml` and `lib/main.dart`.

To regenerate the Android/iOS launcher icon after replacing `app_icon.png`:
```bash
flutter pub get
dart run flutter_launcher_icons
flutter run
```
