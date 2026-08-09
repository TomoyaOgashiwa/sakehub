-- Catalog product images for drinks / cocktails masters (prod seed assets).
-- Separate from cocktail-images (user recipe uploads under {auth.uid()}/…).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'catalog-images',
  'catalog-images',
  true,
  5242880, -- 5 MB
  ARRAY['image/webp']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Public read for catalog cards / detail pages.
CREATE POLICY "catalog_images_select" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'catalog-images');

-- Writes go through service_role (seed CLI). No authenticated-user insert/update/delete.
