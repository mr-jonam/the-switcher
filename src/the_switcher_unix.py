#!/usr/bin/env python3
"""Resolver and profile editor used by The Switcher on Linux and macOS."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import sys
from typing import Any, Optional, Tuple


PROJECT_NAME = re.compile(r"^[A-Za-z0-9._-]+$")
PROFILE_START = "# >>> the-switcher >>>"
PROFILE_END = "# <<< the-switcher <<<"


class SwitcherError(Exception):
    """A configuration or resolution error safe to show to the user."""


def config_path() -> Path:
    configured = os.environ.get("SWITCHER_CONFIG")
    return Path(configured).expanduser() if configured else Path.home() / ".the-switcher" / "projects.json"


def load_config(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SwitcherError(f"Project map not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SwitcherError(f"Invalid JSON in {path}: line {exc.lineno}, column {exc.colno}") from exc

    projects = data.get("projects")
    if not isinstance(projects, dict) or not projects:
        raise SwitcherError("projects.json must contain a non-empty 'projects' object")

    for name, project in projects.items():
        if not isinstance(name, str) or not PROJECT_NAME.fullmatch(name):
            raise SwitcherError(f"Invalid project name: {name!r}")
        if not isinstance(project, dict) or not isinstance(project.get("codexHome"), str):
            raise SwitcherError(f"Project '{name}' must define codexHome")
        paths = project.get("paths", [])
        if not isinstance(paths, list) or any(not isinstance(item, str) for item in paths):
            raise SwitcherError(f"Project '{name}' paths must be an array of strings")
    return data


def expand_path(value: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(value))).resolve(strict=False)


def find_marker(start: Path) -> Optional[Tuple[str, Path]]:
    current = start.resolve(strict=False)
    if not current.is_dir():
        current = current.parent
    for directory in (current, *current.parents):
        marker = directory / ".codexproject"
        if marker.is_file():
            name = next(
                (
                    line.strip()
                    for line in marker.read_text(encoding="utf-8").splitlines()
                    if line.strip() and not line.lstrip().startswith("#")
                ),
                "",
            )
            if not PROJECT_NAME.fullmatch(name):
                raise SwitcherError(f"Invalid project name in {marker}")
            return name, marker
    return None


def is_within(current: Path, root: Path) -> bool:
    return current == root or root in current.parents


def resolve_project(data: dict[str, Any], explicit: Optional[str], current_path: Path) -> dict[str, str]:
    projects = data["projects"]
    if explicit:
        if explicit not in projects:
            raise SwitcherError(f"Unknown project: {explicit}")
        name, resolved_by = explicit, "explicit"
    else:
        marker = find_marker(current_path)
        if marker:
            name, marker_path = marker
            if name not in projects:
                raise SwitcherError(f"Marker {marker_path} names an unknown project: {name}")
            resolved_by = f"marker:{marker_path}"
        else:
            current = current_path.resolve(strict=False)
            matches: list[tuple[int, str, Path]] = []
            for candidate, project in projects.items():
                for raw_path in project.get("paths", []):
                    root = expand_path(raw_path)
                    if is_within(current, root):
                        matches.append((len(root.parts), candidate, root))
            if matches:
                _, name, matched_path = max(matches, key=lambda item: item[0])
                resolved_by = f"path:{matched_path}"
            else:
                name = data.get("default")
                if not isinstance(name, str) or name not in projects:
                    raise SwitcherError("The configured default project does not exist")
                resolved_by = "default"

    project = projects[name]
    return {
        "name": name,
        "codexHome": str(expand_path(project["codexHome"])),
        "apiKeyName": str(project.get("apiKeyName", "(not labelled)")),
        "resolvedBy": resolved_by,
    }


def safe_record(values: list[str]) -> str:
    if any("|" in value or "\n" in value or "\r" in value for value in values):
        raise SwitcherError("Project output fields cannot contain pipes or newlines")
    return "|".join(values)


def strip_profile_block(content: str) -> str:
    complete_block = re.compile(
        rf"(?ms)^{re.escape(PROFILE_START)}\n.*?^{re.escape(PROFILE_END)}\n?"
    )
    return complete_block.sub("", content).rstrip()


def edit_profile(profile: Path, script: Path, helper: Path, remove: bool) -> None:
    content = profile.read_text(encoding="utf-8") if profile.exists() else ""
    content = strip_profile_block(content)
    if not remove:
        block = "\n".join(
            [
                PROFILE_START,
                f"export SWITCHER_HELPER={shlex.quote(str(helper))}",
                f". {shlex.quote(str(script))}",
                PROFILE_END,
            ]
        )
        content = f"{content}\n\n{block}" if content else block
    profile.parent.mkdir(parents=True, exist_ok=True)
    profile.write_text(content.rstrip() + ("\n" if content else ""), encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="The Switcher Unix helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve_parser = subparsers.add_parser("resolve")
    resolve_parser.add_argument("--name")
    resolve_parser.add_argument("--path", default=os.getcwd())
    resolve_parser.add_argument("--config", type=Path)

    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("--config", type=Path)

    edit_parser = subparsers.add_parser("edit-profile")
    edit_parser.add_argument("--profile", type=Path, required=True)
    edit_parser.add_argument("--script", type=Path, required=True)
    edit_parser.add_argument("--helper", type=Path, required=True)
    edit_parser.add_argument("--remove", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "edit-profile":
            edit_profile(args.profile.expanduser(), args.script.expanduser(), args.helper.expanduser(), args.remove)
            return 0

        path = args.config.expanduser() if args.config else config_path()
        data = load_config(path)
        if args.command == "list":
            for name in sorted(data["projects"]):
                print(name)
            return 0

        resolved = resolve_project(data, args.name, Path(args.path).expanduser())
        print(safe_record([resolved["name"], resolved["codexHome"], resolved["apiKeyName"], resolved["resolvedBy"]]))
        return 0
    except (OSError, SwitcherError) as exc:
        print(f"the-switcher: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
