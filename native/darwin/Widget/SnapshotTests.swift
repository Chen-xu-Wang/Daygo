import Foundation

@main
struct SnapshotTests {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let raw = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let stamp = (raw["generatedAtTs"] as! NSNumber).doubleValue
        let now = Date(timeIntervalSince1970: stamp)
        guard let snapshot = WidgetSnapshot.decode(data, now: now), snapshot.cards.first?.title == "匿名活动", snapshot.day == "2026-10-12" else { fatalError("Go/Swift v1 fixture mismatch") }
        precondition(WidgetSnapshot.decode(data, now: Date(timeIntervalSince1970: Double(snapshot.validUntilTs))) == nil, "expired snapshot accepted")
        precondition(WidgetSnapshot.decode(Data("{}".utf8), now: now) == nil, "malformed snapshot accepted")
        precondition(WidgetSnapshot.decode(Data(repeating: 32, count: 32 * 1024 + 1), now: now) == nil, "oversized snapshot accepted")
        for (key, value) in [("version", 2), ("generatedAtTs", Int(stamp) + 120), ("validUntilTs", Int(stamp) + 27 * 3600)] {
            var changed = raw
            changed[key] = value
            precondition(WidgetSnapshot.decode(try! JSONSerialization.data(withJSONObject: changed), now: now) == nil, "invalid field accepted: " + key)
        }
        var changed = raw
        changed["cards"] = Array(repeating: (raw["cards"] as! [[String: Any]])[0], count: 9)
        precondition(WidgetSnapshot.decode(try! JSONSerialization.data(withJSONObject: changed), now: now) == nil, "card limit ignored")
        changed["cards"] = Array(repeating: (raw["cards"] as! [[String: Any]])[0], count: 2)
        precondition(WidgetSnapshot.decode(try! JSONSerialization.data(withJSONObject: changed), now: now) == nil, "duplicate IDs accepted")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("daygo-widget-test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("snapshot.json")
        try writeWidgetSnapshot(data, to: file)
        let actual = try Data(contentsOf: file)
        precondition(actual == data, "atomic write changed snapshot")
        let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
        precondition((attrs[.posixPermissions] as! NSNumber).intValue == 0o600, "snapshot permissions differ")
        let replacement = Data("{}".utf8)
        try writeWidgetSnapshot(replacement, to: file)
        let replaced = try Data(contentsOf: file)
        precondition(replaced == replacement, "atomic replace failed")
        precondition(try! FileManager.default.contentsOfDirectory(atPath: directory.path).count == 1, "temporary file leaked")
        print("widget: Go/Swift v1, expiry, malformed, future, version, size, card limits and atomic 0600 replacement passed")
    }
}
