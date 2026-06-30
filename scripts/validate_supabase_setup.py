"""Validate CollectIQ AI Supabase setup files.

Default mode performs local static validation of committed SQL files. Live mode
can run the read-only readiness SQL through psql when SUPABASE_DB_URL is set.
No secrets are stored by this script.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS_DIR = ROOT / "supabase" / "migrations"
CHECKS_SQL = ROOT / "supabase" / "setup" / "production_readiness_checks.sql"

EXPECTED_TABLES = [
    "users",
    "collections",
    "collectibles",
    "scan_history",
    "pricing_snapshots",
    "favorites",
    "wishlist",
]

EXPECTED_PUBLIC_POLICIES = [
    "Users can read own profile",
    "Users can insert own profile",
    "Users can update own profile",
    "Users can delete own profile",
    "Users can read own collections",
    "Users can insert own collections",
    "Users can update own collections",
    "Users can delete own collections",
    "Users can read own collectibles",
    "Users can insert own collectibles",
    "Users can update own collectibles",
    "Users can delete own collectibles",
    "Users can read own scan history",
    "Users can insert own scan history",
    "Users can update own scan history",
    "Users can delete own scan history",
    "Users can read own pricing snapshots",
    "Users can insert own pricing snapshots",
    "Users can update own pricing snapshots",
    "Users can delete own pricing snapshots",
    "Users can read own favorites",
    "Users can insert own favorites",
    "Users can delete own favorites",
    "Users can read own wishlist",
    "Users can insert own wishlist",
    "Users can update own wishlist",
    "Users can delete own wishlist",
]

EXPECTED_STORAGE_POLICIES = [
    "Users can read own collectible images",
    "Users can upload own collectible images",
    "Users can update own collectible images",
    "Users can delete own collectible images",
]


@dataclass(frozen=True)
class CheckResult:
    name: str
    passed: bool
    details: str


def _read_sql() -> str:
    sql_files = sorted(MIGRATIONS_DIR.glob("*.sql"))
    return "\n".join(path.read_text(encoding="utf-8") for path in sql_files)


def validate_local_sql() -> list[CheckResult]:
    sql = _read_sql()
    normalized = sql.lower()
    results: list[CheckResult] = []

    for table in EXPECTED_TABLES:
        results.append(
            CheckResult(
                name=f"table:{table}",
                passed=f"create table if not exists public.{table}" in normalized,
                details=f"public.{table} exists in migrations",
            )
        )
        results.append(
            CheckResult(
                name=f"rls:{table}",
                passed=f"alter table public.{table} enable row level security"
                in normalized,
                details=f"RLS enabled for public.{table}",
            )
        )

    for policy in EXPECTED_PUBLIC_POLICIES:
        results.append(
            CheckResult(
                name=f"policy:{policy}",
                passed=f'create policy "{policy.lower()}"' in normalized,
                details="owner-scoped public table policy exists",
            )
        )

    for policy in EXPECTED_STORAGE_POLICIES:
        results.append(
            CheckResult(
                name=f"storage-policy:{policy}",
                passed=f'create policy "{policy.lower()}"' in normalized,
                details="user-folder storage policy exists",
            )
        )

    results.extend(
        [
            CheckResult(
                name="storage-bucket:collectible-images",
                passed="values ('collectible-images', 'collectible-images', false)"
                in normalized,
                details="private storage bucket setup exists",
            ),
            CheckResult(
                name="storage-path:user-folder",
                passed="(storage.foldername(name))[1] = auth.uid()::text"
                in normalized,
                details="{userId}/{collectibleCloudId}/image.ext policy exists",
            ),
            CheckResult(
                name="collectibles:soft-delete",
                passed="add column if not exists deleted_at timestamptz"
                in normalized,
                details="soft delete columns are present",
            ),
            CheckResult(
                name="collectibles:sync-status",
                passed="add column if not exists sync_status text not null"
                in normalized,
                details="sync status columns are present",
            ),
            CheckResult(
                name="collectibles:user-id-owner",
                passed="user_id uuid not null references public.users(id)"
                in normalized
                and "with check (auth.uid() = user_id)" in normalized,
                details="rows are tied to auth.uid() through user_id",
            ),
            CheckResult(
                name="readiness-sql:file",
                passed=CHECKS_SQL.exists(),
                details=str(CHECKS_SQL.relative_to(ROOT)),
            ),
        ]
    )

    return results


def print_results(results: list[CheckResult]) -> int:
    failures = [result for result in results if not result.passed]
    for result in results:
        prefix = "PASS" if result.passed else "FAIL"
        print(f"[{prefix}] {result.name} - {result.details}")

    print()
    print(f"Checks: {len(results)}")
    print(f"Passed: {len(results) - len(failures)}")
    print(f"Failed: {len(failures)}")
    return 1 if failures else 0


def run_live_checks(database_url: str) -> int:
    if not CHECKS_SQL.exists():
        print(f"Missing readiness SQL: {CHECKS_SQL}", file=sys.stderr)
        return 1

    command = [
        "psql",
        database_url,
        "--set",
        "ON_ERROR_STOP=1",
        "--file",
        str(CHECKS_SQL),
    ]
    print("Running live read-only Supabase readiness checks with psql...")
    print("Database URL is read from environment and is not printed.")
    completed = subprocess.run(command, check=False)
    return completed.returncode


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate CollectIQ AI Supabase setup.",
    )
    parser.add_argument(
        "--live",
        action="store_true",
        help="Run read-only live checks with psql using SUPABASE_DB_URL.",
    )
    args = parser.parse_args()

    exit_code = print_results(validate_local_sql())
    if exit_code != 0:
        return exit_code

    if args.live:
        database_url = os.environ.get("SUPABASE_DB_URL", "").strip()
        if not database_url:
            print(
                "SUPABASE_DB_URL is required for --live checks.",
                file=sys.stderr,
            )
            return 1
        return run_live_checks(database_url)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
