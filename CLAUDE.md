# Captain of Industry Mod — ResearchQueue

## Project Overview

This is a C# mod for the game **Captain of Industry** (COI), developed using the official Mafi modding framework. The mod's goal is to give players a new UI element where they can reorder their research queue.

The maintainer developing the mod and prompting is a not a programmer by trade. Code should be explained clearly and kept as simple as possible.

## Mod Identity

- **Author:** Jagg111
- **Mod ID:** `ResearchQueue`
- **GitHub repo:** `Jagg111/COI-ResearchQueue`
- **Game:** Captain of Industry
- **Framework:** Mafi (.NET 4.8)
- **Mod type:** `IMod`

## Distribution

- **Exclusive:** [COI Mod Hub](https://hub.coigame.com/Mod/17) — the only distribution channel. Players download and install updates manually from there. The Hub does NOT auto-update.
- **Hub forum:** Each mod gets its own forum board on the Hub. Bug reports go to [/Forum/Mods/ResearchQueue/bugs](https://hub.coigame.com/Forum/Mods/ResearchQueue/bugs); ideas/feedback go to [/Forum/Mods/ResearchQueue/ideas](https://hub.coigame.com/Forum/Mods/ResearchQueue/ideas).
- **GitHub repo:** source code only. Not a player-facing channel — do not direct players there.
- **License (mod's own code):** MIT (see `LICENSE`).
- **License (game-code excerpts):** Per the [COI Modding Policy](https://www.captain-of-industry.com/modding-policy), short excerpts of game code (type names, method signatures, small samples — e.g. throughout `docs/MODDING-REFERENCE.md`) are © MaFi Games and used only under the modding policy. The MIT grant explicitly excludes them; both `LICENSE` and `docs/MODDING-REFERENCE.md` carry the required attribution notice.
- **Hub license picker:** The Hub's per-mod license setting (COI-Open / COI-Keep / MIT / etc.) is configured once in the Hub UI at first upload and persists across versions. Not edited per release or via configs or manifest.

## External Resources

- **Hub mod page:** https://hub.coigame.com/Mod/17
- **Modding policy:** https://www.captain-of-industry.com/modding-policy
- **Official modding repo for reference (local clone):** `C:\Code\Captain-of-industry-modding`

## Project Structure

```
ResearchQueue.sln          # Visual Studio solution
ResearchQueue.csproj       # Project file (build config, references, auto-deploy)
ResearchQueue.cs           # Main mod entry point
ResearchQueueWindowController.cs  # Queue panel injected into research tree (auto-registered via DI)
manifest.json                # Mod metadata (id, version, authors, dependencies, etc. — see Manifest Fields below)
changelog.txt                # Cumulative player-facing changelog; bundled in every release zip
bin/                         # Build output (gitignored)
obj/                         # Build intermediates (gitignored)
```

## Build & Deploy

### Environment Variables Required
- `COI_ROOT` — path to the Captain of Industry game install directory (e.g., Steam folder)

### Build
Open `ResearchQueue.sln` in Visual Studio and build, or run from the project root (`C:\Code\COI-research-queue`):
```
dotnet build ResearchQueue.sln
```
Note: always specify `ResearchQueue.sln` explicitly and run from the project root. Do not pass `/p:LangVersion=latest` — it breaks argument parsing with `dotnet build`.

On build, the mod is automatically deployed to `%APPDATA%\Captain of Industry\Mods\ResearchQueue\`.

### What gets deployed
- `ResearchQueue.dll` — compiled mod
- `manifest.json` — mod metadata
- `ResearchQueue.pdb` — debug symbols (Debug builds only)

## Manifest Fields

`manifest.json` fields — required and optional. Character limits are enforced by the Hub and **cannot be changed after a version is uploaded**.

**Required:**
- `id` — unique mod identifier, pattern `[a-zA-Z0-9][a-zA-Z0-9_-]*`, must not start with `COI-`
- `version` — format `major.minor[.patch[letter]]` (e.g. `1.0.1`, `0.8.2c`)
- `primary_dlls` — array of DLL filenames to load

**Optional (Hub-visible):**
- `display_name` — max 50 chars; shown as the mod title on the Hub
- `description_short` — max 180 chars; shown in Hub search results and mod listings
- `description_long` — full mod page description; supports `\n` for newlines
- `links` — array of URLs shown on the Hub mod page (e.g. GitHub repo)
- `authors` — author name or array of names
- `min_game_version` — minimum game version required
- `max_verified_game_version` — highest game version tested; update this after each game update check

**Optional (behavior flags):**
- `non_locking_dll_load` — if true, DLL loaded into memory rather than locked on disk (allows hot-reload during dev)
- `can_add_to_saved_game` — whether the mod can be added to an existing save
- `can_remove_from_saved_game` — whether the mod can be safely removed from a save
- `mod_dependencies` — array of mod IDs that must be loaded for this mod to work
- `optional_mod_dependencies` — array of mod IDs that integrate with this mod if present, but aren't required
- `incompatible_mods` — array of mod IDs that cannot be loaded alongside this mod
- `primary_mod_class_name` — explicit class name for the mod entry point (otherwise auto-detected)

## Hub Packaging Requirements

The COI Hub is strict about what it expects in the zip and what it can display. Key rules learned the hard way:

- **ZIP structure:** The zip must contain the mod folder as its root (e.g. `ResearchQueue/manifest.json`), so players can extract directly into their `Mods/` folder. Our script handles this automatically.
- **Files in zip:** `ResearchQueue.dll`, `manifest.json`, `changelog.txt`. Nothing else — the Hub renders install instructions and metadata, so no `readme.txt` is needed.
- **`changelog.txt` format** — plain text, cumulative, newest entry first:
  ```
  v1.0.1 | 2026-05-07
  * Bullet one
  * Bullet two

  v1.0.0 | 2026-05-07
  * Initial release
  ```
  The Hub parses this automatically — no manual pasting needed. Strip any markdown from bullets (plain text only).
- **Manifest field limits** — `display_name` max 50 chars, `description_short` max 180 chars. These **cannot be edited after a version is uploaded**, so verify before packaging.
- **Versions cannot be deleted or edited** once uploaded to the Hub. Always verify the zip contents before uploading.
- **Output zip:** `package-release.ps1` writes to `bin\pkg\ResearchQueue-v<version>.zip`
- **License:** Configured once in the Hub UI at first upload and persists across versions — not set in the zip and not edited per release. See the Distribution section above for the full license picture.
- **Distribution is manual:** The Hub does not auto-update players. Each new version must be downloaded and installed by the player.

## Release Workflow

The skill `/ship-it` will create a new release. It handles everything end-to-end: version bump, What's New drafting, `changelog.txt` update, packaging, and reminding the user to upload to the COI Mod Hub. See `.claude/skills/ship-it/SKILL.md` for details.

- `manifest.json` -- version is the source of truth for release tags and titles
- `changelog.txt` -- cumulative changelog updated each release; bundled inside the zip so the Hub parses it automatically
- `package-release.ps1` -- the underlying packaging script called by `/ship-it`; can also be run standalone

## Health Checks & Game Version Compatibility

The skill `/game-version-check` can be run after any Captain of Industry game update to check whether the mod will still work. The skill handles the full workflow end-to-end -- see `.claude/skills/game-version-check/SKILL.md` for details.

- `check-reflection-targets.ps1` — the underlying diagnostic script; checks all internal game references the mod depends on against the actual game DLLs. Can also be run standalone.
- `inspect_dll.ps1` — deeper inspection tool used when something breaks to see what changed in the game

## Modding Reference

For detailed game API docs, modding patterns, reflection examples, and UI patterns (all verified against Update 4 DLLs), see **docs/MODDING-REFERENCE.md**.

## Mod Goal & Player Experience

The mod adds a drag-and-drop research queue panel inside the existing research tree screen, letting players reorder queued research items and start/remove them.

Queue state lives in the game's own save data, manipulated directly via reflection — no separate mod-owned files. The mod works on existing saves and can be removed safely; the queue stays in whatever order it was last left in.

## Working Style Notes

- User is not a programmer — explain what code does in plain language when making changes
- **Version bumping:** See the Versioning section below for full details. If a session involves code changes, **proactively ask the user whether a version bump should be included before the session ends**. If the user confirms a bump, use `/ship-it` to run the full release workflow.
- The `COI_ROOT` env var must be set for builds to work
- Before writing any code, ask clarifying questions to gather enough context to attempt the task in one pass. Don't start writing until the intent is clear and there is little room for ambiguity or interpretation.
- **GitHub Issues:** Before starting any bug fix or feature work, check `gh issue list` for a related open issue. If one exists, remind the user so commit messages can include `Fixes #N` (or `Closes #N` / `Resolves #N`) — GitHub auto-closes the issue when the commit lands on `main`
- **Commit messages:** Single line describing what changed. No body text. For sessions related to github issues append `Fixes #N` for bug issues or `Closes #N` for enhancement issues.
- **Reflection safety:** All reflection access (`GetField`, `GetProperty`, `GetMethod`) must go through the `ReflectionProbe` helper in `ResearchQueueWindowController.cs`. This keeps the runtime health check and `check-reflection-targets.ps1` automatically in sync. After a game update, run `/game-version-check` to diagnose breakage.

## Versioning

This project uses **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

- **Patch (0.0.X)** — Bug fixes and small tweaks. **When in doubt, bump this one.** Examples: fixing items not showing up, correcting a visual glitch, small behavior fix.
- **Minor (0.X.0)** — New features a player would notice. Resets patch to 0. Examples: adding drag-and-drop, adding a new button or UI element, adding a new capability.
- **Major (X.0.0)** — Reserved for major milestones or breaking changes. Resets minor and patch to 0. Examples: mod reaching "complete" status (1.0.0), a game update forcing a major rewrite that changes how the mod works for the player.

**Rules:**
- Do NOT bump for docs-only, build script, or comment-only changes
- If unsure then remind the user about semantic versioning and ask what their preference is
- `manifest.json` version is always the source of truth

**End-of-session workflow:**
1. If code changes were made during the session, ask the user if a version bump is needed
2. If yes, run `/ship-it` — it handles version bump, What's New drafting, changelog update, packaging, and Hub upload reminder end-to-end

## Documentation Rules (IMPORTANT)

Whenever we discover something new about how the game works, its APIs, types, method signatures, or modding patterns — **always update the relevant docs without being asked**:

- **docs/MODDING-REFERENCE.md** — Game API discoveries, type signatures, working code patterns, gotchas, and corrections to previous assumptions. This is the technical encyclopedia.
- **CLAUDE.md** — Update if project-level info changes (mod type, structure, scope decisions, etc.)

Do not wait for the user to prompt for doc updates. If we learn it, we document it.
