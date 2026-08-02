/** base_spirit filter chips for /cocktails (values match seed data). */
export const BASE_SPIRIT_FILTERS = [
  { value: '', label: 'すべて' },
  { value: 'Gin', label: 'Gin' },
  { value: 'Vodka', label: 'Vodka' },
  { value: 'Rum', label: 'Rum' },
  { value: 'Whisky', label: 'Whisky' },
  { value: 'Tequila', label: 'Tequila' },
  { value: 'Shochu', label: 'Shochu' },
  { value: 'Brandy', label: 'Brandy' },
  { value: 'Liqueur', label: 'Liqueur' },
  { value: 'Cachaca', label: 'Cachaça' },
] as const;

export const COCKTAIL_LIST_PAGE_SIZE = 48;
