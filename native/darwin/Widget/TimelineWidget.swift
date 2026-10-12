import SwiftUI
import WidgetKit

struct DaygoEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct DaygoProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaygoEntry { DaygoEntry(date: .now, snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (DaygoEntry) -> Void) {
        let now = Date()
        completion(DaygoEntry(date: now, snapshot: WidgetSnapshot.load(now: now)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DaygoEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshot.load(now: now)
        var entries = [DaygoEntry(date: now, snapshot: snapshot)]
        if let snapshot {
            entries.append(DaygoEntry(date: Date(timeIntervalSince1970: Double(snapshot.validUntilTs)), snapshot: nil))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

struct TimelineWidgetView: View {
    let entry: DaygoEntry
    @Environment(\.widgetFamily) private var family
    var body: some View { TimelineWidgetContent(entry: entry, family: family) }
}

// Explicit family keeps the presentation inspectable outside the system host.
struct TimelineWidgetContent: View {
    let entry: DaygoEntry
    let family: WidgetFamily
    private var limit: Int { family == .systemSmall ? 1 : family == .systemMedium ? 3 : 8 }
    private var locale: Locale { Locale(identifier: entry.snapshot?.language ?? "zh-CN") }
    private func copy(_ key: String) -> String {
        let language = entry.snapshot?.language ?? Locale.preferredLanguages.first ?? "zh-CN"
        let supported = ["zh-CN", "zh-Hant", "en", "ja", "ko", "de", "fr", "es", "pt-BR"]
        let match: String
        if supported.contains(language) { match = language }
        else if language.hasPrefix("zh-Hant") || language.hasPrefix("zh-TW") || language.hasPrefix("zh-HK") { match = "zh-Hant" }
        else if language.hasPrefix("zh") { match = "zh-CN" }
        else if language.hasPrefix("pt") { match = "pt-BR" }
        else { match = supported.first(where: { language.hasPrefix($0) }) ?? "en" }
        let bundle = Bundle.main.path(forResource: match, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 4 : family == .systemSmall ? 6 : 8) {
            HStack {
                Text("Daygo").font(.headline)
                Spacer()
                Text(copy("timeline")).font(.caption).foregroundStyle(.secondary)
            }
            if let snapshot = entry.snapshot {
                Text(snapshot.day).font(.caption2).foregroundStyle(.secondary)
                if snapshot.cards.isEmpty {
                    Spacer(minLength: 0)
                    Text(copy("empty")).font(.callout).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                } else {
                    ForEach(Array(snapshot.cards.prefix(limit))) { card in
                        HStack(alignment: .top, spacing: 8) {
                            RoundedRectangle(cornerRadius: 2).fill(color(card.colorHex)).frame(width: 3)
                            VStack(alignment: .leading, spacing: 2) {
                                if family != .systemSmall {
                                    HStack(spacing: 8) {
                                        HStack(spacing: 2) {
                                            Text(Date(timeIntervalSince1970: Double(card.startTs)), style: .time)
                                            if family == .systemMedium {
                                                Text("–")
                                                Text(Date(timeIntervalSince1970: Double(card.endTs)), style: .time)
                                            }
                                        }.font(.caption2).foregroundStyle(.secondary)
                                            .frame(width: family == .systemMedium ? 100 : 65, alignment: .leading)
                                        Text(card.title).font(family == .systemMedium ? .caption : .callout).lineLimit(1)
                                    }
                                } else {
                                    HStack(spacing: 3) {
                                        Text(Date(timeIntervalSince1970: Double(card.startTs)), style: .time)
                                        Text("–")
                                        Text(Date(timeIntervalSince1970: Double(card.endTs)), style: .time)
                                    }.font(.caption2).foregroundStyle(.secondary)
                                    Text(card.title).font(.callout).lineLimit(family == .systemSmall ? 3 : 1)
                                }
                            }
                        }.fixedSize(horizontal: false, vertical: true).privacySensitive()
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 4) {
                    Text(copy("updated"))
                    Text(Date(timeIntervalSince1970: Double(snapshot.generatedAtTs)), style: .time)
                }.font(.caption2).foregroundStyle(.secondary)
            } else {
                Spacer(minLength: 0)
                Text(copy("sync")).font(.callout).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .environment(\.locale, locale)
        .containerBackground(.background, for: .widget)
    }
    private func color(_ hex: String) -> Color {
        guard hex.count == 7, hex.first == "#", let value = UInt32(hex.dropFirst(), radix: 16) else { return .accentColor }
        return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
