-- Run this in Supabase SQL Editor. If you already ran an earlier version of
-- this schema, drop the old tables first (this rewrite changes their shape):
--   drop table if exists payments;
--   drop table if exists orders;
--   drop table if exists users;
-- Then run everything below.

create table if not exists users (
  id text primary key,
  name text not null,
  phone text,
  revolut_handle text
);

create table if not exists orders (
  id text primary key,
  supplier text,
  owner_id text references users(id),
  transport numeric default 0,
  products jsonb default '[]',
  people jsonb default '[]',
  qty jsonb default '{}',
  created_at bigint,
  status text default 'activo',       -- 'activo' | 'completado'
  completed_at bigint
);

create table if not exists payments (
  key text primary key,               -- '<fromUserId>::<toUserId>'
  paid boolean default false,
  amount numeric,                     -- snapshot of the amount at the moment it was marked paid
  marked_by text,
  marked_date bigint                  -- epoch ms, editable via the date picker in the app
);

alter publication supabase_realtime add table users;
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table payments;

-- Row Level Security: only people logged in (via the shared account you
-- create in Supabase Auth) can read or write anything.
alter table users enable row level security;
alter table orders enable row level security;
alter table payments enable row level security;

create policy "authenticated read users" on users for select to authenticated using (true);
create policy "authenticated write users" on users for insert to authenticated with check (true);
create policy "authenticated update users" on users for update to authenticated using (true);
create policy "authenticated delete users" on users for delete to authenticated using (true);

create policy "authenticated read orders" on orders for select to authenticated using (true);
create policy "authenticated write orders" on orders for insert to authenticated with check (true);
create policy "authenticated update orders" on orders for update to authenticated using (true);
create policy "authenticated delete orders" on orders for delete to authenticated using (true);

create policy "authenticated read payments" on payments for select to authenticated using (true);
create policy "authenticated write payments" on payments for insert to authenticated with check (true);
create policy "authenticated update payments" on payments for update to authenticated using (true);
