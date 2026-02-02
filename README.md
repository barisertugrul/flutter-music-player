# Flutter Music Player

A simple Flutter music player demo using `just_audio`, `audio_session`, `hive` and `get_it`.  
Includes a basic UI with a song list, playback controls, progress slider, and persistent last-played info.

## Features

- Play remote MP3 files using `just_audio`
- Track position and duration, seek with a slider
- Play/pause toggle and auto-stop at end
- Persist last played song metadata with `hive`
- Dependency injection via `get_it`
- Basic audio session configuration via `audio_session`

## Requirements

- Flutter SDK (stable)
- Android SDK / iOS toolchain as needed
- Device or emulator with internet access

## Important files

- `lib/main.dart` — app entry, DI setup and `BaDumTss` audio provider
- `lib/musicPlayerScreen.dart` — main UI and playback logic (uses `just_audio`)
- `lib/customListItem_widget.dart` — list item UI
- `android/app/src/main/AndroidManifest.xml` — ensure `INTERNET` permission is present
- `pubspec.yaml` — project dependencies

## Setup

1. Ensure Flutter is installed and up-to-date.
2. Add required packages (example):
   ```bash
   flutter pub add just_audio
   flutter pub add audio_session
   flutter pub add hive
   flutter pub add get_it
   flutter pub add path_provider
   
3. Ensure `INTERNET` permission is in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

4. For development, always perform a full restart after adding native plugins:
   ```bash
   flutter clean
   ```
   
5. Get dependencies:
   ```bash
   flutter pub get
   ```

## Running the App

* For development, always perform a full restart after adding native plugins:
   ```bash
   flutter run
   ```

* In Android Studio / Android emulators: stop the app and press Run (hot-reload is often not sufficient for native plugin registration).

## Troubleshooting

 - MissingPluginException (e.g. `No implementation found for method init on channel com.ryanheise.just_audio.methods`):
   - Stop the app completely, run `flutter clean`, `flutter pub get`, then `flutter run`.
   - Verify `MainActivity` uses V2 embedding (empty subclass of `FlutterActivity`) in:
     - `android/app/src/main/kotlin/.../MainActivity.kt` or
     - `android/app/src/main/java/.../MainActivity.java`
   - If you use a custom `FlutterEngine` or add-to-app, ensure plugins are registered on that engine.
 - If remote URLs don't play:
   - Open the URL in the device browser to confirm accessibility.
   - Check emulator/device network settings.
## Notes

 - The project uses `just_audio` for more stable Android playback and gapless support. For very simple cases `audioplayers` can work but `just_audio` is recommended for reliability.
 - The app persists last-played metadata in a Hive box named `myBox` located in app documents directory.
## Contributing

 Small fixes and improvements welcome. Open issues or PRs on the repository.
## License

 MIT License — see `LICENSE` if present.