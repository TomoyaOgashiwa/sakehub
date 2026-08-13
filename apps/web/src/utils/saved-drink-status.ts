import type { SavedDrinkStatus } from '@sakehub/types';

export function savedDrinkStatusLabel(status: SavedDrinkStatus): string {
  return status === 'want' ? '飲みたい' : '飲んだ';
}

export function oppositeSavedDrinkStatus(status: SavedDrinkStatus): SavedDrinkStatus {
  return status === 'drank' ? 'want' : 'drank';
}
