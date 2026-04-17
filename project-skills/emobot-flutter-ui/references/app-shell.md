# App Shell

Use this file for route structure, tabs, and feature ownership.

## Main tabs

- `home`
- `today`
- `me`

## Home modules

- Treehole entry
- Mood Weather entry
- Blind Box Lite entry
- My momo entry

## Suggested feature structure

```text
lib/
  app/
  core/
  features/
    home/
    mood_weather/
    treehole/
    modes/
    blind_box/
    growth/
    records/
    settings/
```

## Shared UI building blocks

- page scaffold
- soft card
- momo hero
- calm CTA button
- mood chip
- state panel for loading, empty, and error

## Placement rules

- Keep route names stable and snake_case.
- Keep scene-specific widgets inside their feature module.
- Put reusable visual primitives in `core/` only after a second real use case.
