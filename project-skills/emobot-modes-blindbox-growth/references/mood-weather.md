# Mood Weather

Use this file for the check-in flow and result logic.

## Input shape

- mood type
- intensity
- one short freeform line

## Output shape

- saved check-in
- short empathy line
- two or three invitations:
  - continue to Treehole
  - try a recommended mode scene
  - open Blind Box Lite when appropriate

## Core rule

Mood Weather should classify and guide, but never force.

## Mapping hints

- higher joy -> `joy_mode`
- heavier sadness or fatigue -> `low_mode`
- anger or agitation -> `anger_mode`

These are recommendations, not automatic jumps.
