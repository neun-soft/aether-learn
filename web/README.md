# Aether Learn — website

Marketing site + legal pages for **Aether Learn** (the Neun iOS app),
deployed at **aether-learn.neunsoft.com**.

Built with Next.js (App Router) + TypeScript. No CSS framework — the theme in
`app/globals.css` mirrors the app's own design tokens
(`Aether/DesignSystem/Theme.swift`). Mirrors the structure of the Aether Jam
site (`../../app/web`).

## Pages

| Route      | Purpose                                    |
| ---------- | ------------------------------------------ |
| `/`        | Landing page                               |
| `/privacy` | Privacy policy (App Store Privacy URL)     |
| `/terms`   | Terms of service                           |
| `/support` | Support / FAQ (App Store Support URL)      |

## Develop

```sh
cd web
npm install
npm run dev      # http://localhost:3000
npm run build    # production build
```

## Assets

- `public/logo.svg` / `public/favicon.svg` — the sine-wave mark, matching the
  app icon (gold→lavender→blue on the family's dark background).
- `public/shots/*.png` — the 6.7" App Store screenshots. Regenerate the source
  with `swift ../tool/make-screenshots.swift ../fastlane/screenshots/en-US`,
  then copy them here.

## Deploy to Vercel

Lives in the `web/` subdirectory of the Aether Learn repo. Point a Vercel
project at this directory and set the custom domain to
`aether-learn.neunsoft.com` (this subdomain needs a TLS cert — it currently
resolves to the shared host but has no cert, which is why the App Store listing
temporarily uses `neunsoft.com/privacy`).
