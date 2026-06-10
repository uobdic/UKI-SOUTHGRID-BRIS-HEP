#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml


SCRIPT_NAME = "publish-cephfs-storage-accounting"
SCHEMA_VERSION = 1


def get_ceph_xattr(path: Path, attr: str) -> int:
    try:
        result = subprocess.run(
            ["getfattr", "-n", attr, "--only-values", str(path)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return int(result.stdout.strip())
    except (subprocess.CalledProcessError, ValueError):
        return 0


def human_bytes(value: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    size = float(value)

    for unit in units:
        if size < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(size)} {unit}"
            return f"{size:.1f} {unit}".replace(".0 ", " ")
        size /= 1024

    return f"{value} B"


def rel_depth(root: Path, path: Path) -> int:
    if root == path:
        return 0
    return len(path.relative_to(root).parts)


def list_children(path: Path) -> list[Path]:
    try:
        return sorted(path.iterdir(), key=lambda p: p.name.lower())
    except (PermissionError, FileNotFoundError, NotADirectoryError):
        return []


def make_entry(path: Path) -> dict:
    is_dir = path.is_dir()

    return {
        "name": path.name,
        "path": str(path),
        "type": "directory" if is_dir else "file",
        "used_bytes": get_ceph_xattr(path, "ceph.dir.rbytes")
        if is_dir
        else path.stat().st_size,
        "number_of_files": get_ceph_xattr(path, "ceph.dir.rfiles") if is_dir else 1,
    }


def usage_markdown(parent: Path, entries: list[dict], updated_at: str) -> str:
    lines = [
        "# Storage usage",
        "",
        f"Last updated: {updated_at}",
        "",
        f"Path: `{parent}`",
        "",
        "## Immediate contents",
        "",
    ]

    if not entries:
        lines.append("_No entries found, or directory could not be read._")
        return "\n".join(lines) + "\n"

    for entry in sorted(entries, key=lambda e: e["used_bytes"], reverse=True):
        lines.append(
            f"- `{entry['name']}` "
            f"({human_bytes(entry['used_bytes'])}, {entry['number_of_files']} files)"
        )

    return "\n".join(lines) + "\n"


def write_text_atomic(path: Path, content: str) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.replace(tmp, path)


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=3, sort_keys=True) + "\n")
    os.replace(tmp, path)


def discover_summary_parents(root: Path, max_child_depth: int) -> list[Path]:
    parents = []

    if not root.exists():
        return parents

    max_parent_depth = max_child_depth - 1

    for current, dirnames, _filenames in os.walk(root, topdown=True, followlinks=False):
        current_path = Path(current)
        depth = rel_depth(root, current_path)

        if depth <= max_parent_depth:
            parents.append(current_path)

        if depth >= max_parent_depth:
            dirnames[:] = []

    return sorted(set(parents))


def build_summary_for_parent(
    parent: Path, updated_at: str, timestamp: int, updated_date: str
) -> dict:
    entries = []

    for child in list_children(parent):
        try:
            entries.append(make_entry(child))
        except (FileNotFoundError, PermissionError, OSError):
            entries.append(
                {
                    "name": child.name,
                    "path": str(child),
                    "type": "unknown",
                    "used_bytes": 0,
                    "number_of_files": 0,
                    "error": "could not read entry",
                }
            )

    total_used = sum(entry["used_bytes"] for entry in entries)
    total_files = sum(entry["number_of_files"] for entry in entries)

    return {
        "generator": SCRIPT_NAME,
        "schema_version": SCHEMA_VERSION,
        "timestamp": timestamp,
        "updated_at": updated_at,
        "updated_date": updated_date,
        "path": str(parent),
        "used_bytes": total_used,
        "number_of_files": total_files,
        "entries": entries,
    }


def safe_output_name(path: Path) -> str:
    return str(path).strip("/").replace("/", "__") or "root"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c", "--config", default="/etc/dice/cephfs-storage-accounting.yaml"
    )
    args = parser.parse_args()

    config = yaml.safe_load(Path(args.config).read_text())
    output_root = Path(config.get("output_root", "/software/dice/accounting/cephfs"))

    now = int(time.time())
    updated_dt = datetime.now(timezone.utc)
    updated_at = updated_dt.strftime("%Y-%m-%d %H:%M:%S UTC")
    updated_date = updated_dt.strftime("%Y.%m.%d")

    all_summaries = []

    for include in config["includes"]:
        root = Path(include["path"])
        max_child_depth = int(include.get("max_child_depth", 1))

        include_summaries = []

        for parent in discover_summary_parents(root, max_child_depth):
            summary = build_summary_for_parent(parent, updated_at, now, updated_date)

            try:
                write_text_atomic(
                    parent / "USAGE.md",
                    usage_markdown(parent, summary["entries"], updated_at),
                )
            except (PermissionError, OSError):
                summary["usage_md_error"] = "could not write USAGE.md"

            include_summaries.append(summary)
            all_summaries.append(summary)

            write_json(
                output_root / include["name"] / f"{safe_output_name(parent)}.json",
                summary,
            )

        write_json(
            output_root / include["name"] / "summary.json",
            {
                "generator": SCRIPT_NAME,
                "schema_version": SCHEMA_VERSION,
                "timestamp": now,
                "updated_at": updated_at,
                "updated_date": updated_date,
                "name": include["name"],
                "path": str(root),
                "max_child_depth": max_child_depth,
                "summaries": include_summaries,
            },
        )

    write_json(
        output_root / "summary.json",
        {
            "generator": SCRIPT_NAME,
            "schema_version": SCHEMA_VERSION,
            "timestamp": now,
            "updated_at": updated_at,
            "updated_date": updated_date,
            "summaries": all_summaries,
        },
    )

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"{SCRIPT_NAME}: {error}", file=sys.stderr)
        raise SystemExit(1)
