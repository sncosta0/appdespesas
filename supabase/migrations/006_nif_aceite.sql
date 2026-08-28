-- Migração 006 — aceitar faturas sem o NIF da empresa
-- Colar no SQL Editor do Supabase e carregar em "Run".
--
-- Faturas estrangeiras (ou simplificadas) não têm o NIF da empresa e não é
-- erro. nif_aceite = true tira-as do aviso «sem o NIF da empresa» no painel
-- e do filtro «Sem NIF» — nos dois iPhones, porque vive na base de dados.

alter table public.despesas add column if not exists nif_aceite boolean not null default false;
