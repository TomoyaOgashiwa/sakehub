'use client';

import { useActionState, useRef, useState } from 'react';
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

const initialState: RecipeFormState = { ok: false, error: '' };

function makeIngredient(): IngredientRow {
  return { id: crypto.randomUUID(), name: '', amount: '', unit: 'ml' };
}

export function CocktailRecipeForm() {
  const [state, formAction, isPending] = useActionState(createCocktailRecipe, initialState);
  const [ingredients, setIngredients] = useState<IngredientRow[]>([makeIngredient()]);
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

  return (
    <form action={formAction} encType="multipart/form-data" className="space-y-8">
      <input type="hidden" name="ingredients" value={serializedIngredients} readOnly />

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

      {/* Memo */}
      <div className="space-y-2">
        <Label htmlFor="memo">メモ・説明</Label>
        <Textarea
          id="memo"
          name="memo"
          placeholder="作り方の手順やコツを記入..."
          maxLength={1000}
          rows={4}
          className="resize-none"
        />
      </div>

      {/* Ingredients */}
      <div className="space-y-4">
        <Label>
          材料 <span className="text-destructive">*</span>
        </Label>

        <div className="space-y-3">
          {/* Column headers */}
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
          {isPending ? '登録中...' : 'レシピを登録する'}
        </button>
      </div>
    </form>
  );
}
