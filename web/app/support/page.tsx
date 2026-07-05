import type { Metadata } from "next";
import Link from "next/link";
import { Nav, Footer, CONTACT_EMAIL } from "../components";

export const metadata: Metadata = {
  title: "Support",
  description:
    "Get help with Aether Learn: answers to common questions and how to reach us.",
};

export default function Support() {
  return (
    <>
      <Nav />
      <main className="prose">
        <Link href="/" className="back">
          ← Back to Aether Learn
        </Link>
        <h1>Support</h1>
        <p className="updated">We&apos;re a small team and we read every email.</p>

        <p className="lead">
          Something not working, or have a lesson idea? Email{" "}
          <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a> and we&apos;ll
          get back to you.
        </p>

        <h2>Frequently asked</h2>

        <h2 style={{ fontSize: 17 }}>Do I need to know music theory?</h2>
        <p>
          No. Aether Learn starts at the very beginning, from what sound is, and
          builds up from there. No notation, no prerequisites, just headphones
          and curiosity.
        </p>

        <h2 style={{ fontSize: 17 }}>Do I need an account?</h2>
        <p>
          No. Aether Learn has no accounts and no sign-up. Download it and start
          the first lesson.
        </p>

        <h2 style={{ fontSize: 17 }}>Does it work offline?</h2>
        <p>
          Yes, entirely. The app makes no network calls, so every lesson and the
          built-in synth work with no connection.
        </p>

        <h2 style={{ fontSize: 17 }}>I hear no sound. What should I check?</h2>
        <p>
          Make sure your device isn&apos;t on silent mode and the volume is up.
          Headphones are recommended, especially for the lessons about bass and
          low frequencies.
        </p>

        <h2 style={{ fontSize: 17 }}>Is my progress saved?</h2>
        <p>
          Yes. Your lesson progress is stored locally on your device so you can
          pick up where you left off.
        </p>

        <h2 style={{ fontSize: 17 }}>What devices are supported?</h2>
        <p>Aether Learn runs on iPhone with iOS 17 or later.</p>

        <h2>Still stuck?</h2>
        <p>
          Email <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a> with your
          device model and iOS version and we&apos;ll help you out.
        </p>
      </main>
      <Footer />
    </>
  );
}
