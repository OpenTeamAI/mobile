# OpenTeam Portal React Native

This is the React Native mobile shell for OpenTeam Portal. The Android app is
implemented as a production WebView wrapper around the Portal web app, with
native handling for app links, external links, popup windows, safe areas, and the
Android hardware back button.

## Android Target

- Package: `com.openteam.portal`
- Display name: `OpenTeam`
- Version: `1.1`
- Version code: `4`
- Initial URL: `https://openteam.ai/auth`
- Portal hosts handled in-app:
  - `openteam.ai`
  - `www.openteam.ai`
  - `portal.openteam.ai`
- Minimum SDK: `24`
- Target SDK: `36`

## Setup

Install dependencies from this directory:

```sh
npm install
```

Android builds require a Java runtime and the Android SDK. This project uses the
checked-in Gradle wrapper under `android/`.

## Development

Start Metro:

```sh
npm start
```

Run on an emulator or connected Android device:

```sh
npm run android
```

Build a debug APK without installing it:

```sh
npm run android:debug
```

Build a debug APK with the JavaScript bundle packaged into the APK. This is
useful for emulator smoke tests when Metro is not running:

```sh
npm run android:debug:standalone
```

## Release Signing

Release builds read signing credentials either from environment variables:

```sh
export OPENTEAM_UPLOAD_STORE_FILE=/absolute/path/to/openteam-upload.keystore
export OPENTEAM_UPLOAD_STORE_PASSWORD=...
export OPENTEAM_UPLOAD_KEY_ALIAS=openteam-upload
export OPENTEAM_UPLOAD_KEY_PASSWORD=...
```

or from `android/keystore.properties`, using
`android/keystore.properties.example` as the template. The real
`android/keystore.properties` file is ignored by git.

Build a release APK:

```sh
npm run android:apk
```

Build a Play Store app bundle:

```sh
npm run android:bundle
```

## Verification

```sh
npm run typecheck
npm run lint
npm test -- --runInBand
```

If Gradle fails with `Unable to locate a Java Runtime`, install/configure a JDK
and rerun the Android build command.
