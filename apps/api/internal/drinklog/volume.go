package drinklog

import "math"

// US fluid ounce in milliliters.
const mlPerOz = 29.5735

// Ethanol density (g/ml) used for pure alcohol mass.
const ethanolDensity = 0.789

func ozToML(oz float64) float64 {
	return round2(oz * mlPerOz)
}

func mlToOz(ml float64) float64 {
	return round2(ml / mlPerOz)
}

func toVolumeML(unit VolumeUnit, value float64) float64 {
	switch unit {
	case UnitOZ:
		return ozToML(value)
	default:
		return round2(value)
	}
}

func pureAlcoholGrams(volumeML, abv float64) float64 {
	return round2(volumeML * (abv / 100) * ethanolDensity)
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}

func nearlyEqual(a, b float64) bool {
	return math.Abs(a-b) < 0.05
}
