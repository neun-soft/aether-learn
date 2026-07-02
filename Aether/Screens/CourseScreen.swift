import SwiftUI

struct CourseScreen: View {
    let course: Course
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var lang: LangStore

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    ForEach(course.modules) { module in
                        moduleSection(module)
                    }
                    Spacer(minLength: 24)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AETHER LEARN")
                .mono(11, .medium).tracking(2)
                .foregroundColor(Theme.textDim)
            Text(lang.t(course.title))
                .ui(30, .semibold)
                .foregroundColor(Theme.textPrimary)
            Text(lang.t(course.subtitle))
                .ui(15)
                .foregroundColor(Theme.textMuted)
            ProgressBar(value: progress.courseProgress(course), tint: Theme.tone)
                .padding(.top, 6)
        }
        .padding(.top, 8)
    }

    private var langPicker: some View {
        Menu {
            ForEach(Lang.allCases) { l in
                Button { lang.lang = l } label: {
                    if lang.lang == l { Label(l.label, systemImage: "checkmark") } else { Text(l.label) }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "globe").font(.system(size: 12))
                Text(lang.lang.short).mono(11, .semibold)
            }
            .foregroundColor(Theme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.panel).clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.hairline(), lineWidth: 1))
        }
    }

    private func moduleSection(_ module: Module) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(module.accent).frame(width: 9, height: 9)
                Text(lang.t(module.title).uppercased())
                    .mono(12, .semibold).tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Int(progress.moduleProgress(module) * 100))%")
                    .mono(11).foregroundColor(Theme.textDim)
            }
            Text(lang.t(module.subtitle))
                .ui(13).foregroundColor(Theme.textDim)
                .padding(.bottom, 2)

            VStack(spacing: 8) {
                ForEach(Array(module.lessons.enumerated()), id: \.element.id) { idx, lesson in
                    NavigationLink(value: Route.lesson(Curriculum.indexOf(lesson.id))) {
                        lessonRow(lesson, index: idx + 1, accent: module.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func lessonRow(_ lesson: Lesson, index: Int, accent: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Theme.hairline(0.12), lineWidth: 1.5).frame(width: 30, height: 30)
                if progress.isDone(lesson.id) {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                        .foregroundColor(accent)
                } else {
                    Text("\(index)").mono(12).foregroundColor(Theme.textMuted)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(lang.t(lesson.title)).ui(16, .medium).foregroundColor(Theme.textPrimary)
                Text(lang.t(lesson.concept)).ui(12).foregroundColor(Theme.textDim).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textFaint)
        }
        .padding(14)
        .background(progress.isDone(lesson.id) ? accent.opacity(0.13) : Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: Theme.rRow, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rRow, style: .continuous)
                .stroke(progress.isDone(lesson.id) ? accent.opacity(0.45) : Theme.hairline(), lineWidth: 1))
    }
}

struct ProgressBar: View {
    var value: Double
    var tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline(0.08))
                Capsule().fill(tint).frame(width: max(0, geo.size.width * value))
            }
        }
        .frame(height: 6)
    }
}
