# AppDespesas

App de despesas (PWA) para digitalizar, arquivar e controlar faturas da empresa — para dois utilizadores.

## Arquitetura

- **Captura**: atalho iOS "AppDespesas" (Scan Documents → extração com Apple Intelligence / Private Cloud Compute → arquiva o PDF na pasta iCloud certa → envia os dados ao Supabase como registo *por confirmar*).
- **App (este repositório)**: PWA estática hospedada no GitHub Pages. Login Supabase, confirmação/edição dos dados extraídos, dashboard com totais por mês/ano e por tipo (cartão da empresa vs. a reembolsar), lista com filtros e export CSV.
- **Dados**: Supabase (Postgres + Auth). Os PDFs **não** ficam no Supabase — vivem nas pastas do iCloud Drive, ligados a cada registo pelo nome do ficheiro (`AAAA-MM-DD_Fornecedor_total.pdf`).

## Setup (uma vez)

1. **Supabase — schema**: colar `supabase/schema.sql` no SQL Editor e correr.
2. **Supabase — utilizadores**: Authentication → Users → *Add user* (email + password, com *Auto Confirm*) para cada um dos dois utilizadores.
3. **App**: publicada via GitHub Pages a partir deste repositório. Abrir o URL no Safari do iPhone → Partilhar → *Adicionar ao ecrã principal* → abrir a app instalada e fazer login.
4. **Atalho**: seguir o guia de montagem do atalho (artifact "Atalho AppDespesas").

## Segurança

- A `anon key` embutida em `index.html` é pública por natureza (é assim que o Supabase funciona); os dados estão protegidos por Row Level Security — só utilizadores autenticados leem/alteram.
- O atalho só consegue *inserir* registos, através da função `registar_fatura` (não lê nada).
- A `service_role` key nunca deve aparecer neste repositório nem no atalho.
