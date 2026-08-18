'use client';

import { useActionState, useRef, useState } from 'react';
import type { Cocktail } from '@sakehub/types';
import { PlusIcon, Trash2Icon, UploadIcon } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/utils/utils';

import { type RecipeFormState, createCocktailRecipe } from './actions';

const UNITS = ['ml', 'g', 'tsp', 'tbsp', 'oz', 'cl', 'dash', 'drop', 'piece'] as const;
type Unit = (typeof UNITS)[number];

interface IngredientRow {
  id: string;
  name: string;
  amount: string;
  unit: Unit;
}

interface StepRow {
  id: string;
  body: string;
}

const initialState: RecipeFormState = { ok: false, error: '' };

function makeIngredient(): IngredientRow {
  return { id: crypto.randomUUID(), name: '', amount: '', unit: 'ml' };
}

function makeStep(): StepRow {
  return { id: crypto.randomUUID(), body: '' };
}

interface CocktailRecipeFormProps {
  cocktails: Cocktail[];
  defaultCocktailId?: string;
}

export function CocktailRecipeForm({ cocktails, defaultCocktailId }: CocktailRecipeFormProps) {
  const [state, formAction, isPending] = useActionState(createCocktailRecipe, initialState);
  const [ingredients, setIngredients] = useState<IngredientRow[]>([makeIngredient()]);
  const [steps, setSteps] = useState<StepRow[]>([makeStep()]);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const serializedIngredients = JSON.stringify(
    ingredients.map((ing, idx) => ({
      name: ing.name,
      amount: ing.amount ? parseFloat(ing.amount) : undefined,
      unit: ing.amount ? ing.unit : undefined,
      sort_order: idx,
    })),
  );

  const serializedSteps = JSON.stringify(
    steps.map((step, idx) => ({
      body: step.body,
      sort_order: idx,
    })),
  );

  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
  }

  function handleDropZoneClick() {
    fileInputRef.current?.click();
  }

  function handleDrop(e: React.DragEvent<HTMLDivElement>) {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (!file || !file.type.startsWith('image/')) return;
    if (fileInputRef.current) {
      const dt = new DataTransfer();
      dt.items.add(file);
      fileInputRef.current.files = dt.files;
    }
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
  }

  function addIngredient() {
    setIngredients((prev) => [...prev, makeIngredient()]);
  }

  function removeIngredient(id: string) {
    setIngredients((prev) => prev.filter((ing) => ing.id !== id));
  }

  function updateIngredient(id: string, field: keyof IngredientRow, value: string) {
    setIngredients((prev) => prev.map((ing) => (ing.id === id ? { ...ing, [field]: value } : ing)));
  }

  function addStep() {
    setSteps((prev) => [...prev, makeStep()]);
  }

  function removeStep(id: string) {
    setSteps((prev) => prev.filter((step) => step.id !== id));
  }

  function updateStep(id: string, body: string) {
    setSteps((prev) => prev.map((step) => (step.id === id ? { ...step, body } : step)));
  }

  return (
    <form action={formAction} className="space-y-8">
      <input type="hidden" name="ingredients" value={serializedIngredients} readOnly />
      <input type="hidden" name="steps" value={serializedSteps} readOnly />

      {/* Image upload */}
      <div className="space-y-2">
        <Label>カクテル写真</Label>
        <div
          role="button"
          tabIndex={0}
          onClick={handleDropZoneClick}
          onKeyDown={(e) => e.key === 'Enter' && handleDropZoneClick()}
          onDrop={handleDrop}
          onDragOver={(e) => e.preventDefault()}
          className={cn(
            'border-border hover:border-ring relative flex min-h-52 cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed transition-colors',
            previewUrl ? 'border-solid' : '',
          )}
        >
          {previewUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={previewUrl}
              alt="プレビュー"
              className="h-52 w-full rounded-xl object-cover"
            />
          ) : (
            <div className="text-muted-foreground flex flex-col items-center gap-3 p-8 text-center">
              <div className="border-border flex size-12 items-center justify-center rounded-full border">
                <UploadIcon className="size-5" />
              </div>
              <div>
                <p className="text-sm font-medium">クリックまたはドラッグ&amp;ドロップ</p>
                <p className="text-xs">JPG, PNG, WEBP（最大 10MB）</p>
              </div>
            </div>
          )}
          <input
            ref={fileInputRef}
            type="file"
            name="image"
            accept="image/jpeg,image/png,image/webp"
            className="sr-only"
            onChange={handleImageChange}
          />
        </div>
        {previewUrl && (
          <button
            type="button"
            onClick={() => {
              setPreviewUrl(null);
              if (fileInputRef.current) fileInputRef.current.value = '';
            }}
            className="text-muted-foreground hover:text-foreground text-xs underline underline-offset-2"
          >
            写真を削除
          </button>
        )}
      </div>

      {/* Cocktail genre */}
      <div className="space-y-2">
        <Label htmlFor="cocktail_id">
          カクテルの種類 <span className="text-destructive">*</span>
        </Label>
        <select
          id="cocktail_id"
          name="cocktail_id"
          required
          defaultValue={defaultCocktailId ?? ''}
          className="border-input dark:bg-input/30 h-12 w-full rounded-lg border bg-transparent px-3 text-sm outline-none focus-visible:ring-2"
        >
          <option value="" disabled>
            種類を選択してください
          </option>
          {cocktails.map((cocktail) => (
            <option key={cocktail.id} value={cocktail.id}>
              {cocktail.name}
              {cocktail.nameEn ? ` (${cocktail.nameEn})` : ''}
            </option>
          ))}
        </select>
        <p className="text-muted-foreground text-xs">
          レシピはこの種類（ジャンル）に紐づいて一覧表示されます
        </p>
      </div>

      {/* Cocktail name */}
      <div className="space-y-2">
        <Label htmlFor="name">
          カクテル名 <span className="text-destructive">*</span>
        </Label>
        <Input
          id="name"
          name="name"
          placeholder="例：東京ミュール、桜マティーニ..."
          maxLength={100}
          required
          className="h-12"
        />
      </div>

      {/* Ingredients */}
      <div className="space-y-4">
        <Label>
          材料 <span className="text-destructive">*</span>
        </Label>

        <div className="space-y-3">
          <div className="grid grid-cols-[1fr_120px_120px_40px] gap-2 px-1">
            <span className="text-muted-foreground text-xs font-medium">材料名</span>
            <span className="text-muted-foreground text-xs font-medium">数量</span>
            <span className="text-muted-foreground text-xs font-medium">単位</span>
            <span />
          </div>

          {ingredients.map((ing, idx) => (
            <div key={ing.id} className="grid grid-cols-[1fr_120px_120px_40px] items-center gap-2">
              <Input
                placeholder={`材料 ${idx + 1}`}
                value={ing.name}
                onChange={(e) => updateIngredient(ing.id, 'name', e.target.value)}
                maxLength={100}
                required
                className="h-10"
              />
              <Input
                type="number"
                placeholder="0"
                min="0"
                step="any"
                value={ing.amount}
                onChange={(e) => updateIngredient(ing.id, 'amount', e.target.value)}
                className="h-10"
              />
              <select
                value={ing.unit}
                onChange={(e) => updateIngredient(ing.id, 'unit', e.target.value)}
                className="border-input dark:bg-input/30 h-10 w-full rounded-lg border bg-transparent px-2.5 text-sm outline-none focus-visible:ring-2"
              >
                {UNITS.map((u) => (
                  <option key={u} value={u}>
                    {u}
                  </option>
                ))}
              </select>
              <Button
                type="button"
                variant="ghost"
                size="icon"
                onClick={() => removeIngredient(ing.id)}
                disabled={ingredients.length === 1}
                aria-label="材料を削除"
                className="text-muted-foreground"
              >
                <Trash2Icon className="size-4" />
              </Button>
            </div>
          ))}
        </div>

        <Button type="button" variant="outline" onClick={addIngredient} className="w-full gap-2">
          <PlusIcon className="size-4" />
          材料を追加
        </Button>
      </div>

      {/* Steps */}
      <div className="space-y-4">
        <Label>
          作り方 <span className="text-destructive">*</span>
        </Label>

        <div className="space-y-3">
          {steps.map((step, idx) => (
            <div key={step.id} className="flex items-start gap-2">
              <span
                className="bg-muted text-muted-foreground mt-2 flex size-7 shrink-0 items-center justify-center rounded-full text-xs font-medium tabular-nums"
                aria-hidden="true"
              >
                {idx + 1}
              </span>
              <Textarea
                placeholder={`手順 ${idx + 1}（例: グラスに氷をたっぷり入れる）`}
                value={step.body}
                onChange={(e) => updateStep(step.id, e.target.value)}
                maxLength={500}
                rows={2}
                required
                className="resize-none"
              />
              <Button
                type="button"
                variant="ghost"
                size="icon"
                onClick={() => removeStep(step.id)}
                disabled={steps.length === 1}
                aria-label="手順を削除"
                className="text-muted-foreground mt-1"
              >
                <Trash2Icon className="size-4" />
              </Button>
            </div>
          ))}
        </div>

        <Button type="button" variant="outline" onClick={addStep} className="w-full gap-2">
          <PlusIcon className="size-4" />
          手順を追加
        </Button>
      </div>

      {/* Tips */}
      <div className="space-y-2">
        <Label htmlFor="memo">コツ・ポイント</Label>
        <Textarea
          id="memo"
          name="memo"
          placeholder="氷は大きめのものを使うと薄まりにくい..."
          maxLength={1000}
          rows={4}
          className="resize-none"
        />
      </div>

      {/* Error */}
      {!state.ok && state.error && <p className="text-destructive text-sm">{state.error}</p>}

      {/* Submit buttons */}
      <div className="flex gap-3 pt-2">
        <Button
          type="submit"
          name="status"
          value="draft"
          variant="outline"
          disabled={isPending}
          className="flex-1"
        >
          下書き保存
        </Button>
        <button
          type="submit"
          name="status"
          value="published"
          disabled={isPending}
          className={cn(
            'flex-1 rounded-lg px-4 py-2 text-sm font-medium transition-opacity',
            'bg-amber text-amber-foreground hover:opacity-90 disabled:opacity-50',
            isPending && 'cursor-not-allowed',
          )}
        >
          {isPending ? '投稿中...' : 'レシピを投稿する'}
        </button>
      </div>
    </form>
  );
}
