import Image from "next/image";
import { Nav, Footer } from "./components";

export default function Home() {
  return (
    <>
      <Nav />

      {/* Hero */}
      <header className="container hero">
        <div>
          <span className="eyebrow">A hands-on course in synthesis</span>
          <h1>
            Learn how <span className="grad-text">synthesizers</span> really
            work.
          </h1>
          <p className="lede">
            Aether Learn teaches you sound from the ground up — one hands-on
            lesson at a time. No jargon, no prerequisites. Every idea comes with
            a real synth engine you play with your finger, so you hear it the
            moment you read it.
          </p>
          <div className="cta-row">
            <span className="btn btn-primary" aria-disabled="true">
              Coming soon to the App Store
            </span>
            <a href="#learn" className="btn btn-ghost">
              What you&apos;ll learn
            </a>
          </div>
          <div className="hero-meta">
            iPhone · iOS 17+ · No account, no sign-up, nothing collected
          </div>
        </div>
        <div className="phone-wrap">
          <div className="phone">
            <Image
              src="/shots/harmonics.png"
              alt="A waveform being built from pure sine waves, one at a time"
              width={1320}
              height={2868}
              style={{ height: "auto" }}
              priority
            />
          </div>
        </div>
      </header>

      {/* Module chips */}
      <section className="section" style={{ paddingTop: 40, paddingBottom: 40 }}>
        <div className="container">
          <div className="layers">
            <span className="chip tone">SOUND &amp; FREQUENCY</span>
            <span className="chip wave">WAVEFORMS</span>
            <span className="chip filter">FILTERS</span>
            <span className="chip shape">ENVELOPES</span>
            <span className="chip motion">MODULATION</span>
          </div>
          <p
            style={{
              textAlign: "center",
              color: "var(--text-dim)",
              marginTop: 18,
              fontSize: 14,
            }}
          >
            Five modules. From what sound is, to making sounds you understand.
          </p>
        </div>
      </section>

      {/* What you learn */}
      <section id="learn" className="section">
        <div className="container">
          <div className="section-head">
            <div className="kicker">Learn by playing</div>
            <h2>Read it, watch it, then play it yourself.</h2>
            <p>
              Every lesson has three steps: the idea in plain language, a short
              demo that moves the controls for you, then a real instrument you
              play. The waveform, harmonics, filter curve, and envelope all
              respond in real time as you turn the knobs.
            </p>
          </div>

          <div className="features">
            <article className="card">
              <div className="dot tone">≋</div>
              <h3>Start at the very beginning</h3>
              <p>
                What sound is, how frequency becomes pitch, and why a wave&apos;s
                shape decides its character. No prior music theory needed — just
                curiosity and headphones.
              </p>
            </article>

            <article className="card">
              <div className="dot wave">◇</div>
              <h3>See a wave built from sines</h3>
              <p>
                Add pure sine waves one at a time and watch them stack into a
                bright saw — then hear the tone sharpen with every one. The idea
                behind every sound, made visible.
              </p>
            </article>

            <article className="card">
              <div className="dot filter">◆</div>
              <h3>Shape tone with filters</h3>
              <p>
                Sweep the cutoff, add resonance, and hear the classic filter
                sweep. A live, EQ-style curve shows exactly which harmonics you
                keep and which you carve away.
              </p>
            </article>

            <article className="card">
              <div className="dot shape">▲</div>
              <h3>Sculpt sound over time</h3>
              <p>
                Attack, hold, decay, sustain, release, and delay — the envelope
                that turns one raw tone into a pluck, a pad, or a stab. Watch the
                playhead ride the shape you draw.
              </p>
            </article>

            <article className="card">
              <div className="dot motion">∿</div>
              <h3>Add motion and movement</h3>
              <p>
                LFOs, vibrato, tremolo, and the rhythmic filter wobble at the
                heart of bass music. Point one modulator anywhere and hear the
                sound come alive.
              </p>
            </article>

            <article className="card">
              <div className="dot neutral">⛶</div>
              <h3>Yours, on device</h3>
              <p>
                Everything runs on your phone. No account, no analytics, no
                network calls. Learn at your own pace, fully offline.
              </p>
            </article>
          </div>
        </div>
      </section>

      {/* Screens */}
      <section id="screens" className="section">
        <div className="container">
          <div className="section-head">
            <div className="kicker">A look inside</div>
            <h2>A real synth, in every lesson.</h2>
            <p>
              A deep, dim interface that keeps the focus on sound — with a color
              for every module and a live instrument on every screen.
            </p>
          </div>
          <div className="shots">
            {[
              {
                src: "/shots/harmonics.png",
                alt: "Building a wave from sine waves",
              },
              { src: "/shots/filter.png", alt: "Filter cutoff and resonance" },
              { src: "/shots/envelope.png", alt: "The ADSR envelope shape" },
              { src: "/shots/play.png", alt: "Playing the built-in synth" },
            ].map((s) => (
              <div className="shot" key={s.src}>
                <Image src={s.src} alt={s.alt} width={1320} height={2868} />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="section" style={{ borderTop: "none" }}>
        <div className="container">
          <div className="cta-band">
            <h2>Go from zero to making sounds you understand.</h2>
            <p>
              Aether Learn is a one-time download. No subscription, no sign-up —
              just the whole introductory course to sound design.
            </p>
            <span className="btn btn-primary" aria-disabled="true">
              Coming soon to the App Store
            </span>
          </div>
        </div>
      </section>

      <Footer />
    </>
  );
}
