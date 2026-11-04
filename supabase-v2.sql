-- =====================================================================
-- QIRAT v2 : blocage des faux déclarants et suppression automatique
-- À exécuter une fois, après supabase.sql.
-- =====================================================================

-- 1. Déclarants bloqués -------------------------------------------------------
create table if not exists public.banned (
  id text primary key,
  uid uuid default auth.uid(),
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.banned enable row level security;
drop policy if exists "lecture" on public.banned;
create policy "lecture" on public.banned for select using (public.is_admin() or id = auth.uid()::text);
drop policy if exists "ecriture_moderateurs" on public.banned;
create policy "ecriture_moderateurs" on public.banned for all using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.banned to anon, authenticated;

create or replace function public.is_banned() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.banned where id = auth.uid()::text)
$$;
grant execute on function public.is_banned() to anon, authenticated;

-- Un déclarant bloqué ne peut plus déclarer ni participer
drop policy if exists "creation" on public.declarations;
create policy "creation" on public.declarations for insert
  with check (uid = auth.uid() and id = auth.uid()::text and not public.is_banned());
drop policy if exists "modification" on public.declarations;
create policy "modification" on public.declarations for update
  using (uid = auth.uid() or public.is_admin())
  with check (public.is_admin() or (uid = auth.uid() and not public.is_banned()));

do $$
declare t text;
begin
  foreach t in array array['going','khatma','reports','suggestions'] loop
    execute format('drop policy if exists "creation" on public.%I', t);
    execute format('create policy "creation" on public.%I for insert with check (uid = auth.uid() and not public.is_banned())', t);
  end loop;
end $$;

do $$
begin
  execute 'alter publication supabase_realtime add table public.banned';
exception when duplicate_object then null;
end $$;

-- 2. Suppression automatique ---------------------------------------------------
-- Annonces : 7 jours après la date de la janaza, avec inscriptions, khatma et signalements.
-- Déclarations (dont le téléphone) : 15 jours après l'envoi.
-- Décisions de modération : 60 jours.
create or replace function public.qirat_purge() returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.janazas
   where data->>'date' ~ '^\d{4}-\d{2}-\d{2}$'
     and (data->>'date')::date < current_date - 7;
  delete from public.going   g where not exists (select 1 from public.janazas j where j.id = g.data->>'jid');
  delete from public.khatma  k where not exists (select 1 from public.janazas j where j.id = k.data->>'jid');
  delete from public.reports r where not exists (select 1 from public.janazas j where j.id = r.data->>'jid');
  delete from public.declarations
   where to_timestamp(coalesce(nullif(data->>'at','')::bigint, 0) / 1000.0) < now() - interval '15 days';
  delete from public.decisions
   where to_timestamp(coalesce(nullif(data->>'decidedAt','')::bigint, nullif(data->>'at','')::bigint, 0) / 1000.0) < now() - interval '60 days';
end $$;
revoke execute on function public.qirat_purge() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.unschedule(jobid) from cron.job where jobname = 'qirat-purge';
select cron.schedule('qirat-purge', '15 3 * * *', 'select public.qirat_purge()');

select jobname, schedule from cron.job where jobname = 'qirat-purge';

-- 3. Modérateurs enregistrés à l'avance par e-mail --------------------------
-- Ajouter un modérateur : insert into public.admin_emails (email) values ('adresse@exemple.fr');
create table if not exists public.admin_emails (email text primary key);
alter table public.admin_emails enable row level security;
revoke all on public.admin_emails from anon, authenticated;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
      or exists (select 1 from public.admin_emails
                  where email = lower(coalesce(auth.jwt()->>'email',''))
                    and coalesce(auth.jwt()->>'email','') <> '')
$$;
grant execute on function public.is_admin() to anon, authenticated;
