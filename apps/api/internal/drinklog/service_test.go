package drinklog

import (
	"context"
	"database/sql"
	"testing"
	"time"
)

type stubRepo struct {
	meta         *drinkMeta
	metaErr      error
	inserted     []*Log
	searchMisses []string
}

func (s *stubRepo) FindDrinkMeta(ctx context.Context, drinkID string) (*drinkMeta, error) {
	if s.metaErr != nil {
		return nil, s.metaErr
	}
	return s.meta, nil
}

func (s *stubRepo) Insert(ctx context.Context, log *Log) error {
	log.ID = "log-1"
	log.CreatedAt = time.Now().UTC()
	log.UpdatedAt = log.CreatedAt
	s.inserted = append(s.inserted, log)
	return nil
}

func (s *stubRepo) ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error) {
	return nil, nil
}

func (s *stubRepo) Delete(ctx context.Context, id, userID string) error {
	return nil
}

func (s *stubRepo) Summary(ctx context.Context, userID string, from, to time.Time) (int, int, float64, error) {
	return 0, 0, 0, nil
}

func (s *stubRepo) InsertSearchMiss(ctx context.Context, userID, queryRaw string) error {
	s.searchMisses = append(s.searchMisses, queryRaw)
	return nil
}

func TestOzToML(t *testing.T) {
	got := ozToML(9)
	if got != 266.16 {
		t.Fatalf("ozToML(9) = %v, want 266.16", got)
	}
}

func TestCreateBatchKeepsEstimatedPreset(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer", ABV: sql.NullFloat64{Float64: 5, Valid: true}}}
	svc := NewService(repo)

	key := "beer_mug_m"
	drinkID := "drink-1"
	logs, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &drinkID,
			InputUnit:       UnitML,
			InputValue:      300,
			ServingKey:      &key,
			VolumePrecision: PrecisionEstimated,
		}},
	}, "user-1")
	if err != nil {
		t.Fatalf("CreateBatch: %v", err)
	}
	if logs[0].VolumePrecision != PrecisionEstimated {
		t.Fatalf("precision = %s, want estimated", logs[0].VolumePrecision)
	}
}

func TestCreateBatchCustomDrink(t *testing.T) {
	repo := &stubRepo{}
	svc := NewService(repo)

	name := "未知の銘柄テスト"
	logs, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		PlaceName: strPtr("自宅"),
		Items: []CreateItemInput{{
			CustomDrinkName: &name,
			InputUnit:       UnitML,
			InputValue:      180,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if err != nil {
		t.Fatalf("CreateBatch: %v", err)
	}
	if logs[0].DrinkID != nil {
		t.Fatal("expected nil drink_id")
	}
	if logs[0].CustomDrinkName == nil || *logs[0].CustomDrinkName != name {
		t.Fatalf("custom name = %v", logs[0].CustomDrinkName)
	}
	if logs[0].PlaceName == nil || *logs[0].PlaceName != "自宅" {
		t.Fatalf("place = %v", logs[0].PlaceName)
	}
	if len(repo.searchMisses) != 1 || repo.searchMisses[0] != name {
		t.Fatalf("search misses = %v", repo.searchMisses)
	}
}

func TestCreateBatchRejectsBothDrinkIDAndCustom(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	name := "both"
	_, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &id,
			CustomDrinkName: &name,
			InputUnit:       UnitML,
			InputValue:      100,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if err == nil {
		t.Fatal("expected validation error")
	}
}

func TestCreateBatchOzManual(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	logs, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitOZ,
			InputValue:      9,
			VolumePrecision: PrecisionEstimated,
		}},
	}, "user-1")
	if err != nil {
		t.Fatalf("CreateBatch: %v", err)
	}
	if logs[0].VolumeML != 266.16 {
		t.Fatalf("volume_ml = %v", logs[0].VolumeML)
	}
}

func TestCreateBatchQuantity(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	logs, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
			Quantity:        3,
		}},
	}, "user-1")
	if err != nil {
		t.Fatalf("CreateBatch: %v", err)
	}
	if logs[0].Quantity != 3 {
		t.Fatalf("quantity = %d, want 3", logs[0].Quantity)
	}
}

func TestCreateBatchDefaultQuantity(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	logs, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if err != nil {
		t.Fatalf("CreateBatch: %v", err)
	}
	if logs[0].Quantity != 1 {
		t.Fatalf("quantity = %d, want 1", logs[0].Quantity)
	}
}

func TestCreateBatchRejectsInvalidQuantity(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	_, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
			Quantity:        21,
		}},
	}, "user-1")
	if err == nil {
		t.Fatal("expected validation error")
	}
}

func strPtr(s string) *string { return &s }
