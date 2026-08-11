import type { CatalogImageSource } from '@sakehub/types';

export interface CatalogImageSourceLabel {
  text: string;
  variant: 'secondary' | 'outline';
}

/** Returns a disclosure label for catalog master images, or null when none. */
export function getCatalogImageSourceLabel(
  source: CatalogImageSource | undefined,
): CatalogImageSourceLabel | null {
  if (source === 'generated') {
    return { text: 'AI生成画像', variant: 'secondary' };
  }
  if (source === 'brand') {
    return { text: '公式提供', variant: 'outline' };
  }
  return null;
}
