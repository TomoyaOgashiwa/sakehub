'use client';

import { useActionState, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import type { DrinkLog } from '@sakehub/types';

import { updateDrinkLog, type DrinkLogActionState } from '@/application/drink-log-actions';
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
  drinkLogUpdateSchema,
  isoToTokyoDateInput,
  tokyoTodayYmd,
} from '@/utils/drink-log-schema';

const initialState: DrinkLogActionState = { ok: false, error: '' };

function logToLine(log: DrinkLog): DrinkLogLine {
  if (log.drink) {
    return {
      localId: log.id,
      kind: 'catalog',
      drinkId: log.drink.id,
      name: log.drink.name,
      category: log.drink.category,
      unit: log.inputUnit,
      value: String(log.inputValue),
      servingKey: log.servingKey ?? null,
      precision: log.volumePrecision,
      quantity: log.quantity,
    };
  }
  return {
    localId: log.id,
    kind: 'custom',
    name: log.customDrinkName ?? '不明な銘柄',
    unit: log.inputUnit,
    value: String(log.inputValue),
    servingKey: null,
    precision: log.volumePrecision,
    quantity: log.quantity,
  };
}

interface EditLogFormProps {
  log: DrinkLog;
}

export function EditLogForm({ log }: EditLogFormProps) {
  const router = useRouter();
  const [drankAt, setDrankAt] = useState(() => isoToTokyoDateInput(log.drankAt));
  const [placeName, setPlaceName] = useState(log.placeName ?? '');
  const [placeUrl, setPlaceUrl] = useState(log.placeUrl ?? '');
  const [line, setLine] = useState<DrinkLogLine>(() => logToLine(log));
  const maxDate = tokyoTodayYmd();

  const boundUpdate = updateDrinkLog.bind(null, log.id);

  const [state, formAction, isPending] = useActionState(
    async (prev: DrinkLogActionState, formData: FormData) => {
      const result = await boundUpdate(prev, formData);
      if (result.ok) {
        router.push('/my-logs');
        router.refresh();
      }
      return result;
    },
    initialState,
  );

  const itemJSON = useMemo(() => JSON.stringify(lineToApiItem(line)), [line]);

  const canSubmit = useMemo(() => {
    const parsed = drinkLogUpdateSchema.safeParse({
      drank_at: drankAt,
      place_name: placeName,
      place_url: placeUrl,
      ...lineToApiItem(line),
    });
    return parsed.success;
  }, [drankAt, placeName, placeUrl, line]);

  function replaceDrink(option: SelectedDrinkOption) {
    setLine(createLineFromSelection(option));
  }

  return (
    <form action={formAction} className="space-y-8">
      <input type="hidden" name="item_json" value={itemJSON} />

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
        <div className="space-y-2">
          <Label>銘柄を変更</Label>
          <DrinkAutocomplete onSelect={replaceDrink} />
        </div>
        <DrinkLogLineEditor
          line={line}
          onChange={(patch) => setLine((prev) => ({ ...prev, ...patch }))}
          showRemove={false}
        />
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
        </div>
      </div>

      {!state.ok && state.error && (
        <p className="text-destructive text-sm" role="alert">
          {state.error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={isPending || !canSubmit}>
          {isPending ? '保存中…' : '変更を保存'}
        </Button>
        <Button
          type="button"
          variant="outline"
          onClick={() => router.push('/my-logs')}
          disabled={isPending}
        >
          キャンセル
        </Button>
      </div>
    </form>
  );
}
