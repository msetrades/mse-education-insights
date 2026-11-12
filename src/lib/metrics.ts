export type ProgressSnapshot = { program_id: string; period_start: string; assessed: number; met_benchmark: number };
export type StaffAssignment = { capacity_id: string; assigned_hours_week: number };

export function programProgressDelta(snapshots: ProgressSnapshot[], programId: string): number | null {
  const eligible = snapshots
    .filter((snapshot) => snapshot.program_id === programId && snapshot.assessed >= 10)
    .sort((a, b) => a.period_start.localeCompare(b.period_start));
  if (eligible.length < 2) return null;
  const first = eligible[0];
  const latest = eligible[eligible.length - 1];
  return latest.met_benchmark / latest.assessed * 100 - first.met_benchmark / first.assessed * 100;
}

export function assignedHours(assignments: StaffAssignment[], capacityId: string): number {
  return assignments
    .filter((assignment) => assignment.capacity_id === capacityId)
    .reduce((total, assignment) => total + assignment.assigned_hours_week, 0);
}
