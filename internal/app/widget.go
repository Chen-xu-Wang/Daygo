package app

import (
	"context"
	"log"

	"github.com/Jwz-git/Daygo/internal/platform"
	"github.com/Jwz-git/Daygo/internal/settings"
	"github.com/Jwz-git/Daygo/internal/timeutil"
	"github.com/Jwz-git/Daygo/internal/widget"
)

// widgetSource is deliberately not a Wails binding.
type widgetSource struct{ backend *Backend }

func (s widgetSource) WidgetSnapshot(ctx context.Context) (widget.Snapshot, error) {
	store := s.backend.store()
	now := s.backend.clock.Now()
	day := timeutil.LogicalDay(now, store.Location())
	cards, err := store.Cards().CardsForDay(ctx, day)
	if err != nil {
		return widget.Snapshot{}, err
	}
	categories, err := store.Categories().List(ctx)
	if err != nil {
		return widget.Snapshot{}, err
	}
	prefs, err := settings.New(store.Settings()).Load(ctx)
	if err != nil {
		return widget.Snapshot{}, err
	}
	return widget.Build(now, store.Location(), resolveInterfaceLanguage(prefs), cards, categories), nil
}

func (b *Backend) startWidgetPublisher(parent context.Context) func() {
	sink, ok := b.system.(platform.WidgetSnapshotSink)
	writable, owner := b.instanceOwnership()
	if !ok || !writable || !owner || b.store() == nil || !sink.WidgetAvailable() {
		return func() {}
	}
	ctx, cancel := context.WithCancel(parent)
	done := make(chan struct{})
	publisher := &widget.Publisher{Source: widgetSource{b}, Sink: sink}
	go func() {
		defer close(done)
		publisher.Run(ctx, func(error) { log.Print("widget snapshot unavailable") })
	}()
	return func() { cancel(); <-done }
}
