#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import time
from pathlib import Path

import yaml


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


def statvfs_capacity(path: Path) -> tuple[int, int]:
    st = os.statvfs(path)
    return st.f_blocks * st.f_frsize, (st.f_blocks - st.f_bfree) * st.f_frsize


def discover_dirs(root: Path, max_depth: int) -> list[Path]:
    paths = [root]

    for current, subdirs, _files in os.walk(root):
        current_path = Path(current)
        rel_depth = len(current_path.relative_to(root).parts)

        if rel_depth >= max_depth:
            subdirs[:] = []
            continue

        for subdir in subdirs:
            paths.append(current_path / subdir)

    return paths


def make_share(path: Path, vos: list[str], timestamp: int) -> dict:
    return {
        "numberoffiles": get_ceph_xattr(path, "ceph.dir.rfiles"),
        "path": [str(path)],
        "timestamp": timestamp,
        "totalsize": get_ceph_xattr(path, "ceph.quota.max_bytes"),
        "usedsize": get_ceph_xattr(path, "ceph.dir.rbytes"),
        "vos": vos,
    }


def build_report(config: dict) -> dict:
    now = int(time.time())
    service = config["service"]

    root = Path(service["root"])
    total_online, used_online = statvfs_capacity(root)

    storageshares = []
    seen_paths = set()

    for share in config["shares"]:
        vos = share["vos"]

        for item in share.get("include", []):
            base = Path(item["path"])

            if not base.exists():
                continue

            if "discover_depth" in item:
                paths = discover_dirs(base, int(item["discover_depth"]))
            else:
                paths = [base]

            for path in paths:
                path_string = str(path)
                if path_string in seen_paths:
                    continue

                seen_paths.add(path_string)
                storageshares.append(make_share(path, vos, now))

    endpoints = []
    all_share_names = [share["name"] for share in config["shares"]]

    for endpoint in config["endpoints"]:
        endpoints.append({
            "assignedshares": endpoint.get("assignedshares", all_share_names),
            "endpointurl": endpoint["endpointurl"],
            "interfacetype": endpoint["interfacetype"],
            "name": endpoint["name"],
        })

    return {
        "storageservice": {
            "implementation": service.get("implementation", "CephFS"),
            "implementationversion": service.get("implementationversion", "unknown"),
            "latestupdate": now,
            "name": service["name"],
            "storagecapacity": {
                "offline": {"totalsize": 0, "usedsize": 0},
                "online": {
                    "totalsize": total_online,
                    "usedsize": used_online,
                },
            },
            "storageendpoints": endpoints,
            "storageshares": storageshares,
        }
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--config",
        default="/etc/xrootd/storage-accounting.yaml",
    )
    args = parser.parse_args()

    with open(args.config, "r", encoding="utf-8") as handle:
        config = yaml.safe_load(handle)

    output = Path(config["service"]["output"])
    output.parent.mkdir(parents=True, exist_ok=True)

    report = build_report(config)

    tmp = output.with_suffix(output.suffix + ".tmp")
    tmp.write_text(json.dumps(report, indent=3, sort_keys=True) + "\n")
    os.replace(tmp, output)


if __name__ == "__main__":
    main()
