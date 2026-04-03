# /game-version-check

Run this skill after a Captain of Industry game update to check whether the ResearchQueue mod will still work with the new version.

## What this checks and why

The ResearchQueue mod works by peeking at internal game code that isn't part of any official modding API. Think of it like the mod knowing the exact name and location of a drawer inside the game's filing cabinet. When the game updates, the developers might rename those drawers, move them, or remove them entirely -- and the mod wouldn't know where to look anymore.

This skill runs a diagnostic that checks whether all those "drawers" (called reflection targets in the code) still exist where the mod expects them. It tells you exactly what's working, what's broken, and what to do about it.

## Key files

| File | What it does |
|------|-------------|
| `check-reflection-targets.ps1` | The diagnostic script. Reads the mod's source code to find every internal game reference, then checks each one against the actual game files. No separate list to maintain -- it always matches what's in the code. |
| `inspect_dll.ps1` | A deeper inspection tool. When something breaks, this shows you what a game type looks like now so you can spot what changed (renamed, moved, etc.). |
| `ResearchQueueWindowController.cs` | The mod's main code file. Contains all the `ReflectionProbe.*` calls that define what internal game code the mod depends on. |

## Workflow

### Step 1: Run the diagnostic

Run the diagnostic script from the project root:

```
powershell -ExecutionPolicy Bypass -File check-reflection-targets.ps1
```

Always show the user the full output table. The results break down into three categories:

- **PASS** -- The mod can find this internal game reference. This feature will work.
- **FAIL** -- The game changed and the mod can't find this reference anymore. This feature is broken and needs a code fix.
- **SKIP** -- This reference uses a dynamic type that can only be checked by actually running the game. The mod's built-in health check (visible in the game log at startup) will verify these automatically.

### Step 2: If everything passes

Great news -- tell the user the mod should work fine with the new game version. Remind them to:
1. Update `max_verified_game_version` in `manifest.json` to the new game version
2. Update the `MAX_VERIFIED_VERSION` constant in `ResearchQueueWindowController.cs` (search for "keep in sync with max_verified_game_version")
3. Test in-game to confirm (especially the SKIP items that couldn't be checked offline)

### Step 3: If something fails

Explain to the user in plain language what broke and what it means for the mod. For each failed target:

1. Run `inspect_dll.ps1` on the affected type to see what it looks like now:
   ```
   powershell -File inspect_dll.ps1 <TypeName> <DllName>
   ```

2. Compare the output against the member name that failed. Explain what likely happened:
   - **Renamed:** The game developers renamed it. Fix: update the name string in the `ReflectionProbe` call in the code.
   - **Moved:** It's now on a different class. Fix: update the type reference in the `ReflectionProbe` call.
   - **Removed:** The game no longer has this at all. The mod feature tied to it will need a new approach, or it stays disabled. The mod's graceful degradation system will automatically disable just that feature without crashing.

3. After making fixes, rebuild and re-run the diagnostic:
   ```
   dotnet build ResearchQueue.sln
   powershell -ExecutionPolicy Bypass -File check-reflection-targets.ps1
   ```

4. Once all targets pass, update the version tracking (same as Step 2 above).

Remind the user about version bumping per CLAUDE.md rules.

## What happens if the mod loads with broken targets?

The mod won't crash. It has a built-in safety system with two layers:

1. **Health check log** -- On startup, the mod writes a report to the game log showing exactly what resolved and what's missing. Look for the `=== Health Check ===` block.

2. **Graceful degradation** -- If some features can't work, the mod disables just those features instead of crashing. For example, if queue reading works but queue manipulation doesn't, the panel shows in read-only mode (you can see your queue but not reorder it). Critical failures disable the mod entirely with a clear message.

## Notes

- Some targets are marked SKIP because they depend on types that only exist at runtime inside the game. The offline diagnostic can't check these -- the mod's built-in health check handles them instead.
- If you're sharing this with someone else debugging the mod: they need the `COI_ROOT` environment variable set to their game install path for the script to find the game files.
