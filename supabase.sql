-- =====================================================================
-- QIRAT : base de données Supabase
-- À coller en entier dans Supabase > SQL Editor > New query, puis "Run".
-- À exécuter une seule fois.
-- =====================================================================

-- 1. Les modérateurs ------------------------------------------------------
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text
);
alter table public.admins enable row level security;
drop policy if exists "admins_lire_soi" on public.admins;
create policy "admins_lire_soi" on public.admins for select using (user_id = auth.uid());

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
$$;

-- 2. Les tables de l'appli (même structure pour toutes) --------------------
do $$
declare t text;
begin
  foreach t in array array['janazas','declarations','decisions','going','khatma','reports','config','mosques','suggestions'] loop
    execute format('create table if not exists public.%I (
      id text primary key,
      uid uuid default auth.uid(),
      data jsonb not null default ''{}''::jsonb,
      updated_at timestamptz not null default now()
    )', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- 3. Les règles de sécurité ----------------------------------------------

-- Annonces publiées, décisions, dons, mosquées ajoutées : tout le monde lit, seuls les modérateurs écrivent
do $$
declare t text;
begin
  foreach t in array array['janazas','config','mosques'] loop
    execute format('drop policy if exists "lecture" on public.%I', t);
    execute format('create policy "lecture" on public.%I for select using (true)', t);
    execute format('drop policy if exists "ecriture_moderateurs" on public.%I', t);
    execute format('create policy "ecriture_moderateurs" on public.%I for all using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- Décisions de modération : le déclarant voit la sienne, les modérateurs voient tout
drop policy if exists "lecture" on public.decisions;
create policy "lecture" on public.decisions for select using (public.is_admin() or id = auth.uid()::text);
drop policy if exists "ecriture_moderateurs" on public.decisions;
create policy "ecriture_moderateurs" on public.decisions for all using (public.is_admin()) with check (public.is_admin());

-- Déclarations de décès : privées (téléphone du déclarant), une par personne
drop policy if exists "lecture" on public.declarations;
create policy "lecture" on public.declarations for select using (public.is_admin() or uid = auth.uid());
drop policy if exists "creation" on public.declarations;
create policy "creation" on public.declarations for insert with check (uid = auth.uid() and id = auth.uid()::text);
drop policy if exists "modification" on public.declarations;
create policy "modification" on public.declarations for update using (uid = auth.uid() or public.is_admin());
drop policy if exists "suppression" on public.declarations;
create policy "suppression" on public.declarations for delete using (public.is_admin());

-- Participation (J'y serai, khatma, signalements, mosquées proposées) : tout le monde lit, chacun gère les siens
do $$
declare t text;
begin
  foreach t in array array['going','khatma','reports','suggestions'] loop
    execute format('drop policy if exists "lecture" on public.%I', t);
    execute format('create policy "lecture" on public.%I for select using (true)', t);
    execute format('drop policy if exists "creation" on public.%I', t);
    execute format('create policy "creation" on public.%I for insert with check (uid = auth.uid())', t);
    execute format('drop policy if exists "modification" on public.%I', t);
    execute format('create policy "modification" on public.%I for update using (uid = auth.uid())', t);
    execute format('drop policy if exists "suppression" on public.%I', t);
    execute format('create policy "suppression" on public.%I for delete using (uid = auth.uid() or public.is_admin())', t);
  end loop;
end $$;

-- 4. Accès depuis l'appli ---------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select on public.admins to anon, authenticated;
grant select, insert, update, delete on
  public.janazas, public.declarations, public.decisions, public.going, public.khatma,
  public.reports, public.config, public.mosques, public.suggestions
  to anon, authenticated;
grant execute on function public.is_admin() to anon, authenticated;

-- 5. Mises à jour en direct ---------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['janazas','declarations','decisions','going','khatma','reports','config','mosques','suggestions'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- 6. Trois annonces de test --------------------------------------------------
insert into public.janazas (id, data) values
('test1', '{"test":true,"name":"Ahmed B.","sex":"m","age":"74","mosq":"Grande Mosquée d''Évry-Courcouronnes","city":"Évry-Courcouronnes","dep":"91","lat":48.624,"lon":2.429,"date":"2026-11-07","salat":"Asr","cim":"Carré musulman du cimetière de Courcouronnes"}'),
('test2', '{"test":true,"name":"Fatima Z.","sex":"f","age":"61","mosq":"Grande Mosquée de Lieusaint","city":"Lieusaint","dep":"77","lat":48.633,"lon":2.549,"date":"2026-11-08","salat":"Dhuhr","cim":"Rapatriement au Maroc après la prière"}'),
('test3', '{"test":true,"name":"Youssef M.","sex":"m","age":"38","mosq":"Grande Mosquée de Créteil (Sahaba)","city":"Créteil","dep":"94","lat":48.79,"lon":2.455,"date":"2026-11-13","salat":"Jumu''a","cim":"Carré musulman du cimetière de Valenton"}')
on conflict (id) do nothing;

-- =====================================================================
-- APRÈS ta première connexion modérateur dans l'appli (guide, étape 4),
-- exécute ces 2 lignes en remplaçant les e-mails par les vôtres :
--
-- insert into public.admins (user_id, email)
-- select id, email from auth.users where email in ('ton.email@exemple.fr', 'email.associe@exemple.fr')
-- on conflict (user_id) do nothing;
-- =====================================================================
