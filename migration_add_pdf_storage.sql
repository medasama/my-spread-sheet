-- PDFをリンクで共有するためのSupabase Storage設定
-- Supabase SQL Editorで一度だけ実行してください（medasama-toolsプロジェクト内）

-- 公開バケットを作成（存在しなければ）
insert into storage.buckets (id, name, public)
values ('money-tabs-pdfs', 'money-tabs-pdfs', true)
on conflict (id) do nothing;

-- 誰でも閲覧・アップロード・上書きできるようにする（既存の場合はスキップ）
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'money-tabs-pdfs public read') then
    create policy "money-tabs-pdfs public read"
      on storage.objects for select
      using ( bucket_id = 'money-tabs-pdfs' );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'money-tabs-pdfs anon upload') then
    create policy "money-tabs-pdfs anon upload"
      on storage.objects for insert
      with check ( bucket_id = 'money-tabs-pdfs' );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'money-tabs-pdfs anon update') then
    create policy "money-tabs-pdfs anon update"
      on storage.objects for update
      using ( bucket_id = 'money-tabs-pdfs' );
  end if;
end $$;

-- 補足：
-- このバケットは「公開」設定なので、発行されたURLを知っている人は誰でもPDFを閲覧できます
-- （ファイル名にはランダムなタイムスタンプが入るため、推測でアクセスされる可能性は低いですが、
-- 　他ツールと同様に「URLを知っている人はアクセス可能」という前提の運用になります）
