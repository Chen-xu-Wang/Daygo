import SwiftUI
import AppKit
import WidgetKit
@main
struct Preview {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let titles = ["实现时间线小组件", "运行匿名契约测试", "检查凌晨四点换日", "阅读原生扩展文档", "调整分类配色", "验证多语言文案", "准备贡献说明", "回顾今天的进度"]
        let colors = ["#467CE8", "#24A083", "#9C6ADE"]
        var cards: [WidgetCard] = []
        for index in 0..<8 {
            let start: Int64 = 1791799200 - Int64(index * 1800)
            cards.append(WidgetCard(id: Int64(index + 1), startTs: start, endTs: start + 1800, title: titles[index], colorHex: colors[index % 3]))
        }
        let snapshot = WidgetSnapshot(version: 1, day: "2026-10-12", language: "zh-CN", generatedAtTs: 1791799200, validUntilTs: 1791864000, cards: cards)
        for theme in [ColorScheme.light, ColorScheme.dark] {
            for (name, family, width, height) in [("small", WidgetFamily.systemSmall, 170.0, 170.0), ("medium", WidgetFamily.systemMedium, 360.0, 170.0), ("large", WidgetFamily.systemLarge, 360.0, 380.0)] {
                let view = TimelineWidgetContent(entry: DaygoEntry(date: Date(timeIntervalSince1970: 1791799200), snapshot: snapshot), family: family)
                    .environment(\.colorScheme, theme)
                    .padding(16).frame(width: width, height: height).background(theme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.09) : Color.white)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                guard let image = renderer.cgImage else { fatalError("render failed") }
                let rep = NSBitmapImageRep(cgImage: image)
                try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1] + "/" + name + (theme == .dark ? "-dark" : "") + ".png"))
            }
        }
    }
}
