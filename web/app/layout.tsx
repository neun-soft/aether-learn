import type { Metadata, Viewport } from "next";
import { Space_Grotesk, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const display = Space_Grotesk({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-display",
  display: "swap",
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-mono",
  display: "swap",
});

const SITE_URL = "https://aether-learn.neunsoft.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Aether Learn: Learn synthesis by ear",
    template: "%s · Aether Learn",
  },
  description:
    "Learn how sound and synthesizers really work, one hands-on lesson at a time. Every concept comes with a real synth engine you play with your finger.",
  keywords: [
    "synth",
    "synthesizer",
    "sound design",
    "music theory",
    "learn synthesis",
    "ear training",
    "waveform",
    "filter",
    "LFO",
    "iOS music app",
    "Aether",
    "Neun",
  ],
  authors: [{ name: "Neun" }],
  applicationName: "Aether Learn",
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: "Aether Learn",
    title: "Aether Learn: Learn synthesis by ear",
    description:
      "Understand every sound you make. A hands-on course in synthesis, with a real synth engine built into every lesson.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Aether Learn: Learn synthesis by ear",
    description:
      "Understand every sound you make. A hands-on course in synthesis, with a real synth engine built into every lesson.",
  },
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#0a0c12",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${display.variable} ${mono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
