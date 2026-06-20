"""Build a YDP02X resource tree without replacing current firmware files."""

from __future__ import annotations

import argparse
import os
import shutil
import stat
from pathlib import Path


STUB_MARKER = b"STUB for build verification only"
GENERATED_FILES = {Path("qrc_qml.h"), Path("resource.qrc")}


def _files(root: Path):
    return sorted(path for path in root.rglob("*") if path.is_file())


def _validate_source(root: Path) -> None:
    if not root.is_dir():
        raise ValueError(f"resource source is not a directory: {root}")
    for header in root.rglob("qrc_qml.h"):
        if STUB_MARKER in header.read_bytes():
            raise ValueError(f"stub resource header is forbidden: {header}")


def _copy_file(source: Path, destination: Path) -> None:
    if source.is_symlink():
        raise ValueError(f"symbolic links are forbidden in resources: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def _remove_readonly(function, path, error) -> None:
    """Let deterministic rebuilds replace files copied from read-only exports."""
    if not isinstance(error, PermissionError):
        raise error
    os.chmod(path, stat.S_IWRITE)
    function(path)


def build_tree(device: Path, legacy: Path, output: Path) -> list[Path]:
    """Copy device resources, then add only paths absent from the device tree."""
    device = device.resolve()
    legacy = legacy.resolve()
    output = output.resolve()
    _validate_source(device)
    _validate_source(legacy)
    if output == device or output == legacy or output in device.parents or output in legacy.parents:
        raise ValueError("output must not replace either source tree")

    if output.exists():
        shutil.rmtree(output, onexc=_remove_readonly)
    output.mkdir(parents=True)

    device_paths: set[Path] = set()
    for source in _files(device):
        relative = source.relative_to(device)
        if relative in GENERATED_FILES:
            continue
        device_paths.add(relative)
        _copy_file(source, output / relative)

    copied_legacy: list[Path] = []
    for source in _files(legacy):
        relative = source.relative_to(legacy)
        if relative in GENERATED_FILES or relative in device_paths:
            continue
        _copy_file(source, output / relative)
        copied_legacy.append(relative)

    return copied_legacy


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True, type=Path)
    parser.add_argument("--legacy", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    copied = build_tree(args.device, args.legacy, args.output)
    print(f"Built {args.output} with {len(copied)} legacy-only files")


if __name__ == "__main__":
    main()
