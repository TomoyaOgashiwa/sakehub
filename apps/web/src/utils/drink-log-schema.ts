import { z } from 'zod';

export const volumeUnitSchema = z.enum(['ml', 'oz']);
export const volumePrecisionSchema = z.enum(['exact', 'estimated']);

const dateYmdSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, '日付が不正です。')
  .refine((raw) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(raw);
    if (!match) return false;
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    // Validate calendar components without local TZ (UTC noon probe).
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
  .refine(
    (v) => v === undefined || /^https?:\/\//i.test(v) || !v.includes('://'),
    'URL は http(s) で始めてください。',
  )
  .refine((v) => {
    if (v === undefined || !/^https?:\/\//i.test(v)) return true;
    try {
      const parsed = new URL(v);
      return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    } catch {
      return false;
    }
  }, '場所の URL が不正です。');

export const drinkLogItemSchema = z
  .object({
    drink_id: z.string().trim().min(1).optional(),
    custom_drink_name: z.string().trim().min(1).max(200).optional(),
    input_unit: volumeUnitSchema,
    input_value: z.number().positive(),
    serving_key: z.string().trim().min(1).optional(),
    volume_precision: volumePrecisionSchema,
    quantity: z.number().int().min(1).max(20).optional().default(1),
  })
  .superRefine((item, ctx) => {
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
  });

export const drinkLogBatchSchema = z.object({
  drank_at: dateYmdSchema.optional(),
  place_name: optionalTrimmed(200),
  place_url: placeUrlSchema,
  items: z.array(drinkLogItemSchema).min(1, '飲んだお酒を1つ以上追加してください。').max(20),
});

export const drinkLogUpdateSchema = z
  .object({
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
  });

export type DrinkLogBatchParsed = z.infer<typeof drinkLogBatchSchema>;
export type DrinkLogUpdateParsed = z.infer<typeof drinkLogUpdateSchema>;
export type DrinkLogItemParsed = z.infer<typeof drinkLogItemSchema>;

/**
 * Interpret a YYYY-MM-DD calendar day as Asia/Tokyo local midnight, return ISO UTC.
 */
export function tokyoDateToIso(ymd: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymd);
  if (!match) {
    throw new Error('invalid date');
  }
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  // Tokyo is UTC+9 with no DST.
  const utcMs = Date.UTC(year, month - 1, day, 0, 0, 0) - 9 * 60 * 60 * 1000;
  return new Date(utcMs).toISOString();
}

/** Format an ISO timestamp as YYYY-MM-DD in Asia/Tokyo. */
export function isoToTokyoDateInput(iso: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(iso));
  const year = parts.find((p) => p.type === 'year')?.value;
  const month = parts.find((p) => p.type === 'month')?.value;
  const day = parts.find((p) => p.type === 'day')?.value;
  return `${year}-${month}-${day}`;
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
