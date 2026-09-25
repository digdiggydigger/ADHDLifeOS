# next-step-field — `F-E2-NextStepField`

**Environment:** iPhone 17 Pro simulator on **iOS 27.0** (E's OS), Firebase emulator (started with
`--import scripts/audit/emulator-state`), a throwaway `uitest-e2nextstep-*@example.test` account made
per run, 2026-09-25, after a CLEAN build. Frames are `NextStepFieldRenderUITests.testRenderTheNextStepRow`'s
own screenshots, one run per appearance, each on a freshly ERASED simulator. **Light and dark PASSED.**

## What these frames settle that no test could

E's round 5a: *"Next step → 'A "Next step" field.' One optional line on a task, editable from the
card and from task detail."* The card half is `F-E3`'s. Unit tests pin the `next_step` key, the
delete-on-clear and the Save diff; the frames show the row where it sits and the line surviving a
real round trip.

1. **The empty row, beside Notes**, reads "Next Step" over the placeholder "What to do first". The
   harness asserts Save is DISABLED on the untouched task, so opening a task never reads as an edit.
2. **Typed, Save enables.**
3. **Saved, left and reopened, the line came back from the document** ("Put my trainers by the
   door"), not from the screen, and it still reads as the next step because the caption stays.

**Why the caption exists — frame 03 of the first run, now replaced.** The row first shipped with its
name only as a placeholder, and once saved the line stood alone in the form, indistinguishable from a
note. `text-fields.md › Best practices`: *"Because placeholder text disappears when people start
typing, it can also be useful to include a separate label describing the field to remind people of
its purpose."* The caption is hidden from VoiceOver; the field itself is labelled "Next Step", so it
is heard once.

**Accessibility XL — measured, not framed.** The AX run reached the row and measured the field at
**338 × 48pt** (22pt at the default size): it grows with the text rather than clipping. The run then
failed at the typing step on a harness hittability problem, and its result bundle was cut short by
the watchdog, so no AX frame survived. Not re-run a fourth time; the AX look is on E's arc-close pass.

**Measured:** the text field is 338 × 22pt inside its Form row, the same shape as Notes beside it.
The row around it is taller; the frames do not show whether a tap on the row's padding focuses the
field, and that was not measured.

## Throwaway data

Each run made one emulator account and saved one next step on its seeded "Take a 10-minute walk". The
local emulator discards both on restart; nothing was written to the live project. The simulator was
ERASED after the runs.

## Files

| file | proves |
|---|---|
| `01-empty-row-{light,dark}.jpg` | The row beside Notes: caption "Next Step", placeholder "What to do first"; Save disabled |
| `02-typed-{light,dark}.jpg` | A typed line enables Save |
| `03-reopened-{light,dark}.jpg` | After Save and a fresh fetch, the line is back and still named |
