"""Stage the verified Ubuntu arm64 GStreamer software decoder for Loader/media."""

import argparse
import hashlib
import io
from pathlib import Path
import tarfile
from urllib.request import urlopen


URL = ("https://ports.ubuntu.com/ubuntu-ports/pool/universe/g/gst-libav1.0/"
       "gstreamer1.0-libav_1.14.5-0ubuntu1~18.04.1_arm64.deb")
PACKAGE_SHA256 = "da288f2c0488a668ec119f76e6a174c39c78961f21d01bf9a5c3338e8b3d17e3"
PLUGIN_SHA256 = "c3947208150ce0fcbdf94e407630e3ba0cf534b3ec250ec3ca2e163157ee669e"


def data_archive(package: bytes) -> bytes:
    if not package.startswith(b"!<arch>\n"):
        raise ValueError("Expected a Debian ar archive")
    pos = 8
    while pos + 60 <= len(package):
        header = package[pos:pos + 60]
        if header[-2:] != b"`\n":
            raise ValueError("Invalid Debian archive header")
        size = int(header[48:58])
        pos += 60
        if header[:16].rstrip(b" /") == b"data.tar.xz" and pos + size <= len(package):
            return package[pos:pos + size]
        pos += size + size % 2
    raise ValueError("Package has no data.tar.xz")


def prepare(output: Path, package: bytes) -> None:
    if hashlib.sha256(package).hexdigest() != PACKAGE_SHA256:
        raise ValueError("Decoder package checksum does not match the pinned build")
    with tarfile.open(fileobj=io.BytesIO(data_archive(package)), mode="r:xz") as archive:
        plugin = archive.extractfile("./usr/lib/aarch64-linux-gnu/gstreamer-1.0/libgstlibav.so").read()
        notice = archive.extractfile("./usr/share/doc/gstreamer1.0-libav/copyright").read()
    if hashlib.sha256(plugin).hexdigest() != PLUGIN_SHA256:
        raise ValueError("Decoder library checksum does not match")
    output.mkdir(parents=True, exist_ok=True)
    (output / "libgstlibav.so").write_bytes(plugin)
    (output / "gst-libav-copyright.txt").write_bytes(notice)
    print(f"Verified GStreamer 1.14.5 ARM64 software decoder: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--package", type=Path, help="Use a previously downloaded copy of the pinned package")
    args = parser.parse_args()
    if args.package:
        prepare(args.output, args.package.read_bytes())
    else:
        with urlopen(URL, timeout=30) as response:
            prepare(args.output, response.read(1024 * 1024))
