-- Image attribution for catalog masters (AI-generated vs brand-provided).
-- Used for UI labels (e.g. regulatory AI disclosure). Recipe photos are out of scope.

ALTER TABLE drinks
  ADD COLUMN image_source text NOT NULL DEFAULT 'none'
  CHECK (image_source IN ('none', 'generated', 'brand'));

ALTER TABLE cocktails
  ADD COLUMN image_source text NOT NULL DEFAULT 'none'
  CHECK (image_source IN ('none', 'generated', 'brand'));

UPDATE drinks
SET image_source = 'generated'
WHERE image_url IS NOT NULL
  AND image_url LIKE '%/storage/v1/object/public/catalog-images/drinks/%';

UPDATE cocktails
SET image_source = 'generated'
WHERE image_url IS NOT NULL
  AND image_url LIKE '%/storage/v1/object/public/catalog-images/cocktails/%';
