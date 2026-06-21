import json
import unittest
from copy import deepcopy
from pathlib import Path


AI_DEFAULTS = {
    "enabled": False,
    "provider_index": 0,
    "base_url": "https://api.deepseek.com",
    "api_key": "",
    "model": "deepseek-v4-flash",
    "temperature": 0.7,
    "system_prompt": "你是有道词典笔的 AI 助手，请简洁准确地回答问题。",
}


def migrate_fixture(data):
    result = deepcopy(data)
    if "version" not in result or result["version"] == 200:
        return result
    ai = result.setdefault("ai", {})
    for key, value in AI_DEFAULTS.items():
        ai.setdefault(key, value)
    result["version"] = 200
    return result


class ConfigMigrationTests(unittest.TestCase):
    def test_v120_preserves_sections_and_bing(self):
        source = {
            "version": 120,
            "logger": {"no_upload_httplog": True},
            "ai": {
                "bing": {"enabled": True, "request_address": "local"},
                "model": "custom-model",
            },
        }
        migrated = migrate_fixture(json.loads(json.dumps(source)))
        self.assertEqual(migrated["version"], 200)
        self.assertEqual(migrated["logger"], source["logger"])
        self.assertEqual(migrated["ai"]["bing"], source["ai"]["bing"])
        self.assertEqual(migrated["ai"]["model"], "custom-model")
        self.assertEqual(migrated["ai"]["api_key"], "")

    def test_v200_is_idempotent(self):
        source = {"version": 200, "ai": {"api_key": "fixture-only"}}
        self.assertEqual(migrate_fixture(source), source)

    def test_cpp_uses_safe_guard_and_missing_key_merge(self):
        cpp = (
            Path(__file__).parents[1] / "src/mod/Config.cpp"
        ).read_text(encoding="utf-8")
        self.assertIn('if (!data.contains("version"))', cpp)
        self.assertIn('if (data.at("version") == VERSION_CONFIG)', cpp)
        self.assertIn("addMissing", cpp)
        self.assertNotIn('data["ai"]["api_key"]        = ""', cpp)

    def test_deepseek_default_and_legacy_model_migration(self):
        header = (
            Path(__file__).parents[1] / "src/ai/AIAssistant.h"
        ).read_text(encoding="utf-8")
        source = (
            Path(__file__).parents[1] / "src/ai/AIAssistant.cpp"
        ).read_text(encoding="utf-8")
        self.assertIn('"DeepSeek",   "https://api.deepseek.com",                          "deepseek-v4-flash"', header)
        self.assertIn('mModel == "deepseek-chat"', source)
        self.assertIn('mModel == "v4-flash"', source)
        self.assertIn('mCfg["model"] = "deepseek-v4-flash"', source)

    def test_reasoning_content_is_not_shown_or_saved(self):
        source = (
            Path(__file__).parents[1] / "src/ai/AIAssistant.cpp"
        ).read_text(encoding="utf-8")
        reasoning_block = source.split('if (delta.contains("reasoning_content")', 1)[1]
        reasoning_block = reasoning_block.split("}", 1)[0]
        self.assertNotIn("mAccumulatedReply +=", reasoning_block)
        self.assertNotIn("emit replyChunkChanged", reasoning_block)


if __name__ == "__main__":
    unittest.main()
