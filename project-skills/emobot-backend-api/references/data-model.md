# Data Model

Use this file when editing persistence.

## Core tables

- `devices`
- `mood_entries`
- `treehole_sessions`
- `treehole_messages`
- `mode_sessions`
- `blind_box_draws`
- `growth_ledgers`
- `report_events`
- `safety_events`

## Important enums

- mood: `joy`, `calm`, `sad`, `angry`, `anxious`, `tired`
- mode: `joy_mode`, `low_mode`, `anger_mode`
- blind_box_card_type: `comfort`, `action`, `reframe`
- growth_stage: `seed`, `bloom`, `glow`

## Persistence rules

- Keep long freeform text out of ordinary analytics logs.
- Store enough structured fields to rebuild history and growth.
- Safety events should be queryable separately from normal sessions.
- Growth awards must be deterministic and derived from product actions, not model text.
