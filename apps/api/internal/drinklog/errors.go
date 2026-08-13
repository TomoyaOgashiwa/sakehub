package drinklog

import "errors"

var (
	ErrNotFound      = errors.New("drink log not found")
	ErrForbidden     = errors.New("not allowed to modify this drink log")
	ErrValidation    = errors.New("validation error")
	ErrDrinkNotFound = errors.New("drink not found")
)
