# Launching Aether Learn

Release automation is set up with Fastlane. This file lists the steps that need
your Apple credentials — the parts I can't do for you — and how to run the lanes.

## What's already wired up

- `fastlane/Fastfile` — three lanes: `beta` (TestFlight), `release` (App Store), `bump` (version).
- Auto signing via `-allowProvisioningUpdates`, matching the project's `CODE_SIGN_STYLE: Automatic`.
- Every lane runs `xcodegen generate` first, so the throwaway `.xcodeproj` is never stale.
- Version bumps edit `project.yml` (the real source of truth), then regenerate.
- App Store metadata scaffolded under `fastlane/metadata/` (description, keywords, etc.).
- `ITSAppUsesNonExemptEncryption: false` in `project.yml` so uploads skip the export-compliance prompt.
- A placeholder 1024 app icon at `Aether/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.

## One-time setup (needs your Apple account)

1. **App Store Connect API key.**
   App Store Connect → Users and Access → Integrations → App Store Connect API →
   generate a key with **App Manager** access. Download the `.p8` once (Apple only
   shows it once) and store it outside the repo, e.g. `~/.appstoreconnect/`.

2. **Fill in credentials.**
   ```
   cp fastlane/.env.example fastlane/.env
   ```
   Set `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH`. (`.env` and `*.p8` are gitignored.)

3. **Create the app record** (once), if it doesn't exist yet:
   ```
   fastlane produce -u <your-apple-id> --app_identifier app.neun.aether.learn \
     --app_name "Aether Learn" --language en-US
   ```
   Or create it by hand in App Store Connect. The bundle ID `app.neun.aether.learn`
   must be registered under team `7LAGLNXS6L`.

## Ship a TestFlight build

```
fastlane beta
```
Builds, stamps a unique timestamp build number, uploads to TestFlight. First run
creates the distribution cert/profile automatically (you may get a Keychain prompt).

## Submit to the App Store

```
fastlane release
```
Builds and pushes the binary + metadata. It stops short of submitting for review
(`submit_for_review: false`) until you've confirmed the listing. Flip that flag in
`fastlane/Fastfile` when you're ready to auto-submit.

## Before public launch — still to do

- [ ] **Replace the placeholder icon.** `icon-1024.png` is a generated sine-wave placeholder.
      Drop your final 1024×1024 (opaque, no alpha) at the same path.
- [ ] **Screenshots.** Required for App Store (not for TestFlight). Add 6.7" and 6.5"
      sets under `fastlane/screenshots/en-US/`, then set `skip_screenshots(false)` in
      `fastlane/Deliverfile`. `fastlane snapshot` can automate capture if you add a UI test.
- [ ] **Real URLs.** `fastlane/metadata/en-US/{support,marketing}_url.txt` currently point
      at `neun.app` placeholders. Update to live pages.
- [ ] **Privacy + age rating.** Set the privacy policy URL, data-collection answers, and
      age rating in App Store Connect (not managed by these files).
- [ ] **Confirm categories.** Primary Music / Secondary Education are in
      `fastlane/metadata/primary_category.txt` — change if you disagree.

## Notes

- Homebrew's `fastlane` works for local runs. The `Gemfile` pins it for CI; use
  `bundle exec fastlane ...` there.
- Set `SKIP_GIT_CHECK=1` to run a lane against a dirty tree (skips the clean-tree
  check and release tagging) — handy for dry runs.
- To migrate to `match` (git-stored certs) later: `fastlane match init`, create a
  private certs repo, then swap the auto-signing block in `build` for
  `match(type: "appstore", readonly: true)`.
