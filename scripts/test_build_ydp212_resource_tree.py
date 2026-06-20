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
    ROOT = Path(__file__).parents[1]
    RESOURCE = ROOT / "resource/models/YDP02X"

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

    def test_ai_route_stays_outside_firmware_home_menu(self):
        enum_header = (self.ROOT / "src/mod/Mod.h").read_text(encoding="utf-8")
        self.assertIn("AIAssistant", enum_header)

        main = self.read("main.qml")
        index_page = self.read("qml/YIndexPage.qml")
        title_bar = self.read("qml/components/YMainTitleBar.qml")
        chat = self.read("qml/AIChatPage.qml")
        self.assertIn("onShowAIAssistant:", main)
        self.assertIn('showPage("AIChatPage")', main)
        self.assertIn("signal showAIAssistant()", index_page)
        self.assertIn("function openAIAssistant()", index_page)
        self.assertIn("showAIAssistant()", index_page)
        self.assertIn("id_title_bar.openAIAssistant()", title_bar)
        self.assertIn("parent.openAIAssistant()", title_bar)
        self.assertIn("id_container_index.openAIAssistant()", index_page)
        ai_button = title_bar[
            title_bar.index("id: id_ai_assistant_icon") : title_bar.index(
                "id: id_icon_container"
            )
        ]
        self.assertNotIn("wifiManager.internetConnect", ai_button)
        self.assertNotIn("requestShowPage(PageIndex.AIAssistant)", title_bar)
        menu_model = index_page[index_page.index("id: mainMenuModel") :]
        self.assertNotIn("PageIndex.AIAssistant", menu_model)
        for page in ("Dict", "Fav", "History", "Setting"):
            self.assertIn(
                f'append({{iconFg: "home-{page.lower() if page != "Setting" else "setting"}", '
                f"pageIndex: YEnum.PageIndex.{page}}})",
                menu_model,
            )
        self.assertIn("currentPageIndex = PageIndex.AIAssistant", chat)
        self.assertNotIn("MEnum.PG_NewBing", main + title_bar + chat)
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

    def test_ai_page_submits_fresh_scan_and_global_loader_yields(self):
        chat = self.read("qml/AIChatPage.qml")
        loader = self.read("qml/components/YScanWordsResultLoader.qml")
        self.assertIn("function submitMessage(content)", chat)
        self.assertIn("function onOcrStop(scanType)", chat)
        self.assertIn("submitMessage(systemBase.ocrCompletedResult)", chat)
        self.assertIn(
            "qmlGlobal.currentPageIndex === PageIndex.AIAssistant", loader
        )
        ai_guard = loader.index(
            "qmlGlobal.currentPageIndex === PageIndex.AIAssistant"
        )
        self.assertIn("return", loader[ai_guard : ai_guard + 300])

    def test_shared_keyboard_inserts_scan_at_cursor(self):
        input_page = self.read("qml/YInputPage.qml")
        keyboard_hook = (self.ROOT / "src/tweaker/KeyBoard.cpp").read_text(
            encoding="utf-8"
        )
        self.assertIn("target: keyBoard", input_page)
        self.assertIn("function onScanFinished(result)", input_page)
        self.assertIn("enabled: id_input_page.visible", input_page)
        self.assertIn("result.length > 0", input_page)
        self.assertIn("id_input_text_title_area.enterChar(result)", input_page)
        self.assertIn("emit mod::KeyBoard::getInstance().scanFinished(content)", keyboard_hook)
        self.assertIn("inputPageShowingEv", keyboard_hook)

    def test_readme_distinguishes_upstream_and_port_changes(self):
        readme = (self.ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("https://github.com/PenUniverse/PenMods", readme)
        self.assertIn("GPL-3.0", readme)
        self.assertIn("YDP02X 2.1.2 适配修改", readme)
        self.assertIn("原项目原创", readme)
        self.assertIn("本分支修改", readme)


if __name__ == "__main__":
    unittest.main()
