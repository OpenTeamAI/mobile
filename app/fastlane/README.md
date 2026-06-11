fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_play_bundle

```sh
[bundle exec] fastlane android build_play_bundle
```

Build the signed Android App Bundle for Google Play

### android upload_play_metadata

```sh
[bundle exec] fastlane android upload_play_metadata
```

Upload Google Play store metadata and screenshots only

### android upload_internal_draft

```sh
[bundle exec] fastlane android upload_internal_draft
```

Upload the signed AAB to Google Play internal testing as a draft

### android upload_production_draft

```sh
[bundle exec] fastlane android upload_production_draft
```

Upload the signed AAB to Google Play production as a draft

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
