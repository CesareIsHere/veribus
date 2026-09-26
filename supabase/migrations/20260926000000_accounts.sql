-- Account data used by SupabaseAuthRepository. Apply with `supabase db push`.
-- Every policy uses `(select auth.uid())`: evaluated once per query, not per row.

-- Push tokens (FCM), one row per user and device.
create table public.push_tokens (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  token text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, token)
);

alter table public.push_tokens enable row level security;

create policy "Users manage their push tokens" on public.push_tokens
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.push_tokens to authenticated;

-- Avatars: avatars/{uid}/avatar.jpg. Public read (the URL is stored in the
-- user metadata), images up to 5 MB, writable only by their owner.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/*'])
on conflict (id) do nothing;

-- Upserts need select + insert + update.
create policy "Users read their avatar folder" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users upload to their avatar folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users update their avatar folder" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users delete their avatar folder" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Clients can't delete their own auth user: this runs with the owner's
-- rights but only ever deletes the caller. Their rows go with ON DELETE CASCADE.
create function public.delete_account()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = (select auth.uid());
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
