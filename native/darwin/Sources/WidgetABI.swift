import Foundation
import Darwin
import WidgetKit

private func widgetContainer() -> URL? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "DaygoWidgetAppGroup") as? String,
          !group.isEmpty else { return nil }
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
}

@_cdecl("dg_widget_available")
public func dgWidgetAvailable() -> Int32 {
    widgetContainer() == nil ? 0 : 1
}

@_cdecl("dg_widget_publish")
public func dgWidgetPublish(_ payload: UnsafePointer<UInt8>?, _ length: Int32) -> Int32 {
    guard let payload, length > 0, length <= 32 * 1024 else { return 1 }
    guard let container = widgetContainer() else { return 2 }
    do {
        let data = Data(bytes: payload, count: Int(length))
        let url = container.appendingPathComponent("timeline-widget-v1.json")
        try writeWidgetSnapshot(data, to: url)
        WidgetCenter.shared.reloadTimelines(ofKind: "DaygoTimeline")
        return 0
    } catch { return 3 }
}

// Same atomic 0600 writer is exercised with anonymous temporary files.
func writeWidgetSnapshot(_ data: Data, to url: URL) throws {
    let temporary = url.deletingLastPathComponent().appendingPathComponent(".timeline-widget-" + UUID().uuidString)
    let fd = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL, 0o600)
    guard fd >= 0 else { throw CocoaError(.fileWriteUnknown) }
    let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
    defer { try? handle.close(); try? FileManager.default.removeItem(at: temporary) }
    try handle.write(contentsOf: data)
    try handle.synchronize()
    try handle.close()
    guard rename(temporary.path, url.path) == 0 else { throw CocoaError(.fileWriteUnknown) }
}
