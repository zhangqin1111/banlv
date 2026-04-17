---
name: emobot-flutter-ui
description: Use when implementing or modifying EmoBot Flutter screens, routes, components, animations, layout, or UI behavior. This skill applies the project's UX flow, design tokens, momo motion rules, and the original-demand-compatible MVP module structure.
---

# EmoBot Flutter UI

Use this skill for Flutter UI, screen flow, widgets, animation, and page behavior.

## Read first

- `references/app-shell.md`

## Read as needed

- `references/screen-specs.md`
  Read when building or changing a page, route, or feature module.
- `references/motion-style.md`
  Read when working on animation, scene mood, or visual polish.

## Source docs

- `../../single-dev-mvp/02_信息架构与用户流程_UX.md`
- `../../single-dev-mvp/03_UI视觉与角色动效规范_UI.md`
- `../../single-dev-mvp/04_Flutter前端实现规范_Frontend.md`

## Workflow

1. Place the work inside the existing route and feature tree first.
2. Reuse shared widgets before making new ones.
3. Keep Home centered on Treehole, Mood Weather, Blind Box Lite, and My momo.
4. Keep momo as the emotional anchor on every major screen.
5. Add loading, empty, error, and analytics hooks for every new page.
