-- Migração 002 — NIF do cliente (validação do NIF da empresa na fatura)
-- Colar este ficheiro completo no SQL Editor do Supabase e carregar em "Run".

alter table public.despesas add column if not exists nif_cliente text;

-- A assinatura da função muda (novo parâmetro), por isso a antiga é removida
-- para não haver ambiguidade no PostgREST.
drop function if exists public.registar_fatura(text,text,text,text,text,text,text,text,text);

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

revoke execute on function public.registar_fatura(text,text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.registar_fatura(text,text,text,text,text,text,text,text,text,text)
  to anon, authenticated;
