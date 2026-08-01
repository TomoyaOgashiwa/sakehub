import type { CocktailRecipe } from '@sakehub/types';

/** Build schema.org/Recipe JSON-LD. Conditionally omits aggregateRating and image. */
export function buildRecipeJsonLd(recipe: CocktailRecipe): Record<string, unknown> {
  return {
    '@context': 'https://schema.org',
    '@type': 'Recipe',
    name: recipe.name,
    ...(recipe.imageUrl && { image: [recipe.imageUrl] }),
    ...(recipe.memo && { description: recipe.memo }),
    author: recipe.isOfficial
      ? { '@type': 'Organization', name: 'SakeHub' }
      : { '@type': 'Person', name: recipe.authorName ?? 'SakeHub ユーザー' },
    datePublished: recipe.createdAt,
    recipeCategory: 'カクテル',
    recipeYield: '1杯',
    recipeIngredient: recipe.ingredients.map((i) =>
      i.amount != null ? `${i.name} ${i.amount}${i.unit ?? ''}` : `${i.name} 適量`,
    ),
    recipeInstructions: recipe.steps.map((s, idx) => ({
      '@type': 'HowToStep',
      position: idx + 1,
      text: s.body,
    })),
    ...(recipe.totalRatings > 0 && {
      aggregateRating: {
        '@type': 'AggregateRating',
        ratingValue: recipe.averageRating,
        ratingCount: recipe.totalRatings,
        bestRating: 5,
        worstRating: 1,
      },
    }),
  };
}
