import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "package-report.py"
spec = importlib.util.spec_from_file_location("package_report", SCRIPT)
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)

SNAP_LIST = """Name Version Rev Tracking Publisher Notes
core22 1 1 latest/stable canonical** base
snapd 1 1 latest/stable canonical** snapd
gnome-42-2204 1 1 latest/stable canonical** -
code 1 1 latest/stable vscode** classic
helm 1 1 latest/stable x -
newapp 1 1 latest/stable x -
"""

DNF_CLI_JSON = json.dumps({
    "backend": "dnf",
    "packages": ["fedy", "vim-enhanced", "extra-user"],
    "image_packages": ["glibc", "fedora-release-workstation"],
    "excluded_auto": ["kernel", "kernel-core"],
    "warnings": [],
})

APT_CLI_JSON = json.dumps({
    "backend": "apt",
    "packages": ["extra"],
    "image_packages": ["git"],
    "excluded_auto": [],
    "warnings": [],
})

DNF_INSTALLED = """glibc
kernel-core
kernel-devel
kernel-modules
kernel-modules-core
kernel-modules-extra
kernel
gpu-firmware
fedora-release-workstation
fedy
vim-enhanced
subversion
extra-user
git
neovim
"""


def dnf_runner(argv, overrides=None):
    mapping = {
        ("rpm", "-qa"): DNF_INSTALLED,
        ("user-installed-packages",): DNF_CLI_JSON,
    }
    if overrides:
        mapping.update(overrides)
    for size in range(len(argv), 0, -1):
        if tuple(argv[:size]) in mapping:
            value = mapping[tuple(argv[:size])]
            if isinstance(value, Exception):
                raise value
            return value
    raise report.CollectorError(f"unexpected command: {argv}")


def make_manifests(root):
    (root / "Brewfile").write_text(
        '# c\ntap "x/y"\nbrew "fd"\nbrew "ffmpeg-full", link: true\n'
        'cask "ghostty"\nvscode "Foo.Bar"\nmas "Xcode", id: 1\n'
    )
    (root / "dnf-packages.txt").write_text("# c\nneovim\ngit\ntmux-sesh\n")
    (root / "ubuntu-packages.txt").write_text("git\nzsh\ntmux-sesh\n")
    (root / "ubuntu-snap-packages.txt").write_text("# c\ncode --classic\nhelm\nterraform\n")
    (root / "flatpak-packages.txt").write_text("flathub a.B\nflathub c.D\n")


def opts_for(root, platform_name, **kw):
    ns = report.parse_args(["--manifest-dir", str(root), "--platform", platform_name])
    for key, value in kw.items():
        setattr(ns, key, value)
    return ns


class ReportTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        make_manifests(self.root)

    def tearDown(self):
        self.tmp.cleanup()

    def test_snap_filters_runtimes_and_keeps_manifest_arguments(self):
        def runner(argv):
            if argv[0] == "snap":
                return SNAP_LIST
            if argv[0] == "user-installed-packages":
                return APT_CLI_JSON
            return "ii  git\n"
        text, complete = report.build_report(opts_for(self.root, "ubuntu", flatpak=False), runner=runner)
        self.assertIn("+ newapp", text)
        self.assertNotIn("core22", text)
        self.assertNotIn("gnome-42", text)
        self.assertIn("- terraform", text)
        self.assertNotIn("code --classic", text)
        self.assertTrue(complete)

    def test_apt_externally_installed_sesh_is_not_reported_missing(self):
        def runner(argv):
            if argv[0] == "dpkg-query":
                return "ii  git\nii  zsh\nii  extra\nrc  old\n"
            if argv[0] == "user-installed-packages":
                return APT_CLI_JSON
            return SNAP_LIST
        text, _ = report.build_report(opts_for(self.root, "ubuntu"), runner=runner)
        self.assertIn("+ extra", text)
        self.assertNotIn("- tmux-sesh", text)
        self.assertNotIn("+ old", text)

    def test_brew_keeps_options_and_reports_unsupported_lines(self):
        def runner(argv):
            return {
                ("brew", "list", "--formula"): "fd\n",
                ("brew", "leaves", "--installed-on-request"): "fd\nripgrep\n",
                ("brew", "list", "--cask"): "ghostty\nrectangle\n",
                ("brew", "tap"): "homebrew/core\nx/y\nnew/tap\n",
                ("code", "--list-extensions"): "foo.bar\nbaz.qux\n",
            }[tuple(a for a in argv if a != "-1")]
        text, complete = report.build_report(opts_for(self.root, "macos"), runner=runner)
        self.assertIn('+ brew "ripgrep"', text)
        self.assertIn('- brew "ffmpeg-full", link: true', text)
        self.assertIn('+ cask "rectangle"', text)
        self.assertIn('+ tap "new/tap"', text)
        self.assertIn('+ vscode "baz.qux"', text)
        self.assertIn('mas "Xcode"', text)
        self.assertTrue(complete)

    def test_dnf_image_packages_and_auto_updates_are_not_candidates(self):
        text, complete = report.build_report(
            opts_for(self.root, "fedora", flatpak=False), runner=dnf_runner
        )
        self.assertIn("+ fedy", text)
        self.assertIn("+ vim-enhanced", text)
        self.assertIn("+ extra-user", text)
        self.assertNotIn("+ kernel", text)
        self.assertNotIn("+ glibc", text)
        self.assertNotIn("+ fedora-release-workstation", text)
        self.assertNotIn("+ subversion", text)
        self.assertNotIn("+ gpu-firmware", text)
        self.assertTrue(complete)

    def test_dnf_tool_missing_is_unavailable_and_incomplete(self):
        def runner(argv):
            if argv[0] == "user-installed-packages":
                raise report.ToolMissing("nope")
            return dnf_runner(argv)

        text, complete = report.build_report(
            opts_for(self.root, "fedora", flatpak=False), runner=runner,
        )
        self.assertIn("[unavailable]", text)
        self.assertFalse(complete)

    def test_dnf_tool_warnings_are_surfaced(self):
        cli_json = json.dumps({
            "backend": "dnf",
            "packages": ["fedy"],
            "image_packages": [],
            "excluded_auto": [],
            "warnings": ["dnf history is unavailable; fell back to the rpm INSTALLTIME window"],
        })
        def runner(argv):
            if argv[0] == "user-installed-packages":
                return cli_json
            return dnf_runner(argv)

        text, complete = report.build_report(
            opts_for(self.root, "fedora", flatpak=False), runner=runner,
        )
        self.assertIn("user-installed-packages: dnf history is unavailable", text)
        self.assertTrue(complete)

    def test_failed_collector_never_fabricates_missing_packages(self):
        def runner(argv):
            raise report.CollectorError("boom")
        text, complete = report.build_report(opts_for(self.root, "macos"), runner=runner)
        self.assertNotIn("- brew", text)
        self.assertIn("[failed]", text)
        self.assertFalse(complete)

    def test_missing_tool_is_unavailable_and_incomplete(self):
        def runner(argv):
            raise report.ToolMissing("nope")
        text, complete = report.build_report(opts_for(self.root, "fedora"), runner=runner)
        self.assertIn("[unavailable]", text)
        self.assertFalse(complete)

    def test_flatpak_scope_and_disabled(self):
        def runner(argv):
            if argv[0] == "flatpak":
                return "a.B\tflathub\tsystem\nc.D\tflathub\tuser\nx.Y\tflathub\tsystem\n"
            if argv[0] == "user-installed-packages":
                return DNF_CLI_JSON
            return ""
        text, _ = report.build_report(opts_for(self.root, "fedora"), runner=runner)
        self.assertIn("+ flathub x.Y", text)
        self.assertIn("installed in user scope only", text)
        text, complete = report.build_report(opts_for(self.root, "fedora", flatpak=False), runner=runner)
        self.assertIn("[disabled]", text)
        self.assertTrue(complete)

    def test_manifests_unchanged_and_output_private(self):
        before = {p.name: p.read_bytes() for p in self.root.iterdir()}
        out = self.root / "state" / "report.txt"
        rc = report.main([
            "--manifest-dir", str(self.root), "--platform", "fedora",
            "--no-flatpak", "--output", str(out),
        ])
        self.assertIn(rc, (0, 2))
        self.assertEqual(out.stat().st_mode & 0o777, 0o600)
        after = {p.name: p.read_bytes() for p in self.root.iterdir() if p.is_file()}
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
