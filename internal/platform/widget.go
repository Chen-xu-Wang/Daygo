package platform

import "context"

// WidgetSnapshotSink is optional. An adapter advertises availability only when
// the containing app has explicit App Group configuration. Payload is a v1
// bounded JSON snapshot, never a database path or raw activity metadata.
type WidgetSnapshotSink interface {
	WidgetAvailable() bool
	PublishWidgetSnapshot(context.Context, []byte) error
}
