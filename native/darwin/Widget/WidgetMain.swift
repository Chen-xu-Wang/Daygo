import SwiftUI
import WidgetKit

@main
struct DaygoTimelineWidget: Widget {
    let kind = "DaygoTimeline"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaygoProvider()) { entry in TimelineWidgetView(entry: entry) }
            .configurationDisplayName("timeline")
            .description("description")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
