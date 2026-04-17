# API Contracts

Use this file as the default contract map.

## Core endpoints

- `POST /v1/devices/register`
- `GET /v1/home`
- `POST /v1/mood-weather/checkin`
- `POST /v1/treehole/sessions`
- `GET /v1/treehole/sessions/{session_id}/stream`
- `POST /v1/modes/sessions`
- `POST /v1/blind-box/draw`
- `GET /v1/growth`
- `GET /v1/records`
- `POST /v1/report`
- `DELETE /v1/me/data`

## Contract rules

- Keep request and response keys stable once a screen depends on them.
- Home should return enough data to render the hero summary and the four module cards.
- Mood Weather should return:
  - saved mood payload
  - short empathy line
  - invitation options
- Treehole stream should send chunked text and a final structured summary event.
- Mode session responses should carry mode id, completion state, and awarded growth points.
- Blind Box draw should return card id, card type, title, body, and optional action line.

## Naming rules

- Use snake_case in payload keys.
- Use stable enum values for mood and mode ids.
