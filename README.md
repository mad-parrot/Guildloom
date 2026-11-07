# Guildloom
AI slop - vibecoded

**Weaves your guild together.** Guildloom is a modern guild window for **World of Warcraft: Forever**. It shows ranks, professions and recipe search, and adds shared crafting requests, officer activity tools and alt linking, all in one window.

![Game: WoW Forever](https://img.shields.io/badge/WoW-Forever-4fc3f7)
![Interface 16001](https://img.shields.io/badge/interface-16001-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

> Open it with the **minimap button** (the guild tabard icon) or type `/loom`.

<!-- Screenshots: add images to a "screenshots" folder and link them here, e.g.
![Ranks tab](screenshots/ranks.png)
-->

---

## Features

| Tab | What it does |
|---|---|
| **Overview** | Member count, online now, average level, number at max level, a class breakdown and a summary of professions. |
| **Ranks** | Members grouped by rank, with **▲ promote** and **▼ demote** buttons. They only work if your rank has the permission. The Guild Master also gets **✕ remove**, which asks to confirm. |
| **Professions** | Members grouped by profession, with skill bars. **Type 3+ letters to search everyone's recipes.** |
| **Requests** | Shared crafting requests. Post what you need (or link an item) and see who can craft it. Crafters **claim** it, then mark it **done**. |
| **Activity** | Officer tool: members inactive for **7–180+ days**, grouped by rank, with the same rank buttons. Alts of active players can be skipped. |
| **Alts** | Main and alt grouping, detected from notes (`alt of Mad Parrot`, `Mad Parrot's alt`, `main: Mad Parrot`, ...) or linked by hand. |

**Also included:**
- 🔔 **Notices window**: a separate, movable window for request alerts, with sounds and clickable item links. It works with any chat addon, including Chattynator.
- 🔊 **Choose your alert sound** in Settings, from 9 game sounds or any SharedMedia sound pack you have installed.
- 🔴 **Minimap badge** showing the number of open requests *you* can craft.
- 🎨 **8 skins** (Blizzard (default) in the game's own frame style, Midnight, Classic Gold, Rustic Stone, Horde, Alliance, Emerald Dream, Void), plus window scale and opacity settings.
- 🔍 Search across names, notes, zone, class, rank and profession, plus an "Online only" filter.

## Installation

1. Download the latest `Guildloom-x.y.z.zip` from the [**Releases**](../../releases) page.
2. Extract it into your Forever addons folder, so that you get:
   `World of Warcraft\_forever_\Interface\AddOns\Guildloom\Guildloom.toc`
   (The game-version folder may be named differently on your install.)
3. **Restart the game.** A `/reload` doesn't pick up newly added addons.

> **Don't** use GitHub's green *Code → Download ZIP* button. It creates a folder named `Guildloom-main`, which the game won't load. Use the Releases zip, or rename the folder to `Guildloom`.


## Commands

| Command | What it does |
|---|---|
| `/loom` | Open or close Guildloom (`/gp` and `/guildloom` work too) |
| `/loom settings` | Settings and skins (also in *Options → AddOns → Guildloom*) |
| `/loom notices` | Show or hide the notices window |
| `/loom sync` | Ask guildmates to share professions and recipes |
| `/loom testalert` | Send a test alert to the notices window |
| `/loom minimap` | Show or hide the minimap button |
| `/loom reset` | Reset the window and minimap button positions |
| `/loom debug` | Print the game's raw guild profession data |

**Minimap button:** left-click opens or closes Guildloom, shift-click opens the notices window, right-click syncs, and you can drag it to move it.

## How data is shared

Guildloom talks to other Guildloom users over a hidden **guild addon channel**. It uses no external servers or websites. Messages are small and throttled.

- **Professions** come from the game's own guild profession list, which names online members (Guildloom remembers them over time), and from Guildloom users.
- **Recipes** are recorded when you **open one of your profession windows**. After that, only a short fingerprint is broadcast, and the full list is sent only when a guildmate's copy is missing or out of date.
- **Requests** are shared live. Logging in asks guildmates for the requests that are still open.
- **Manual alt links** and your settings stay on your computer.

Requests and recipes only reach guildmates who also have Guildloom installed.

## Development

```
Guildloom/
├─ Guildloom.toc      addon manifest (load order, saved variables)
├─ Core.lua           roster scan, profession data, guild sync, events
├─ Recipes.lua        own-recipe collection, recipe sync & search
├─ Requests.lua       crafting requests + notices
├─ Alts.lua           alt detection and manual links
├─ UI.lua             all windows, tabs, skins, settings, minimap button
├─ .pkgmeta           packaging config (BigWigs packager)
└─ .github/workflows/release.yml
```

### Making a release
1. Update `## Version:` in `Guildloom.toc` and add an entry to `CHANGELOG.md`.
2. Commit, then create and push a tag:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
3. GitHub Actions builds `Guildloom-v1.1.0.zip` with the [BigWigs packager](https://github.com/BigWigsMods/packager) and attaches it to a new release.

*Optional:* to publish to CurseForge or Wago too, add `## X-Curse-Project-ID:` / `## X-Wago-ID:` to the `.toc` file, and add `CF_API_KEY` / `WAGO_API_TOKEN` under **Settings → Secrets and variables → Actions** in the repository.

### Reporting bugs
Turn on Lua errors with `/console scriptErrors 1`, then open an issue with the error text and what you were doing.

## License

[MIT](LICENSE)
