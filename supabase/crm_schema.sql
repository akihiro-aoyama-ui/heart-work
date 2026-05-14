-- 大栄電通様 営業支援CRM
-- Supabase SQL Editorで実行してください。
-- RLSを有効化し、ログイン済みユーザーだけが閲覧・編集できる前提です。

create extension if not exists pgcrypto;

create table if not exists public.crm_companies (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  industry text not null default '未分類',
  area text not null default '未設定',
  pain text not null default '',
  support_type text not null default '未分類'
    check (support_type in ('伴走支援', 'システム構築', 'Google Workspace導入', 'スポット開発', '未分類')),
  stage text not null default 'ヒアリング前'
    check (stage in ('ヒアリング前', '課題確認中', '提案準備', '提案済み', '受注', '保留', '失注')),
  priority text not null default '中'
    check (priority in ('高', '中', '低')),
  daiei_owner text not null default '',
  creasta_owner text not null default '',
  next_action text not null default '',
  next_action_date date,
  estimated_amount integer not null default 0 check (estimated_amount >= 0),
  monthly_amount integer not null default 0 check (monthly_amount >= 0),
  memo text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_contacts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.crm_companies(id) on delete cascade,
  contact_name text not null,
  department text not null default '',
  role_title text not null default '',
  email text not null default '',
  phone text not null default '',
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_activities (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.crm_companies(id) on delete cascade,
  activity_date date not null default current_date,
  activity_type text not null default 'メモ'
    check (activity_type in ('訪問', '電話', 'メール', 'オンラインMTG', '提案', 'メモ')),
  summary text not null,
  detail text not null default '',
  owner_name text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists crm_companies_stage_idx on public.crm_companies(stage);
create index if not exists crm_companies_support_type_idx on public.crm_companies(support_type);
create index if not exists crm_companies_next_action_date_idx on public.crm_companies(next_action_date);
create index if not exists crm_contacts_company_id_idx on public.crm_contacts(company_id);
create index if not exists crm_activities_company_id_idx on public.crm_activities(company_id);
create index if not exists crm_activities_activity_date_idx on public.crm_activities(activity_date desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_crm_companies_updated_at on public.crm_companies;
create trigger set_crm_companies_updated_at
before update on public.crm_companies
for each row execute function public.set_updated_at();

drop trigger if exists set_crm_contacts_updated_at on public.crm_contacts;
create trigger set_crm_contacts_updated_at
before update on public.crm_contacts
for each row execute function public.set_updated_at();

alter table public.crm_companies enable row level security;
alter table public.crm_contacts enable row level security;
alter table public.crm_activities enable row level security;

drop policy if exists "authenticated users can read companies" on public.crm_companies;
create policy "authenticated users can read companies"
on public.crm_companies for select
to authenticated
using (true);

drop policy if exists "authenticated users can insert companies" on public.crm_companies;
create policy "authenticated users can insert companies"
on public.crm_companies for insert
to authenticated
with check (true);

drop policy if exists "authenticated users can update companies" on public.crm_companies;
create policy "authenticated users can update companies"
on public.crm_companies for update
to authenticated
using (true)
with check (true);

drop policy if exists "authenticated users can delete companies" on public.crm_companies;
create policy "authenticated users can delete companies"
on public.crm_companies for delete
to authenticated
using (true);

drop policy if exists "authenticated users can read contacts" on public.crm_contacts;
create policy "authenticated users can read contacts"
on public.crm_contacts for select
to authenticated
using (true);

drop policy if exists "authenticated users can write contacts" on public.crm_contacts;
create policy "authenticated users can write contacts"
on public.crm_contacts for all
to authenticated
using (true)
with check (true);

drop policy if exists "authenticated users can read activities" on public.crm_activities;
create policy "authenticated users can read activities"
on public.crm_activities for select
to authenticated
using (true);

drop policy if exists "authenticated users can write activities" on public.crm_activities;
create policy "authenticated users can write activities"
on public.crm_activities for all
to authenticated
using (true)
with check (true);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.crm_companies to authenticated;
grant select, insert, update, delete on public.crm_contacts to authenticated;
grant select, insert, update, delete on public.crm_activities to authenticated;

insert into public.crm_companies (
  company_name, industry, area, pain, support_type, stage, priority,
  daiei_owner, creasta_owner, next_action, next_action_date,
  estimated_amount, monthly_amount, memo
) values
  (
    'サンプル製造株式会社',
    '製造業',
    '久留米市',
    '見積書、図面、問い合わせ履歴が担当者ごとに分散している',
    '伴走支援',
    '課題確認中',
    '高',
    '大栄電通 担当A',
    'クリエスタ 青山',
    '業務フローを30分ヒアリングする',
    current_date + interval '7 days',
    300000,
    120000,
    'Google Workspaceの共有ドライブ設計とAI活用の伴走候補'
  ),
  (
    'サンプル運送株式会社',
    '運送業',
    '鳥栖市',
    '紙とExcelの運行予定を毎日転記していて確認に時間がかかる',
    'システム構築',
    '提案準備',
    '中',
    '大栄電通 担当B',
    'クリエスタ 青山',
    'デモ画面を見せて必要項目を確認する',
    current_date + interval '3 days',
    650000,
    0,
    'GAS、スプレッドシート、AI整理のスポット開発候補'
  )
on conflict do nothing;
