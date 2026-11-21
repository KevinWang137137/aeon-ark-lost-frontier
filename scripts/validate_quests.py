#!/usr/bin/env python3
"""Offline static validator for Aeon Ark's JustQuests datapack."""
from __future__ import annotations
import base64, gzip, json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GLOBAL_ROOT = ROOT / "global_packs"
QUEST_ROOT = GLOBAL_ROOT / "required_data/arkfrontier_quests/data/arkfrontier/justquests/quests"
OBJECTIVE_REQUIRED = {
    "justquests:collect_item": {"item", "count"}, "justquests:have_item": {"item", "count"},
    "justquests:craft_item": {"item", "count"}, "justquests:smelt_item": {"item", "count"},
    "justquests:consume_item": {"item", "count"}, "justquests:enchant_item": {"count"},
    "justquests:brew_potion": {"count"}, "justquests:find_biome": {"biome"},
    "justquests:find_structure": {"structure"}, "justquests:breed_animal": {"entity", "count"},
    "justquests:fish_item": {"count"}, "justquests:place_block": {"block", "count"},
    "justquests:reach_level": {"level"}, "justquests:stat": {"stat", "count"},
    "justquests:visit_dimension": {"dimension"}, "justquests:cut_item": {"count"},
    "justquests:cook_item": {"count"}, "justquests:rich_soil": {"count"},
    "justquests:trade_villager": {"count"}, "justquests:use_item": {"item", "count"},
    "justquests:mine_block": {"block", "count"}, "justquests:kill_mob": {"entity", "count"},
    "justquests:reach_location": {"x", "y", "z"}, "justquests:gain_advancement": {"advancement"},
}
REWARD_REQUIRED = {
    "justquests:give_item": {"item", "count"}, "justquests:xp": {"amount"},
    "justquests:message": {"message"}, "justquests:title": {"title"},
    "justquests:command": {"command"}, "justquests:choice": {"options"},
    "justquests:loot_table": {"loot_table"}, "justquests:effect": {"effect"},
}

def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

def unpack_bundle() -> None:
    if QUEST_ROOT.exists() and any(QUEST_ROOT.rglob("*.json")):
        return
    bundle = ROOT / "quest-data/quests.json.gz.b64"
    if not bundle.exists():
        raise FileNotFoundError("Missing quest files and quest-data/quests.json.gz.b64")
    payload = gzip.decompress(base64.b64decode(bundle.read_text(encoding="ascii").strip()))
    entries = json.loads(payload).get("files", [])
    for entry in entries:
        target = GLOBAL_ROOT / entry["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(entry["content"], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def main() -> int:
    unpack_bundle()
    errors, quest_ids, entries = [], set(), []
    objective_counts, reward_counts, categories = Counter(), Counter(), Counter()
    files = sorted(QUEST_ROOT.rglob("*.json"))
    for path in files:
        relative = path.relative_to(QUEST_ROOT).with_suffix("").as_posix()
        qid = "arkfrontier:" + relative
        if qid in quest_ids: errors.append(f"duplicate quest id: {qid}")
        quest_ids.add(qid)
        try: quest = read_json(path)
        except Exception as exc:
            errors.append(f"invalid JSON {path}: {exc}")
            continue
        if not isinstance(quest, dict):
            errors.append(f"quest root must be object: {path}")
            continue
        for key in ("title", "objectives", "rewards"):
            if key not in quest: errors.append(f"{qid}: missing {key}")
        if not isinstance(quest.get("objectives"), list) or not quest.get("objectives"):
            errors.append(f"{qid}: objectives must be a non-empty list")
        if not isinstance(quest.get("rewards"), list):
            errors.append(f"{qid}: rewards must be a list")
        categories[quest.get("category", "datapack")] += 1
        for i, obj in enumerate(quest.get("objectives", [])):
            if not isinstance(obj, dict):
                errors.append(f"{qid}: objectives[{i}] must be object")
                continue
            kind = obj.get("type")
            objective_counts[kind or "<missing>"] += 1
            needed = OBJECTIVE_REQUIRED.get(kind)
            if needed is None: errors.append(f"{qid}: unknown objective {kind}")
            elif needed - obj.keys(): errors.append(f"{qid}: {kind} missing {sorted(needed - obj.keys())}")
            if "count" in obj and (not isinstance(obj["count"], int) or obj["count"] < 1):
                errors.append(f"{qid}: count must be positive integer")
        for i, reward in enumerate(quest.get("rewards", [])):
            if not isinstance(reward, dict):
                errors.append(f"{qid}: rewards[{i}] must be object")
                continue
            kind = reward.get("type")
            reward_counts[kind or "<missing>"] += 1
            needed = REWARD_REQUIRED.get(kind)
            if needed is None: errors.append(f"{qid}: unknown reward {kind}")
            elif needed - reward.keys(): errors.append(f"{qid}: {kind} missing {sorted(needed - reward.keys())}")
        entries.append((qid, quest))
    for qid, quest in entries:
        for prereq in quest.get("requires", []):
            if prereq not in quest_ids: errors.append(f"{qid}: missing prerequisite {prereq}")
    pack_meta = GLOBAL_ROOT / "required_data/arkfrontier_quests/pack.mcmeta"
    try:
        pack = read_json(pack_meta).get("pack", {})
        if pack.get("min_format") != [121, 0] or pack.get("max_format") != 121:
            errors.append("pack.mcmeta is not the locked Minecraft 26.3 data format")
    except Exception as exc:
        errors.append(f"invalid pack.mcmeta: {exc}")
    report = {
        "game": "Minecraft Java 26.3", "loader": "Fabric",
        "quest_count": len(entries), "category_count": len(categories),
        "categories": dict(sorted(categories.items())),
        "objective_type_counts": dict(sorted(objective_counts.items())),
        "reward_type_counts": dict(sorted(reward_counts.items())),
        "missing_prerequisites": [], "static_errors": errors, "client_launch_test": "NOT RUN",
    }
    report_path = ROOT / "docs/quest_validation_report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(main())
