# EmoBot Workspace

This workspace now contains a working EmoBot original-demand-compatible MVP build with Flutter + FastAPI.

## Structure

```text
mobile/
  Flutter source scaffold
backend/
  FastAPI source scaffold
project-skills/
  Project-private Codex skills
single-dev-mvp/
  Product and implementation docs
```

## Mobile

`mobile/` contains a runnable Flutter app with:

- app router
- soft theme tokens
- 3-tab shell
- Home
- Mood Weather
- Treehole
- Joy / Low / Anger mode pages
- Blind Box Lite
- My momo growth page
- Records
- Privacy / Report / Safety pages

Run helpers:

- `mobile\flutterw.ps1` uses the local Flutter SDK at `D:\flutter-sdk`.
- `mobile\run_web_preview.ps1` serves the built web output and opens Chrome.

Typical commands:

```powershell
cd mobile
.\flutterw.ps1 pub get
.\flutterw.ps1 analyze
.\flutterw.ps1 test
.\flutterw.ps1 build web
.\run_web_preview.ps1
```

Docker launch:

```powershell
docker compose up -d --build
```

Web preview in Docker:

- `http://localhost:18081`
- API health: `http://localhost:8000/health`

## Backend

`backend/` contains a FastAPI single-service scaffold with:

- config and env loading
- SQLAlchemy base and session
- models, schemas, services
- `/v1` route modules for auth, home, mood weather, treehole, modes, blind box, growth, records, reports, and settings
- Qwen-compatible env placeholders

### Env setup

Copy `backend/.env.example` to `.env` and fill in your real values.

Do not commit or paste real secrets into source files.

Recommended env vars:

- `DATABASE_URL`
- `QWEN_API_KEY`
- `QWEN_BASE_URL`
- `QWEN_MODEL`

### Run backend

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Run backend tests

```powershell
cd backend
python -m unittest tests.test_treehole_flow
```

## Current status

- Flutter `analyze` passes
- Flutter `test` passes
- Flutter `build web` passes
- Backend integration tests pass
- Core modules are wired:
  - guest bootstrap
  - home summary
  - mood weather
  - treehole SSE
  - three mode scenes
  - blind box draw/save
  - momo growth
  - records timeline
  - report / delete / safety flows

## Suggested next build order

1. Add Alembic migrations and switch to a persistent PostgreSQL instance.
2. Add richer module-specific tests for blind box, records, and settings flows.
3. Polish more scene animation and responsive layout details.
4. Prepare a closed-beta deployment target for backend and web/mobile distribution.
