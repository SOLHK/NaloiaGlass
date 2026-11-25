#!/usr/bin/env python3
"""Mach-O 64-bit ARM64 dylib auditor for IPA injection compatibility."""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

MH_MAGIC_64 = 0xFEEDFACF
CPU_TYPE_ARM64 = 0x0100000C
MH_DYLIB = 6

LC_LOAD_DYLIB = 0x0C
LC_ID_DYLIB = 0x0D
LC_LOAD_WEAK_DYLIB = 0x80000018
LC_REEXPORT_DYLIB = 0x8000001F
LC_LAZY_LOAD_DYLIB = 0x20
LC_LOAD_UPWARD_DYLIB = 0x80000023

DYLIB_LOAD_CMDS = {
    LC_LOAD_DYLIB,
    LC_LOAD_WEAK_DYLIB,
    LC_REEXPORT_DYLIB,
    LC_LAZY_LOAD_DYLIB,
    LC_LOAD_UPWARD_DYLIB,
}

ALLOWED_SYSTEM_PREFIXES = (
    "/System/Library/Frameworks/",
    "/System/Library/PrivateFrameworks/",
    "/usr/lib/",
)

FORBIDDEN_SUBSTRINGS = (
    "CydiaSubstrate",
    "libsubstrate",
    "ElleKit",
    "libhooker",
    "Orion",
    "/var/jb",
    "/Library/MobileSubstrate",
)


def _extract_cstring(blob: bytes, offset: int) -> str:
    end = blob.find(b"\x00", offset)
    if end == -1:
        end = len(blob)
    return blob[offset:end].decode("utf-8", errors="replace")


def audit_dylib_bytes(data: bytes) -> dict:
    if len(data) < 32:
        raise ValueError("File too small to be a 64-bit Mach-O binary")

    magic, cputype, _cpusubtype, filetype, ncmds, sizeofcmds, _flags, _reserved = struct.unpack_from(
        "<IIIIIIII", data, 0
    )
    if magic != MH_MAGIC_64:
        raise ValueError(f"Unexpected Mach-O magic: 0x{magic:08X} (expected MH_MAGIC_64)")
    if cputype != CPU_TYPE_ARM64:
        raise ValueError(f"Unexpected CPU type: 0x{cputype:08X} (expected CPU_TYPE_ARM64)")
    if filetype != MH_DYLIB:
        raise ValueError(f"Unexpected Mach-O filetype: {filetype} (expected MH_DYLIB=6)")
    if 32 + sizeofcmds > len(data):
        raise ValueError("Truncated Mach-O load commands")

    install_name: str | None = None
    linked_libs: list[str] = []

    pos = 32
    for _ in range(ncmds):
        if pos + 8 > len(data):
            raise ValueError("Malformed load command header")
        cmd, cmdsize = struct.unpack_from("<II", data, pos)
        if cmdsize < 8 or pos + cmdsize > len(data):
            raise ValueError(f"Invalid load command size {cmdsize} at offset {pos}")
        cmd_bytes = data[pos : pos + cmdsize]

        if cmd == LC_ID_DYLIB or cmd in DYLIB_LOAD_CMDS:
            if cmdsize < 24:
                raise ValueError("dylib_command smaller than 24 bytes")
            (str_offset,) = struct.unpack_from("<I", cmd_bytes, 8)
            if str_offset >= cmdsize:
                raise ValueError("dylib_command string offset out of bounds")
            path = _extract_cstring(cmd_bytes, str_offset)
            if cmd == LC_ID_DYLIB:
                install_name = path
            else:
                linked_libs.append(path)

        pos += cmdsize

    if install_name != "@rpath/NaloiaGlass.dylib":
        raise ValueError(
            f"LC_ID_DYLIB must be '@rpath/NaloiaGlass.dylib' for IPA signing compatibility, got {install_name!r}"
        )

    for lib in linked_libs:
        for bad in FORBIDDEN_SUBSTRINGS:
            if bad.lower() in lib.lower():
                raise ValueError(f"Forbidden external jailbreak dependency linked: {lib}")
        if not lib.startswith(ALLOWED_SYSTEM_PREFIXES):
            raise ValueError(f"Non-system linked library disallowed for stock IPA injection: {lib}")

    return {
        "architecture": "arm64",
        "install_name": install_name,
        "linked_libraries": linked_libs,
    }


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: audit_macho.py <path-to-NaloiaGlass.dylib>", file=sys.stderr)
        return 2
    target = Path(argv[1])
    report = audit_dylib_bytes(target.read_bytes())
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
