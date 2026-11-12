-- Evaluate auth.uid() once per statement instead of once per candidate row.
drop policy if exists "members create programs" on learnsignal.programs;
create policy "members create programs" on learnsignal.programs for insert to authenticated
  with check (learnsignal.is_org_member(organization_id) and created_by = (select auth.uid()));

drop policy if exists "members add snapshots" on learnsignal.progress_snapshots;
create policy "members add snapshots" on learnsignal.progress_snapshots for insert to authenticated
  with check (learnsignal.is_org_member(organization_id) and created_by = (select auth.uid()));

drop policy if exists "members add capacity" on learnsignal.resource_capacities;
create policy "members add capacity" on learnsignal.resource_capacities for insert to authenticated
  with check (learnsignal.is_org_member(organization_id) and created_by = (select auth.uid()));

drop policy if exists "members add actions" on learnsignal.action_plans;
create policy "members add actions" on learnsignal.action_plans for insert to authenticated
  with check (learnsignal.is_org_member(organization_id) and created_by = (select auth.uid()));
