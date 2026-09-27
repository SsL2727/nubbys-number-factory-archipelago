# Nubby's Number Factory - Archipelago World

An [Archipelago](https://archipelago.gg) randomizer implementation for *Nubby's Number Factory*. Randomization is save-native: game logic is enforced via a companion Python client and a small set of binary patches applied to the game's `data.win`.

## What's in this repo

- `nubbys_number_factory/` - the apworld's Python source (items, locations, options, regions, and the in-game client).
- `nubbys_number_factory.apworld` - the built, installable apworld package.
- `gml_patch/PatchApItemLockV30_MASTER.csx` - the raw [UndertaleModTool](https://github.com/UnderminersTeam/UndertaleModTool) script the patched `data.win` is built from, for anyone who wants to inspect it or rebuild it themselves.
- `poptracker_pack/nnf_poptracker_pack.zip` - a [PopTracker](https://github.com/black-sliver/PopTracker) pack for tracking checks.

## Setup

### 1. Back up your own files first

Before touching anything, back up:

- **Your game's `data.win`** - in your game's install folder (e.g. `...\steamapps\common\Nubby's Number Factory\data.win`). Copy it somewhere safe, e.g. rename your copy to `data.win.vanilla_backup`.
- **Your save files** - in `%LOCALAPPDATA%\NNF_FullVersion\`. Copy the whole folder somewhere safe.

You'll need these to go back to a normal, non-randomized game later (see "Reverting" below).

### 2. Install the apworld

Copy `nubbys_number_factory.apworld` into your Archipelago install's `custom_worlds` folder, then generate or join a game as usual.

### 3. Patch Data.win

1. Back up your `data.win` (see step 1 above, if you haven't already).
2. Open your `data.win` in UndertaleModTool and run **Decompile All Code** (or use `UndertaleModCli`'s decompile mode). This produces a folder of `.gml` files - point it somewhere on disk, e.g. `C:\NNF_decompiled\`.
3. Open `gml_patch/PatchApItemLockV30_MASTER.csx` and either set the `NNF_DECOMP_FOLDER` environment variable to that folder, or edit **line 13** directly:
   ```csharp
   string decompFolder = Environment.GetEnvironmentVariable("NNF_DECOMP_FOLDER") ?? @"C:\NNF_decompiled";
   ```
4. Run the script against your own `data.win` with UndertaleModCli:
   ```
   UndertaleModCli.exe load "data.win" -s "PatchApItemLockV30_MASTER.csx" -o "data.win.patched"
   ```
5. Replace the game's `data.win` with `data.win.patched`.

### 4. Connect the client

Launch **ArchipelagoLauncher.exe** and pick **Nubby's Number Factory Client** from the list. Enter your server address/port and slot name like any other Archipelago client.

### 5. (Optional) PopTracker

Open [PopTracker](https://github.com/black-sliver/PopTracker), load `poptracker_pack/nnf_poptracker_pack.zip` as a pack, and connect it to the same session for a visual check tracker.

## Reverting to a normal game

To go back to playing the base game, no randomizer:

1. **Restore `data.win`**: replace it with the backup copy you made in step 1.
2. **Restore your saves**: the client automatically takes a one-time backup of whatever save you had *before* Archipelago ever touched it. In the client, run:
   ```
   /restore_vanilla
   ```
   Then restart the game. If you'd rather restore your own manual backup from step 1 instead, just copy those files back into `%LOCALAPPDATA%\NNF_FullVersion\` yourself.

## Advanced: rebuilding the patch yourself

## Notes

- If items you've received ever seem to go missing (e.g. after a rough reconnect), the client supports `/resync` to force a full re-application of everything you've received.
- The client warns loudly on connect if your `data.win` doesn't look patched - if you see that warning, redo step 3.
- If the game crashes immediately on launch mentioning a "wad file" or "FORM" error, your `data.win` download was almost certainly incomplete or corrupted - redownload it from the [latest Release](../../releases/latest) and confirm the file is about 69 MB before replacing your game's copy.
- Steam can silently update the base game (and revert any patched `data.win` back to vanilla if it does so while you're testing locally). If a newer game update ever breaks compatibility, check the [Releases page](../../releases) for a newer `data.win` build.
