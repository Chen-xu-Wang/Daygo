package widget

import (
	"context"
	"errors"
	"testing"
	"time"
)

type fixtureSource struct {
	value Snapshot
	err   error
}

func (s *fixtureSource) WidgetSnapshot(context.Context) (Snapshot, error) { return s.value, s.err }

type fixtureSink struct {
	calls int
	err   error
}

func (s *fixtureSink) PublishWidgetSnapshot(context.Context, []byte) error { s.calls++; return s.err }
func TestPublisherChangeDetectionRetryAndDeletion(t *testing.T) {
	source := &fixtureSource{value: Build(time.Now(), time.UTC, "en", nil, nil)}
	sink := &fixtureSink{}
	p := Publisher{Source: source, Sink: sink}
	if err := p.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	source.value.GeneratedAtTs++
	if err := p.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if sink.calls != 1 {
		t.Fatal("timestamp alone requested reload")
	}
	source.value.Cards = []Card{{ID: 1, StartTs: 1, EndTs: 2, Title: "anonymous"}}
	sink.err = errors.New("fixture write failure")
	if p.Refresh(context.Background()) == nil {
		t.Fatal("lost sink failure")
	}
	sink.err = nil
	if err := p.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if sink.calls != 3 {
		t.Fatal("failed publish was not retried")
	}
	source.value.Cards = []Card{}
	if err := p.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if sink.calls != 4 {
		t.Fatal("deletion did not invalidate")
	}
	source.err = errors.New("fixture read failure")
	if p.Refresh(context.Background()) == nil || sink.calls != 4 {
		t.Fatal("read failure overwrote snapshot")
	}
}
func TestPublisherCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	sink := &fixtureSink{}
	p := Publisher{Source: &fixtureSource{}, Sink: sink}
	done := make(chan struct{})
	go func() { p.Run(ctx, nil); close(done) }()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("publisher did not stop")
	}
	if sink.calls != 0 {
		t.Fatal("canceled publisher still wrote")
	}
}

type canceledSource struct{ started chan struct{} }

func (s canceledSource) WidgetSnapshot(ctx context.Context) (Snapshot, error) {
	close(s.started)
	<-ctx.Done()
	return Snapshot{}, ctx.Err()
}
func TestPublisherCancelsInFlightRead(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	started := make(chan struct{})
	sink := &fixtureSink{}
	p := Publisher{Source: canceledSource{started}, Sink: sink}
	done := make(chan struct{})
	go func() { p.Run(ctx, nil); close(done) }()
	select {
	case <-started:
	case <-time.After(time.Second):
		t.Fatal("read never started")
	}
	cancel()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("in-flight read did not cancel")
	}
	if sink.calls != 0 {
		t.Fatal("canceled read published data")
	}
}
