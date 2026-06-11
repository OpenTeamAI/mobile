# Google Play Submission

## App

- Package name: `com.openteam.portal`
- App name: `OpenTeam`
- Category: Productivity
- Pricing: Free
- Target audience: Business users
- Privacy policy: `https://www.openteam.ai/policies/privacy`
- Support contact: `info@openteam.ai`

## Binary

Google Play uses Android App Bundles for new apps. Build the signed bundle with:

```sh
npm run android:bundle
```

Current release bundle:

```text
android/app/build/outputs/bundle/release/app-release.aab
```

## Store Listing

Store metadata and screenshots live under:

```text
fastlane/metadata/android/en-US
```

The listing uses the same positioning as the iOS submission: OpenTeam is a
business productivity workspace for authenticated teams. A valid OpenTeam
account is required.

## Reviewer Access

Use the local `../agents.md` review account notes. Do not commit review account
credentials or stable login codes to git.

## fastlane

Place the Google Play service account JSON at:

```text
fastlane/play/google-play-service-account.json
```

or set:

```sh
export SUPPLY_JSON_KEY=/absolute/path/to/google-play-service-account.json
```

Upload metadata only:

```sh
bundle exec fastlane android upload_play_metadata
```

Upload the signed AAB to internal testing as a draft:

```sh
bundle exec fastlane android upload_internal_draft
```

Upload the signed AAB to production as a draft:

```sh
bundle exec fastlane android upload_production_draft
```

The app must first exist in Play Console, Play App Signing must be accepted, and
the service account must have access to this app.
