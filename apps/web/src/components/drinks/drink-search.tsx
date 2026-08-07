'use client';

import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';

export function DrinkSearch() {
  return (
    <ConfirmedSearchInput pathname="/" placeholder="お酒を検索..." ariaLabel="お酒をキーワードで検索" />
  );
}
