'use client';

import { useActionState, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import type { DrinkCategoryProduct, VolumePrecision, VolumeUnit } from '@sakehub/types';

import { createDrinkLogBatch, type DrinkLogActionState } from '@/application/drink-log-actions';
import {
  DrinkAutocomplete,
  type SelectedDrinkOption,
} from '@/components/drink-logs/drink-autocomplete';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { findServingPreset, presetsForCategory } from '@/config/serving-presets';
import { cn } from '@/utils/utils';
import { convertVolumeValue, round2 } from '@/utils/volume';

interface LogDrinkLine {
  localId: string;
  kind: 'catalog' | 'custom';
  drinkId?: string;
  name: string;
  category?: DrinkCategoryProduct;
  unit: VolumeUnit;
  value: string;
  servingKey: string | null;
  precision: VolumePrecision;
  quantity: number;
}

const initialState: DrinkLogActionState = { ok: false, error: '' };

function toDateInputValue(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function NewLogForm() {
  const router = useRouter();
  const [drankAt, setDrankAt] = useState(() => toDateInputValue(new Date()));
  const [placeName, setPlaceName] = useState('');
  const [placeUrl, setPlaceUrl] = useState('');
  const [lines, setLines] = useState<LogDrinkLine[]>([]);

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

  const itemsJSON = useMemo(
    () =>
      JSON.stringify(
        lines.map((line) => ({
          ...(line.kind === 'catalog' && line.drinkId
            ? { drink_id: line.drinkId }
            : { custom_drink_name: line.name }),
          input_unit: line.unit,
          input_value: Number(line.value),
          volume_precision: line.precision,
          quantity: line.quantity,
          ...(line.servingKey ? { serving_key: line.servingKey } : {}),
        })),
      ),
    [lines],
  );

  function addDrink(option: SelectedDrinkOption) {
    const defaultMl =
      option.kind === 'catalog' && option.category
        ? (presetsForCategory(option.category)[0]?.volumeMl ?? 180)
        : 180;
    const firstPreset =
      option.kind === 'catalog' && option.category
        ? presetsForCategory(option.category)[0]
        : undefined;

    setLines((prev) => [
      ...prev,
      {
        localId: crypto.randomUUID(),
        kind: option.kind,
        drinkId: option.drinkId,
        name: option.name,
        category: option.category,
        unit: 'ml',
        value: String(defaultMl),
        servingKey: firstPreset?.key ?? null,
        precision: firstPreset?.defaultPrecision ?? 'exact',
        quantity: 1,
      },
    ]);
  }

  function updateLine(localId: string, patch: Partial<LogDrinkLine>) {
    setLines((prev) =>
      prev.map((line) => (line.localId === localId ? { ...line, ...patch } : line)),
    );
  }

  function removeLine(localId: string) {
    setLines((prev) => prev.filter((line) => line.localId !== localId));
  }

  function selectPreset(line: LogDrinkLine, key: string) {
    const preset = findServingPreset(key);
    if (!preset) return;
    updateLine(line.localId, {
      servingKey: key,
      unit: 'ml',
      value: String(preset.volumeMl),
      precision: preset.defaultPrecision,
    });
  }

  function handleUnitChange(line: LogDrinkLine, next: VolumeUnit) {
    if (next === line.unit) return;
    const numeric = Number(line.value);
    const nextValue =
      line.value !== '' && Number.isFinite(numeric) && numeric > 0
        ? String(convertVolumeValue(numeric, line.unit, next))
        : line.value;
    updateLine(line.localId, {
      unit: next,
      value: nextValue,
      servingKey: null,
      precision: 'exact',
    });
  }

  function handleValueChange(line: LogDrinkLine, raw: string) {
    const patch: Partial<LogDrinkLine> = { value: raw };
    if (!line.servingKey) {
      patch.precision = 'exact';
    } else {
      const preset = findServingPreset(line.servingKey);
      const numeric = Number(raw);
      if (
        !preset ||
        line.unit !== 'ml' ||
        !Number.isFinite(numeric) ||
        round2(numeric) !== round2(preset.volumeMl)
      ) {
        patch.servingKey = null;
        patch.precision = 'exact';
      }
    }
    updateLine(line.localId, patch);
  }

  const canSubmit =
    lines.length > 0 &&
    lines.every(
      (l) =>
        Number.isFinite(Number(l.value)) &&
        Number(l.value) > 0 &&
        Number.isInteger(l.quantity) &&
        l.quantity >= 1 &&
        l.quantity <= 20,
    );

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
            {lines.map((line) => {
              const presets = line.category ? presetsForCategory(line.category) : [];
              return (
                <li key={line.localId} className="space-y-3 rounded-xl border p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium">{line.name}</p>
                      <p className="text-muted-foreground text-xs">
                        {line.kind === 'custom' ? 'カタログ外（自由入力）' : line.category}
                      </p>
                    </div>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => removeLine(line.localId)}
                    >
                      削除
                    </Button>
                  </div>

                  {presets.length > 0 && (
                    <div className="flex flex-wrap gap-2">
                      {presets.map((preset) => (
                        <Button
                          key={preset.key}
                          type="button"
                          size="sm"
                          variant={line.servingKey === preset.key ? 'default' : 'outline'}
                          onClick={() => selectPreset(line, preset.key)}
                        >
                          {preset.label}
                        </Button>
                      ))}
                    </div>
                  )}

                  <div className="flex flex-wrap items-end gap-4">
                    <div className="space-y-1">
                      <Label htmlFor={`qty-${line.localId}`}>杯数</Label>
                      <div className="flex items-center gap-1">
                        <Button
                          type="button"
                          variant="outline"
                          size="icon-sm"
                          aria-label="1杯減らす"
                          disabled={line.quantity <= 1}
                          onClick={() =>
                            updateLine(line.localId, { quantity: Math.max(1, line.quantity - 1) })
                          }
                        >
                          −
                        </Button>
                        <Input
                          id={`qty-${line.localId}`}
                          type="number"
                          inputMode="numeric"
                          min={1}
                          max={20}
                          step={1}
                          required
                          value={line.quantity}
                          onChange={(e) => {
                            const n = Number.parseInt(e.target.value, 10);
                            if (!Number.isFinite(n)) {
                              updateLine(line.localId, { quantity: 1 });
                              return;
                            }
                            updateLine(line.localId, {
                              quantity: Math.min(20, Math.max(1, n)),
                            });
                          }}
                          className="w-14 text-center"
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="icon-sm"
                          aria-label="1杯増やす"
                          disabled={line.quantity >= 20}
                          onClick={() =>
                            updateLine(line.localId, { quantity: Math.min(20, line.quantity + 1) })
                          }
                        >
                          ＋
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-1">
                      <Label htmlFor={`vol-${line.localId}`}>1杯あたりの量</Label>
                      <div className="flex flex-wrap items-center gap-2">
                        <Input
                          id={`vol-${line.localId}`}
                          type="number"
                          inputMode="decimal"
                          min={line.unit === 'oz' ? 0.5 : 1}
                          max={line.unit === 'oz' ? 70 : 2000}
                          step="any"
                          required
                          value={line.value}
                          onChange={(e) => handleValueChange(line, e.target.value)}
                          className="max-w-40"
                        />
                        <div
                          className="border-border inline-flex rounded-lg border p-0.5"
                          role="group"
                          aria-label="単位"
                        >
                          {(['ml', 'oz'] as const).map((u) => (
                            <button
                              key={u}
                              type="button"
                              className={cn(
                                'rounded-md px-2.5 py-1 text-sm font-medium transition-colors',
                                line.unit === u
                                  ? 'bg-primary text-primary-foreground'
                                  : 'text-muted-foreground hover:text-foreground',
                              )}
                              onClick={() => handleUnitChange(line, u)}
                              aria-pressed={line.unit === u}
                            >
                              {u}
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              );
            })}
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
