import importlib.util
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
            return SNAP_LIST if argv[0] == "snap" else "ii  git\n"
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
            if argv[0] == "apt-mark":
                return "git\nzsh\nextra\nold\n"
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
