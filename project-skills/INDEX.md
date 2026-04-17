# EmoBot Project Skills

This folder contains the project-private skills for the EmoBot original-demand-compatible MVP.

## Skill list

1. `emobot-master-planner`
   Use for scope decisions, priority cuts, milestone changes, and doc-update ordering.
2. `emobot-flutter-ui`
   Use for Flutter screens, routes, widgets, animation behavior, and UI implementation.
3. `emobot-backend-api`
   Use for FastAPI, PostgreSQL, SSE chat, schemas, and API contracts.
4. `emobot-ai-safety`
   Use for prompts, reply behavior, safety blocking, and high-risk handling.
5. `emobot-modes-blindbox-growth`
   Use for Mood Weather, the three emotional scenes, Blind Box Lite, and growth rules.
6. `emobot-momo-visuals`
   Use for momo character art, scene art, image prompts, and visual consistency.
7. `emobot-analytics-qa-release`
   Use for instrumentation, QA, beta readiness, and release gates.

## Reference structure

Each skill now uses a `references/` folder.

- `SKILL.md` holds the workflow and selection logic.
- `references/*.md` holds the detailed implementation facts.
- `single-dev-mvp/` remains the source-of-truth doc pack for full product context.

This keeps the skill body small and lets Codex load only the detail it needs.

## Install into Codex

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\project-skills\install-to-codex.ps1
```

The script copies every skill directory, including `references/`, into `$CODEX_HOME/skills`.
