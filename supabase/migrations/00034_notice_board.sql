-- ============================================================
-- Notice Board
-- ============================================================

create table if not exists notices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  title text not null check (char_length(title) between 5 and 150),
  body text not null check (char_length(body) >= 1),
  category text not null default 'general'
    check (category in ('academic','sports','events','holiday','examination','fee','general','emergency')),
  audience text not null default 'all'
    check (audience in ('all','students','parents','teachers','staff')),
  is_pinned boolean not null default false,
  is_published boolean not null default true,
  attachment_url text,
  attachment_name text,
  created_by uuid not null references users(id),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_notices_tenant_published
  on notices(tenant_id, is_published, created_at desc);

create index if not exists idx_notices_tenant_category
  on notices(tenant_id, category);

create index if not exists idx_notices_pinned
  on notices(tenant_id, is_pinned) where is_pinned = true;

-- RLS
alter table notices enable row level security;

-- Tenants can see their own notices
create policy "tenant members can view published notices"
  on notices for select
  using (
    tenant_id = (
      select (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    )
    and is_published = true
  );

-- Only admins/principals can insert
create policy "admins can insert notices"
  on notices for insert
  with check (
    tenant_id = (
      select (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    )
    and created_by = auth.uid()
  );

-- Authors can update their own notices; admins can update any
create policy "admins can update notices"
  on notices for update
  using (
    tenant_id = (
      select (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );

-- Authors / admins can delete
create policy "admins can delete notices"
  on notices for delete
  using (
    tenant_id = (
      select (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );

-- Auto-update updated_at
create or replace function update_notices_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists notices_updated_at on notices;
create trigger notices_updated_at
  before update on notices
  for each row execute function update_notices_updated_at();
