# Goal data, progress and research

Load when changing goals, rules, migration, roster snapshots or data sources.

## Persistent semantics

- Preserve stable goal IDs, section/part ordering and step indices. Append
  Forever-only group parts at the end. Structural edits require a one-time remap
  of existing saved ticks/selected parts and dependency indices. Handle sparse or
  partially migrated saves. Wording alone requires no migration.
- `ApplyAutoRules` only ticks; it never unticks, since items can be consumed.
  `RuleMet` supports alternative conditions and roster-wide progress with explicit
  race/faction scopes. Do not silently change these semantics to character-local.
- `completeWith` can finish a goal from reward ownership. Piece totals use
  `FGT.PieceProgress`: materials OR a piece checkbox, never both. Retain completion
  dates, reset undo, celebration suppression during appropriate restoration and
  existing migration order.
- SavedVariables arrive at `ADDON_LOADED`. Guard load-time reads. Bank counts are
  snapshots from when the bank was open; do not imply they are live on other alts.
- Unknown reputations can report Neutral/0: consult `KnownFactions()` before
  trusting faction values. Ownership does not prove per-character riding access.
- Dependencies represent shared-roster prerequisites, not recommended raid order
  or proof of current-character eligibility. False quest API results do not prove
  a prerequisite. The separate Forever graph starts empty; add only verified edges.
  `/goals testlocks` is a session preview, not confirmation of Forever rules.

## Wording and classification

Keep rules, IDs, step order, exact quest names, item/goal tags and material-parsing
strings intact during copy edits. Steps are checkable actions; practical advice,
drop chances, prerequisites, exceptions, costs and restrictions belong in tips
where appropriate. `FGT.StepText` removes closing periods at display time; do not
strip data punctuation by hand. Every item named in tips should have its item tag.
Link only existing goals; preserve faction aliases and longer-name-first linking.

Use `Unconfirmed` and `Source unknown` honestly. Preserve nil/listed/confirmed/new/
updated Forever distinctions: a database listing is not proof of unchanged steps.
Era treats updated Classic content appropriately and hides Forever-only content.
Use current `FGT.CatalogGoalCount()` and client filters, not historical totals.

Preserved data lessons: Atiesh, Thunderfury and Sulfuras are Legendary;
Benediction, Corrupted Ashbringer, Rhok'delar, Lok'delar and Quel'Serrar are Epic.
Lok'delar is Hunter-only. Rank 11 is Commander (Alliance) or Lieutenant General
(Horde). Verify changed factual claims rather than extrapolating from these examples.

## Research

Use verified native client data and recorded evidence; do not invent quest IDs,
sources, icons or Forever mechanics from memory. Classic and Forever databases
are distinct. The active [data audit workflow](../audit/README.md) prohibits
automated Wowhead access pending permission; archived batching/scraping advice
is retired. A requested data audit may use `/goals audit` and its report tooling.
It is not a login, session-start or unrelated-task requirement. Never clear audit
SavedVariables or other player data without authorization.

For detailed existing behavior, inspect the affected module: Data/Library for
goals, ArmorSets/AQArmor for set recipes, Npcs/Quests for links, Filters for views,
Dependencies for prerequisite edges, Core for roster/rules. Old research ledgers
and dated handoffs are evidence only, loaded for the specific feature in question.
