fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios latest_build

```sh
[bundle exec] fastlane ios latest_build
```

Read the latest uploaded build number

### ios update_metadata

```sh
[bundle exec] fastlane ios update_metadata
```

Upload metadata and screenshots to App Store Connect

### ios update_store_assets

```sh
[bundle exec] fastlane ios update_store_assets
```

Upload metadata and screenshots to App Store Connect

### ios upload_build

```sh
[bundle exec] fastlane ios upload_build
```

Archive and upload build to App Store Connect

### ios upload_existing_ipa

```sh
[bundle exec] fastlane ios upload_existing_ipa
```

Upload the already exported IPA to App Store Connect

### ios prepare_review_candidate

```sh
[bundle exec] fastlane ios prepare_review_candidate
```

Upload build, then update metadata and screenshots for the new App Store version

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
