"""Decode the actual shipped Qt v3 arrays, including compressed payloads."""

import re
import unittest
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "resource/models/YDP02X"


def embedded_files():
    code = (MODEL / "qrc_qml.h").read_text(encoding="utf-8")
    arrays = {}
    for name in ("data", "name", "struct"):
        body = re.search(r"qt_resource_" + name + r"\[\] = \{(.*?)\n\};", code, re.S)[1]
        body = re.sub(r"//[^\n]*", "", body)
        arrays[name] = bytes(int(value, 16) for value in re.findall(r"0x([0-9a-fA-F]+)", body))
    tree, names, data = (arrays[name] for name in ("struct", "name", "data"))

    def number(source, offset, width=4):
        return int.from_bytes(source[offset:offset + width], "big")

    files = {}

    def visit(index, parent):
        offset = index * 22  # Qt resource format v3
        name_offset = number(tree, offset)
        length = number(names, name_offset, 2)
        name = names[name_offset + 6:name_offset + 6 + length * 2].decode("utf-16-be")
        path = f"{parent}/{name}" if index else ""
        flags = number(tree, offset + 4, 2)
        if flags & 2:
            count, first = number(tree, offset + 6), number(tree, offset + 10)
            for child in range(first, first + count):
                visit(child, path)
        else:
            start = number(tree, offset + 10)
            size = number(data, start)
            payload = data[start + 4:start + 4 + size]
            if flags & 1:
                payload = zlib.decompress(payload[4:])
            files[path.lstrip("/")] = payload

    visit(0, "")
    return files


class EmbeddedResourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = embedded_files()

    def test_every_packaged_file_matches_source(self):
        expected = {}
        for group in ET.parse(MODEL / "resource.qrc").getroot():
            for entry in group:
                path = entry.get("alias", entry.text)
                expected[path] = (MODEL / entry.text).read_bytes()
        self.assertEqual(set(self.files), set(expected))
        for path, payload in expected.items():
            with self.subTest(path=path):
                self.assertEqual(self.files[path], payload)

    def test_retired_promotional_assets_are_not_shipped(self):
        self.assertFalse(any("sponsor/" in path or "AFDian" in path for path in self.files))
        about = self.files["qml/settingpages/AboutPenMods.qml"].decode("utf-8")
        for obsolete in ("641664873", "QQ交流群", "捐助项目发展", "AFDianQrCode"):
            self.assertNotIn(obsolete, about)
        self.assertIn("GPL", about)
        self.assertIn("PenUniverse/PenMods", about)


if __name__ == "__main__":
    unittest.main()
