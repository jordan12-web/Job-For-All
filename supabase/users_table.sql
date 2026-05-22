-- Run in Supabase SQL Editor (Layer 11 – Part 2)
-- Links public.users to auth.users

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  name text not null,
  role text not null check (role in ('seeker', 'employer', 'admin')),
  created_at timestamptz default now()
);

alter table public.users enable row level security;

-- Users can read their own profile
create policy "Users can read own profile"
  on public.users for select
  using (auth.uid() = id);

-- Users can insert their own row on signup
create policy "Users can insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

-- Create admin manually in Supabase Auth, then insert:
-- insert into public.users (id, email, name, role)
-- values ('<auth-user-uuid>', 'admin@yourcompany.com', 'Admin User', 'admin');
