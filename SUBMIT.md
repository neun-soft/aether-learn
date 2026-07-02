# Submitting Aether Learn — finish steps

Everything automatable is done and committed: metadata, screenshots, icon,
credentials, and the fastlane lanes with submission info. What's left needs your
Apple login and the App Store Connect web UI (fastlane can't do these headlessly
for a brand-new app). This is the same flow Aether Jam and Alivio used.

## The one blocker: the app record doesn't exist yet

`app.neun.aether.learn` is not in App Store Connect. Creating it registers a new
bundle ID in the Developer Portal, which requires an interactive Apple ID login
with 2FA. Two ways:

**A. fastlane (terminal):** set your Apple ID, then run the setup lane:
```
cd app/ios   # (this repo)
# add your Apple Developer email to fastlane/Appfile:  apple_id("you@example.com")
set -a; . fastlane/.env; set +a
fastlane setup          # runs produce; enter your Apple ID password + 2FA once
```

**B. Web UI (what Jam/Alivio did):** App Store Connect → My Apps → + → New App.
- Platform: iOS · Name: **Aether Learn** · Language: **English (U.S.)**
- Bundle ID: **app.neun.aether.learn** (register it in the Developer Portal first
  if it's not in the dropdown) · SKU: **aetherlearn-1**

## Then one command does the rest

```
set -a; . fastlane/.env; set +a
fastlane release
```
This builds, uploads the binary, pushes all metadata + screenshots, sets the
export-compliance/IDFA/third-party answers, and submits for review. It does NOT
auto-release (you press "Release this version" after approval).

## ASC web-UI items fastlane can't set (do once, before review passes)

App Store Connect blocks a first submission until these are filled:

- [ ] **Pricing and Availability** → Price: **Free**, all territories.
- [ ] **App Privacy** → **Data Not Collected** (Aether Learn has no accounts,
      analytics, or network calls — same as Jam/Alivio).
- [ ] **Age Rating** → answer the questionnaire; all "None" → **4+**.

`fastlane release` will upload and attempt to submit; if these aren't set yet,
ASC holds the submission and flags them — fill them and re-run, or hit Submit in
the UI. Once they're set the first time, future updates submit hands-off.

## What's already filled (for reference)

| Field | Value |
|---|---|
| Name | Aether Learn |
| Subtitle | Learn synthesis by ear |
| Category | Music (primary) / Education (secondary) |
| Keywords | synth, synthesizer, sound design, music theory, waveform, filter, LFO, ear training, producer |
| Support URL | https://aether-jam.neunsoft.com/support |
| Marketing URL | https://neunsoft.com |
| Privacy URL | https://neunsoft.com/privacy |
| Copyright | 2026 Neun |
| Screenshots | 6× 6.7" in fastlane/screenshots/en-US |
| Version / build | 1.0 / timestamp per upload |

The URLs are family/company stopgaps (Learn's own `aether-learn.neunsoft.com`
has no TLS cert yet). Swap them in ASC anytime once those pages are live.
