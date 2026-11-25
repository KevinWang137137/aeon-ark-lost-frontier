# Aeon Ark: The Lost Frontier

**方舟纪元：失落的世界** — a Minecraft Java adventure and exploration modpack.

**v1.0.0 stable release**

- Minecraft Java **26.3**
- Fabric Loader **0.20.1**
- Java **25 x64**
- PCL import format: **MMC instance ZIP**
- Published pack: **150 actual mod JAR files**
- Authored quests: **72 across 8 categories**

## Download

[Download AeonArk-26.3-Fabric-v1.0.0.zip](https://github.com/KevinWang137137/aeon-ark-lost-frontier/releases/download/v1.0.0/AeonArk-26.3-Fabric-v1.0.0.zip)

[Open the v1.0.0 release page](https://github.com/KevinWang137137/aeon-ark-lost-frontier/releases/tag/v1.0.0)

The ZIP is a complete PCL-importable client instance. It contains the resolved mod JARs, config, quest data, global packs and AEON ARK title-logo resource pack. The release workflow counted **150 actual JARs inside the ZIP** and verified the downloaded Modrinth hashes before publishing.

## Install with PCL

1. Download the ZIP from the release page.
2. Drag the ZIP into PCL and import it as a **new, separate instance**.
3. Keep the internet connection available on first install so PCL can install Minecraft, Fabric and runtime libraries.
4. Select Java 25 x64. Start with 5 GB allocated memory; this is a starting point, not a verified performance guarantee.
5. Create a new world for testing. Do not point the instance at an existing save.

## What is in the pack

- Special isolated-island survival start, standard Survival difficulty.
- Chinese chapter quest book with 72 authored quests in 8 categories.
- Exploration, structures, creatures, food, industrial systems and magic.
- AEON ARK title-logo resource pack, configured to be enabled by default in a fresh instance.
- Modrinth dependency resolution and file-hash verification in the Windows build workflow.

## Verification boundary

**Verified by GitHub Actions:** 150 actual `.jar` files are present in the published ZIP; Modrinth hashes were checked during download; PCL MMC ZIP structure was checked; the title texture and resource-pack metadata are present; `options.txt` enables the title pack by default; quest data passes static validation.

**Still requires a real desktop game session:** visual confirmation of the title logo on the live main menu, PCL import on the target computer, island spawn validation, in-game quest objective checks, mod interaction/stability checks, and 5 GB memory performance. The title resource pack is packaged and auto-enabled, but this CI runner did not perform a manual visual inspection of the running game.

## License

Original Aeon Ark content (original quest text, project-authored configs, scripts, documentation, artwork and logos) is **All Rights Reserved**. Personal gameplay use of the compiled modpack is permitted; redistribution or derivative use of original project materials requires prior written permission. This does not change the separate licenses and distribution terms of Minecraft, Fabric, or any third-party mods and assets. See [LICENSE](LICENSE).

## Development

Run `python scripts/validate_quests.py` to validate the authored quest data.

On Windows, `Build_PCL整合包.bat` builds the PCL instance ZIP. The build fails if it cannot resolve and verify at least 150 actual mod JARs for Minecraft 26.3 + Fabric.

The long-term quest target remains 360+ quests. See `CHANGELOG.md` and `docs/` for project history and technical notes.
