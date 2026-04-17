---
name: emobot-master-planner
description: Use when planning, reprioritizing, or changing EmoBot scope, milestones, or feature boundaries. This skill decides whether work belongs in the original-demand-compatible MVP, what must stay P0, what can slip, and which project docs to update first.
---

# EmoBot Master Planner

Use this skill when the task is about scope, sequencing, tradeoffs, or roadmap control.

## Read first

- `references/scope-matrix.md`

## Read as needed

- `references/change-policy.md`
  Read when a request changes docs, milestones, or cross-team contracts.

## Source docs

Open these only if the reference files are not enough:

- `../../single-dev-mvp/EmoBot_单人开发版_MVP方案文档.md`
- `../../single-dev-mvp/01_范围冻结与需求清单_PRD.md`
- `../../single-dev-mvp/10_开发任务拆分与里程碑_Sprint.md`

## Workflow

1. Classify the request as `P0`, `P1`, or `not-now`.
2. Map it to an existing module before proposing anything new.
3. Prefer protecting core identity modules over adding side features.
4. If scope changes, update docs in the order defined in `references/change-policy.md`.
5. If schedule is at risk, cut polish before cutting core identity.
