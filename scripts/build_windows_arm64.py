"""Build Linux ARM64 PenMods with the portable D:\\PenModsBuild SDK."""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import subprocess
from pathlib import Path


def build(sdk: Path, qt_host: Path, jobs: int) -> None:
    repo = Path(__file__).resolve().parents[1]
    sdk, qt_host = sdk.resolve(), qt_host.resolve()
    output = sdk / "penmods-build"
    output.mkdir(parents=True, exist_ok=True)
    zig = sdk / "toolchain/zig-x86_64-windows-0.14.1/zig.exe"
    qt = sdk / "sysroot/usr/include/aarch64-linux-gnu/qt5"
    modules = ["Core", "Gui", "Network", "Qml", "Quick", "Multimedia", "WebSockets", "Sql"]
    # src/base/StdInt.h shadows the system stdint.h on case-insensitive Windows.
    includes = [repo / "src", output, qt,
                sdk / "sources/Dobby-0932d69c320e786672361ab53825ba8f4245e9d3/include",
                sdk / "sources/spdlog-1.15.3/include",
                sdk / "sources/json-3.12.0/include",
                sdk / "sources/ELFIO-Release_3.12",
                sdk / "sysroot/usr/include"] + [qt / ("Qt" + module) for module in modules]
    include_flags = ["-I" + str(path) for path in includes]
    defines = ["-DPL_BUILD_YDP02X", "-DPL_DEV_CHANNEL", "-DBUILD_CHANNEL=dev", "-DNDEBUG",
               "-DQT_OPENGL_ES_2"]
    version = (repo / "src/mod/Version.h.in").read_text(encoding="utf-8")
    revision = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=repo, text=True).strip()
    for key, value in {"VERSION_MAJOR": "2", "VERSION_MINOR": "0", "VERSION_ALTER": "0",
                       "MODE": "release", "GIT_COMMIT": revision + "-maintenance"}.items():
        version = version.replace("${" + key + "}", value)
    (output / "Version.h").write_text(version, encoding="utf-8")

    sources = sorted((repo / "src").rglob("*.cpp"))
    for header in sorted((repo / "src").rglob("*.h")):
        contents = header.read_text(encoding="utf-8")
        if "Q_OBJECT" not in contents and "Q_GADGET" not in contents:
            continue
        generated = output / ("moc_" + "_".join(header.relative_to(repo / "src").parts) + ".cpp")
        subprocess.run([str(qt_host / "moc.exe"), "-D__linux__", "-U_WIN32", *defines,
                        *include_flags, str(header), "-o", str(generated)], check=True)
        sources.append(generated)

    common = [str(zig), "c++", "-target", "aarch64-linux-gnu.2.27", "-std=c++23",
              "-fPIC", "-O2", "-fvisibility=hidden", "-ffunction-sections", "-fdata-sections",
              *defines, *include_flags]
    pch = output / "Base.pch"
    subprocess.run([*common, "-x", "c++-header", str(repo / "src/base/Base.h"), "-o", str(pch)], check=True)
    common += ["-include-pch", str(pch)]

    def compile_one(item):
        index, source = item
        obj = output / f"{index:03}_{source.stem}.o"
        log = output / f"{index:03}_{source.stem}.log"
        # Recompile when any source/header changes; skip only within this exact source snapshot.
        resource_stamp = resource_hash if source == repo / "src/mod/Engine.cpp" else ""
        stamp = hashlib.sha256((str(source) + source.read_text(encoding="utf-8") + snapshot + resource_stamp).encode()).hexdigest()
        stamp_file = obj.with_suffix(".sha256")
        if not obj.exists() or not stamp_file.exists() or stamp_file.read_text() != stamp:
            result = subprocess.run([*common, "-c", str(source), "-o", str(obj)], capture_output=True, text=True)
            log.write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode:
                print(result.stderr[:3500], flush=True)
                raise RuntimeError(f"Compile failed: {source}; log: {log}")
            stamp_file.write_text(stamp)
        print(f"[{index + 1}/{len(sources)}] {source.name}", flush=True)
        return obj

    resource_hash = hashlib.sha256((repo / "resource/models/YDP02X/qrc_qml.h").read_bytes()).hexdigest()
    snapshot = hashlib.sha256(b"".join(p.read_bytes() for p in sorted((repo / "src").rglob("*.h")))
                              + json.dumps(common).encode() + version.encode()).hexdigest()
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        objects = list(pool.map(compile_one, enumerate(sources)))
    library = output / "libPenMods.so"
    libraries = [sdk / "sysroot/usr/lib" / f"libQt5{module}.so.5.15.2" for module in modules]
    command = [str(zig), "c++", "-target", "aarch64-linux-gnu.2.27", "-shared", "-static-libstdc++", "-s",
               "-Wl,-soname,libPenMods.so", "-Wl,--gc-sections",
               "-Wl,--no-undefined", "-Wl,--as-needed",
               "-Wl,-z,relro,-z,now", "-o", str(library), *map(str, objects),
               str(sdk / "dobby-pinned-build/libdobby.a"), *map(str, libraries),
               str(sdk / "sysroot/usr/lib/libmp3lame.so.0.0.0"), "-ldl", "-lpthread"]
    subprocess.run(command, check=True)
    manifest = {"target": "aarch64-linux-gnu.2.27", "qt": "5.15.2", "revision": revision,
                "sha256": hashlib.sha256(library.read_bytes()).hexdigest(), "size": library.stat().st_size}
    (output / "build-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, default=Path("D:/PenModsBuild"))
    parser.add_argument("--qt-host", type=Path, required=True)
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    build(args.sdk, args.qt_host, args.jobs)
