package admin

import "errors"

var (
	ErrNotFound     = errors.New("admin subject not found")
	ErrUnauthorized = errors.New("unauthorized")
)

const AppRoleAdmin = "admin"

type Overview struct {
	DrinkMissRows     int `json:"drink_miss_rows"`
	DrinkMissQueries  int `json:"drink_miss_queries"`
	ProvisionalDrinks int `json:"provisional_drinks"`
	PublishedDrinks   int `json:"published_drinks"`
}
