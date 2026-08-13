package saveddrink

import "errors"

var (
	ErrNotFound      = errors.New("saved drink not found")
	ErrValidation    = errors.New("validation error")
	ErrDrinkNotFound = errors.New("drink not found")
)
