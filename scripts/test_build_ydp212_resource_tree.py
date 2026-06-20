import tempfile
import unittest
from pathlib import Path

from scripts.build_ydp212_resource_tree import build_tree


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class ResourceTreeTests(unittest.TestCase):
    def test_overlay_copies_only_legacy_only_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            device = root / "device"
            legacy = root / "legacy"
            output = root / "output"
            write(device / "qml/YIndexPage.qml", "device-index")
            write(legacy / "qml/YIndexPage.qml", "legacy-index")
            write(legacy / "qml/settingpages/AboutPenMods.qml", "penmods")

            copied = build_tree(device, legacy, output)

            self.assertEqual(
                (output / "qml/YIndexPage.qml").read_text(encoding="utf-8"),
                "device-index",
            )
            self.assertEqual(
                (output / "qml/settingpages/AboutPenMods.qml").read_text(
                    encoding="utf-8"
                ),
                "penmods",
            )
            self.assertEqual(copied, [Path("qml/settingpages/AboutPenMods.qml")])

    def test_rejects_stub_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            device = root / "device"
            legacy = root / "legacy"
            write(device / "qrc_qml.h", "STUB for build verification only")
            legacy.mkdir()

            with self.assertRaisesRegex(ValueError, "stub resource"):
                build_tree(device, legacy, root / "output")


class PortedResourceTests(unittest.TestCase):
    RESOURCE = Path(__file__).parents[1] / "resource/models/YDP02X"

    def read(self, relative: str) -> str:
        return (self.RESOURCE / relative).read_text(encoding="utf-8")

    def test_settings_keep_official_routes_and_add_penmods_routes(self):
        text = self.read("qml/YSettingPage.qml")
        self.assertIn("YEnum.SettingIndex.Network", text)
        self.assertIn('showSettingPage("settingpages/DeveloperSettingPage")', text)
        self.assertIn('showSettingPage("settingpages/AISettingPage")', text)
        self.assertIn('showSettingPage("settingpages/AboutPenMods")', text)
        self.assertNotIn(
            'YEnum.SettingIndex.Network,       settingIcon: res.getDisk', text
        )

    def test_ai_page_uses_only_ai_assistant_transport(self):
        chat = self.read("qml/AIChatPage.qml")
        self.assertIn("aiAssistant.send", chat)
        self.assertIn("onReplyChunkChanged", chat)
        self.assertNotIn("bing", chat.lower())

        setting = self.read("qml/settingpages/AISettingPage.qml")
        self.assertIn("aiAssistant.apiKey", setting)
        self.assertNotIn("text: aiAssistant.apiKey", setting)

    def test_ai_route_is_added_without_removing_official_routes(self):
        main = self.read("main.qml")
        self.assertIn("case MEnum.PG_NewBing:", main)
        self.assertIn('showPage("AIChatPage")', main)
        for route in (
            "YEnum.PageIndex.Dict",
            "YEnum.PageIndex.TextBook",
            "YEnum.PageIndex.Setting",
        ):
            self.assertIn(route, main)

    def test_file_manager_keeps_current_page_shell_and_adds_mod_actions(self):
        page = self.read("qml/audiopages/YMyImportPageComponent.qml")
        self.assertIn("YBackButtonAudioPage", page)
        self.assertIn("id_import_page_column_view", page)
        self.assertIn("model: fileManager", page)
        self.assertIn("FileManagerDrawerLayer", page)
        self.assertIn("fileManager.remove", page)
        self.assertIn("textReader.open", page)
        self.assertIn("videoPlayer.open", page)


if __name__ == "__main__":
    unittest.main()
