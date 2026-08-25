-- Migração 005 — triagem de duplicados partilhada entre os dois iPhones
-- Colar no SQL Editor do Supabase e carregar em "Run".
--
-- Cada linha é um par (data|total) marcado como «são diferentes» na vista
-- de duplicados. Antes vivia no localStorage de cada dispositivo; agora é
-- partilhado: o que um marca deixa de aparecer ao outro.
-- A app migra sozinha a triagem antiga do dispositivo na primeira abertura.

create table if not exists public.duplicados_ignorados (
  chave     text primary key,          -- "AAAA-MM-DD|total com 2 casas", ex. "2026-03-07|1868.01"
  criada_em timestamptz not null default now()
);

alter table public.duplicados_ignorados enable row level security;

-- Só utilizadores autenticados (o casal) mexem; o papel anon fica fora.
drop policy if exists "autenticados tudo" on public.duplicados_ignorados;
create policy "autenticados tudo" on public.duplicados_ignorados
  for all to authenticated using (true) with check (true);
