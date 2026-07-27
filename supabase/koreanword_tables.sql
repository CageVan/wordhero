-- ============================================================
--  韩语单词本 独立云端表（与英语 wordhero_* 完全隔离）
--  在 Supabase SQL Editor 执行（项目：mvddczcebdhjzrjhehnq）
--  执行一次即可。改完韩语 APP 进度同步/共享词库即走 koreanword_* 表。
-- ============================================================

-- 0) 管理员密码表（先建，下面的词库 RLS 会引用它）
create table if not exists koreanword_admin (
  id  text primary key default 'admin',
  pwd text
);
insert into koreanword_admin (id, pwd) values ('admin', '1234')
  on conflict (id) do nothing;

-- 1) 进度备份表（每设备一行，按 device_id 隔离；与英语 wordhero_backups 互不干扰）
create table if not exists koreanword_backups (
  device_id  text primary key,
  payload    jsonb,
  user_name  text,
  updated_at timestamptz default now()
);
alter table koreanword_backups enable row level security;
-- 用 anon key 直接读写（device_id 为随机 UUID，不可猜测 = 弱隔离；与英语一致）
create policy "kw_backups_anon_all" on koreanword_backups
  for all using (true) with check (true);

-- 2) 共享词库表（id='master' 存词库；管理员写需带 x-admin-pwd 头，服务端校验）
create table if not exists koreanword_lib (
  id         text primary key,
  books      jsonb,
  updated_at timestamptz default now()
);
alter table koreanword_lib enable row level security;
create policy "kw_lib_anon_read" on koreanword_lib for select using (true);
create policy "kw_lib_admin_write" on koreanword_lib for all
  using (
    current_setting('request.headers', true)::json->>'x-admin-pwd'
    = (select pwd from koreanword_admin where id='admin')
  )
  with check (
    current_setting('request.headers', true)::json->>'x-admin-pwd'
    = (select pwd from koreanword_admin where id='admin')
  );

-- 3) 管理员密码校验 / 修改 RPC（韩语专属，避免与英语 verify_admin / set_admin_pwd 重名冲突）
create or replace function koreanword_verify_admin(in_pwd text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  return exists (select 1 from koreanword_admin where id='admin' and pwd = in_pwd);
end; $$;

create or replace function koreanword_set_admin_pwd(oldpwd text, newpwd text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from koreanword_admin where id='admin' and pwd = oldpwd) then
    update koreanword_admin set pwd = newpwd where id='admin';
    return true;
  end if;
  return false;
end; $$;

-- 默认管理员密码为 1234，请在 APP 内「设置 → 修改管理密码」改掉。
-- 不打算用「管理员推送韩语共享词库」功能的话，第 2/3 段可跳过，不影响进度同步与家长看板。
