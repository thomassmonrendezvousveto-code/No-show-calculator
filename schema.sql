-- ============================================================
-- SCHEMA SAV MonRendezVousVeto
-- À coller dans Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1. CLINIQUES
create table if not exists clinics (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  city       text not null,
  email      text,          -- email de la clinique (pour auto-match)
  phone      text,
  created_at timestamptz default now()
);

-- 2. TICKETS
create table if not exists tickets (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid references clinics(id) on delete set null,
  title        text not null,
  status       text not null default 'Ouvert'
                 check (status in ('Ouvert','En cours','En attente','Résolu')),
  priority     text not null default 'Normale'
                 check (priority in ('Basse','Normale','Haute','Critique')),
  channel      text default 'Email',
  sender_email text,
  sender_name  text,
  assigned_to  text,        -- agent name
  tags         text[],
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- 3. MESSAGES
create table if not exists messages (
  id         uuid primary key default gen_random_uuid(),
  ticket_id  uuid references tickets(id) on delete cascade,
  from_name  text not null,
  text       text not null,
  kind       text default 'client'
               check (kind in ('client','internal')),
  created_at timestamptz default now()
);

-- 4. Auto-update updated_at sur les tickets
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tickets_updated_at on tickets;
create trigger tickets_updated_at
  before update on tickets
  for each row execute function update_updated_at();

-- 5. Index utiles
create index if not exists tickets_clinic_id_idx  on tickets(clinic_id);
create index if not exists tickets_status_idx      on tickets(status);
create index if not exists tickets_updated_at_idx  on tickets(updated_at desc);
create index if not exists messages_ticket_id_idx  on messages(ticket_id);
create index if not exists clinics_email_idx       on clinics(lower(email));

-- 6. Activer le Realtime sur les tickets (pour les mises à jour live)
alter publication supabase_realtime add table tickets;
alter publication supabase_realtime add table messages;

-- 7. Données de départ (les cliniques de démo)
insert into clinics (name, city, email, phone) values
  ('Unilasalle Rouen',       'Rouen',    'rouen@unilasalle.fr',   ''),
  ('Clinique Vét. Bayonne',  'Bayonne',  'contact@vetbayonne.fr', '05 59 00 00 01'),
  ('Clinique du Littoral',   'Biarritz', 'littoral@vet64.fr',     '05 59 00 00 02'),
  ('Veto Santé Pau',         'Pau',      'contact@vetopau.fr',    '05 59 00 00 03')
on conflict do nothing;

-- ============================================================
-- VÉRIFICATION : tu dois voir 4 tables dans Table Editor
-- clinics / tickets / messages
-- ============================================================
