import assert from "node:assert/strict";
import test from "node:test";
import { assignedHours, programProgressDelta } from "../src/lib/metrics.ts";

test("program progress uses eligible first and latest periods regardless of input order", () => {
  const snapshots = [
    { program_id: "p1", period_start: "2026-03-01", assessed: 20, met_benchmark: 14 },
    { program_id: "p1", period_start: "2026-01-01", assessed: 9, met_benchmark: 8 },
    { program_id: "p1", period_start: "2026-01-01", assessed: 20, met_benchmark: 10 },
  ];
  assert.equal(programProgressDelta(snapshots, "p1"), 20);
  assert.equal(programProgressDelta(snapshots.slice(1, 2), "p1"), null);
});

test("weekly capacity sums only assignments for the selected pool", () => {
  assert.equal(assignedHours([
    { capacity_id: "a", assigned_hours_week: 5 },
    { capacity_id: "b", assigned_hours_week: 12 },
    { capacity_id: "a", assigned_hours_week: 7.5 },
  ], "a"), 12.5);
});
