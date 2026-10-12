import Foundation

struct WidgetCard: Codable, Identifiable {
    let id: Int64
    let startTs: Int64
    let endTs: Int64
    let title: String
    let colorHex: String
}

struct WidgetSnapshot: Codable {
    let version: Int
    let day: String
    let language: String
    let generatedAtTs: Int64
    let validUntilTs: Int64
    let cards: [WidgetCard]

    static func decode(_ data: Data, now: Date) -> WidgetSnapshot? {
        guard data.count <= 32 * 1024,
              let value = try? JSONDecoder().decode(Self.self, from: data),
              value.version == 1, value.cards.count <= 8,
              value.day.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
              value.generatedAtTs <= Int64(now.timeIntervalSince1970) + 60,
              value.validUntilTs > Int64(now.timeIntervalSince1970),
              value.validUntilTs > value.generatedAtTs,
              value.validUntilTs - value.generatedAtTs <= 26 * 3600,
              Set(value.cards.map(\.id)).count == value.cards.count,
              value.cards.allSatisfy({ $0.id > 0 && $0.endTs > $0.startTs && $0.endTs - $0.startTs <= 4 * 3600 && $0.title.unicodeScalars.count <= 160 && $0.startTs <= value.generatedAtTs && $0.endTs <= value.validUntilTs })
        else { return nil }
        return value
    }

    static func load(now: Date) -> WidgetSnapshot? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "DaygoWidgetAppGroup") as? String,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { return nil }
        let url = container.appendingPathComponent("timeline-widget-v1.json")
        // Bound IO before reading, then bound the decoded bytes as well.
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber, size.intValue <= 32 * 1024,
              let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 32 * 1024 + 1) else { return nil }
        return decode(data, now: now)
    }
}
