'use client';

import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';

export function CocktailSearch() {
  return (
    <ConfirmedSearchInput
      pathname="/cocktails"
      placeholder="カクテルを検索..."
      ariaLabel="カクテルをキーワードで検索"
    />
  );
}
