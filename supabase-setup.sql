-- Nova Store: Auth + profils + chat temps réel + stockage privé
-- À exécuter une seule fois dans Supabase > SQL Editor.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Utilisateur Nova',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.nova_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  message_type text not null default 'text' check (message_type in ('text','image','audio')),
  media_path text,
  created_at timestamptz not null default now(),
  constraint nova_message_payload_check check (
    (message_type = 'text' and length(trim(content)) between 1 and 600 and media_path is null)
    or
    (message_type in ('image','audio') and media_path is not null and length(media_path) <= 500)
  )
);

create index if not exists nova_messages_created_at_idx on public.nova_messages(created_at desc);
create index if not exists nova_messages_sender_id_idx on public.nova_messages(sender_id);

-- Création automatique du profil à l'inscription.
create or replace function public.nova_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Utilisateur Nova')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists nova_on_auth_user_created on auth.users;
create trigger nova_on_auth_user_created
after insert on auth.users
for each row execute procedure public.nova_handle_new_user();

-- Rattrapage des comptes créés avant l'installation de ce script.
insert into public.profiles (id, display_name)
select u.id, coalesce(nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''), 'Utilisateur Nova')
from auth.users as u
on conflict (id) do nothing;

-- RLS obligatoire: le client public ne reçoit que les droits explicitement accordés.
alter table public.profiles enable row level security;
alter table public.nova_messages enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.nova_messages from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (display_name) on table public.profiles to authenticated;
grant select, insert, delete on table public.nova_messages to authenticated;

drop policy if exists "profiles_read_authenticated" on public.profiles;
create policy "profiles_read_authenticated"
on public.profiles for select to authenticated
using (true);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "messages_read_authenticated" on public.nova_messages;
create policy "messages_read_authenticated"
on public.nova_messages for select to authenticated
using (true);

drop policy if exists "messages_insert_own" on public.nova_messages;
create policy "messages_insert_own"
on public.nova_messages for insert to authenticated
with check (sender_id = (select auth.uid()));

drop policy if exists "messages_delete_own" on public.nova_messages;
create policy "messages_delete_own"
on public.nova_messages for delete to authenticated
using (sender_id = (select auth.uid()));

-- Bucket privé: aucun accès anonyme. Les fichiers sont rangés dans un dossier = UUID utilisateur.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('nova-chat', 'nova-chat', false, 8388608, array['image/jpeg','image/png','image/webp','image/gif','audio/webm','audio/ogg','audio/mp4','audio/mpeg','audio/wav'])
on conflict (id) do update set public = false, file_size_limit = 8388608,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "nova_chat_read_authenticated" on storage.objects;
create policy "nova_chat_read_authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'nova-chat');

drop policy if exists "nova_chat_upload_own_folder" on storage.objects;
create policy "nova_chat_upload_own_folder"
on storage.objects for insert to authenticated
with check (bucket_id = 'nova-chat' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "nova_chat_delete_own_folder" on storage.objects;
create policy "nova_chat_delete_own_folder"
on storage.objects for delete to authenticated
using (bucket_id = 'nova-chat' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Active les événements Realtime pour la table des messages, sans doublon.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'nova_messages'
  ) then
    alter publication supabase_realtime add table public.nova_messages;
  end if;
end $$;
