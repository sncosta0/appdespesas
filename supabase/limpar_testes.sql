-- Remove os registos de teste criados durante as verificações de ligação.
-- Correr no SQL Editor do Supabase. Não toca em mais nada.

delete from public.despesas
 where fornecedor in (
   'Teste de ligação — podes eliminar',
   'Teste pos-migracao 004 — podes eliminar'
 );

-- Confirmação: deve devolver 0.
-- select count(*) from public.despesas where fornecedor ilike 'Teste%podes eliminar';
