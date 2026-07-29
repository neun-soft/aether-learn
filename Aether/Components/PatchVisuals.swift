import SwiftUI

// MARK: - The signal path, lit up as you build

/// The whole synth as five boxes in the order sound travels through them, with the boxes this
/// lesson is actually working on lit and the rest dimmed. By the last module the reader has met
/// every one of these separately; this is the first time they see them as one chain, and it is
/// the thing that turns a pile of knobs into a machine you can reason about.
struct SignalPathView: View {
    /// Which stages this lesson is about. Everything else is drawn dim.
    var active: Set<Stage>
    /// Live values so the boxes describe what is actually set, not a generic label.
    var wave: Double
    var noise: Double
    var cutoff: Double
    var attack: Double
    var release: Double
    var accent: Color
    /// One line under the diagram saying what this patch is for.
    var caption: String

    enum Stage: Hashable { case source, filter, envelope, movement, space }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("HOW THE SOUND TRAVELS").mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                Spacer()
                Text("left to right").mono(9).foregroundColor(Theme.textDim)
            }

            HStack(spacing: 5) {
                stage(.source, "SOURCE", sourceLabel)
                arrow
                stage(.filter, "FILTER", filterLabel)
                arrow
                stage(.envelope, "SHAPE", envelopeLabel)
                arrow
                stage(.space, "SPACE", "room")
            }
            .frame(height: 92)

            Text(caption)
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sourceLabel: String {
        if noise > 0.6 { return "noise" }
        if wave < 0.2 { return "round" }
        if wave < 0.5 { return "soft" }
        return "rich"
    }
    private var filterLabel: String {
        cutoff < 0.4 ? "closed" : (cutoff < 0.75 ? "half open" : "open")
    }
    private var envelopeLabel: String {
        if attack > 0.3 { return "slow in" }
        if release > 0.45 { return "long tail" }
        return "quick"
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Theme.textDim.opacity(0.7))
    }

    @ViewBuilder private func stage(_ s: Stage, _ title: String, _ value: String) -> some View {
        let on = active.contains(s)
        VStack(spacing: 4) {
            Text(title).mono(8, .semibold).tracking(0.8)
                .foregroundColor(on ? accent : Theme.textDim)
            Text(value).mono(9)
                .foregroundColor(on ? Theme.textPrimary : Theme.textDim.opacity(0.7))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .padding(.vertical, 10).padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(on ? accent.opacity(0.14) : Theme.inset)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(on ? accent.opacity(0.75) : Theme.hairline(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
