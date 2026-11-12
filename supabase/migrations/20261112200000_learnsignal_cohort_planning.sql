-- LearnSignal isolated schema. Apply only to the approved MSE Product Suite project.
create schema if not exists learnsignal;
revoke all on schema learnsignal from anon, public;
grant usage on schema learnsignal to authenticated;

create table if not exists learnsignal.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 100),
  region text not null default '' check (char_length(region) <= 120),
  team_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create table if not exists learnsignal.organization_members (
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);
create index if not exists learnsignal_members_user_idx on learnsignal.organization_members(user_id, organization_id);

create table if not exists learnsignal.programs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 3 and 120),
  grade_band text not null check (char_length(grade_band) between 2 and 60),
  support_model text not null check (char_length(support_model) between 2 and 80),
  focus_area text not null check (char_length(focus_area) between 2 and 100),
  status text not null default 'active' check (status in ('active', 'paused', 'closed')),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  unique (id, organization_id)
);
create index if not exists learnsignal_programs_org_idx on learnsignal.programs(organization_id, status, name);

create table if not exists learnsignal.progress_snapshots (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  program_id uuid not null,
  period_start date not null,
  enrolled integer not null check (enrolled between 10 and 100000),
  attendance_rate numeric(5,2) not null check (attendance_rate between 0 and 100),
  assessed integer not null check (assessed between 0 and enrolled and (assessed = 0 or assessed >= 10)),
  met_benchmark integer not null check (met_benchmark between 0 and assessed and (met_benchmark = 0 or met_benchmark >= 10)),
  sessions_planned integer not null check (sessions_planned between 0 and 100000),
  sessions_delivered integer not null check (sessions_delivered between 0 and 100000),
  staff_hours numeric(9,2) not null check (staff_hours between 0 and 1000000),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  unique (program_id, period_start),
  foreign key (program_id, organization_id) references learnsignal.programs(id, organization_id) on delete cascade
);
create index if not exists learnsignal_snapshots_org_period_idx on learnsignal.progress_snapshots(organization_id, period_start desc);

create table if not exists learnsignal.resource_capacities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  role_label text not null check (char_length(role_label) between 2 and 100),
  available_hours_week numeric(8,2) not null check (available_hours_week between 0 and 100000),
  unit text not null default 'hours / week' check (char_length(unit) between 2 and 24),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  unique (id, organization_id)
);
create index if not exists learnsignal_capacity_org_idx on learnsignal.resource_capacities(organization_id, role_label);

create table if not exists learnsignal.staff_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  capacity_id uuid not null,
  program_id uuid not null,
  assigned_hours_week numeric(8,2) not null check (assigned_hours_week > 0),
  created_by uuid not null default auth.uid() references auth.users(id),
  updated_at timestamptz not null default now(),
  unique (capacity_id, program_id),
  foreign key (capacity_id, organization_id) references learnsignal.resource_capacities(id, organization_id) on delete cascade,
  foreign key (program_id, organization_id) references learnsignal.programs(id, organization_id) on delete cascade
);
create index if not exists learnsignal_assignments_org_idx on learnsignal.staff_assignments(organization_id, capacity_id);

create table if not exists learnsignal.action_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references learnsignal.organizations(id) on delete cascade,
  program_id uuid not null,
  objective text not null check (char_length(objective) between 3 and 240),
  measure text not null check (char_length(measure) between 2 and 180),
  owner_role text not null check (char_length(owner_role) between 2 and 100),
  due_on date,
  status text not null default 'active' check (status in ('active', 'complete')),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (program_id, organization_id) references learnsignal.programs(id, organization_id) on delete cascade
);
create index if not exists learnsignal_actions_org_status_idx on learnsignal.action_plans(organization_id, status, due_on);

create or replace function learnsignal.is_org_member(p_org_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from learnsignal.organization_members m where m.organization_id = p_org_id and m.user_id = (select auth.uid()));
$$;
revoke all on function learnsignal.is_org_member(uuid) from public, anon;
grant execute on function learnsignal.is_org_member(uuid) to authenticated;

create or replace function learnsignal.create_organization(p_name text, p_region text default '')
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(trim(p_name)) not between 2 and 100 then raise exception 'Workspace name must be 2 to 100 characters'; end if;
  insert into learnsignal.organizations(name, region, created_by) values (trim(p_name), coalesce(trim(p_region), ''), auth.uid()) returning id into v_id;
  insert into learnsignal.organization_members(organization_id, user_id, role) values (v_id, auth.uid(), 'owner');
  return v_id;
end;
$$;
revoke all on function learnsignal.create_organization(text,text) from public, anon;
grant execute on function learnsignal.create_organization(text,text) to authenticated;

create or replace function learnsignal.join_organization(p_team_code text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select id into v_id from learnsignal.organizations where team_code = upper(trim(p_team_code));
  if v_id is null then raise exception 'Workspace code not found'; end if;
  insert into learnsignal.organization_members(organization_id, user_id) values (v_id, auth.uid()) on conflict do nothing;
  return v_id;
end;
$$;
revoke all on function learnsignal.join_organization(text) from public, anon;
grant execute on function learnsignal.join_organization(text) to authenticated;

-- Serialize assignment updates and reject any role pool over its weekly capacity.
create or replace function learnsignal.set_staff_assignment(p_capacity_id uuid, p_program_id uuid, p_hours numeric)
returns void language plpgsql security definer set search_path = '' as $$
declare v_capacity learnsignal.resource_capacities%rowtype; v_program_org uuid; v_used numeric; v_existing uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_hours < 0 or p_hours > 100000 then raise exception 'Hours are outside the allowed range'; end if;
  select * into v_capacity from learnsignal.resource_capacities where id = p_capacity_id for update;
  select organization_id into v_program_org from learnsignal.programs where id = p_program_id;
  if v_capacity.id is null or v_program_org is null or v_capacity.organization_id <> v_program_org or not learnsignal.is_org_member(v_capacity.organization_id) then raise exception 'Capacity pool or program unavailable'; end if;
  select id into v_existing from learnsignal.staff_assignments where capacity_id = p_capacity_id and program_id = p_program_id;
  select coalesce(sum(assigned_hours_week), 0) into v_used from learnsignal.staff_assignments where capacity_id = p_capacity_id and id <> coalesce(v_existing, '00000000-0000-0000-0000-000000000000'::uuid);
  if v_used + p_hours > v_capacity.available_hours_week then raise exception 'Assignment exceeds remaining weekly capacity'; end if;
  if p_hours = 0 then
    delete from learnsignal.staff_assignments where capacity_id = p_capacity_id and program_id = p_program_id;
  else
    insert into learnsignal.staff_assignments(organization_id, capacity_id, program_id, assigned_hours_week, created_by)
      values (v_capacity.organization_id, p_capacity_id, p_program_id, p_hours, auth.uid())
      on conflict (capacity_id, program_id) do update set assigned_hours_week = excluded.assigned_hours_week, created_by = auth.uid(), updated_at = now();
  end if;
end;
$$;
revoke all on function learnsignal.set_staff_assignment(uuid,uuid,numeric) from public, anon;
grant execute on function learnsignal.set_staff_assignment(uuid,uuid,numeric) to authenticated;

alter table learnsignal.organizations enable row level security;
alter table learnsignal.organization_members enable row level security;
alter table learnsignal.programs enable row level security;
alter table learnsignal.progress_snapshots enable row level security;
alter table learnsignal.resource_capacities enable row level security;
alter table learnsignal.staff_assignments enable row level security;
alter table learnsignal.action_plans enable row level security;

create policy "members read workspaces" on learnsignal.organizations for select to authenticated using (learnsignal.is_org_member(id));
create policy "members read roster" on learnsignal.organization_members for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members read programs" on learnsignal.programs for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members create programs" on learnsignal.programs for insert to authenticated with check (learnsignal.is_org_member(organization_id) and created_by = auth.uid());
create policy "members read snapshots" on learnsignal.progress_snapshots for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members add snapshots" on learnsignal.progress_snapshots for insert to authenticated with check (learnsignal.is_org_member(organization_id) and created_by = auth.uid());
create policy "members read capacity" on learnsignal.resource_capacities for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members add capacity" on learnsignal.resource_capacities for insert to authenticated with check (learnsignal.is_org_member(organization_id) and created_by = auth.uid());
create policy "members read assignments" on learnsignal.staff_assignments for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members read actions" on learnsignal.action_plans for select to authenticated using (learnsignal.is_org_member(organization_id));
create policy "members add actions" on learnsignal.action_plans for insert to authenticated with check (learnsignal.is_org_member(organization_id) and created_by = auth.uid());
create policy "members update actions" on learnsignal.action_plans for update to authenticated using (learnsignal.is_org_member(organization_id)) with check (learnsignal.is_org_member(organization_id));

revoke all on all tables in schema learnsignal from anon, public;
grant select on learnsignal.organizations, learnsignal.organization_members, learnsignal.programs, learnsignal.progress_snapshots, learnsignal.resource_capacities, learnsignal.staff_assignments, learnsignal.action_plans to authenticated;
grant insert on learnsignal.programs, learnsignal.progress_snapshots, learnsignal.resource_capacities, learnsignal.action_plans to authenticated;
grant update on learnsignal.action_plans to authenticated;
