# Service Rules

Use this file for backend behavior details.

## Architecture boundaries

- One FastAPI service
- One PostgreSQL database
- SSE for streaming chat
- No vector DB, queue system, or extra service by default

## Treehole rules

- Keep a short rolling context plus summary, not open-ended memory.
- Safety check should run before normal generation.
- Persist assistant summaries, not every internal control artifact.

## Logging rules

- Redact or truncate highly sensitive long text in operational logs.
- Log safety triggers separately.
- Keep analytics events product-oriented, not raw transcript dumps.

## Growth rules

- Award fixed points for completed check-in, completed mode scene, blind-box draw, and meaningful Treehole completion.
- Keep the point table in code or config, not in model output.
