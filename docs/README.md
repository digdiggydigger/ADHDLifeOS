# `docs/` is an ARCHIVE. Nothing here is a live reference.

**E's call, 2026-09-06: "The seven files in docs/ are from a legacy build of this application."**
All seven moved to `docs/archive/` on that word. They were last edited **2026-08-17** and describe
the **Supabase** and **AWS/Cognito** backends that were deleted in `5244650` when E cut everything
over to Firebase.

The numbers are the fastest way to see it — across those seven files:

| term | mentions |
|---|---|
| AWS | 105 |
| Supabase | 70 |
| Cognito | 64 |
| DynamoDB | 29 |
| **Firebase** | **0** |
| **Firestore** | **0** |

`ARCHITECTURE.md` opens by calling this app "a second client on the Es_Life_OS Supabase backend",
with "no local persistence layer — Supabase is the source of truth". Both statements were true when
written and are now the opposite of the truth.

## Where the live architecture lives

**`CLAUDE.md`'s "Architecture notes" section**, which is maintained and corrected as things change.
The start-of-session checklist used to send every fresh session here for context; that was a trap of
the same family as a stale session opener, and it was fixed in the same commit that created this
file.

## Why they were kept rather than deleted

They are the record of **why** parts of this app are shaped as they are — the same reason
`TODO-ARCHIVE.md` keeps 8,000 lines of shipped and superseded blocks from the same era. Read them
for history. Never read them for how the app works today.
