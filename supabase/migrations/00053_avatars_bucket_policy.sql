-- Harden the avatars storage bucket: restrict MIME types and enforce a size limit.
-- Mirrors the pattern established in 00049_school_assets_storage.sql.
-- Idempotent: ON CONFLICT updates the bucket row if it already exists without constraints.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit   = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Any authenticated user may upload to their own tenant avatar path.
-- Path shape enforced by WITH CHECK: tenants/<tenant_uuid>/avatars/<filename>
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'tenants'
  AND (storage.foldername(name))[3] = 'avatars'
  AND (storage.foldername(name))[2] = (
    SELECT tenant_id::text
    FROM public.user_roles
    WHERE user_id = auth.uid()
    LIMIT 1
  )
);

-- Users may overwrite their own avatar (upsert support).
CREATE POLICY "Authenticated users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'tenants'
  AND (storage.foldername(name))[3] = 'avatars'
  AND (storage.foldername(name))[2] = (
    SELECT tenant_id::text
    FROM public.user_roles
    WHERE user_id = auth.uid()
    LIMIT 1
  )
);

-- Avatars are public (bucket is public = true) — anyone may read.
CREATE POLICY "Anyone can read avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Users may delete their own tenant's avatars.
CREATE POLICY "Authenticated users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'tenants'
  AND (storage.foldername(name))[3] = 'avatars'
  AND (storage.foldername(name))[2] = (
    SELECT tenant_id::text
    FROM public.user_roles
    WHERE user_id = auth.uid()
    LIMIT 1
  )
);
