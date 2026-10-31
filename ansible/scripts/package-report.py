#!/usr/bin/env python3
"""Read-only report of drift between installed packages and the repo manifests.

Never installs, removes, or edits anything. Exit status: 0 when every enabled
source was compared, 2 when a source was unavailable or failed.
"""
import argparse
import fcntl
import os
import platform
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

PACKAGES_DIR = Path(__file__).resolve().parents[1] / "packages"
TIMEOUT_SECONDS = 120
BREW_DEFAULT_TAPS = {"homebrew/core", "homebrew/cask"}
BREW_KINDS = ("tap", "brew", "cask", "vscode")
SNAP_RUNTIME_PREFIXES = ("gnome-", "gtk-common-themes", "mesa-", "kf5-", "kf6-")


class CollectorError(Exception):
    status = "failed"


class ToolMissing(CollectorError):
    status = "unavailable"


@dataclass
class Result:
    title: str
    status: str = "ok"
    detail: str = ""
    candidates: list = field(default_factory=list)
    missing: list = field(default_factory=list)
    notes: list = field(default_factory=list)


def run(argv):
    try:
        proc = subprocess.run(
            argv, capture_output=True, text=True, timeout=TIMEOUT_SECONDS, check=False
        )
    except FileNotFoundError:
        raise ToolMissing(f"{argv[0]} not found") from None
    except subprocess.TimeoutExpired:
        raise CollectorError(f"{' '.join(argv)} timed out") from None
    if proc.returncode != 0:
        raise CollectorError(
            f"{' '.join(argv)} exited {proc.returncode}: {proc.stderr.strip()[:200]}"
        )
    return proc.stdout


def lines(text):
    return [line.strip() for line in text.splitlines() if line.strip()]


def read_text_manifest(path):
    return [line for line in lines(Path(path).read_text()) if not line.startswith("#")]


def read_brewfile(path):
    entries = {kind: {} for kind in BREW_KINDS}
    unsupported = []
    pattern = re.compile(r'^(tap|brew|cask|vscode)\s+"([^"]+)"')
    for line in lines(Path(path).read_text()):
        if line.startswith("#"):
            continue
        match = pattern.match(line)
        if match:
            entries[match.group(1)][match.group(2)] = line
        else:
            unsupported.append(line)
    return entries, unsupported


def compare(title, declared, installed, explicit, skip, suggest):
    """declared: normalized name -> manifest line; the rest hold normalized names."""
    skip = set(skip)
    result = Result(title)
    for name in sorted(explicit - set(declared) - skip):
        result.candidates.append(suggest(name))
    for name, entry in sorted(declared.items()):
        if name not in installed and name not in skip:
            result.missing.append(entry)
    return result


def guarded(title, func):
    try:
        return func()
    except CollectorError as error:
        return Result(title, status=error.status, detail=str(error))


def brew_name(name):
    return name.split("/")[-1].lower()


def check_homebrew(opts, runner):
    entries, unsupported = read_brewfile(opts.brewfile)
    skip = set(opts.skip)

    def formulae():
        installed = {brew_name(n) for n in lines(runner(["brew", "list", "--formula", "-1"]))}
        explicit = {
            brew_name(n) for n in lines(runner(["brew", "leaves", "--installed-on-request"]))
        }
        declared = {brew_name(n): line for n, line in entries["brew"].items()}
        return compare(
            "Homebrew formulae", declared, installed, explicit, skip, lambda n: f'brew "{n}"'
        )

    def casks():
        installed = {brew_name(n) for n in lines(runner(["brew", "list", "--cask", "-1"]))}
        declared = {brew_name(n): line for n, line in entries["cask"].items()}
        return compare(
            "Homebrew casks", declared, installed, installed, skip, lambda n: f'cask "{n}"'
        )

    def taps():
        installed = {n.lower() for n in lines(runner(["brew", "tap"]))} - BREW_DEFAULT_TAPS
        declared = {n.lower(): line for n, line in entries["tap"].items()}
        return compare(
            "Homebrew taps", declared, installed | BREW_DEFAULT_TAPS, installed, skip,
            lambda n: f'tap "{n}"',
        )

    def vscode():
        installed = {n.lower() for n in lines(runner(["code", "--list-extensions"]))}
        declared = {n.lower(): line for n, line in entries["vscode"].items()}
        return compare(
            "VS Code extensions (Brewfile)", declared, installed, installed, skip,
            lambda n: f'vscode "{n}"',
        )

    results = [
        guarded("Homebrew formulae", formulae),
        guarded("Homebrew casks", casks),
        guarded("Homebrew taps", taps),
        guarded("VS Code extensions (Brewfile)", vscode),
    ]
    if unsupported:
        results[0].notes.append(
            "Unsupported Brewfile lines were not compared: " + "; ".join(unsupported)
        )
    return results


def check_dnf(opts, runner):
    declared = {n: n for n in read_text_manifest(opts.manifest_dir / "dnf-packages.txt")}

    def native():
        installed = set(lines(runner(["rpm", "-qa", "--qf", "%{NAME}\\n"])))
        explicit = set(
            lines(runner(["dnf", "repoquery", "--userinstalled", "--qf", "%{name}\\n"]))
        )
        return compare("DNF packages", declared, installed, explicit, opts.skip, str)

    return [guarded("DNF packages", native)] + check_flatpak(opts, runner)


def check_apt(opts, runner):
    declared = {n: n for n in read_text_manifest(opts.manifest_dir / "ubuntu-packages.txt")}
    skip = set(opts.skip) | {"tmux-sesh"}

    def native():
        installed = set()
        query = ["dpkg-query", "-W", "-f", "${db:Status-Abbrev} ${Package}\\n"]
        for line in lines(runner(query)):
            status, _, name = line.partition(" ")
            if status.startswith("ii"):
                installed.add(name.strip().split(":")[0])
        manual = {n.split(":")[0] for n in lines(runner(["apt-mark", "showmanual"]))}
        return compare("APT packages", declared, installed, manual & installed, skip, str)

    result = guarded("APT packages", native)
    result.notes.append(
        "tmux-sesh is installed from a release archive and is not checked. "
        "Manual APT packages can include defaults from the OS image."
    )
    return [result] + check_snap(opts, runner)


def check_flatpak(opts, runner):
    title = "Flatpak apps"
    if not opts.flatpak:
        return [Result(title, status="disabled", detail="Flatpak disabled")]
    declared = {}
    for line in read_text_manifest(opts.manifest_dir / "flatpak-packages.txt"):
        parts = line.split()
        if len(parts) >= 2:
            declared[parts[1]] = line

    def collect():
        system, user, origins = set(), set(), {}
        query = ["flatpak", "list", "--app", "--columns=application,origin,installation"]
        for line in lines(runner(query)):
            cols = line.split("\t") if "\t" in line else line.split()
            if len(cols) < 3:
                continue
            app, origin, scope = cols[:3]
            (system if scope == "system" else user).add(app)
            origins[app] = origin
        result = compare(
            title, declared, system, system | user, opts.skip,
            lambda n: f"{origins.get(n, 'flathub')} {n}",
        )
        for entry in result.missing:
            if entry.split()[1] in user:
                result.notes.append(f"{entry}: installed in user scope only")
        return result

    return [guarded(title, collect)]


def check_snap(opts, runner):
    title = "Snap apps"
    if not opts.snap:
        return [Result(title, status="disabled", detail="Snap disabled")]
    declared = {}
    for line in read_text_manifest(opts.manifest_dir / "ubuntu-snap-packages.txt"):
        declared[line.split()[0]] = line

    def collect():
        installed, apps = set(), set()
        for line in lines(runner(["snap", "list", "--unicode=never"]))[1:]:
            cols = line.split()
            name, notes = cols[0], cols[-1].split(",")
            installed.add(name)
            is_runtime = (
                name == "snapd"
                or name.startswith(SNAP_RUNTIME_PREFIXES)
                or "base" in notes
                or "snapd" in notes
            )
            if not is_runtime:
                apps.add(name)
        result = compare(title, declared, installed, apps, opts.skip, str)
        result.notes.append("Add --classic yourself where required; confinement is not inferred.")
        return result

    return [guarded(title, collect)]


def detect_platform():
    if platform.system() == "Darwin":
        return "macos"
    try:
        info = dict(
            line.split("=", 1)
            for line in Path("/etc/os-release").read_text().splitlines()
            if "=" in line
        )
    except OSError:
        return "unknown"
    return info.get("ID", "unknown").strip('"').lower()


CHECKS = {"macos": check_homebrew, "fedora": check_dnf, "ubuntu": check_apt}


def build_report(opts, runner=run):
    if opts.platform not in CHECKS:
        raise SystemExit(f"Unsupported platform: {opts.platform}")
    opts.skip = list(opts.skip)
    if platform.machine() not in ("x86_64", "AMD64"):
        opts.skip.append("google-chrome-stable")
    if not opts.flatpak:
        opts.skip.append("flatpak")
    results = CHECKS[opts.platform](opts, runner)
    out = [
        f"Package drift report ({opts.platform}) - {datetime.now().astimezone():%Y-%m-%d %H:%M %Z}",
        "Read-only: nothing was installed, removed, or edited.",
        "",
    ]
    for r in results:
        out.append(f"== {r.title} [{r.status}]")
        if r.detail:
            out.append(f"   {r.detail}")
        if r.candidates:
            out.append("   Installed but not in the manifest (review, then add if wanted):")
            out += [f"     + {c}" for c in r.candidates]
        if r.missing:
            out.append("   In the manifest but not installed here (may be intentional):")
            out += [f"     - {m}" for m in r.missing]
        if r.status == "ok" and not (r.candidates or r.missing):
            out.append("   No drift.")
        out += [f"   note: {n}" for n in r.notes]
        out.append("")
    complete = all(r.status in ("ok", "disabled") for r in results)
    if not complete:
        out.append("Some sources could not be compared; their results are incomplete.")
    return "\n".join(out) + "\n", complete


def write_private(path, text):
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    with os.fdopen(fd, "w") as handle:
        handle.write(text)
    os.replace(tmp, path)


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", default=None, choices=sorted(CHECKS))
    parser.add_argument("--output", type=Path, help="write the report here instead of stdout")
    parser.add_argument("--skip", action="append", default=[], help="package to ignore (repeatable)")
    parser.add_argument("--no-flatpak", dest="flatpak", action="store_false")
    parser.add_argument("--no-snap", dest="snap", action="store_false")
    parser.add_argument("--manifest-dir", type=Path, default=PACKAGES_DIR)
    opts = parser.parse_args(argv)
    opts.platform = opts.platform or detect_platform()
    opts.brewfile = opts.manifest_dir / "Brewfile"
    return opts


def main(argv=None):
    opts = parse_args(argv)
    if opts.output:
        opts.output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        lock = open(opts.output.parent / ".package-report.lock", "w")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return 0
    text, complete = build_report(opts)
    if opts.output:
        write_private(opts.output, text)
    else:
        sys.stdout.write(text)
    return 0 if complete else 2


if __name__ == "__main__":
    sys.exit(main())
