# Aeon Ark: The Lost Frontier

**方舟纪元：失落的世界** — original Minecraft Java adventure modpack.

> **Development snapshot:** v0.2.0-alpha.3 · Minecraft Java 26.3 · Fabric · Java 25  
> **Status:** engineering preview; the Windows build, PCL import and Minecraft client have not yet been launch-tested.

## Vision
A vanilla-inspired survival and exploration pack that begins on a small isolated island. Players explore six broad regions, restore the lost Ark civilization's archives, develop farming, industry and magic, and choose among multiple endings. The design favors discovery and collection over frequent boss fights.

## Current baseline

| Item | Target |
|---|---|
| Minecraft Java | 26.3 |
| Fabric Loader | 0.20.1 |
| Fabric API | 0.166.2+26.3 |
| Java | 25 x64 |
| Launcher | PCL / PCL2 |
| Difficulty | Standard Survival |
| Opening | Dreamcraft-style island start (seed is still unverified) |
| Authored quests | 72 across 8 categories |
| Long-term quest target | 360+ |
| Memory target | ~5 GB, pending performance tests |

## Current contents
- 72 original Chinese JustQuests quests in 8 categories, with objectives, rewards and prerequisite links.
- Instance-level Global Packs configuration and JustQuests configuration.
- Modrinth-based Windows build script for resolving compatible mod versions and verifying downloaded hashes.
- Offline quest validator and validation report.
- Project manifest, mod source list and PCL deployment notes.

## Build and test
1. Download the source snapshot attached in the project conversation, or clone this repository.
2. On an internet-connected Windows machine, use Java 25 x64.
3. Run `Build_PCL整合包.bat` to resolve compatible files and build local install packages.
4. Import/install through PCL and test in a fresh 26.3 instance.
5. Report startup logs and `logs/latest.log` for fixes.

Run the offline quest-data check:

```bash
python scripts/validate_quests.py
```

## Verification boundary
**Passed:** 72 quest JSON files parse; 8 categories exist; prerequisite references resolve; JustQuests objective/reward fields pass static validation; source archive integrity check passed.

**Not yet done:** Windows PowerShell build execution, complete dependency resolution, PCL import, Minecraft client launch, actual island-spawn verification, in-game quest counters, and 5 GB stability/performance testing.

The candidate seed and spawn coordinates are documented as *unverified candidates*, not confirmed island coordinates. Third-party mod JARs are not committed to this source repository.

See [CHANGELOG](CHANGELOG.md), [technical verification](docs/技术核验记录.md), [Alpha 3 notes](docs/V0.2.0-alpha.3更新说明.md), and [quest validation report](docs/quest_validation_report.json).
