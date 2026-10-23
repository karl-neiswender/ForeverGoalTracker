# Git and cross-machine work

Load for synchronization, machine switches or Git setup. Read-only requests never
trigger synchronization. Editing does not imply permission to commit or push each
small change; do that on explicit request or an agreed session closeout.

## Locations and safety

- PC live checkout: `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker`.
- Mac checkout: `/Users/karlneiswender/Projects/ForeverGoalTracker`, symlinked into
  `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/ForeverGoalTracker`.
- SavedVariables: `_classic_beta_/WTF/Account/<account>/SavedVariables/ForeverGoalTracker.lua`;
  PC account is `52647669#1`. Progress stays local. Leave the old
  `KarlClassicGoals.lua` backup and separate old Era installation alone unless
  specifically authorized. A historical replacement request is not standing approval.
- PC Classic Era: a plain copy, refreshed one way by `sh tools/sync-era.sh` (then `/reload`).
  **Never link it** (junction or symlink): the CurseForge app recognises the addon by its TOC
  `X-Curse-Project-ID` and updates it by deleting the folder's contents. On 2026-10-23 that
  deleted this checkout's Media and Fonts through a junction (all restored from Git). The script
  refuses to run if the Era folder is a link. Forever beta closed that day; Era is the only
  testable client until live Forever opens. Era saves (account `KDN`) and the old 2.15.1 copy are
  backed up in `_classic_era_/ForeverGoalTracker-backups/2026-10-23`; beta saves in
  `_classic_beta_/ForeverGoalTracker-backups/2026-10-23`.
- On live launch, relocation of the addon and saves on both machines is a separate
  planned operation. Do not move files automatically based on a date.

## Session operations

1. Check status once when beginning an editing session. Reuse that knowledge until
   concurrent work, an integration, or the final diff review makes rechecking useful.
2. Pull `main` when freshness matters and it is safe. Prefer fast-forward-only.
   Ask before pulling a dirty tree; never stash/reset/discard unrelated work merely
   to permit a pull. An explicitly local documentation audit need not fetch/pull.
3. Preserve narrow edits, encoding and line endings. Stage intended paths/hunks
   with normal context; avoid context-free patches. Do not commit another agent's
   or user's work without authorization. Do not use blanket `git add .` blindly.
4. On requested/agreed editing closeout or machine switch, review changes and sync
   to shared `main`. Do not create a release tag. If committing is prohibited,
   leave work intact and report it is local and unsynced.
5. Once per relevant closeout, inventory `Media/artwork`, including ignored files.
   Include added/updated originals in the sync, even pending banner approval.
   Resolve ignore rules preventing source sync; never silently include deletions.
   Reuse the inventory through commit/push unless assets change. This is not a
   visual re-review of every unchanged asset. Do not do it for read-only work or
   each small edit; a deferred documentation handback is not a sync closeout.
6. Verify intended artwork additions are in the commit and the remote contains
   that commit before claiming synchronization. Do not repeatedly poll unchanged
   remote state. The other machine can then pull; remind Karl to `/reload` as needed.

Git for Windows is at `C:/Program Files/Git/cmd/git.exe` if PATH fails. Do not add
`safe.directory=*` by default; if Git actually reports ownership trouble, resolve
trust narrowly for the intended checkout. On Mac use available Git. Commit identity:
`karl-neiswender <97697208+karl-neiswender@users.noreply.github.com>`.
Authentication setup is needed only if an authorized network operation fails.
