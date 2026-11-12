-- Index product foreign keys for joins and parent-row updates/deletes.
create index if not exists "mse_fk_action_plans_1" on "learnsignal"."action_plans" ("created_by");
create index if not exists "mse_fk_action_plans_2" on "learnsignal"."action_plans" ("program_id", "organization_id");
create index if not exists "mse_fk_organizations_1" on "learnsignal"."organizations" ("created_by");
create index if not exists "mse_fk_programs_1" on "learnsignal"."programs" ("created_by");
create index if not exists "mse_fk_progress_snapshots_1" on "learnsignal"."progress_snapshots" ("created_by");
create index if not exists "mse_fk_progress_snapshots_2" on "learnsignal"."progress_snapshots" ("program_id", "organization_id");
create index if not exists "mse_fk_resource_capacities_1" on "learnsignal"."resource_capacities" ("created_by");
create index if not exists "mse_fk_staff_assignments_1" on "learnsignal"."staff_assignments" ("capacity_id", "organization_id");
create index if not exists "mse_fk_staff_assignments_2" on "learnsignal"."staff_assignments" ("created_by");
create index if not exists "mse_fk_staff_assignments_3" on "learnsignal"."staff_assignments" ("program_id", "organization_id");

