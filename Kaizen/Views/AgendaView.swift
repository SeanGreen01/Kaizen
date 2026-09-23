import SwiftUI

struct CalendarDateStrip: View {
    @Binding var selection: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let events: [CalendarEvent]
    let tasks: [TaskItem]
    @State private var anchor = Calendar.current.startOfDay(for: Date())
    private var days: [Date] {
        (-365...365).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: anchor) }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(days, id: \.self) { date in
                            let selected = Calendar.current.isDate(date, inSameDayAs: selection)
                            let categories = Set(AgendaEntry.entries(on: date, events: events, tasks: tasks).map(\.category))
                            Button { selection = date } label: {
                                VStack(spacing: 6) {
                                    VStack(spacing: 7) {
                                        Text(date.formatted(.dateTime.day())).font(.system(size: 22, weight: .regular))
                                        Text(date.formatted(.dateTime.weekday(.abbreviated)).lowercased())
                                            .font(.system(size: 10, weight: .regular))
                                    }
                                    .frame(width: 46, height: 66)
                                    .background(selected ? KaizenTheme.surface : .clear, in: Capsule())
                                    HStack(spacing: 3) {
                                        ForEach(TaskCategory.allCases.filter { categories.contains($0) }) { category in
                                            Circle().fill(category.color).frame(width: 3, height: 3)
                                        }
                                    }.frame(height: 4)
                                }
                                .foregroundStyle(selected ? .white : KaizenTheme.muted)
                                .frame(width: geometry.size.width / 7.8, height: 90)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain).id(date)
                            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                            .accessibilityValue("\(categories.count) categories with scheduled items")
                            .accessibilityIdentifier("day-\(DayKey.string(date))")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }.scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .task { proxy.scrollTo(Calendar.current.startOfDay(for: selection), anchor: .center) }
                .onChange(of: selection) { _, date in
                    let day = Calendar.current.startOfDay(for: date)
                    if !days.contains(day) { anchor = day }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { proxy.scrollTo(day, anchor: .center) }
                }
                .onChange(of: anchor) { _, _ in
                    proxy.scrollTo(Calendar.current.startOfDay(for: selection), anchor: .center)
                }
            }
        }.frame(height: 96)
    }
}

struct AgendaList: View {
    let entries: [AgendaEntry]
    var onSelect: ((AgendaEntry) -> Void)? = nil
    @ScaledMetric(relativeTo: .caption2) private var timeWidth = 110.0

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if entries.contains(where: \.allDay) {
                section(title: "All day", range: "", items: entries.filter(\.allDay))
            }
            ForEach(AgendaPeriod.allCases) { period in
                section(title: period.rawValue, range: period.rangeLabel,
                        items: entries.filter { !$0.allDay && AgendaPeriod.at($0.start) == period })
            }
        }
    }

    private func section(title: String, range: String, items: [AgendaEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 19, weight: .medium))
                Spacer()
                Text(range).font(.system(size: 10)).foregroundStyle(KaizenTheme.muted)
            }
            if items.isEmpty {
                Text("Nothing scheduled").font(.subheadline).foregroundStyle(KaizenTheme.muted.opacity(0.7))
                    .padding(.vertical, 7)
            }
            VStack(spacing: 0) {
                ForEach(items) { entry in
                    if let onSelect {
                        Button { onSelect(entry) } label: { row(entry) }.buttonStyle(.plain)
                    } else { row(entry) }
                }
            }
        }
    }

    private func row(_ entry: AgendaEntry) -> some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 1).fill(entry.category.color).frame(width: 2, height: 22)
            Text(entry.title).font(.subheadline).fontWeight(.regular)
                .strikethrough(entry.completed).foregroundStyle(entry.completed ? KaizenTheme.muted : Color(white: 0.88))
                .frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
            Text(entry.allDay ? "all day" : "\(entry.start.formatted(date: .omitted, time: .shortened).lowercased())–\(entry.end.formatted(date: .omitted, time: .shortened).lowercased())")
                .font(.caption2).foregroundStyle(KaizenTheme.muted)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: timeWidth, alignment: .trailing)
        }
        .frame(minHeight: 34).contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.category.rawValue), \(entry.allDay ? "all day" : entry.start.formatted(date: .omitted, time: .shortened) + " to " + entry.end.formatted(date: .omitted, time: .shortened))\(entry.completed ? ", completed" : "")")
    }
}
