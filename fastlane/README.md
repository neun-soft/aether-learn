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

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload a beta to TestFlight

### ios whoami

```sh
[bundle exec] fastlane ios whoami
```

Report whether the app record exists in App Store Connect

### ios setup

```sh
[bundle exec] fastlane ios setup
```

Create the app record in App Store Connect if it doesn't exist yet

### ios push_build

```sh
[bundle exec] fastlane ios push_build
```

Upload the already-built IPA to App Store Connect (no rebuild)

### ios screens

```sh
[bundle exec] fastlane ios screens
```

Upload only the screenshots (no binary, no text metadata)

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Push text metadata only (no build, no screenshots)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit a release to the App Store

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Attach the already-uploaded build and submit for review (no rebuild)

### ios pull_from_review

```sh
[bundle exec] fastlane ios pull_from_review
```

TEMP: cancel the in-progress review submission (unlock editing)

### ios shots_audit

```sh
[bundle exec] fastlane ios shots_audit
```

TEMP: audit screenshots on App Store Connect

### ios bump

```sh
[bundle exec] fastlane ios bump
```

Bump the marketing version (major|minor|patch). Usage: fastlane bump type:minor

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
