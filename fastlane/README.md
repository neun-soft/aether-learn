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

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Push text metadata + screenshots only (no build)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit a release to the App Store

### ios bump

```sh
[bundle exec] fastlane ios bump
```

Bump the marketing version (major|minor|patch). Usage: fastlane bump type:minor

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
