# Backup file format

Elimine exports all of its data to one JSON file and imports such files back (Settings → Export / Import). The format is public: to move history from another tracker, write a converter that produces this file and import it. This document describes version 1.

## Example

```json
{
  "format": "elimine-backup",
  "version": 1,
  "exportedAt": "2026-10-04T14:05:00+10:00",
  "substances": [
    {
      "id": "01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a11",
      "name": "Coffee",
      "unit": "mg",
      "color": "orange",
      "icon": "coffee",
      "archived": false,
      "doses": [100, 200],
      "intakes": [
        {
          "id": "01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a12",
          "takenAt": "2026-10-04T08:15:00+10:00",
          "amount": 100
        },
        {
          "id": "01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a13",
          "takenAt": "2026-09-28T21:35:00+03:00",
          "amount": null
        }
      ]
    },
    {
      "id": "01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a14",
      "name": "Melatonin",
      "intakes": [
        { "id": "01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a15", "takenAt": "2026-09-30T23:00:00Z" }
      ]
    }
  ]
}
```

## Document

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `format` | string | yes | Always `elimine-backup`. |
| `version` | integer | yes | Format version, `1`. An app rejects files newer than it knows and reads all older ones. |
| `exportedAt` | time | no | When the file was written; informational. |
| `substances` | list | yes | Substances in the order they appear on the home screen. |

## Substance

| Field | Type | Required | Default | Meaning |
| --- | --- | --- | --- | --- |
| `id` | UUID | yes | | Identity used to match records on import. |
| `name` | string | yes | | Shown as entered; surrounding spaces are trimmed. |
| `unit` | string | no | `""` | Free text such as `mg`; empty means no unit. Units are never converted. |
| `color` | string | no | first unused color | One of `blue`, `orange`, `aqua`, `yellow`, `magenta`, `green`, `violet`, `red`. Unknown names get the default. |
| `icon` | string | no | `pill` | One of `pill`, `syringe`, `drop`, `powder`, `leaf`, `smoke`, `air`, `coffee`, `drink`, `sun`, `moon`, `bolt`, `mind`, `heart`, `science`, `spa`, `star`, `circle`. Unknown names get the default. |
| `archived` | boolean | no | `false` | Archived substances are hidden from the home screen but keep their history. |
| `doses` | list of numbers | no | `[]` | Frequent doses offered as one-tap choices; positive numbers. |
| `intakes` | list | no | `[]` | Intakes of this substance, in any order. |

## Intake

| Field | Type | Required | Default | Meaning |
| --- | --- | --- | --- | --- |
| `id` | UUID | yes | | Identity used to match records on import. |
| `takenAt` | time | yes | | When it happened, with the UTC offset in effect at that moment. |
| `amount` | number or null | no | `null` | The dose in the substance's unit; `null` when unknown. |

## Values

- **UUID**: any UUID in the usual 8-4-4-4-12 hex form; case does not matter. Elimine writes UUIDv7. A converter must produce the same id for the same record every time it runs, so that importing its output twice adds nothing; derive ids deterministically (for example UUIDv5 from the source record's id) rather than generating random ones.
- **Time**: ISO 8601 `YYYY-MM-DDTHH:MM[:SS[.fraction]]` followed by `Z` or `±HH:MM`. The offset is required: together with the local time it fixes the calendar day the intake counts on, wherever the phone is later. Fractions of a second are ignored.
- **Numbers**: positive and finite; `250` and `250.0` are the same.

## Import rules

1. The whole file is validated before anything is written. The first problem rejects the file with its location, e.g. `substances[0].intakes[11].takenAt: is in the future`. Rejected: a wrong `format`, a newer `version`, a missing or malformed `id`, `name` or `takenAt`, a non-positive dose or amount, a time in the future, and an id used twice in the file.
2. Records are matched by `id`. A substance or intake whose id already exists in the app is left unchanged; everything else is added. Intakes of an existing substance are added to it.
3. New substances go after the existing ones, in file order.
4. Before writing, the app shows how many substances and intakes will be added and how many are already present. Nothing is written until the user confirms, and everything is written in one step.

Importing the same file twice therefore adds nothing, and importing an old backup can bring back substances deleted since it was made; the preview shows them before confirming.

## What is not in the file

Intakes deleted with a swipe, when records were created or changed, and when a substance was archived. The file is plain text: keep it somewhere private.
