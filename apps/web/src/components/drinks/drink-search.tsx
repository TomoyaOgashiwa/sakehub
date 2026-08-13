'use client';

import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';

export function DrinkSearch() {
  return (
    <ConfirmedSearchInput
      pathname="/"
      placeholder="銘柄名・別名で検索"
      ariaLabel="銘柄名・別名で検索"
    />
  );
}
