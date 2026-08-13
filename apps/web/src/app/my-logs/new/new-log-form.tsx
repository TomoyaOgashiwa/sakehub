'use client';

import { useActionState, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

import { createDrinkLogBatch, type DrinkLogActionState } from '@/application/drink-log-actions';
import {
  DrinkAutocomplete,
  type SelectedDrinkOption,
} from '@/components/drink-logs/drink-autocomplete';
import {
  createLineFromSelection,
  DrinkLogLineEditor,
  lineToApiItem,
  type DrinkLogLine,
} from '@/components/drink-logs/drink-log-line-editor';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  drinkLogBatchSchema,
  isoToTokyoDateInput,
  tokyoTodayYmd,
} from '@/utils/drink-log-schema';

const initialState: DrinkLogActionState = { ok: false, error: '' };

export function NewLogForm() {
  const router = useRouter();
  const [drankAt, setDrankAt] = useState(() => isoToTokyoDateInput(new Date().toISOString()));
  const maxDate = tokyoTodayYmd();
  const [placeName, setPlaceName] = useState('');
  const [placeUrl, setPlaceUrl] = useState('');
  const [lines, setLines] = useState<DrinkLogLine[]>([]);

  const [state, formAction, isPending] = useActionState(
    async (prev: DrinkLogActionState, formData: FormData) => {
      const result = await createDrinkLogBatch(prev, formData);
      if (result.ok) {
        router.push('/my-logs');
        router.refresh();
      }
      return result;
    },
    initialState,
  );

  const itemsJSON = useMemo(() => JSON.stringify(lines.map(lineToApiItem)), [lines]);

  const canSubmit = useMemo(() => {
    const parsed = drinkLogBatchSchema.safeParse({
      drank_at: drankAt,
      place_name: placeName,
      place_url: placeUrl,
      items: lines.map(lineToApiItem),
    });
    return parsed.success;
  }, [drankAt, placeName, placeUrl, lines]);

  function addDrink(option: SelectedDrinkOption) {
    setLines((prev) => [...prev, createLineFromSelection(option)]);
  }

  function updateLine(localId: string, patch: Partial<DrinkLogLine>) {
    setLines((prev) =>
      prev.map((line) => (line.localId === localId ? { ...line, ...patch } : line)),
    );
  }

  function removeLine(localId: string) {
    setLines((prev) => prev.filter((line) => line.localId !== localId));
  }

  return (
    <form action={formAction} className="space-y-8">
      <input type="hidden" name="items_json" value={itemsJSON} />

      <div className="space-y-2">
        <Label htmlFor="drank_at">いつ飲んだか</Label>
        <Input
          id="drank_at"
          name="drank_at"
          type="date"
          required
          max={maxDate}
          value={drankAt}
          onChange={(e) => setDrankAt(e.target.value)}
          className="max-w-xs"
        />
      </div>

      <div className="space-y-4">
        <DrinkAutocomplete onSelect={addDrink} />

        {lines.length === 0 ? (
          <p className="text-muted-foreground text-sm">まだお酒が追加されていません。</p>
        ) : (
          <ul className="space-y-4">
            {lines.map((line) => (
              <li key={line.localId}>
                <DrinkLogLineEditor
                  line={line}
                  onChange={(patch) => updateLine(line.localId, patch)}
                  onRemove={() => removeLine(line.localId)}
                />
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="place_name">どこで飲んだか（任意）</Label>
          <Input
            id="place_name"
            name="place_name"
            placeholder="例: 自宅、〇〇酒店"
            value={placeName}
            onChange={(e) => setPlaceName(e.target.value)}
            maxLength={200}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="place_url">場所の URL（任意）</Label>
          <Input
            id="place_url"
            name="place_url"
            placeholder="Google マップや店舗サイトの URL"
            value={placeUrl}
            onChange={(e) => setPlaceUrl(e.target.value)}
            maxLength={2000}
          />
          <p className="text-muted-foreground text-xs">
            お店の場合など、分かるときだけ入力してください。
          </p>
        </div>
      </div>

      {!state.ok && state.error && (
        <p className="text-destructive text-sm" role="alert">
          {state.error}
        </p>
      )}

      <Button type="submit" disabled={isPending || !canSubmit}>
        {isPending ? '記録中…' : '記録する'}
      </Button>
    </form>
  );
}
