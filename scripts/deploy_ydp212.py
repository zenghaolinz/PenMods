"""Deploy the PenMods YDP02X firmware 2.1.2 release over ADB."""

import argparse
import hashlib
import io
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import uuid
from urllib.request import urlopen
from zipfile import ZipFile


PACKAGE_NAME = "PenMods-YDP02X-2.1.2-r3.zip"
PACKAGE_URL = (
    "https://github.com/zenghaolinz/PenMods/releases/download/v2.0.0-ydp212.3/"
    + PACKAGE_NAME
)
PACKAGE_SIZE = 1654373
PACKAGE_SHA256 = "bfe0cea4bb20773b5cea042ff9a24db59358910d71f273e234b23da6aa1f527a"
LOADER = "/userdisk/Loader"
FILES = ("media/libgstlibav.so", "media/gst-libav-copyright.txt", "libPenMods.so")
OK = "PENMODS_DEPLOY_OK"

TRANSACTION = r"""#!/bin/sh
set -eu
loader=$1
stage=$2
backup=$3
source=$4
shift 4
lock=$loader/.penmods-deploy-lock
changed=0

checksum() {
    line=$(sha256sum "$1") || return 1
    printf '%s\n' "${line%% *}"
}

copy_checked() {
    expected=$(checksum "$1") && cp -p "$1" "$2" &&
        actual=$(checksum "$2") && [ "$expected" = "$actual" ]
}

replace_from() {
    from=$1
    shift
    for file do
        if [ -f "$from/$file" ]; then
            target=$loader/$file
            mkdir -p "${target%/*}" &&
                copy_checked "$from/$file" "$stage/swap/$file" &&
                mv -f "$stage/swap/$file" "$target" &&
                installed=$(checksum "$target") &&
                wanted=$(checksum "$from/$file") &&
                [ "$installed" = "$wanted" ] || return 1
        else
            rm -f "$loader/$file" || return 1
        fi
    done
}

finish() {
    status=$1
    shift
    trap - EXIT
    trap '' HUP INT TERM
    if [ "$changed" -eq 1 ]; then
        if replace_from "$backup" "$@" && sync; then
            echo "Previous files restored from $backup" >&2
        else
            echo "Automatic restore failed. Backup: $backup" >&2
        fi
    fi
    rm -rf "$stage"
    rmdir "$lock"
    exit "$status"
}

if ! mkdir "$lock"; then
    echo "Another deployment is active or left a lock at $lock" >&2
    rm -rf "$stage"
    exit 1
fi
trap 'finish "$?" "$@"' EXIT
trap 'exit 1' HUP INT TERM

if [ -L "$loader/media" ] || { [ -e "$loader/media" ] && [ ! -d "$loader/media" ]; }; then
    echo "Unexpected Loader/media path" >&2
    exit 1
fi
test -f "$loader/libPenMods.so"
test -f "$source/libPenMods.so"
if [ "$source" = "$stage/new" ]; then
    (cd "$source" && sha256sum -c SHA256SUMS)
    for file do chmod 644 "$source/$file"; done
else
    test -f "$source/.complete"
fi

mkdir "$backup"
mkdir "$backup/media" "$stage/swap" "$stage/swap/media"
for file do
    target=$loader/$file
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -f "$target" ]; }; then
        echo "Unexpected deployment target: $target" >&2
        exit 1
    fi
    if [ -f "$target" ]; then
        copy_checked "$target" "$backup/$file"
    fi
done
touch "$backup/.complete"
sync

changed=1
replace_from "$source" "$@"
sync
changed=0
echo PENMODS_DEPLOY_OK
"""


def run_adb(command, *args):
    result = subprocess.run(
        [*command, *args], capture_output=True, encoding="utf-8",
        errors="replace", timeout=120,
    )
    if result.returncode:
        detail = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
        raise RuntimeError(detail or f"ADB {args[0]} exited with status {result.returncode}")
    return result.stdout


def select_device(adb, serial, connect):
    if connect:
        serial = connect if ":" in connect else f"{connect}:5555"
        print(run_adb(adb, "connect", serial).strip())

    output = run_adb(adb, "devices")
    devices = dict(line.split("\t", 1) for line in output.splitlines() if "\t" in line)
    if serial is None:
        if len(devices) != 1:
            raise RuntimeError("Connect one ADB device, or select it with --serial or --connect.\n" + output)
        serial = next(iter(devices))
    if devices.get(serial) != "device":
        raise RuntimeError(f"ADB device {serial} is unavailable.\n{output}")
    return [*adb, "-s", serial], serial


def checked_shell(adb, command):
    output = run_adb(adb, "shell", command)
    if OK not in output.splitlines():
        raise RuntimeError(output.strip() or "The device did not confirm the operation.")


def prepare_package(directory, package):
    if package is None:
        print(f"Downloading {PACKAGE_NAME} ...", flush=True)
        try:
            with urlopen(PACKAGE_URL, timeout=45) as response:
                data = response.read(PACKAGE_SIZE + 1)
        except OSError as error:
            raise RuntimeError(f"Download failed ({error}). Download {PACKAGE_NAME} and use --package.") from error
    else:
        with package.open("rb") as source:
            data = source.read(PACKAGE_SIZE + 1)
    if len(data) != PACKAGE_SIZE or hashlib.sha256(data).hexdigest() != PACKAGE_SHA256:
        raise ValueError(f"Package checksum does not match {PACKAGE_NAME}.")

    checksums = []
    with ZipFile(io.BytesIO(data)) as archive:
        for name in FILES:
            content = archive.read(name)
            path = directory / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
            checksums.append(f"{hashlib.sha256(content).hexdigest()}  {name}\n")
    (directory / "SHA256SUMS").write_bytes("".join(checksums).encode("ascii"))


def deploy(adb, package, restore):
    token = uuid.uuid4().hex[:12]
    stage = f"{LOADER}/.penmods-stage-{token}"
    backup = f"{LOADER}/.penmods-backup-{token}"
    source = f"{LOADER}/.penmods-backup-{restore}" if restore else f"{stage}/new"
    with tempfile.TemporaryDirectory(prefix="penmods-") as temporary:
        directory = Path(temporary)
        if not restore:
            prepare_package(directory, package)
        script = directory / "apply.sh"
        script.write_bytes(TRANSACTION.encode("ascii"))

        checked_shell(adb, f"mkdir {stage} && echo {OK}")
        started = False
        try:
            if not restore:
                checked_shell(adb, f"mkdir -p {stage}/new/media && echo {OK}")
                for name in (*FILES, "SHA256SUMS"):
                    run_adb(adb, "push", str(directory / name), f"{stage}/new/{name}")
            run_adb(adb, "push", str(script), f"{stage}/apply.sh")
            print(f"Backup ID: {token} ({backup})", flush=True)
            started = True
            checked_shell(adb, shlex.join(["sh", f"{stage}/apply.sh", LOADER, stage, backup, source, *FILES]))
        finally:
            if not started:
                try:
                    run_adb(adb, "shell", f"rm -rf {stage}")
                except (RuntimeError, OSError, subprocess.TimeoutExpired):
                    pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group()
    target.add_argument("--connect", metavar="HOST[:PORT]", help="Connect over Wi-Fi ADB (default port 5555)")
    target.add_argument("--serial", help="Select a device listed by adb devices")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--package", type=Path, help="Use the published ZIP from disk")
    mode.add_argument("--restore", metavar="BACKUP_ID", help="Restore files from a previous deployment")
    parser.add_argument("--adb", help="Path to the ADB executable if it is outside PATH")
    parser.add_argument("--yes", action="store_true", help="Confirm YDP02X firmware 2.1.2 with PenMods Loader")
    parser.add_argument("--no-reboot", action="store_true", help="Leave the restart for later")
    args = parser.parse_args()
    if args.connect and not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9.-]*(?::[0-9]{1,5})?", args.connect):
        parser.error("--connect expects an IPv4 address or hostname, optionally followed by :PORT")
    if args.restore and not re.fullmatch(r"[a-f0-9]{12}", args.restore):
        parser.error("--restore expects the 12-character backup ID printed during deployment")

    try:
        executable = args.adb or shutil.which("adb")
        if not executable:
            raise RuntimeError("ADB not found. Install Android SDK Platform-Tools or use --adb.")
        adb, serial = select_device([executable], args.serial, args.connect)
        checked_shell(adb, (
            'test "$(uname -m)" = aarch64 && '
            'test -x /oem/YoudaoDictPen/output/YoudaoDictPen && '
            f'test -d {LOADER} && test ! -L {LOADER} && '
            f'test -f {LOADER}/libPenMods.so && test ! -L {LOADER}/libPenMods.so && '
            f'command -v sha256sum >/dev/null && echo {OK} || '
            'echo "Expected an ARM64 Youdao pen with an existing PenMods Loader and sha256sum."'
        ))
        print(f"Device: {serial}", flush=True)
        if not args.yes:
            answer = input("Confirm YDP02X firmware 2.1.2 with PenMods Loader [y/N]: ")
            if answer.strip().lower() != "y":
                print("Cancelled.")
                return 1

        deploy(adb, args.package, args.restore)
        print("Files verified on device.", flush=True)
        if args.no_reboot:
            print("Restart the pen to load the files.")
        else:
            try:
                run_adb(adb, "reboot")
                print("Restart requested.")
            except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
                print(f"Files are installed. Restart the pen manually ({error}).", file=sys.stderr)
                return 1
        return 0
    except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired, EOFError) as error:
        print(f"PenMods: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted. Reconnect and check the device before retrying.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
