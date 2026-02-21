# pos_app

Point-of-sale Flutter application.

## Quick start

Prerequisites:
- Install Flutter (includes Dart): https://flutter.dev
- On Windows to build desktop apps: install Visual Studio Build Tools
- For Android: install Android SDK and command-line tools

Clone and open:

```bash
git clone https://github.com/kylewvl-ship-it/pos-app.git
cd pos-app
```

Install dependencies and check environment:

```bash
flutter pub get
flutter doctor -v
flutter devices
```

Run the app (choose a device):

- Windows desktop:
```bash
flutter run -d windows
```
- Web (Chrome):
```bash
flutter run -d chrome
```
- Android:
```bash
flutter run -d <device-id>
```

Entry point: `lib/main.dart`

Common fixes:
- If `flutter doctor` reports missing Android cmdline-tools, install them via the SDK manager and accept licenses:
```bash
sdkmanager --install "cmdline-tools;latest"
flutter doctor --android-licenses
```
- If you see layout overflows, increase the window size or update the layouts in `lib/ui/screens/home_screen.dart`.

If you want, I can also add a `.gitignore` or further developer notes.