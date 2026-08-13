package drinklog

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"testing"
	"time"
)

type stubRepo struct {
	meta          *drinkMeta
	metaErr       error
	inserted      []*Log
	updated       []*Log
	byID          map[string]*Log
	searchMisses  []string
	countOverride *int
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

func (s *stubRepo) FindByID(ctx context.Context, id, userID string) (*Log, error) {
	if s.byID == nil {
		return nil, ErrNotFound
	}
	log, ok := s.byID[id]
	if !ok || log.UserID != userID {
		return nil, ErrNotFound
	}
	cp := *log
	return &cp, nil
}

func (s *stubRepo) Update(ctx context.Context, log *Log) error {
	log.UpdatedAt = time.Now().UTC()
	s.updated = append(s.updated, log)
	if s.byID == nil {
		s.byID = map[string]*Log{}
	}
	cp := *log
	s.byID[log.ID] = &cp
	return nil
}

func (s *stubRepo) ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error) {
	return nil, nil
}

func (s *stubRepo) Delete(ctx context.Context, id, userID string) error {
	if s.byID != nil {
		delete(s.byID, id)
	}
	return nil
}

func (s *stubRepo) CountInRange(ctx context.Context, userID string, from, to time.Time) (int, error) {
	if s.countOverride != nil {
		return *s.countOverride, nil
	}
	n := 0
	for _, log := range s.byID {
		if log.UserID != userID {
			continue
		}
		if (log.DrankAt.Equal(from) || log.DrankAt.After(from)) && log.DrankAt.Before(to) {
			n++
		}
	}
	return n, nil
}

func (s *stubRepo) ReplaceInRange(ctx context.Context, userID string, from, to time.Time, incoming []Log) ([]Log, error) {
	if s.byID == nil {
		s.byID = map[string]*Log{}
	}

	existingInRange := map[string]struct{}{}
	for id, log := range s.byID {
		if log.UserID != userID {
			continue
		}
		if (log.DrankAt.Equal(from) || log.DrankAt.After(from)) && log.DrankAt.Before(to) {
			existingInRange[id] = struct{}{}
		}
	}

	if len(existingInRange) > maxItemsPerBatch {
		return nil, fmt.Errorf("%w: too many logs in day to replace (max %d)", ErrConflict, maxItemsPerBatch)
	}

	incomingIDs := map[string]struct{}{}
	for i := range incoming {
		id := incoming[i].ID
		if id == "" {
			continue
		}
		if _, ok := existingInRange[id]; !ok {
			return nil, fmt.Errorf("%w: item id not in range", ErrValidation)
		}
		incomingIDs[id] = struct{}{}
		if !incoming[i].DrankAt.Before(from) && incoming[i].DrankAt.Before(to) {
			incoming[i].DrankAt = s.byID[id].DrankAt
		}
	}

	for id := range existingInRange {
		if _, keep := incomingIDs[id]; !keep {
			delete(s.byID, id)
		}
	}

	out := make([]Log, 0, len(incoming))
	for i := range incoming {
		log := incoming[i]
		log.UserID = userID
		if log.ID == "" {
			log.ID = fmt.Sprintf("new-%d", i)
			log.CreatedAt = time.Now().UTC()
		}
		log.UpdatedAt = time.Now().UTC()
		cp := log
		s.byID[log.ID] = &cp
		out = append(out, cp)
	}
	return out, nil
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

func TestUpdateKeepsEstimatedPreset(t *testing.T) {
	drinkID := "drink-1"
	existing := &Log{
		ID:         "log-1",
		UserID:     "user-1",
		DrinkID:    &drinkID,
		DrankAt:    time.Date(2026, 8, 1, 12, 0, 0, 0, time.UTC),
		VolumeML:   300,
		Quantity:   1,
		InputUnit:  UnitML,
		InputValue: 300,
	}
	repo := &stubRepo{
		meta: &drinkMeta{Category: "beer", ABV: sql.NullFloat64{Float64: 5, Valid: true}},
		byID: map[string]*Log{"log-1": existing},
	}
	svc := NewService(repo)

	key := "beer_mug_m"
	updated, err := svc.Update(context.Background(), "log-1", "user-1", UpdateInput{
		DrinkID:         &drinkID,
		InputUnit:       UnitML,
		InputValue:      300,
		ServingKey:      &key,
		VolumePrecision: PrecisionEstimated,
		Quantity:        2,
	})
	if err != nil {
		t.Fatalf("Update: %v", err)
	}
	if updated.Quantity != 2 {
		t.Fatalf("quantity = %d, want 2", updated.Quantity)
	}
	if updated.VolumePrecision != PrecisionEstimated {
		t.Fatalf("precision = %s, want estimated", updated.VolumePrecision)
	}
}

func TestUpdateRejectsBothDrinkIDAndCustom(t *testing.T) {
	drinkID := "drink-1"
	existing := &Log{ID: "log-1", UserID: "user-1", DrinkID: &drinkID, DrankAt: time.Now().UTC()}
	repo := &stubRepo{
		meta: &drinkMeta{Category: "beer"},
		byID: map[string]*Log{"log-1": existing},
	}
	svc := NewService(repo)

	name := "both"
	_, err := svc.Update(context.Background(), "log-1", "user-1", UpdateInput{
		DrinkID:         &drinkID,
		CustomDrinkName: &name,
		InputUnit:       UnitML,
		InputValue:      100,
		VolumePrecision: PrecisionExact,
	})
	if err == nil {
		t.Fatal("expected validation error")
	}
}

func TestUpdateCustomDrinkClearsPreset(t *testing.T) {
	existing := &Log{ID: "log-1", UserID: "user-1", DrankAt: time.Now().UTC()}
	repo := &stubRepo{byID: map[string]*Log{"log-1": existing}}
	svc := NewService(repo)

	name := "自由入力銘柄"
	key := "sake_go"
	updated, err := svc.Update(context.Background(), "log-1", "user-1", UpdateInput{
		CustomDrinkName: &name,
		InputUnit:       UnitML,
		InputValue:      180,
		ServingKey:      &key,
		VolumePrecision: PrecisionEstimated,
		Quantity:        1,
		PlaceName:       strPtr("居酒屋"),
	})
	if err != nil {
		t.Fatalf("Update: %v", err)
	}
	if updated.ServingKey != nil {
		t.Fatalf("serving_key should be cleared, got %v", *updated.ServingKey)
	}
	if updated.VolumePrecision != PrecisionExact {
		t.Fatalf("precision = %s, want exact", updated.VolumePrecision)
	}
	if updated.PlaceName == nil || *updated.PlaceName != "居酒屋" {
		t.Fatalf("place = %v", updated.PlaceName)
	}
}

func TestCreateBatchRejectsFutureDrankAt(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	future := time.Now().UTC().Add(48 * time.Hour)
	_, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		DrankAt: &future,
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func TestCreateBatchRejectsTooOldDrankAt(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	old := time.Now().UTC().AddDate(-11, 0, 0)
	_, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		DrankAt: &old,
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func TestUpdateRejectsFutureDrankAt(t *testing.T) {
	drinkID := "drink-1"
	existing := &Log{ID: "log-1", UserID: "user-1", DrinkID: &drinkID, DrankAt: time.Now().UTC()}
	repo := &stubRepo{
		meta: &drinkMeta{Category: "beer"},
		byID: map[string]*Log{"log-1": existing},
	}
	svc := NewService(repo)

	future := time.Now().UTC().Add(48 * time.Hour)
	_, err := svc.Update(context.Background(), "log-1", "user-1", UpdateInput{
		DrinkID:         &drinkID,
		InputUnit:       UnitML,
		InputValue:      100,
		VolumePrecision: PrecisionExact,
		DrankAt:         &future,
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func TestReplaceDayInsertUpdateDelete(t *testing.T) {
	drinkID := "drink-1"
	ymd, from, _ := utcCalendarDay(t, -1)
	keep := &Log{
		ID:         "keep-1",
		UserID:     "user-1",
		DrinkID:    &drinkID,
		DrankAt:    from.Add(time.Hour),
		VolumeML:   180,
		Quantity:   1,
		InputUnit:  UnitML,
		InputValue: 180,
	}
	drop := &Log{
		ID:         "drop-1",
		UserID:     "user-1",
		DrinkID:    &drinkID,
		DrankAt:    from.Add(2 * time.Hour),
		VolumeML:   300,
		Quantity:   1,
		InputUnit:  UnitML,
		InputValue: 300,
	}
	repo := &stubRepo{
		meta: &drinkMeta{Category: "sake"},
		byID: map[string]*Log{"keep-1": keep, "drop-1": drop},
	}
	svc := NewService(repo)

	name := "新規カスタム"
	drankAt := from
	keepID := "keep-1"
	logs, err := svc.ReplaceDay(context.Background(), "user-1", ReplaceDayInput{
		TimeZone:  "UTC",
		Date:      ymd,
		DrankAt:   &drankAt,
		PlaceName: strPtr("自宅"),
		Items: []ReplaceDayItem{
			{
				ID: &keepID,
				CreateItemInput: CreateItemInput{
					DrinkID:         &drinkID,
					InputUnit:       UnitML,
					InputValue:      90,
					VolumePrecision: PrecisionExact,
					Quantity:        2,
				},
			},
			{
				CreateItemInput: CreateItemInput{
					CustomDrinkName: &name,
					InputUnit:       UnitML,
					InputValue:      120,
					VolumePrecision: PrecisionExact,
				},
			},
		},
	})
	if err != nil {
		t.Fatalf("ReplaceDay: %v", err)
	}
	if len(logs) != 2 {
		t.Fatalf("len(logs) = %d, want 2", len(logs))
	}
	if _, ok := repo.byID["drop-1"]; ok {
		t.Fatal("expected drop-1 to be deleted")
	}
	if repo.byID["keep-1"].Quantity != 2 {
		t.Fatalf("keep quantity = %d, want 2", repo.byID["keep-1"].Quantity)
	}
	if !repo.byID["keep-1"].DrankAt.Equal(keep.DrankAt) {
		t.Fatalf("same-day replace should keep original drank_at, got %v", repo.byID["keep-1"].DrankAt)
	}
	if repo.byID["keep-1"].PlaceName == nil || *repo.byID["keep-1"].PlaceName != "自宅" {
		t.Fatalf("place = %v", repo.byID["keep-1"].PlaceName)
	}
	foundNew := false
	for _, log := range logs {
		if log.CustomDrinkName != nil && *log.CustomDrinkName == name {
			foundNew = true
		}
	}
	if !foundNew {
		t.Fatal("expected inserted custom drink")
	}
}

func TestReplaceDayRejectsIDOutsideRange(t *testing.T) {
	drinkID := "drink-1"
	ymd, from, _ := utcCalendarDay(t, -1)
	outside := &Log{
		ID:         "outside-1",
		UserID:     "user-1",
		DrinkID:    &drinkID,
		DrankAt:    from.Add(-time.Hour),
		VolumeML:   180,
		Quantity:   1,
		InputUnit:  UnitML,
		InputValue: 180,
	}
	repo := &stubRepo{
		meta: &drinkMeta{Category: "sake"},
		byID: map[string]*Log{"outside-1": outside},
	}
	svc := NewService(repo)

	outsideID := "outside-1"
	drankAt := from
	_, err := svc.ReplaceDay(context.Background(), "user-1", ReplaceDayInput{
		TimeZone: "UTC",
		Date:     ymd,
		DrankAt:  &drankAt,
		Items: []ReplaceDayItem{{
			ID: &outsideID,
			CreateItemInput: CreateItemInput{
				DrinkID:         &drinkID,
				InputUnit:       UnitML,
				InputValue:      180,
				VolumePrecision: PrecisionExact,
			},
		}},
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func TestReplaceDayRejectsInvalidTimeZone(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	drankAt := time.Now().UTC().Add(-time.Hour)
	id := "drink-1"
	_, err := svc.ReplaceDay(context.Background(), "user-1", ReplaceDayInput{
		TimeZone: "Not/AZone",
		Date:     "2026-08-01",
		DrankAt:  &drankAt,
		Items: []ReplaceDayItem{{
			CreateItemInput: CreateItemInput{
				DrinkID:         &id,
				InputUnit:       UnitML,
				InputValue:      180,
				VolumePrecision: PrecisionExact,
			},
		}},
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func TestReplaceDayRejectsTooManyInRange(t *testing.T) {
	drinkID := "drink-1"
	ymd, from, _ := utcCalendarDay(t, -1)
	byID := map[string]*Log{}
	for i := 0; i < maxItemsPerBatch+1; i++ {
		id := fmt.Sprintf("log-%d", i)
		byID[id] = &Log{
			ID:         id,
			UserID:     "user-1",
			DrinkID:    &drinkID,
			DrankAt:    from.Add(time.Duration(i) * time.Minute),
			VolumeML:   180,
			Quantity:   1,
			InputUnit:  UnitML,
			InputValue: 180,
		}
	}
	repo := &stubRepo{meta: &drinkMeta{Category: "sake"}, byID: byID}
	svc := NewService(repo)

	drankAt := from
	_, err := svc.ReplaceDay(context.Background(), "user-1", ReplaceDayInput{
		TimeZone: "UTC",
		Date:     ymd,
		DrankAt:  &drankAt,
		Items: []ReplaceDayItem{{
			CreateItemInput: CreateItemInput{
				DrinkID:         &drinkID,
				InputUnit:       UnitML,
				InputValue:      180,
				VolumePrecision: PrecisionExact,
			},
		}},
	})
	if !errors.Is(err, ErrConflict) {
		t.Fatalf("err = %v, want conflict", err)
	}
}

func TestReplaceDayRejectsTooManyAfterLock(t *testing.T) {
	drinkID := "drink-1"
	ymd, from, _ := utcCalendarDay(t, -1)
	byID := map[string]*Log{}
	for i := 0; i < maxItemsPerBatch+1; i++ {
		id := fmt.Sprintf("log-%d", i)
		byID[id] = &Log{
			ID:         id,
			UserID:     "user-1",
			DrinkID:    &drinkID,
			DrankAt:    from.Add(time.Duration(i) * time.Minute),
			VolumeML:   180,
			Quantity:   1,
			InputUnit:  UnitML,
			InputValue: 180,
		}
	}
	staleCount := maxItemsPerBatch
	repo := &stubRepo{
		meta:          &drinkMeta{Category: "sake"},
		byID:          byID,
		countOverride: &staleCount,
	}
	svc := NewService(repo)

	drankAt := from
	_, err := svc.ReplaceDay(context.Background(), "user-1", ReplaceDayInput{
		TimeZone: "UTC",
		Date:     ymd,
		DrankAt:  &drankAt,
		Items: []ReplaceDayItem{{
			CreateItemInput: CreateItemInput{
				DrinkID:         &drinkID,
				InputUnit:       UnitML,
				InputValue:      180,
				VolumePrecision: PrecisionExact,
			},
		}},
	})
	if !errors.Is(err, ErrConflict) {
		t.Fatalf("err = %v, want conflict from locked range", err)
	}
}

func TestZonedDayRangeTokyo(t *testing.T) {
	from, to, err := zonedDayRange("Asia/Tokyo", "2026-08-13")
	if err != nil {
		t.Fatal(err)
	}
	if got := from.UTC().Format(time.RFC3339); got != "2026-08-12T15:00:00Z" {
		t.Fatalf("from = %s", got)
	}
	if to.Sub(from) != 24*time.Hour {
		t.Fatalf("duration = %s", to.Sub(from))
	}
}

func TestCreateBatchRejectsJavascriptPlaceURL(t *testing.T) {
	repo := &stubRepo{meta: &drinkMeta{Category: "beer"}}
	svc := NewService(repo)

	id := "drink-1"
	_, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		PlaceURL: strPtr("javascript:alert(1)"),
		Items: []CreateItemInput{{
			DrinkID:         &id,
			InputUnit:       UnitML,
			InputValue:      300,
			VolumePrecision: PrecisionExact,
		}},
	}, "user-1")
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want validation", err)
	}
}

func utcCalendarDay(t *testing.T, offsetDays int) (ymd string, from, to time.Time) {
	t.Helper()
	day := time.Now().UTC().AddDate(0, 0, offsetDays)
	ymd = day.Format("2006-01-02")
	var err error
	from, to, err = zonedDayRange("UTC", ymd)
	if err != nil {
		t.Fatal(err)
	}
	return ymd, from, to
}

func strPtr(s string) *string { return &s }
