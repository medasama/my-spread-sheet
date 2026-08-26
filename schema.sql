-- my-spread-sheet (お金の帳簿): Supabase schema
-- 何度実行しても安全(冪等)な書き方にしています。

-- 0) uuid生成関数のために pgcrypto を有効化
create extension if not exists pgcrypto;

-- 1) テーブル作成: タブ
create table if not exists money_tabs (
  name text primary key,
  sort_order integer not null default 0
);

-- 2) テーブル作成: 明細
create table if not exists money_entries (
  id uuid primary key default gen_random_uuid(),
  tab_name text not null references money_tabs(name) on delete cascade,
  entry_date date not null,
  item text,
  store text,
  amount numeric not null default 0,
  memo text,
  created_at timestamptz not null default now()
);

-- 3) RLSを有効化
alter table money_tabs enable row level security;
alter table money_entries enable row level security;

-- 4) anon/publishable key で全操作(SELECT/INSERT/UPDATE/DELETE)を許可するポリシー
drop policy if exists "money_tabs_anon_all" on money_tabs;
create policy "money_tabs_anon_all"
  on money_tabs
  for all
  to anon
  using (true)
  with check (true);

drop policy if exists "money_entries_anon_all" on money_entries;
create policy "money_entries_anon_all"
  on money_entries
  for all
  to anon
  using (true)
  with check (true);

-- 5) UPDATE/DELETE時にRealtimeへ完全な行情報を送るための設定
alter table money_tabs replica identity full;
alter table money_entries replica identity full;

-- 6) Realtime publication へテーブルを追加(重複追加によるエラーを回避)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'money_tabs'
  ) then
    alter publication supabase_realtime add table money_tabs;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'money_entries'
  ) then
    alter publication supabase_realtime add table money_entries;
  end if;
end $$;
