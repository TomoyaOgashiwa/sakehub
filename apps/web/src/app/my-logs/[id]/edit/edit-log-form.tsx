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
  logToLine,
  type DrinkLogLine,
} from '@/components/drink-logs/drink-log-line-editor';
import { Button } from '@/components/ui/button';
import { Field, FieldDescription, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';
import { useBrowserTimeZone, useBrowserTodayYmd } from '@/hooks/use-browser-calendar';
import { isoToZonedDateInput } from '@/utils/time-zone';

const initialState: DrinkLogActionState = { ok: false, error: '' };

interface EditLogFormProps {
  log: DrinkLog;
  timeZone: string;
}

export function EditLogForm({ log, timeZone }: EditLogFormProps) {
  const router = useRouter();
  const tz = useBrowserTimeZone(timeZone);
  const maxDate = useBrowserTodayYmd();
  const [drankAt, setDrankAt] = useState<string | null>(null);
  const [placeName, setPlaceName] = useState(log.placeName ?? '');
  const [placeUrl, setPlaceUrl] = useState(log.placeUrl ?? '');
  const [line, setLine] = useState<DrinkLogLine>(() => logToLine(log));
  const drankAtValue = drankAt ?? isoToZonedDateInput(log.drankAt, tz);

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
  const fieldErrors = !state.ok ? state.fieldErrors : undefined;
  const drankInvalid = Boolean(fieldErrors?.drank_at);
  const placeNameInvalid = Boolean(fieldErrors?.place_name);
  const placeUrlInvalid = Boolean(fieldErrors?.place_url);

  function replaceDrink(option: SelectedDrinkOption) {
    setLine(createLineFromSelection(option));
  }

  return (
    <form action={formAction} className="flex flex-col gap-8">
      <input type="hidden" name="time_zone" value={tz} />
      <input type="hidden" name="original_drank_at" value={log.drankAt} />
      <input type="hidden" name="item_json" value={itemJSON} />

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
          <FieldDescription>
            日付を変えない場合は元の時刻のままです。今日にすると記録した時刻（UTC）になります。
          </FieldDescription>
          {drankInvalid && <FieldError>{fieldErrors?.drank_at}</FieldError>}
        </Field>

        <Field>
          <FieldLabel>銘柄を変更</FieldLabel>
          <DrinkAutocomplete onSelect={replaceDrink} />
          <DrinkLogLineEditor
            line={line}
            onChange={(patch) => setLine((prev) => ({ ...prev, ...patch }))}
            showRemove={false}
            errors={{
              drink: fieldErrors?.drink_id ?? fieldErrors?.custom_drink_name,
              input_value: fieldErrors?.input_value,
              quantity: fieldErrors?.quantity,
            }}
          />
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
          {placeUrlInvalid && <FieldError>{fieldErrors?.place_url}</FieldError>}
        </Field>
      </FieldGroup>

      {!state.ok && state.error && (!fieldErrors || fieldErrors.time_zone || fieldErrors._form) && (
        <p className="text-destructive text-sm" role="alert">
          {state.error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={isPending}>
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
