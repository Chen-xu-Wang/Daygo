package widget

import (
	"encoding/json"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/Jwz-git/Daygo/internal/domain"
)

func TestSnapshotBoundedMinimalLatestFirst(t *testing.T) {
	now := time.Date(2026, 10, 12, 3, 30, 0, 0, time.FixedZone("fixture", 8*3600))
	cards := make([]domain.TimelineCard, 12)
	for i := range cards {
		cards[i] = domain.TimelineCard{ID: int64(i + 1), StartTs: now.Add(time.Duration(i-12) * time.Minute).Unix(), EndTs: now.Add(time.Duration(i-11) * time.Minute).Unix(), Title: strings.Repeat("匿", 200), Summary: "PRIVATE_SUMMARY", Metadata: "PRIVATE_METADATA", VideoSummaryPath: "PRIVATE_PATH", Category: "Work"}
	}
	cards = append(cards, domain.TimelineCard{ID: 99, StartTs: now.Add(time.Hour).Unix(), EndTs: now.Add(2 * time.Hour).Unix()}, domain.TimelineCard{ID: 100, Deleted: true, StartTs: now.Add(-time.Hour).Unix(), EndTs: now.Unix()})
	got := Build(now, now.Location(), "zh-CN", cards, []domain.Category{{Name: "Work", ColorHex: "#123456"}})
	if got.Day != "2026-10-11" || got.ValidUntilTs != time.Date(2026, 10, 12, 4, 0, 0, 0, now.Location()).Unix() {
		t.Fatalf("boundary: %+v", got)
	}
	if len(got.Cards) != 8 || got.Cards[0].ID != 12 || len([]rune(got.Cards[0].Title)) != 160 || got.Cards[0].ColorHex != "#123456" {
		t.Fatalf("cards: %+v", got.Cards)
	}
	wire, _ := json.Marshal(got)
	for _, secret := range []string{"PRIVATE_SUMMARY", "PRIVATE_METADATA", "PRIVATE_PATH", "summary", "metadata"} {
		if strings.Contains(string(wire), secret) {
			t.Fatalf("leaked %s", secret)
		}
	}
}

func TestSnapshotBoundaryAndClipping(t *testing.T) {
	loc, err := time.LoadLocation("America/New_York")
	if err != nil {
		t.Fatal(err)
	}
	for _, date := range []time.Time{time.Date(2026, 3, 7, 12, 0, 0, 0, loc), time.Date(2026, 11, 1, 3, 30, 0, 0, loc)} {
		got := Build(date, loc, "en", nil, nil)
		if got.Cards == nil || got.ValidUntilTs <= date.Unix() {
			t.Fatalf("empty snapshot: %+v", got)
		}
		if time.Unix(got.ValidUntilTs, 0).In(loc).Hour() != 4 {
			t.Fatal("DST boundary is not 4 AM")
		}
	}
	now := time.Date(2026, 10, 12, 4, 10, 0, 0, time.UTC)
	got := Build(now, time.UTC, "en", []domain.TimelineCard{{ID: 1, StartTs: now.Add(-40 * time.Minute).Unix(), EndTs: now.Add(20 * time.Minute).Unix(), Title: "fixture"}}, nil)
	if len(got.Cards) != 1 || got.Cards[0].StartTs != time.Date(2026, 10, 12, 4, 0, 0, 0, time.UTC).Unix() {
		t.Fatalf("crossing card: %+v", got)
	}
}

func TestSnapshotSharedSwiftGolden(t *testing.T) {
	raw, err := os.ReadFile("testdata/snapshot-v1.json")
	if err != nil {
		t.Fatal(err)
	}
	var expected Snapshot
	if err := json.Unmarshal(raw, &expected); err != nil {
		t.Fatal(err)
	}
	now := time.Unix(expected.GeneratedAtTs, 0).In(time.UTC)
	actual := Build(now, time.UTC, "zh-CN", []domain.TimelineCard{{ID: 1, StartTs: now.Add(-30 * time.Minute).Unix(), EndTs: now.Unix(), Title: "匿名活动", Category: "Work"}}, []domain.Category{{Name: "Work", ColorHex: "#123456"}})
	if !reflect.DeepEqual(actual, expected) {
		t.Fatalf("shared Swift fixture differs: %+v", actual)
	}
}
