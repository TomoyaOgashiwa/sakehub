'use client';

import { useEffect, useId, useRef, useState } from 'react';
import useSWR from 'swr';
import type { Drink, DrinkCategoryProduct } from '@sakehub/types';

import { fetchDrinks } from '@/application/drinks-api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export interface SelectedDrinkOption {
  kind: 'catalog' | 'custom';
  drinkId?: string;
  name: string;
  category?: DrinkCategoryProduct;
}

interface DrinkAutocompleteProps {
  onSelect: (option: SelectedDrinkOption) => void;
}

async function searchDrinks(q: string): Promise<Drink[]> {
  const res = await fetchDrinks({ q, limit: 8 });
  return res.drinks;
}

export function DrinkAutocomplete({ onSelect }: DrinkAutocompleteProps) {
  const listId = useId();
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handle = window.setTimeout(() => {
      setDebouncedQuery(query.trim());
    }, 250);
    return () => window.clearTimeout(handle);
  }, [query]);

  const trimmed = query.trim();
  const { data: results = [], isLoading } = useSWR(
    debouncedQuery.length >= 1 ? (['drink-autocomplete', debouncedQuery] as const) : null,
    ([, q]) => searchDrinks(q),
  );

  useEffect(() => {
    function onPointerDown(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', onPointerDown);
    return () => document.removeEventListener('mousedown', onPointerDown);
  }, []);

  function chooseCatalog(drink: Drink) {
    onSelect({
      kind: 'catalog',
      drinkId: drink.id,
      name: drink.name,
      category: drink.category,
    });
    setQuery('');
    setDebouncedQuery('');
    setOpen(false);
  }

  function chooseCustom() {
    if (!trimmed) return;
    onSelect({ kind: 'custom', name: trimmed });
    setQuery('');
    setDebouncedQuery('');
    setOpen(false);
  }

  const showList = open && trimmed.length >= 1;

  return (
    <div ref={rootRef} className="relative space-y-2">
      <Label htmlFor="drink-autocomplete">お酒を追加</Label>
      <Input
        id="drink-autocomplete"
        role="combobox"
        aria-expanded={showList}
        aria-controls={listId}
        aria-autocomplete="list"
        placeholder="銘柄名で検索…"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setOpen(true);
        }}
        onFocus={() => {
          if (trimmed) setOpen(true);
        }}
        autoComplete="off"
      />

      {showList && (
        <ul
          id={listId}
          role="listbox"
          className="border-border bg-background absolute z-20 mt-1 max-h-64 w-full overflow-auto rounded-lg border shadow-md"
        >
          {isLoading && (
            <li className="text-muted-foreground px-3 py-2 text-sm" role="presentation">
              検索中…
            </li>
          )}
          {!isLoading &&
            results.map((drink) => (
              <li key={drink.id} role="option" aria-selected={false}>
                <button
                  type="button"
                  className="hover:bg-muted flex w-full flex-col items-start px-3 py-2 text-left text-sm"
                  onClick={() => chooseCatalog(drink)}
                >
                  <span className="font-medium">{drink.name}</span>
                  <span className="text-muted-foreground text-xs capitalize">{drink.category}</span>
                </button>
              </li>
            ))}
          {!isLoading && (
            <li role="option" aria-selected={false}>
              <button
                type="button"
                className="hover:bg-muted flex w-full flex-col items-start border-t px-3 py-2 text-left text-sm"
                onClick={chooseCustom}
              >
                <span className="font-medium">「{trimmed}」をそのまま追加</span>
                <span className="text-muted-foreground text-xs">
                  カタログに無い銘柄として記録（需要として拾います）
                </span>
              </button>
            </li>
          )}
        </ul>
      )}

      {trimmed && (
        <Button type="button" size="sm" variant="outline" onClick={chooseCustom}>
          「{trimmed}」を追加
        </Button>
      )}
    </div>
  );
}
