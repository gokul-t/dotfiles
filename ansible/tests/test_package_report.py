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

DNF_HISTORY_LIST = """ID Command line                            Date and time       Action(s) Altered
2 dnf5 --config /kiwi_dnf5.conf -y install  2025-04-09 12:06:00              286
1 dnf5 --config /kiwi_dnf5.conf -y install  2025-04-09 12:05:10             1722
3 dnf install fedy -y                        2025-08-24 17:36:20                2
4 dnf install vim-enhanced                   2025-12-22 18:01:59                4
"""

DNF_HISTORY_INFO_1 = """Transaction ID : 1
Begin time     : 2025-04-09 12:05:10
End time       : 2025-04-09 12:05:10
Status         : Ok
Packages altered:
  Action   Package                          Reason Repository
  Install  glibc-0:2.41-10.fc44.x86_64       Group  updates
  Install  kernel-core-0:7.0.0-1.fc44.x86_64  Group  updates
"""

DNF_HISTORY_INFO_2 = """Transaction ID : 2
Begin time     : 2025-04-09 12:06:00
End time       : 2025-04-09 12:06:00
Status         : Ok
Packages altered:
  Action   Package                          Reason Repository
  Install  fedora-release-workstation-0:44-18.noarch Group fedora
"""

DNF_HISTORY_INFO_3 = """Transaction ID : 3
Begin time     : 2025-08-24 17:36:20
Packages altered:
  Action   Package                          Reason Repository
  Install  fedy-0:5.1.18-1.fc44.noarch      User   copr
"""

DNF_HISTORY_INFO_4 = """Transaction ID : 4
Begin time     : 2025-12-22 18:01:59
Packages altered:
  Action   Package                          Reason Repository
  Install  vim-enhanced-2:9.2.1202-1.fc44.x86_64 User updates
"""

DNF_REPOQUERY = """glibc Group
kernel-core User
kernel-devel User
kernel-modules User
kernel-modules-core User
kernel-modules-extra User
kernel User
gpu-firmware Group
fedora-release-workstation Group
fedy User
vim-enhanced User
subversion Group
extra-user User
"""

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


def dnf_runner(argv, **overrides):
    mapping = {
        ("rpm", "-qa"): DNF_INSTALLED,
        ("dnf", "repoquery"): DNF_REPOQUERY,
        ("dnf", "history", "list"): DNF_HISTORY_LIST,
        ("dnf", "history", "info", "1"): DNF_HISTORY_INFO_1,
        ("dnf", "history", "info", "2"): DNF_HISTORY_INFO_2,
        ("dnf", "history", "info", "3"): DNF_HISTORY_INFO_3,
        ("dnf", "history", "info", "4"): DNF_HISTORY_INFO_4,
    }
    mapping.update(overrides)
    for size in range(len(argv), 1, -1):
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

    def test_dnf_history_unavailable_falls_back_to_install_time_window(self):
        rpm_qa_with_times = "glibc 100\nold-base 100\nextra-user 1000000\n"

        def runner(argv, **overrides):
            if tuple(argv) == ("rpm", "-qa", "--qf", "%{NAME} %{INSTALLTIME}\\n"):
                return rpm_qa_with_times
            if argv[:2] == ["dnf", "history"]:
                raise report.CollectorError("history unavailable")
            return dnf_runner(argv, **overrides)

        text, complete = report.build_report(
            opts_for(self.root, "fedora", flatpak=False), runner=runner
        )
        self.assertIn("+ extra-user", text)
        self.assertNotIn("+ glibc", text)
        self.assertNotIn("+ old-base", text)
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
