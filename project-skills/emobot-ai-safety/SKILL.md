---
name: emobot-ai-safety
description: Use when working on EmoBot treehole prompts, emotional reply style, safety blocking, mode recommendations, blind-box copy behavior, or high-risk handling. This skill keeps the AI warm, brief, non-medical, and safe.
---

# EmoBot AI Safety

Use this skill for prompts, reply behavior, safety rules, and AI writing style.

## Read first

- `references/prompt-contract.md`

## Read as needed

- `references/safety-flows.md`
  Read when changing blocking rules, crisis behavior, or reporting flow.
- `references/copy-style.md`
  Read when changing empathy lines, mode invitations, or blind-box text.

## Source docs

- `../../single-dev-mvp/06_AI对话_Prompt与安全策略_AI.md`
- `../../single-dev-mvp/01_范围冻结与需求清单_PRD.md`
- `../../single-dev-mvp/02_信息架构与用户流程_UX.md`

## Workflow

1. Keep the assistant warm, brief, and non-diagnostic.
2. Prefer invitation over instruction.
3. Stop normal chat immediately on high-risk content.
4. Re-check every wording change against the blocked-behavior list.
5. Treat Blind Box Lite as template-first, not freeform AI content.
