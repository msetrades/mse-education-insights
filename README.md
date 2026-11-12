# LearnSignal

LearnSignal is a school support planning workspace for aggregate program monitoring, resource-capacity allocation, and measurable follow-up actions. It helps teams answer operational questions such as whether scheduled sessions were delivered, what share of an assessed cohort met a benchmark, and whether role capacity has already been committed across programs.

## Workflow

1. Create a private school or service-area workspace and invite colleagues with a team code.
2. Register broad support programs by grade band, intervention model, and learning focus.
3. Record periodic cohort-level snapshots: enrollment, attendance, assessed count, benchmark count, sessions, and staff hours.
4. Review descriptive outcome and delivery trends across reporting periods.
5. Register staff-role capacity and allocate weekly hours to programs. A transactional database function rejects allocations exceeding the pool.
6. Assign an action, measure, review date, and responsible role to guide the next planning cycle.

## Safeguarding and interpretation

The database rejects reported cohorts smaller than ten and suppresses small assessed/benchmark counts (unless zero). The product intentionally stores no student identities, IDs, contacts, grades at the individual level, case notes, disability/health data, or student-level intervention history. School teams must follow local safeguarding, consent, access, and retention policies.

Changes in benchmark shares are descriptive comparisons, not causal evidence that a program produced the change. Cohorts, assessment instruments, participation, and reporting practices may differ; review those factors before drawing conclusions.

## Local setup

Install dependencies, copy .env.example to .env.local, and run npm run dev. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY. Apply supabase/migrations/20261112200000_learnsignal_cohort_planning.sql to the approved MSE Product Suite project, expose the learnsignal schema in the Supabase Data API, and configure Auth redirect URLs for the deployment. Every table has RLS enabled, records are organization-scoped, and anonymous access is revoked.

## Project

- GitHub: https://github.com/msetrades/mse-education-insights
- Planned deployment: https://mse-education-insights.vercel.app
