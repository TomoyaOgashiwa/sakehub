import { z } from 'zod';

import { isSafeHttpUrl } from '@/utils/http-url';
import { isValidTimeZone, todayYmdInTimeZone } from '@/utils/time-zone';

export const volumeUnitSchema = z.enum(['ml', 'oz']);
export const volumePrecisionSchema = z.enum(['exact', 'estimated']);
export const DRINK_LOG_MAX_ITEMS_PER_BATCH = 20;

export const ianaTimeZoneSchema = z
  .string()
  .trim()
  .min(1, 'タイムゾーンが不正です。')
  .refine((tz) => isValidTimeZone(tz), 'タイムゾーンが不正です。');

const dateYmdSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, '日付が不正です。')
  .refine((raw) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(raw);
    if (!match) return false;
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const probe = new Date(Date.UTC(year, month - 1, day, 12));
    return (
      probe.getUTCFullYear() === year &&
      probe.getUTCMonth() === month - 1 &&
      probe.getUTCDate() === day
    );
  }, '日付が不正です。');

const optionalTrimmed = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .optional()
    .transform((v) => (v && v.length > 0 ? v : undefined));

const placeUrlSchema = z
  .string()
  .trim()
  .max(2000)
  .optional()
  .transform((v) => (v && v.length > 0 ? v : undefined))
  .refine((v) => v === undefined || isSafeHttpUrl(v), 'URL は http(s) で始めてください。');

const drinkLogItemFields = z.object({
  id: z.string().uuid().optional(),
  drink_id: z.string().trim().min(1).optional(),
  custom_drink_name: z.string().trim().min(1).max(200).optional(),
  input_unit: volumeUnitSchema,
  input_value: z.number().positive(),
  serving_key: z.string().trim().min(1).optional(),
  volume_precision: volumePrecisionSchema,
  quantity: z.number().int().min(1).max(20).optional().default(1),
});

function refineDrinkLogItem(item: z.infer<typeof drinkLogItemFields>, ctx: z.RefinementCtx) {
  const hasDrink = Boolean(item.drink_id);
  const hasCustom = Boolean(item.custom_drink_name);
  if (hasDrink === hasCustom) {
    ctx.addIssue({
      code: 'custom',
      message: '銘柄はカタログか自由入力のどちらか一方を指定してください。',
      path: hasDrink ? ['custom_drink_name'] : ['drink_id'],
    });
  }
  if (item.input_unit === 'ml' && item.input_value > 2000) {
    ctx.addIssue({
      code: 'custom',
      message: '量（ml）は 2000 以下にしてください。',
      path: ['input_value'],
    });
  }
  if (item.input_unit === 'oz' && item.input_value > 70) {
    ctx.addIssue({
      code: 'custom',
      message: '量（oz）は 70 以下にしてください。',
      path: ['input_value'],
    });
  }
}

function refineNotFutureDate(drankAt: string | undefined, timeZone: string, ctx: z.RefinementCtx) {
  if (!drankAt) return;
  if (drankAt > todayYmdInTimeZone(timeZone)) {
    ctx.addIssue({
      code: 'custom',
      message: '未来の日付は選べません。',
      path: ['drank_at'],
    });
  }
}

export const drinkLogItemSchema = drinkLogItemFields
  .omit({ id: true })
  .superRefine(refineDrinkLogItem);

export const drinkLogDayItemSchema = drinkLogItemFields.superRefine(refineDrinkLogItem);

export const drinkLogBatchSchema = z
  .object({
    time_zone: ianaTimeZoneSchema,
    drank_at: dateYmdSchema.optional(),
    place_name: optionalTrimmed(200),
    place_url: placeUrlSchema,
    items: z
      .array(drinkLogItemSchema)
      .min(1, '飲んだお酒を1つ以上追加してください。')
      .max(DRINK_LOG_MAX_ITEMS_PER_BATCH),
  })
  .superRefine((data, ctx) => {
    refineNotFutureDate(data.drank_at, data.time_zone, ctx);
  });

export const drinkLogDayReplaceSchema = z
  .object({
    time_zone: ianaTimeZoneSchema,
    date: dateYmdSchema,
    drank_at: dateYmdSchema,
    place_name: optionalTrimmed(200),
    place_url: placeUrlSchema,
    items: z
      .array(drinkLogDayItemSchema)
      .min(1, '飲んだお酒を1つ以上追加してください。')
      .max(DRINK_LOG_MAX_ITEMS_PER_BATCH),
  })
  .superRefine((data, ctx) => {
    refineNotFutureDate(data.drank_at, data.time_zone, ctx);
  });

export const drinkLogUpdateSchema = z
  .object({
    time_zone: ianaTimeZoneSchema,
    drank_at: dateYmdSchema.optional(),
    place_name: optionalTrimmed(200),
    place_url: placeUrlSchema,
    drink_id: z.string().trim().min(1).optional(),
    custom_drink_name: z.string().trim().min(1).max(200).optional(),
    input_unit: volumeUnitSchema,
    input_value: z.number().positive(),
    serving_key: z.string().trim().min(1).optional(),
    volume_precision: volumePrecisionSchema,
    quantity: z.number().int().min(1).max(20).optional().default(1),
  })
  .superRefine((item, ctx) => {
    refineDrinkLogItem(item, ctx);
    refineNotFutureDate(item.drank_at, item.time_zone, ctx);
  });

export type DrinkLogBatchParsed = z.infer<typeof drinkLogBatchSchema>;
export type DrinkLogDayReplaceParsed = z.infer<typeof drinkLogDayReplaceSchema>;
export type DrinkLogUpdateParsed = z.infer<typeof drinkLogUpdateSchema>;
export type DrinkLogItemParsed = z.infer<typeof drinkLogItemSchema>;

export {
  isoToZonedDateInput,
  todayYmdInTimeZone,
  ymdToDrankAtIso,
  zonedDateToIso,
} from '@/utils/time-zone';

export function zodIssuesToFieldErrors(error: z.ZodError): Record<string, string> {
  const fieldErrors: Record<string, string> = {};
  for (const issue of error.issues) {
    const key = issue.path.length > 0 ? issue.path.map(String).join('.') : '_form';
    if (fieldErrors[key] === undefined) {
      fieldErrors[key] = issue.message;
    }
  }
  return fieldErrors;
}

export function firstZodErrorMessage(error: z.ZodError): string {
  const tree = z.treeifyError(error);
  const walk = (node: unknown): string | undefined => {
    if (!node || typeof node !== 'object') return undefined;
    const n = node as {
      errors?: string[];
      properties?: Record<string, unknown>;
      items?: unknown[];
    };
    if (n.errors && n.errors.length > 0) return n.errors[0];
    if (n.properties) {
      for (const child of Object.values(n.properties)) {
        const msg = walk(child);
        if (msg) return msg;
      }
    }
    if (n.items) {
      for (const child of n.items) {
        const msg = walk(child);
        if (msg) return msg;
      }
    }
    return undefined;
  };
  return walk(tree) ?? '入力内容を確認してください。';
}
