'use client';

import { useActionState, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

import {
  createDrinkLogBatch,
  replaceDrinkLogsForDay,
  type DrinkLogActionState,
} from '@/application/drink-log-actions';
import {
  DrinkAutocomplete,
  type SelectedDrinkOption,
} from '@/components/drink-logs/drink-autocomplete';
import {
  createLineFromSelection,
  DrinkLogLineEditor,
  lineToApiItem,
  type DrinkLogLine,
  type DrinkLogLineErrors,
} from '@/components/drink-logs/drink-log-line-editor';
import { Button } from '@/components/ui/button';
import { Field, FieldDescription, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';
import { useBrowserTimeZone, useBrowserTodayYmd } from '@/hooks/use-browser-calendar';

const initialState: DrinkLogActionState = { ok: false, error: '' };

function lineErrorsAt(
  fieldErrors: Record<string, string> | undefined,
  index: number,
): DrinkLogLineErrors | undefined {
  if (!fieldErrors) return undefined;
  const drink =
    fieldErrors[`items.${index}.drink_id`] ?? fieldErrors[`items.${index}.custom_drink_name`];
  const input_value = fieldErrors[`items.${index}.input_value`];
  const quantity = fieldErrors[`items.${index}.quantity`];
  if (!drink && !input_value && !quantity) return undefined;
  return { drink, input_value, quantity };
}

export interface DrinkLogBatchFormProps {
  mode: 'create' | 'day-edit';
  timeZone?: string;
  initialDrankAt?: string;
  initialPlaceName?: string;
  initialPlaceUrl?: string;
  initialLines?: DrinkLogLine[];
  originalDate?: string;
  placeMixed?: boolean;
}

export function DrinkLogBatchForm({
  mode,
  timeZone: timeZoneProp,
  initialDrankAt = '',
  initialPlaceName = '',
  initialPlaceUrl = '',
  initialLines = [],
  originalDate,
  placeMixed = false,
}: DrinkLogBatchFormProps) {
  const router = useRouter();
  const browserToday = useBrowserTodayYmd();
  const browserTz = useBrowserTimeZone(timeZoneProp ?? 'UTC');
  const timeZone = mode === 'create' ? browserTz : (timeZoneProp ?? browserTz);
  const maxDate = browserToday;
  const [drankAt, setDrankAt] = useState<string | null>(mode === 'create' ? null : initialDrankAt);
  const [placeName, setPlaceName] = useState(initialPlaceName);
  const [placeUrl, setPlaceUrl] = useState(initialPlaceUrl);
  const [lines, setLines] = useState<DrinkLogLine[]>(initialLines);
  const drankAtValue = drankAt ?? (mode === 'create' ? browserToday : initialDrankAt);

  const action = mode === 'create' ? createDrinkLogBatch : replaceDrinkLogsForDay;

  const [state, formAction, isPending] = useActionState(
    async (prev: DrinkLogActionState, formData: FormData) => {
      const result = await action(prev, formData);
      if (result.ok) {
        router.push('/my-logs');
        router.refresh();
      }
      return result;
    },
    initialState,
  );

  const itemsJSON = useMemo(() => JSON.stringify(lines.map(lineToApiItem)), [lines]);
  const fieldErrors = !state.ok ? state.fieldErrors : undefined;
  const drankInvalid = Boolean(fieldErrors?.drank_at);
  const placeNameInvalid = Boolean(fieldErrors?.place_name);
  const placeUrlInvalid = Boolean(fieldErrors?.place_url);
  const itemsInvalid = Boolean(fieldErrors?.items);

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
    <form action={formAction} className="flex flex-col gap-8">
      <input type="hidden" name="time_zone" value={timeZone} />
      <input type="hidden" name="items_json" value={itemsJSON} />
      {mode === 'day-edit' && originalDate && (
        <input type="hidden" name="original_date" value={originalDate} />
      )}

      <FieldGroup>
        <Field data-invalid={drankInvalid ? true : undefined}>
          <FieldLabel htmlFor="drank_at">いつ飲んだか</FieldLabel>
          <Input
            id="drank_at"
            name="drank_at"
            type="date"
            required
            max={maxDate || undefined}
            value={drankAtValue}
            aria-invalid={drankInvalid}
            onChange={(e) => setDrankAt(e.target.value)}
            className="max-w-xs"
          />
          {mode === 'create' && (
            <FieldDescription>
              今日のままなら、記録した時刻（UTC）で保存されます。昨日以前にするときだけ日付を変えてください。
            </FieldDescription>
          )}
          {drankInvalid && <FieldError>{fieldErrors?.drank_at}</FieldError>}
        </Field>

        <Field data-invalid={itemsInvalid ? true : undefined}>
          <FieldLabel>飲んだお酒</FieldLabel>
          <DrinkAutocomplete onSelect={addDrink} />
          {lines.length === 0 ? (
            <p className="text-muted-foreground text-sm">まだお酒が追加されていません。</p>
          ) : (
            <ul className="flex flex-col gap-4">
              {lines.map((line, index) => (
                <li key={line.localId}>
                  <DrinkLogLineEditor
                    line={line}
                    onChange={(patch) => updateLine(line.localId, patch)}
                    onRemove={() => removeLine(line.localId)}
                    errors={lineErrorsAt(fieldErrors, index)}
                  />
                </li>
              ))}
            </ul>
          )}
          {itemsInvalid && <FieldError>{fieldErrors?.items}</FieldError>}
        </Field>

        <Field data-invalid={placeNameInvalid ? true : undefined}>
          <FieldLabel htmlFor="place_name">どこで飲んだか（任意）</FieldLabel>
          <Input
            id="place_name"
            name="place_name"
            placeholder="例: 自宅、〇〇酒店"
            value={placeName}
            aria-invalid={placeNameInvalid}
            onChange={(e) => setPlaceName(e.target.value)}
            maxLength={200}
          />
          {placeMixed && (
            <FieldDescription>
              この日は複数の場所があります。保存するとこの日の場所は1つに揃います。
            </FieldDescription>
          )}
          {placeNameInvalid && <FieldError>{fieldErrors?.place_name}</FieldError>}
        </Field>

        <Field data-invalid={placeUrlInvalid ? true : undefined}>
          <FieldLabel htmlFor="place_url">場所の URL（任意）</FieldLabel>
          <Input
            id="place_url"
            name="place_url"
            placeholder="Google マップや店舗サイトの URL"
            value={placeUrl}
            aria-invalid={placeUrlInvalid}
            onChange={(e) => setPlaceUrl(e.target.value)}
            maxLength={2000}
          />
          <FieldDescription>お店の場合など、分かるときだけ入力してください。</FieldDescription>
          {placeUrlInvalid && <FieldError>{fieldErrors?.place_url}</FieldError>}
        </Field>
      </FieldGroup>

      {!state.ok && state.error && (!fieldErrors || fieldErrors.time_zone || fieldErrors._form) && (
        <p className="text-destructive text-sm" role="alert">
          {state.error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={isPending || lines.length === 0}>
          {isPending
            ? mode === 'create'
              ? '記録中…'
              : '保存中…'
            : mode === 'create'
              ? '記録する'
              : '変更を保存'}
        </Button>
        {mode === 'day-edit' && (
          <Button
            type="button"
            variant="outline"
            onClick={() => router.push('/my-logs')}
            disabled={isPending}
          >
            キャンセル
          </Button>
        )}
      </div>
    </form>
  );
}
