package drinklog

// ServingPreset mirrors packages/types SERVING_PRESETS for server-side validation.
type ServingPreset struct {
	Key              string
	VolumeML         float64
	Categories       []string
	DefaultPrecision VolumePrecision
}

var spiritCategories = []string{
	"whisky", "vodka", "gin", "rum", "tequila", "brandy", "liqueur", "shochu",
}

var servingPresets = []ServingPreset{
	{Key: "beer_mug_m", VolumeML: 300, Categories: []string{"beer"}, DefaultPrecision: PrecisionEstimated},
	{Key: "beer_mug_l", VolumeML: 500, Categories: []string{"beer"}, DefaultPrecision: PrecisionEstimated},
	{Key: "beer_glass_s", VolumeML: 200, Categories: []string{"beer"}, DefaultPrecision: PrecisionEstimated},
	{Key: "beer_can_350", VolumeML: 350, Categories: []string{"beer"}, DefaultPrecision: PrecisionExact},
	{Key: "beer_can_500", VolumeML: 500, Categories: []string{"beer"}, DefaultPrecision: PrecisionExact},
	{Key: "sake_go", VolumeML: 180, Categories: []string{"sake"}, DefaultPrecision: PrecisionExact},
	{Key: "sake_half_go", VolumeML: 90, Categories: []string{"sake"}, DefaultPrecision: PrecisionExact},
	{Key: "sake_tokkuri", VolumeML: 360, Categories: []string{"sake"}, DefaultPrecision: PrecisionEstimated},
	{Key: "sake_guinomi", VolumeML: 60, Categories: []string{"sake"}, DefaultPrecision: PrecisionEstimated},
	{Key: "spirit_single", VolumeML: 30, Categories: spiritCategories, DefaultPrecision: PrecisionEstimated},
	{Key: "spirit_double", VolumeML: 60, Categories: spiritCategories, DefaultPrecision: PrecisionEstimated},
	{Key: "spirit_on_rocks", VolumeML: 40, Categories: spiritCategories, DefaultPrecision: PrecisionEstimated},
	{Key: "wine_glass", VolumeML: 120, Categories: []string{"wine"}, DefaultPrecision: PrecisionEstimated},
	{Key: "wine_half_bottle", VolumeML: 375, Categories: []string{"wine"}, DefaultPrecision: PrecisionExact},
}

func findServingPreset(key string) *ServingPreset {
	for i := range servingPresets {
		if servingPresets[i].Key == key {
			return &servingPresets[i]
		}
	}
	return nil
}

func presetAllowsCategory(p *ServingPreset, category string) bool {
	for _, c := range p.Categories {
		if c == category {
			return true
		}
	}
	return false
}
