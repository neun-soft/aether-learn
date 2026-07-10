# Aether Learn — submission status & finish sheet

App Store Connect app ID **6786776504** · bundle `app.neun.aether.learn` · team 7LAGLNXS6L

## Done (automated)

- ✅ App record created in App Store Connect + Developer Portal.
- ✅ Signed release binary built and **uploaded** (build 1.0). Processing on Apple's
  side takes 5–30 min; it'll appear under TestFlight / the version's "Build" picker.
- ✅ All 6 screenshots (6.7") uploaded to the 1.0 version.
- ✅ App name set: **Aether Learn**.

## Blocked (fastlane bug — do these in the ASC web UI)

The first-version text metadata upload hits fastlane deliver bug #20538 (ASC returns
"No data" on a brand-new app's version localization). This clears itself once the
app has its first submitted version, so `fastlane release` / `fastlane metadata`
will work for every future update. For THIS first version, paste the fields below.

Open App Store Connect → Apps → Aether Learn → iOS App 1.0.

### 1. Version fields (paste)

**Subtitle**
```
Learn synthesis by ear
```
**Promotional Text**
```
Learn how synthesizers really work by playing a real one built into every lesson. From what sound is to filters, envelopes, and modulation.
```
**Keywords**
```
synth,synthesizer,sound design,music theory,waveform,filter,LFO,ear training,producer
```
**Description** — copy from `fastlane/metadata/en-US/description.txt`.

**Support URL** `https://aether.neunsoft.com/support`
**Marketing URL** `https://aether.neunsoft.com/learn`
**Copyright** `2026 Neun`

### 2. App-level settings (required before you can submit)

- **Privacy Policy URL** (App Information): `https://aether.neunsoft.com/privacy`
- **Category**: Primary **Music**, Secondary **Education**.
- **Pricing and Availability**: **Free**, all territories.
- **App Privacy**: **Data Not Collected** (no accounts, analytics, or network calls).
- **Age Rating**: run the questionnaire, all "None" → **4+**.

### 3. Attach build + submit

- Under the 1.0 version, **Build → +**, pick the processed build (1.0).
- Export compliance: **No** (uses no non-exempt encryption).
- **Add for Review → Submit**.

## Retry path (optional)

The metadata bug is usually eventual-consistency. If you'd rather not paste, wait
~1 hour after app creation and run:
```
cd /Users/diego/Development/neun/aether/learn
set -a; . fastlane/.env; set +a
fastlane metadata      # text + screenshots
fastlane release       # rebuild, upload, submit for review
```
If `fastlane metadata` still says "No data", the paste sheet above is the reliable
path. Once the first version is submitted, fastlane handles all future releases.
