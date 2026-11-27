# Final review grades each test yes or no, on proof

Status: approved
Branch: feature/binary-test-verdict
Base: origin/main
Date: 2026-11-27

## Problem

The final review can grade an AC's test "partly", and the owner can waive a "partly" or "no" row. Across 32 features, 46 of 104 fix tickets were test-only gaps from these rows, and the owner waived 23 rows by hand (measured 2026-11-27). The owner wants a two-way call: the reviewer shows a code break the tests miss and it is fixed, or the test stands and nothing is written down.

## User stories

### US-1 A test is graded yes or no, and a no carries its proof

As the owner reading a final review, I want every AC row graded yes or no, with each no naming the code break its tests miss, so that a fix ticket is always a real gap and there is nothing to waive.

- US-1.AC1: Given a review whose AC table has a row graded "partly", when the review check runs, then it exits 1, names that row, and its Fix line says to grade the row yes or no, whatever the Verdict line says.
- US-1.AC2: Given a review whose AC table has a row graded "no" and a Note that does not start with "Mutation:", when the review check runs, then it exits 1, names that row, and its Fix line says to start the Note with "Mutation:", the production change that makes the AC false and the test command that still passed, or to grade the row yes.
- US-1.AC3: Given a review with Verdict PASS and a row graded "no" whose Note starts "Waived 2026-11-02 (owner): flaky", when the review check runs, then it exits 1, names that row, and its Fix line says to set Verdict FAIL and write a fix ticket, with no mention of a waiver.

## Decisions

- Testing seams: the review check's exit code and printed lines, driven from the scripts' own test suite with a review file written by the test.
- Grading: the reviewer grades "no" only after making the production change in a throwaway copy of the branch and seeing the AC's tests still pass; when it cannot make such a change, the row is "yes". The check holds the shape of the Note, the reviewer's prompt holds the run.
- Waivers: no row can be waived. An AC the owner no longer wants proven is reworded in the spec.
- Carried rows: a delta review re-judges a row an earlier review graded "partly" instead of copying it.

## Out of Scope

- A script that applies the named change and re-runs the tests itself, as the guard check does for guard commits (later, if reviewers write changes that do not hold).
- Rewriting review files of features already merged.
- The per-ticket checks and reviewers in the build stage.

## Manual check

1. Run the scripts' test suite: every case passes, the three new ones included.
2. On the next feature's final review, open the review file: every AC row says yes or no, each no starts with "Mutation:", and no row says "Waived".
