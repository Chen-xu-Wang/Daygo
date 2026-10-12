package app

import (
	"context"
	"testing"
	"time"

	"github.com/Jwz-git/Daygo/internal/domain"
	"github.com/Jwz-git/Daygo/internal/platform/fake"
)

func TestWidgetSourcePreviousLogicalDayAndDeletion(t *testing.T) {
	backend, _ := writerBackendWithStore(t, t.TempDir())
	seedTimelineDay(t, backend, []domain.CardShell{{Start: "11:00 AM", End: "11:30 AM", Category: "Work", Title: "anonymous"}})
	backend.clock = fixedClock{now: time.Date(2026, 9, 13, 3, 30, 0, 0, backend.store().Location())}
	snapshot, err := (widgetSource{backend}).WidgetSnapshot(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.Day != "2026-09-12" || len(snapshot.Cards) != 1 {
		t.Fatalf("source: %+v", snapshot)
	}
	if err := backend.DeleteCard(snapshot.Cards[0].ID); err != nil {
		t.Fatal(err)
	}
	snapshot, err = (widgetSource{backend}).WidgetSnapshot(context.Background())
	if err != nil || len(snapshot.Cards) != 0 {
		t.Fatalf("deleted card remains: %+v %v", snapshot, err)
	}
	backend.clock = fixedClock{now: time.Date(2026, 9, 13, 4, 0, 0, 0, backend.store().Location())}
	snapshot, err = (widgetSource{backend}).WidgetSnapshot(context.Background())
	if err != nil || snapshot.Day != "2026-09-13" || len(snapshot.Cards) != 0 {
		t.Fatalf("4 AM rollover: %+v %v", snapshot, err)
	}
}

type widgetTestSystem struct {
	*fake.System
	availableChecks int
}

func (s *widgetTestSystem) WidgetAvailable() bool { s.availableChecks++; return false }
func (*widgetTestSystem) PublishWidgetSnapshot(context.Context, []byte) error {
	panic("unconfigured widget wrote data")
}
func TestWidgetPublisherRequiresBothOwnershipLocks(t *testing.T) {
	for _, capture := range []bool{false, true} {
		store := openTestStore(t, t.TempDir(), capture)
		backend := newBackend(fixedClock{now: time.Now()}, nil, store, false, false)
		system := &widgetTestSystem{}
		backend.system = system
		stop := backend.startWidgetPublisher(context.Background())
		stop()
		wanted := 0
		if capture {
			wanted = 1
		}
		if system.availableChecks != wanted {
			t.Fatalf("capture %v checked availability %d times", capture, system.availableChecks)
		}
	}
	dir := t.TempDir()
	_ = openTestStore(t, dir, true)
	reader := openTestStore(t, dir, true)
	backend := newBackend(fixedClock{now: time.Now()}, nil, reader, true, true)
	system := &widgetTestSystem{}
	backend.system = system
	backend.startWidgetPublisher(context.Background())()
	if system.availableChecks != 0 {
		t.Fatal("read-only instance checked publisher")
	}
}
