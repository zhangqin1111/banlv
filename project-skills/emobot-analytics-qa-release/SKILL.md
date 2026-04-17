---
name: emobot-analytics-qa-release
description: Use when adding instrumentation, defining success metrics, writing or executing QA checks, preparing closed beta releases, or deciding if an EmoBot build is ready to ship. This skill applies the project's funnel, safety blockers, and release gates.
---

# EmoBot Analytics, QA, and Release

Use this skill for instrumentation, testing, beta operations, and release readiness.

## Read first

- `references/event-map.md`

## Read as needed

- `references/qa-gates.md`
  Read when writing test cases, regressions, or ship-blocking checks.
- `references/release-playbook.md`
  Read when preparing builds, invite-only beta, or rollout decisions.

## Source docs

- `../../single-dev-mvp/07_埋点指标与实验设计_Analytics.md`
- `../../single-dev-mvp/08_QA测试用例与验收清单_QA.md`
- `../../single-dev-mvp/09_发布运维与封测手册_Release.md`
- `../../single-dev-mvp/10_开发任务拆分与里程碑_Sprint.md`

## Workflow

1. Track the funnel before adding vanity metrics.
2. Treat safety, delete, report, privacy, and age notice as ship blockers.
3. Test the three mode scenes separately.
4. Release to one platform and one closed cohort first.
5. Expand in rounds based on retention, helpfulness, and safety quality.
