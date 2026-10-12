// Package widget projects the minimal desktop timeline snapshot. It owns no
// database, GUI or filesystem; the host supplies data and a platform sink.
package widget

import (
	"context"
	"encoding/json"
	"sort"
	"time"

	"github.com/Jwz-git/Daygo/internal/domain"
	"github.com/Jwz-git/Daygo/internal/timeutil"
)

const MaxCards = 8
const MaxBytes = 32 * 1024

type Card struct {
	ID       int64  `json:"id"`
	StartTs  int64  `json:"startTs"`
	EndTs    int64  `json:"endTs"`
	Title    string `json:"title"`
	ColorHex string `json:"colorHex"`
}
type Snapshot struct {
	Version       int    `json:"version"`
	Day           string `json:"day"`
	Language      string `json:"language"`
	GeneratedAtTs int64  `json:"generatedAtTs"`
	ValidUntilTs  int64  `json:"validUntilTs"`
	Cards         []Card `json:"cards"`
}

func Build(now time.Time, loc *time.Location, language string, cards []domain.TimelineCard, categories []domain.Category) Snapshot {
	day := timeutil.LogicalDay(now, loc)
	start, end, _ := timeutil.DayWindow(day, loc)
	snapshot := Snapshot{Version: 1, Day: day, Language: language, GeneratedAtTs: now.Unix(), ValidUntilTs: end.Unix(), Cards: []Card{}}
	colors := make(map[string]string, len(categories))
	for _, category := range categories {
		colors[category.Name] = category.ColorHex
	}
	for _, card := range cards {
		if card.Deleted || card.StartTs > now.Unix() || card.EndTs <= card.StartTs || card.EndTs-card.StartTs > 4*3600 || card.EndTs <= start.Unix() || card.StartTs >= end.Unix() {
			continue
		}
		title := []rune(card.Title)
		if len(title) > 160 {
			title = title[:160]
		}
		snapshot.Cards = append(snapshot.Cards, Card{ID: card.ID, StartTs: max(start.Unix(), card.StartTs), EndTs: min(end.Unix(), card.EndTs), Title: string(title), ColorHex: colors[card.Category]})
	}
	sort.Slice(snapshot.Cards, func(i, j int) bool {
		if snapshot.Cards[i].StartTs == snapshot.Cards[j].StartTs {
			return snapshot.Cards[i].ID > snapshot.Cards[j].ID
		}
		return snapshot.Cards[i].StartTs > snapshot.Cards[j].StartTs
	})
	if len(snapshot.Cards) > MaxCards {
		snapshot.Cards = snapshot.Cards[:MaxCards]
	}
	return snapshot
}

type Source interface {
	WidgetSnapshot(context.Context) (Snapshot, error)
}
type Sink interface {
	PublishWidgetSnapshot(context.Context, []byte) error
}

// Publisher remembers only successful content, so failed publishes are retried.
// The publication timestamp is not part of change detection.
type Publisher struct {
	Source   Source
	Sink     Sink
	previous string
}

func (p *Publisher) Refresh(ctx context.Context) error {
	snapshot, err := p.Source.WidgetSnapshot(ctx)
	if err != nil {
		return err
	}
	stable := snapshot
	stable.GeneratedAtTs = 0
	comparison, err := json.Marshal(stable)
	if err != nil {
		return err
	}
	if string(comparison) == p.previous {
		return nil
	}
	payload, err := json.Marshal(snapshot)
	if err != nil {
		return err
	}
	if len(payload) > MaxBytes {
		return ErrSnapshotTooLarge
	}
	if err := p.Sink.PublishWidgetSnapshot(ctx, payload); err != nil {
		return err
	}
	p.previous = string(comparison)
	return nil
}
