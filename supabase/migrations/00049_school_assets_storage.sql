-- Create storage bucket for school assets (logos, branding)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'school-assets',
  'school-assets',
  true,
  2097152, -- 2MB limit
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to their tenant's logo folder
CREATE POLICY "Tenant admins can upload school assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'school-assets'
  AND (storage.foldername(name))[1] = 'logos'
  AND EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.role IN ('tenant_admin', 'principal', 'super_admin')
  )
);

-- Allow authenticated users to update/overwrite their school's logo
CREATE POLICY "Tenant admins can update school assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'school-assets'
  AND EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.role IN ('tenant_admin', 'principal', 'super_admin')
  )
);

-- Allow anyone to read school assets (logos are public)
CREATE POLICY "Anyone can read school assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'school-assets');

-- Allow admins to delete school assets
CREATE POLICY "Tenant admins can delete school assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'school-assets'
  AND EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.role IN ('tenant_admin', 'principal', 'super_admin')
  )
);
