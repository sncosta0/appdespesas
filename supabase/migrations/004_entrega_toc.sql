-- Migração 004 — data de entrega ao contabilista
-- Colar no SQL Editor do Supabase e carregar em "Run".
--
-- entregue_em NULL = ainda não entregue. Guardar a data (e não só um sim/não)
-- permite saber o que foi no lote de cada mês.

alter table public.despesas add column if not exists entregue_em date;

create index if not exists despesas_entregue_idx on public.despesas (entregue_em);

-- As faturas do histórico que já estavam nas subpastas "Enviado para TOC"
-- foram, por definição, entregues. Marca-as com a data da própria fatura
-- (aproximação honesta: não sabemos o dia exato da entrega).
update public.despesas
   set entregue_em = data
 where entregue_em is null
   and data is not null
   and (ficheiro ilike '%Enviado_para_TOC%' or ficheiro ilike '%Enviado para TOC%');

-- Quantas ficaram marcadas:
-- select count(*) filter (where entregue_em is not null) as entregues,
--        count(*) filter (where entregue_em is null)     as por_entregar
--   from public.despesas;
