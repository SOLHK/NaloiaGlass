#!/usr/bin/env python3
"""Pure-Python deterministic rootless .deb packager (no dpkg/Homebrew required)."""

from __future__ import annotations

import gzip
import io
from pathlib import Path
import sys
import tarfile

FIXED_MTIME = 1700000000


def _tar_gz_bytes(entries: list[tuple[str, bytes, int, int]]) -> bytes:
    """entries: list of (arcname, content_bytes, mode, tar_type_flag_int_or_0_for_file)"""
    tar_buf = io.BytesIO()
    with tarfile.open(fileobj=tar_buf, mode="w", format=tarfile.GNU_FORMAT) as tf:
        for name, content, mode, is_dir in entries:
            info = tarfile.TarInfo(name=name)
            info.mtime = FIXED_MTIME
            info.uid = 0
            info.gid = 0
            info.uname = "root"
            info.gname = "wheel"
            info.mode = mode
            if is_dir:
                info.type = tarfile.DIRTYPE
                info.size = 0
                tf.addfile(info)
            else:
                info.type = tarfile.REGTYPE
                info.size = len(content)
                tf.addfile(info, io.BytesIO(content))

    gz_buf = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=gz_buf, compresslevel=9, mtime=FIXED_MTIME) as gz:
        gz.write(tar_buf.getvalue())
    return gz_buf.getvalue()


def _ar_member(name: str, payload: bytes) -> bytes:
    header = (
        f"{name:<16}"
        f"{FIXED_MTIME:<12}"
        f"{0:<6}"
        f"{0:<6}"
        f"{'100644':<8}"
        f"{len(payload):<10}"
        "`\n"
    ).encode("ascii")
    pad = b"\n" if (len(payload) % 2 == 1) else b""
    return header + payload + pad


def build_rootless_deb(
    dylib_path: Path,
    plist_path: Path,
    control_path: Path,
    version: str,
    output_deb: Path,
) -> Path:
    dylib_bytes = dylib_path.read_bytes()
    plist_bytes = plist_path.read_bytes()
    installed_kb = max(1, (len(dylib_bytes) + len(plist_bytes) + 1023) // 1024)

    raw_control = control_path.read_text(encoding="utf-8").strip().splitlines()
    out_lines: list[str] = []
    for line in raw_control:
        if line.startswith("Version:"):
            out_lines.append(f"Version: {version}")
        else:
            out_lines.append(line)
    out_lines.append(f"Installed-Size: {installed_kb}")
    control_bytes = ("\n".join(out_lines) + "\n").encode("utf-8")

    control_tgz = _tar_gz_bytes(
        [
            ("./", b"", 0o755, 1),
            ("./control", control_bytes, 0o644, 0),
        ]
    )

    dyn_dir = "./var/jb/Library/MobileSubstrate/DynamicLibraries"
    data_tgz = _tar_gz_bytes(
        [
            ("./", b"", 0o755, 1),
            ("./var/", b"", 0o755, 1),
            ("./var/jb/", b"", 0o755, 1),
            ("./var/jb/Library/", b"", 0o755, 1),
            ("./var/jb/Library/MobileSubstrate/", b"", 0o755, 1),
            (f"{dyn_dir}/", b"", 0o755, 1),
            (f"{dyn_dir}/NaloiaGlass.dylib", dylib_bytes, 0o755, 0),
            (f"{dyn_dir}/NaloiaGlass.plist", plist_bytes, 0o644, 0),
        ]
    )

    deb_blob = (
        b"!<arch>\n"
        + _ar_member("debian-binary", b"2.0\n")
        + _ar_member("control.tar.gz", control_tgz)
        + _ar_member("data.tar.gz", data_tgz)
    )
    output_deb.parent.mkdir(parents=True, exist_ok=True)
    output_deb.write_bytes(deb_blob)
    return output_deb


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parents[1]
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    dylib_path = Path(argv[1]) if len(argv) > 1 else (root / "dist/NaloiaGlass.dylib")
    out_deb = (
        Path(argv[2])
        if len(argv) > 2
        else (root / f"dist/com.solhk.naloiaglass_{version}_iphoneos-arm64.deb")
    )
    built = build_rootless_deb(
        dylib_path=dylib_path,
        plist_path=root / "NaloiaGlass.plist",
        control_path=root / "control",
        version=version,
        output_deb=out_deb,
    )
    print(f"[NaloiaGlass] Packaged rootless deb: {built}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
