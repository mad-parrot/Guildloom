# Changelog

## v1.3.0
### Added
- **Blizzard skin**: uses the game's own frame art, so Guildloom looks like the built-in windows (for example Guild & Communities): a metal frame with a round guild portrait, the red close button, red game buttons, game input boxes, inset panels, gold titles and shadowed Friz Quadrata text. The notices window and the popups use it too. **It's now the default skin** for new installs; if you already picked a skin, Guildloom keeps your choice.
- **Rustic Stone skin**: a classic Blizzard look, with a gold-trimmed dialog border, a tiled stone background, translucent content panels and gold window titles. It applies to the main window and the notices window.

## v1.2.0
### Added
- **Alert sound picker** in Settings: choose from Whisper, Ready check, Raid warning, Battle.net toast, Group invite, Map ping, Alarm clock, Coins or Auction house. Each sound plays when you pick it, and there's a Test button.
- **SharedMedia sounds**: if you have SharedMedia sound packs installed, their sounds appear in the same list.

## v1.1.1
### Fixed
- Alt detection from notes now works for character names with spaces, e.g. `alt of Mad Parrot` or `Mad Parrot's alt`. Before, only the first word ("Mad") was checked, so these alts were never linked.

## v1.1.0
First public release under the name **Guildloom** (previously "GuildPlus").

### Added
- **Requests**: shared crafting requests. Post a request (type it or link an item), pick a profession from a drop-down, see who can craft it, then claim it and mark it done.
- **Notices window**: a separate, movable window for request alerts that works with any chat addon (Blizzard chat, Chattynator, ...). Alerts play a sound, and the window keeps its history between sessions.
- **Recipe search**: type 3+ letters on the Professions tab to find guildmates who know a recipe. Recipe lists sync between Guildloom users.
- **Activity**: an officer tool listing members inactive for 7–180+ days, with promote, demote and remove buttons. Alts of active players can be skipped.
- **Alts**: alt linking, detected from notes ("alt of X", "X's alt", ...) or set by hand.
- **Skins**: Midnight, Classic Gold, Horde, Alliance, Emerald Dream and Void, plus window scale and opacity settings.
- **Minimap button** with a badge counting open requests you can craft.

### Changed
- Renamed from GuildPlus to Guildloom: new folder, saved data (imported from GuildPlus if present), sync channel and `/loom` command. `/gp` still works.
- Names are shown without Forever's internal realm suffix. Whisper, invite, promote, demote and remove use the character name.

## v1.0.0
- First version: an Overview tab, members grouped by rank with promote, demote and remove, and guild professions from the game's guild profession list and from addon sync.
