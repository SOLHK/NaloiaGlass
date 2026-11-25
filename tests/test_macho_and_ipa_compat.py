from pathlib import Path
import plistlib
import re
import struct
import tarfile
import tempfile
import unittest
import io

ROOT = Path(__file__).resolve().parents[1]


def make_synthetic_macho64_dylib(install_name: str, linked_libs: list[str]) -> bytes:
    MH_MAGIC_64 = 0xFEEDFACF
    CPU_TYPE_ARM64 = 0x0100000C
    MH_DYLIB = 6
    LC_LOAD_DYLIB = 0x0C
    LC_ID_DYLIB = 0x0D

    def dylib_cmd(cmd_type: int, path: str) -> bytes:
        raw_path = path.encode("utf-8") + b"\x00"
        name_offset = 24
        cmd_size = (name_offset + len(raw_path) + 7) & ~7
        padded = raw_path.ljust(cmd_size - name_offset, b"\x00")
        return struct.pack("<IIIIII", cmd_type, cmd_size, name_offset, 2, 0x010000, 0x010000) + padded

    cmds = [dylib_cmd(LC_ID_DYLIB, install_name)]
    for lib in linked_libs:
        cmds.append(dylib_cmd(LC_LOAD_DYLIB, lib))
    cmds_blob = b"".join(cmds)
    header = struct.pack("<IIIIIIII", MH_MAGIC_64, CPU_TYPE_ARM64, 0, MH_DYLIB, len(cmds), len(cmds_blob), 0, 0)
    return header + cmds_blob


class MachOAndIPACompatTest(unittest.TestCase):
    def test_packaging_and_ci_files_exist(self):
        expected = [
            ROOT / ".gitattributes",
            ROOT / "Makefile",
            ROOT / "NaloiaGlass.plist",
            ROOT / "control",
            ROOT / "README.md",
            ROOT / "scripts/audit_macho.py",
            ROOT / "scripts/build_dylib.sh",
            ROOT / "scripts/package_deb.py",
            ROOT / "scripts/package_deb.sh",
            ROOT / ".github/workflows/build.yml",
        ]
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing file: {path}")

    def test_plist_locked_strictly_to_official_wechat_bundle(self):
        plist_data = plistlib.loads((ROOT / "NaloiaGlass.plist").read_bytes())
        self.assertEqual(plist_data, {"Filter": {"Bundles": ["com.tencent.xin"]}})

    def test_build_script_and_makefile_cover_all_sources_without_substrate(self):
        actual_sources = sorted(
            p.relative_to(ROOT).as_posix() for p in (ROOT / "src").rglob("*.m")
        )
        self.assertGreaterEqual(len(actual_sources), 10)

        build_sh = (ROOT / "scripts/build_dylib.sh").read_text(encoding="utf-8")
        makefile = (ROOT / "Makefile").read_text(encoding="utf-8")

        for rel in actual_sources:
            self.assertIn(rel, build_sh, f"{rel} missing from scripts/build_dylib.sh")
            self.assertIn(rel, makefile, f"{rel} missing from Makefile")

        self.assertIn("@rpath/NaloiaGlass.dylib", build_sh)
        for text in (build_sh, makefile):
            self.assertNotIn("CydiaSubstrate", text)
            self.assertNotIn("-lsubstrate", text)
            self.assertNotIn("ElleKit", text)

    def test_macho_auditor_accepts_clean_rpath_dylib_and_rejects_jailbreak_deps(self):
        import sys
        sys.path.insert(0, str(ROOT / "scripts"))
        import audit_macho  # type: ignore

        good = make_synthetic_macho64_dylib(
            "@rpath/NaloiaGlass.dylib",
            [
                "/System/Library/Frameworks/UIKit.framework/UIKit",
                "/System/Library/Frameworks/Foundation.framework/Foundation",
                "/System/Library/Frameworks/QuartzCore.framework/QuartzCore",
                "/usr/lib/libobjc.A.dylib",
                "/usr/lib/libSystem.B.dylib",
            ],
        )
        report = audit_macho.audit_dylib_bytes(good)
        self.assertEqual(report["install_name"], "@rpath/NaloiaGlass.dylib")
        self.assertEqual(len(report["linked_libraries"]), 5)

        bad_substrate = make_synthetic_macho64_dylib(
            "@rpath/NaloiaGlass.dylib",
            [
                "/System/Library/Frameworks/UIKit.framework/UIKit",
                "/var/jb/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate",
            ],
        )
        with self.assertRaises(ValueError):
            audit_macho.audit_dylib_bytes(bad_substrate)

        bad_id = make_synthetic_macho64_dylib(
            "/Library/MobileSubstrate/DynamicLibraries/NaloiaGlass.dylib",
            ["/usr/lib/libobjc.A.dylib"],
        )
        with self.assertRaises(ValueError):
            audit_macho.audit_dylib_bytes(bad_id)

    def test_rootless_deb_builder_produces_valid_ar_and_data_tar(self):
        import sys
        sys.path.insert(0, str(ROOT / "scripts"))
        import package_deb  # type: ignore

        fake_dylib = make_synthetic_macho64_dylib(
            "@rpath/NaloiaGlass.dylib",
            ["/usr/lib/libobjc.A.dylib"],
        )
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            dylib_path = tmp_dir / "NaloiaGlass.dylib"
            dylib_path.write_bytes(fake_dylib)
            out_deb = tmp_dir / "out.deb"
            package_deb.build_rootless_deb(
                dylib_path=dylib_path,
                plist_path=ROOT / "NaloiaGlass.plist",
                control_path=ROOT / "control",
                version="1.0.0",
                output_deb=out_deb,
            )
            raw = out_deb.read_bytes()
            self.assertTrue(raw.startswith(b"!<arch>\n"))
            self.assertIn(b"debian-binary", raw)
            self.assertIn(b"control.tar.gz", raw)
            self.assertIn(b"data.tar.gz", raw)

    def test_github_workflow_verifies_codesign_and_uploads_dylib_zip(self):
        wf = (ROOT / ".github/workflows/build.yml").read_text(encoding="utf-8")
        self.assertIn("macos-latest", wf)
        self.assertIn("scripts/build_dylib.sh", wf)
        self.assertIn("scripts/audit_macho.py", wf)
        self.assertIn("codesign --force --sign -", wf)
        self.assertIn("upload-artifact", wf)
        # Ensure bash scripts have LF line endings only
        for sh in ["scripts/build_dylib.sh", "scripts/package_deb.sh"]:
            raw = (ROOT / sh).read_bytes()
            self.assertNotIn(b"\r\n", raw, f"CRLF found in {sh}")


if __name__ == "__main__":
    unittest.main()
