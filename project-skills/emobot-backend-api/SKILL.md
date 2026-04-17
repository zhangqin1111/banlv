---
name: emobot-backend-api
description: Use when implementing or changing EmoBot FastAPI endpoints, PostgreSQL schemas, SSE chat streaming, growth rules, blind box data, or module persistence. This skill enforces the single-service backend architecture and the project's API contracts.
---

# EmoBot Backend API

Use this skill for backend, schema, API, and persistence work.

## Read first

- `references/api-contracts.md`

## Read as needed

- `references/data-model.md`
  Read when adding or changing tables, enums, or persistence rules.
- `references/service-rules.md`
  Read when touching streaming chat, logging, safety boundaries, or business logic.

## Source docs

- `../../single-dev-mvp/01_范围冻结与需求清单_PRD.md`
- `../../single-dev-mvp/05_Backend_API与数据模型_Backend.md`
- `../../single-dev-mvp/06_AI对话_Prompt与安全策略_AI.md`

## Workflow

1. Start from the existing contract and keep a single FastAPI service.
2. Update schema before routes.
3. Keep PostgreSQL as the only database.
4. Use SSE for Treehole streaming, not a heavier realtime stack.
5. Re-check analytics and QA impact after API changes.
