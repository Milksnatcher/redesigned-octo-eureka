-- Run this once in your Supabase project's SQL Editor (left sidebar → SQL Editor → New query).

create table if not exists orders (
  id text primary key,
  supplier text,
  owner_name text,
  owner_phone text,
  transport numeric default 0,
  products jsonb default '[]',
  people jsonb default '[]',
  qty jsonb default '{}',
  created_at bigint
);

create table if not exists payments (
  key text primary key,
  paid boolean default false
);

-- Enable realtime sync for both tables
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table payments;

-- Row Level Security: only people logged in (via the shared account you
-- create in Supabase Auth) can read or write. Someone with just the site
-- link and the public anon key, but no login, gets nothing back.
alter table orders enable row level security;
alter table payments enable row level security;

create policy "authenticated read orders" on orders for select to authenticated using (true);
create policy "authenticated write orders" on orders for insert to authenticated with check (true);
create policy "authenticated update orders" on orders for update to authenticated using (true);
create policy "authenticated delete orders" on orders for delete to authenticated using (true);

create policy "authenticated read payments" on payments for select to authenticated using (true);
create policy "authenticated write payments" on payments for insert to authenticated with check (true);
create policy "authenticated update payments" on payments for update to authenticated using (true);
