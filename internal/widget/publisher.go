package widget

import (
	"context"
	"errors"
	"time"
)

var ErrSnapshotTooLarge = errors.New("widget snapshot exceeds size limit")

// Run is synchronous and owned by the caller's context; errors contain no
// activity data. The caller must join it before closing its data source.
func (p *Publisher) Run(ctx context.Context, report func(error)) {
	tick := time.NewTicker(30 * time.Second)
	defer tick.Stop()
	for {
		if ctx.Err() != nil {
			return
		}
		readCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		err := p.Refresh(readCtx)
		cancel()
		if err != nil && ctx.Err() == nil && report != nil {
			report(err)
		}
		select {
		case <-ctx.Done():
			return
		case <-tick.C:
		}
	}
}
