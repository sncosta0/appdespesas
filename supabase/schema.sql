-- AppDespesas — schema inicial
-- Colar este ficheiro completo no SQL Editor do Supabase e carregar em "Run".

-- Tabela principal
create table if not exists public.despesas (
  id uuid primary key default gen_random_uuid(),
  criada_em timestamptz not null default now(),
  data date,
  fornecedor text,
  nif text,
  total numeric(10,2),
  iva numeric(10,2),
  categoria text,
  tipo text not null default 'reembolso' check (tipo in ('cartao','reembolso')),
  pago_por text,
  ficheiro text,
  nif_cliente text,
  confirmada boolean not null default false
);

create index if not exists despesas_data_idx on public.despesas (data desc);

alter table public.despesas enable row level security;

-- Os dois utilizadores autenticados (tu e a tua mulher) têm acesso total.
create policy "autenticados leem" on public.despesas
  for select to authenticated using (true);
create policy "autenticados inserem" on public.despesas
  for insert to authenticated with check (true);
create policy "autenticados atualizam" on public.despesas
  for update to authenticated using (true) with check (true);
create policy "autenticados apagam" on public.despesas
  for delete to authenticated using (true);

-- O papel anon (a chave pública que vai no atalho) não tem acesso direto à tabela:
revoke all on public.despesas from anon;

-- Única porta de entrada do atalho: função tolerante a campos vazios ou mal formatados,
-- para uma extração imperfeita nunca perder o registo.
create or replace function public.registar_fatura(
  p_tipo text default 'reembolso',
  p_data text default '',
  p_fornecedor text default '',
  p_nif text default '',
  p_total text default '',
  p_iva text default '',
  p_categoria text default '',
  p_pago_por text default '',
  p_ficheiro text default '',
  p_nif_cliente text default ''
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into public.despesas
    (tipo, data, fornecedor, nif, total, iva, categoria, pago_por, ficheiro, nif_cliente, confirmada)
  values (
    case when p_tipo in ('cartao','reembolso') then p_tipo else 'reembolso' end,
    case when p_data ~ '^\d{4}-\d{2}-\d{2}$' then p_data::date else null end,
    nullif(trim(p_fornecedor), ''),
    nullif(regexp_replace(p_nif, '\D', '', 'g'), ''),
    case when replace(trim(p_total), ',', '.') ~ '^\d+(\.\d+)?$'
         then replace(trim(p_total), ',', '.')::numeric else null end,
    case when replace(trim(p_iva), ',', '.') ~ '^\d+(\.\d+)?$'
         then replace(trim(p_iva), ',', '.')::numeric else null end,
    nullif(trim(p_categoria), ''),
    nullif(trim(p_pago_por), ''),
    nullif(trim(p_ficheiro), ''),
    nullif(regexp_replace(p_nif_cliente, '\D', '', 'g'), ''),
    false
  )
  returning id into v_id;
  return v_id;
end
$$;

revoke execute on function public.registar_fatura from public;
grant execute on function public.registar_fatura(text,text,text,text,text,text,text,text,text,text)
  to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Triagem de duplicados partilhada (migração 005)
-- Pares (data|total) marcados como «são diferentes» na vista de duplicados.
-- ---------------------------------------------------------------------------

create table if not exists public.duplicados_ignorados (
  chave     text primary key,
  criada_em timestamptz not null default now()
);

alter table public.duplicados_ignorados enable row level security;

create policy "autenticados tudo" on public.duplicados_ignorados
  for all to authenticated using (true) with check (true);

-- ---------------------------------------------------------------------------
-- Aceitar faturas sem o NIF da empresa (migração 006)
-- true = estrangeira/simplificada aceite; sai do aviso e do filtro «Sem NIF».
-- ---------------------------------------------------------------------------

alter table public.despesas add column if not exists nif_aceite boolean not null default false;
