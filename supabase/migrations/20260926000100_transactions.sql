-- Finance demo (FEATURE_DEMO): SupabaseTransactionsRepository.
-- `tool/setup.dart --without demo` deletes this file.

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null check (title <> ''),
  -- Cents, always positive: the sign comes from `type`.
  amount bigint not null check (amount > 0),
  category text not null,
  type text not null check (type in ('income', 'expense')),
  date timestamptz not null,
  note text,
  created_at timestamptz not null default now()
);

-- Keyset pagination (newest first), with and without the type filter.
create index transactions_user_date_idx on public.transactions (user_id, date desc, id desc);
create index transactions_user_type_date_idx on public.transactions (user_id, type, date desc, id desc);

alter table public.transactions enable row level security;

create policy "Users manage their transactions" on public.transactions
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.transactions to authenticated;
