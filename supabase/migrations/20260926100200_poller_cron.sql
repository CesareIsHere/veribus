-- Realtime poller every 10 s (edge runtime). Needs two Vault secrets, created once per project:
--   select vault.create_secret('https://<ref>.supabase.co/functions/v1/poller', 'poller_url');
--   select vault.create_secret('<random string, same as the POLLER_SECRET function secret>', 'poller_secret');
-- Until they exist the job does nothing. To move to the container runtime: select cron.unschedule('poller');

create extension if not exists pg_cron;
create extension if not exists pg_net;

create function live.invoke_poller() returns void
language plpgsql security definer set search_path = '' as $$
declare
  url text := (select decrypted_secret from vault.decrypted_secrets where name = 'poller_url');
  secret text := (select decrypted_secret from vault.decrypted_secrets where name = 'poller_secret');
begin
  if url is null or secret is null then return; end if;
  perform net.http_post(url := url, headers := jsonb_build_object('Authorization', 'Bearer ' || secret),
                        timeout_milliseconds := 30000);
end $$;
revoke all on function live.invoke_poller() from public;

select cron.schedule('poller', '10 seconds', 'select live.invoke_poller()');

-- pg_net keeps every response: trim it, and the snapshot index past the 90 days of the archive (RF-83).
select cron.schedule('cleanup', '17 3 * * *', $$
  delete from net._http_response where created < now() - interval '1 day';
  delete from live.snapshot where fetched_at < now() - interval '90 days';
  delete from network_meta.route_seen where date < current_date - 30;
$$);
