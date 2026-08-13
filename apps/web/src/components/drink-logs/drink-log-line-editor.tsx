'use client';

import type { VolumeUnit } from '@sakehub/types';

import { type DrinkLogLine, type DrinkLogLineErrors } from '@/components/drink-logs/drink-log-line';
import { Button } from '@/components/ui/button';
import { Field, FieldError, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';
import { findServingPreset, presetsForCategory } from '@/config/serving-presets';
import { cn } from '@/utils/utils';
import { convertVolumeValue, round2 } from '@/utils/volume';

export type { DrinkLogLine, DrinkLogLineErrors } from '@/components/drink-logs/drink-log-line';
export {
  createLineFromSelection,
  lineToApiItem,
  logToLine,
} from '@/components/drink-logs/drink-log-line';

interface DrinkLogLineEditorProps {
  line: DrinkLogLine;
  onChange: (patch: Partial<DrinkLogLine>) => void;
  onRemove?: () => void;
  showRemove?: boolean;
  errors?: DrinkLogLineErrors;
}

export function DrinkLogLineEditor({
  line,
  onChange,
  onRemove,
  showRemove = true,
  errors,
}: DrinkLogLineEditorProps) {
  const presets = line.category ? presetsForCategory(line.category) : [];
  const drinkInvalid = Boolean(errors?.drink);
  const qtyInvalid = Boolean(errors?.quantity);
  const volInvalid = Boolean(errors?.input_value);

  function selectPreset(key: string) {
    const preset = findServingPreset(key);
    if (!preset) return;
    onChange({
      servingKey: key,
      unit: 'ml',
      value: String(preset.volumeMl),
      precision: preset.defaultPrecision,
    });
  }

  function handleUnitChange(next: VolumeUnit) {
    if (next === line.unit) return;
    const numeric = Number(line.value);
    const nextValue =
      line.value !== '' && Number.isFinite(numeric) && numeric > 0
        ? String(convertVolumeValue(numeric, line.unit, next))
        : line.value;
    onChange({
      unit: next,
      value: nextValue,
      servingKey: null,
      precision: 'exact',
    });
  }

  function handleValueChange(raw: string) {
    const patch: Partial<DrinkLogLine> = { value: raw };
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
    onChange(patch);
  }

  return (
    <div className="flex flex-col gap-3 rounded-xl border p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="font-medium">{line.name}</p>
          <p className="text-muted-foreground text-xs">
            {line.kind === 'custom' ? 'カタログ外（自由入力）' : line.category}
          </p>
          {drinkInvalid && <FieldError>{errors?.drink}</FieldError>}
        </div>
        {showRemove && onRemove && (
          <Button type="button" variant="ghost" size="sm" onClick={onRemove}>
            削除
          </Button>
        )}
      </div>

      {presets.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {presets.map((preset) => (
            <Button
              key={preset.key}
              type="button"
              size="sm"
              variant={line.servingKey === preset.key ? 'default' : 'outline'}
              onClick={() => selectPreset(preset.key)}
            >
              {preset.label}
            </Button>
          ))}
        </div>
      )}

      <div className="flex flex-wrap items-end gap-4">
        <Field data-invalid={qtyInvalid ? true : undefined} className="w-auto">
          <FieldLabel htmlFor={`qty-${line.localId}`}>杯数</FieldLabel>
          <div className="flex items-center gap-1">
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              aria-label="1杯減らす"
              disabled={line.quantity <= 1}
              onClick={() => onChange({ quantity: Math.max(1, line.quantity - 1) })}
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
              aria-invalid={qtyInvalid}
              value={line.quantity}
              onChange={(e) => {
                const n = Number.parseInt(e.target.value, 10);
                if (!Number.isFinite(n)) {
                  onChange({ quantity: 1 });
                  return;
                }
                onChange({ quantity: Math.min(20, Math.max(1, n)) });
              }}
              className="w-14 text-center"
            />
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              aria-label="1杯増やす"
              disabled={line.quantity >= 20}
              onClick={() => onChange({ quantity: Math.min(20, line.quantity + 1) })}
            >
              ＋
            </Button>
          </div>
          {qtyInvalid && <FieldError>{errors?.quantity}</FieldError>}
        </Field>

        <Field data-invalid={volInvalid ? true : undefined} className="w-auto">
          <FieldLabel htmlFor={`vol-${line.localId}`}>1杯あたりの量</FieldLabel>
          <div className="flex flex-wrap items-center gap-2">
            <Input
              id={`vol-${line.localId}`}
              type="number"
              inputMode="decimal"
              min={line.unit === 'oz' ? 0.5 : 1}
              max={line.unit === 'oz' ? 70 : 2000}
              step="any"
              required
              aria-invalid={volInvalid}
              value={line.value}
              onChange={(e) => handleValueChange(e.target.value)}
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
                  onClick={() => handleUnitChange(u)}
                  aria-pressed={line.unit === u}
                >
                  {u}
                </button>
              ))}
            </div>
          </div>
          {volInvalid && <FieldError>{errors?.input_value}</FieldError>}
        </Field>
      </div>
    </div>
  );
}
