#!/usr/bin/env python3

import argparse
import json
import os
import pwd
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml


SCRIPT_NAME = "publish-nfs-storage-accounting"
SCHEMA_VERSION = 1


def run_xfs_quota(quota_mount: Path, quota_type: str) -> str:
    flag = {"user": "-u", "project": "-p"}[quota_type]
    cmd = ["xfs_quota", "-x", "-c", f"report -b {flag}", str(quota_mount)]
    result = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.stdout


def parse_bytes(value: str) -> int:
    if value in ("-", "0"):
        return 0
    return int(value) * 1024 # xfs_quota reports in KiB


def resolve_user_name(name: str) -> str:
    if name.startswith("#") and name[1:].isdigit():
        try:
            return pwd.getpwuid(int(name[1:])).pw_name
        except KeyError:
            return name
    return name


def get_top_level_paths_for_user(quota_mount: Path, user_name: str) -> list[Path]:
    try:
        user_info = pwd.getpwnam(user_name)
    except KeyError:
        return []

    paths = []
    for child in quota_mount.iterdir():
        try:
            if child.is_dir() and child.stat().st_uid == user_info.pw_uid:
                paths.append(child)
        except (FileNotFoundError, PermissionError):
            continue

    return sorted(paths)


def get_named_top_level_path(quota_mount: Path, entity_name: str) -> Path:
    candidate = quota_mount / entity_name
    if candidate.is_dir():
        return candidate
    return None


def public_root_for(quota_mount: Path, share: dict) -> str:
    if "path" in share:
        return share["path"].rstrip("/")
    return "/" + str(quota_mount).removeprefix("/exports/").strip("/")


def public_path_for(quota_mount: Path, fs_path: Path, share: dict) -> str:
    root = public_root_for(quota_mount, share)
    relative = fs_path.relative_to(quota_mount)
    return f"{root}/{relative}"


def parse_xfs_report(
    output: str,
    share: dict,
    quota_type: str,
    timestamp: int,
    updated_at: str,
    updated_date: str,
) -> list[dict]:
    records = []
    quota_mount = Path(share["quota_mount"])
    share_name = share["name"]

    for line in output.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith(("User quota", "Project quota", "Filesystem", "Blocks", "User ID", "Project ID")):
            continue
        if line.startswith("-"):
            continue

        parts = re.split(r"\s+", line)
        if len(parts) < 4:
            continue

        raw_name = parts[0]

        try:
            used = parse_bytes(parts[1])
            soft = parse_bytes(parts[2])
            hard = parse_bytes(parts[3])
        except ValueError:
            continue

        grace = None
        if len(parts) >= 5 and parts[4] not in ("-", "0", "00:00"):
            grace = parts[4]

        is_numeric_id = raw_name.startswith("#") and raw_name[1:].isdigit()
        numeric_id = int(raw_name[1:]) if is_numeric_id else None

        if quota_type == "user":
            entity_name = resolve_user_name(raw_name)
            entity_paths = get_top_level_paths_for_user(quota_mount, entity_name)
        else:
            entity_name = raw_name.removeprefix("#")
            named_path = get_named_top_level_path(quota_mount, entity_name)
            entity_paths = [named_path] if named_path else []

        public_paths = [public_path_for(quota_mount, path, share) for path in entity_paths]

        usage_file_path = None
        named_path = get_named_top_level_path(quota_mount, entity_name)
        if named_path is not None:
            usage_file_path = str(named_path)

        soft_reached = soft > 0 and used >= soft
        hard_reached = hard > 0 and used >= hard

        records.append({
            "generator": SCRIPT_NAME,
            "schema_version": SCHEMA_VERSION,
            "share": share_name,
            "quota_type": quota_type,
            "name": entity_name,
            "raw_name": raw_name,
            "id": numeric_id,
            "paths": public_paths,
            "filesystem_paths": [str(path) for path in entity_paths],
            "path": public_paths[0] if public_paths else None,
            "filesystem_path": str(entity_paths[0]) if entity_paths else None,
            "usage_file_path": usage_file_path,
            "used_bytes": used,
            "soft_limit_bytes": soft,
            "hard_limit_bytes": hard,
            "soft_limit_reached": soft_reached,
            "hard_limit_reached": hard_reached,
            "grace": grace,
            "orphaned": is_numeric_id or len(entity_paths) == 0,
            "timestamp": timestamp,
            "updated_at": updated_at,
            "updated_date": updated_date,
        })

    return records


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=3, sort_keys=True) + "\n")
    os.replace(tmp, path)


def human_bytes(value: int) -> str:
    units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    size = float(value)

    for unit in units:
        if size < 1024 or unit == units[-1]:
            return f"{size:.1f} {unit}"
        size /= 1024

    return f"{value} B"


def usage_md_for_records(path: Path, records: list[dict], updated_at: str) -> str:
    lines = [
        "# Storage usage",
        "",
        f"Last updated: {updated_at}",
        "",
        f"Path: `{path}`",
        "",
    ]

    if any(r["hard_limit_reached"] for r in records):
        lines += [
            "# WARNING: hard quota limit reached",
            "",
            "Writes may already be blocked.",
            "",
        ]
    elif any(r["soft_limit_reached"] for r in records):
        lines += [
            "# WARNING: soft quota limit reached",
            "",
            "The soft quota limit has been reached. Once the grace period expires, writes may be blocked until usage is reduced below the soft limit.",
            "",
        ]

    for record in records:
        lines += [
            f"## {record['quota_type'].title()} quota",
            "",
            f"Name: `{record['name']}`",
            "",
            f"Used: {human_bytes(record['used_bytes'])}",
            f"Soft limit: {human_bytes(record['soft_limit_bytes'])}",
            f"Hard limit: {human_bytes(record['hard_limit_bytes'])}",
            "",
        ]

        if record["hard_limit_reached"]:
            lines += ["Status: **HARD LIMIT REACHED**", ""]
        elif record["soft_limit_reached"]:
            lines += ["Status: **SOFT LIMIT REACHED**"]
            if record["grace"]:
                lines.append(f"Grace period remaining: **{record['grace']}**")
            lines.append("")
        else:
            lines += ["Status: OK", ""]

    return "\n".join(lines).rstrip() + "\n"


def write_usage_files(records: list[dict], updated_at: str) -> None:
    by_path: dict[Path, list[dict]] = {}

    for record in records:
        fs_path_value = record.get("usage_file_path")
        if not fs_path_value:
            continue

        fs_path = Path(fs_path_value)
        if not fs_path.is_dir():
            continue

        by_path.setdefault(fs_path, []).append(record)

    for path, path_records in by_path.items():
        (path / "USAGE.md").write_text(usage_md_for_records(path, path_records, updated_at))


def build_metadata(timestamp: int, updated_at: str, updated_date: str) -> dict:
    return {
        "generator": SCRIPT_NAME,
        "schema_version": SCHEMA_VERSION,
        "timestamp": timestamp,
        "updated_at": updated_at,
        "updated_date": updated_date,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", default="/etc/dice/nfs-storage-accounting.yaml")
    args = parser.parse_args()

    config = yaml.safe_load(Path(args.config).read_text())
    output_root = Path(config.get("output_root", "/software/dice/accounting/nfs"))

    now = int(time.time())
    updated_dt = datetime.now(timezone.utc)
    updated_at = updated_dt.strftime("%Y-%m-%d %H:%M:%S UTC")
    updated_date = updated_dt.strftime("%Y.%m.%d")

    all_records = []
    orphaned = []

    for share in config["shares"]:
        share_records = []

        for quota_type in share.get("quota_types", ["user"]):
            output = run_xfs_quota(Path(share["quota_mount"]), quota_type)
            share_records.extend(parse_xfs_report(output, share, quota_type, now, updated_at, updated_date))

        write_usage_files(share_records, updated_at)

        write_json(output_root / share["name"] / "summary.json", {
            **build_metadata(now, updated_at, updated_date),
            "share": share["name"],
            "quota_mount": share["quota_mount"],
            "records": share_records,
        })

        all_records.extend(share_records)
        orphaned.extend([record for record in share_records if record["orphaned"]])

    write_json(output_root / "summary.json", {
        **build_metadata(now, updated_at, updated_date),
        "records": all_records,
    })

    write_json(output_root / "orphaned.json", {
        **build_metadata(now, updated_at, updated_date),
        "records": orphaned,
    })

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        print(error.stderr, file=sys.stderr)
        raise SystemExit(error.returncode)
