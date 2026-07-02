import SwiftUI

// MARK: - Frequency-range chart (which gear reproduces which frequencies)

struct FrequencyRangeChart: View {
    var gear: [Gear]
    var selectedID: String?
    var markerHz: Double?
    var accent: Color
    @EnvironmentObject var lang: LangStore

    private let fMin = 20.0, fMax = 20000.0
    private func x(_ hz: Double, _ w: CGFloat) -> CGFloat {
        CGFloat((log(hz) - log(fMin)) / (log(fMax) - log(fMin))) * w
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("20 Hz").mono(9).foregroundColor(Theme.textFaint)
                Spacer()
                Text("1 kHz").mono(9).foregroundColor(Theme.textFaint)
                Spacer()
                Text("20 kHz").mono(9).foregroundColor(Theme.textFaint)
            }
            ForEach(gear) { row($0) }
            if markerHz != nil {
                Text(lang.t("The white line is the note you are playing."))
                    .ui(11).foregroundColor(Theme.textFaint)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).panel()
    }

    private func row(_ g: Gear) -> some View {
        let on = g.id == selectedID
        return HStack(spacing: 10) {
            Text(lang.t(g.short))
                .ui(12, on ? .semibold : .regular)
                .foregroundColor(on ? accent : Theme.textMuted)
                .frame(width: 82, alignment: .leading)
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline(0.06)).frame(height: 8)
                        .frame(maxHeight: .infinity, alignment: .center)
                    Capsule().fill(on ? accent : Theme.textDim.opacity(0.45))
                        .frame(width: max(4, x(g.high, w) - x(g.low, w)), height: 8)
                        .offset(x: x(g.low, w))
                        .frame(maxHeight: .infinity, alignment: .center)
                    if let m = markerHz {
                        Rectangle().fill(.white).frame(width: 1.5)
                            .offset(x: x(m, w))
                    }
                }
            }
            .frame(height: 18)
        }
    }
}

// MARK: - Gear selector chips

struct GearChips: View {
    var gear: [Gear]
    @Binding var selectedID: String?
    var accent: Color
    @EnvironmentObject var lang: LangStore

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(gear) { g in
                let on = g.id == selectedID
                Button { selectedID = on ? nil : g.id } label: {
                    Text(lang.t(g.name))
                        .ui(12, on ? .semibold : .regular)
                        .foregroundColor(on ? .black : Theme.textMuted)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(on ? accent : Theme.inset)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Scenario → setup matching

struct ScenarioMatchView: View {
    var scenarios: [Playback.Scenario]
    var gear: [Gear]
    @Binding var matches: [String: String]
    var accent: Color
    @EnvironmentObject var lang: LangStore

    var body: some View {
        VStack(spacing: 12) {
            ForEach(scenarios) { s in card(s) }
        }
    }

    private func card(_ s: Playback.Scenario) -> some View {
        let chosen = matches[s.id]
        let correct = chosen == s.gearID
        return VStack(alignment: .leading, spacing: 10) {
            Text(lang.t(s.title)).ui(15, .medium).foregroundColor(Theme.textPrimary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
                ForEach(gear) { g in
                    let on = chosen == g.id
                    Button { matches[s.id] = g.id } label: {
                        Text(lang.t(g.short))
                            .ui(11, on ? .semibold : .regular)
                            .foregroundColor(on ? .black : Theme.textMuted)
                            .frame(maxWidth: .infinity).padding(.vertical, 7)
                            .background(on ? (correct ? accent : Theme.rec.opacity(0.8)) : Theme.inset)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            if correct {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(accent).font(.system(size: 13))
                    Text(lang.t(s.why)).ui(12).foregroundColor(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if chosen != nil {
                Text(lang.t("Not the best fit. Try another.")).ui(12).foregroundColor(Theme.textFaint)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .panel().overlay(
            RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                .stroke(correct ? accent.opacity(0.6) : .clear, lineWidth: 1.5))
    }
}
