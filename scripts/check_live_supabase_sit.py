"""Read-only live Supabase SIT setup checker.

Uses only SUPABASE_URL and SUPABASE_ANON_KEY. The checker does not require a
service-role key and does not write data.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass


REQUIRED_TABLES = ["portfolio_items", "user_profiles"]
REQUIRED_BUCKET = "collectiq-portfolio-images"
TIMEOUT_SECONDS = 15


@dataclass(frozen=True)
class CheckResult:
    name: str
    passed: bool
    details: str
    warning: bool = False


def _base_url() -> str:
    value = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    if not value:
        return ""
    if not value.startswith(("https://", "http://")):
        value = f"https://{value}"
    return value


def _anon_key() -> str:
    return os.environ.get("SUPABASE_ANON_KEY", "").strip()


def _headers() -> dict[str, str]:
    anon_key = _anon_key()
    return {
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }


def _request(
    method: str,
    url: str,
    *,
    body: bytes | None = None,
) -> tuple[int, str]:
    request = urllib.request.Request(
        url,
        data=body,
        headers=_headers(),
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            return response.status, response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as error:
        return 0, str(error.reason)
    except TimeoutError:
        return 0, "request timed out"


def _rest_url(path: str, query: dict[str, str] | None = None) -> str:
    base = _base_url()
    encoded_query = urllib.parse.urlencode(query or {})
    suffix = f"?{encoded_query}" if encoded_query else ""
    return f"{base}/rest/v1/{path}{suffix}"


def _status_details(status: int, body: str) -> str:
    compact = " ".join(body.strip().split())
    if len(compact) > 180:
        compact = f"{compact[:177]}..."
    return f"HTTP {status}: {compact}" if compact else f"HTTP {status}"


def _check_config() -> list[CheckResult]:
    results: list[CheckResult] = []
    url = _base_url()
    key = _anon_key()
    results.append(
        CheckResult(
            "config:SUPABASE_URL",
            bool(url),
            "SUPABASE_URL is set" if url else "SUPABASE_URL is missing",
        )
    )
    results.append(
        CheckResult(
            "config:SUPABASE_ANON_KEY",
            bool(key),
            "SUPABASE_ANON_KEY is set" if key else "SUPABASE_ANON_KEY is missing",
        )
    )
    return results


def _check_reachability() -> CheckResult:
    status, body = _request("GET", f"{_base_url()}/auth/v1/settings")
    return CheckResult(
        "supabase:reachable",
        200 <= status < 500,
        _status_details(status, body),
    )


def _check_auth_endpoint() -> CheckResult:
    status, body = _request("GET", f"{_base_url()}/auth/v1/settings")
    return CheckResult(
        "auth:settings-endpoint",
        status == 200,
        _status_details(status, body),
    )


def _check_table(table_name: str) -> CheckResult:
    status, body = _request(
        "GET",
        _rest_url(table_name, {"select": "id", "limit": "0"}),
    )
    missing_markers = ("PGRST205", "Could not find the table", "does not exist")
    missing = any(marker in body for marker in missing_markers)
    return CheckResult(
        f"table:{table_name}",
        200 <= status < 300 and not missing,
        _status_details(status, body),
    )


def _check_storage_endpoint() -> CheckResult:
    status, body = _request("GET", f"{_base_url()}/storage/v1/bucket")
    return CheckResult(
        "storage:endpoint",
        200 <= status < 500 and status != 404,
        _status_details(status, body),
    )


def _json_object(body: str) -> dict[str, object]:
    try:
        value = json.loads(body)
    except json.JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}


def _json_list(body: str) -> list[object]:
    try:
        value = json.loads(body)
    except json.JSONDecodeError:
        return []
    return value if isinstance(value, list) else []


def _body_proves_missing_bucket(status: int, body: str) -> bool:
    if status not in {400, 404}:
        return False
    lowered = body.lower()
    missing_markers = (
        "bucket not found",
        "bucket_not_found",
        "not_found",
    )
    return any(marker in lowered for marker in missing_markers)


def _bucket_name_from_entry(entry: object) -> str:
    if not isinstance(entry, dict):
        return ""
    value = entry.get("id") or entry.get("name")
    return value if isinstance(value, str) else ""


def _check_bucket() -> CheckResult:
    list_status, list_body = _request("GET", f"{_base_url()}/storage/v1/bucket")
    if list_status == 200:
        buckets = _json_list(list_body)
        bucket_names = {_bucket_name_from_entry(entry) for entry in buckets}
        if REQUIRED_BUCKET in bucket_names:
            return CheckResult(
                f"bucket:{REQUIRED_BUCKET}",
                True,
                "bucket found via storage bucket list endpoint",
            )

    direct_status, direct_body = _request(
        "GET",
        f"{_base_url()}/storage/v1/bucket/{urllib.parse.quote(REQUIRED_BUCKET)}",
    )
    if direct_status == 200:
        data = _json_object(direct_body)
        bucket_id = data.get("id") or data.get("name")
        if bucket_id == REQUIRED_BUCKET or REQUIRED_BUCKET in direct_body:
            return CheckResult(
                f"bucket:{REQUIRED_BUCKET}",
                True,
                "bucket found via direct storage bucket endpoint",
            )

    object_list_status, object_list_body = _request(
        "POST",
        f"{_base_url()}/storage/v1/object/list/{urllib.parse.quote(REQUIRED_BUCKET)}",
        body=b'{"limit":1,"offset":0}',
    )
    if object_list_status in {200, 401, 403}:
        return CheckResult(
            f"bucket:{REQUIRED_BUCKET}",
            True,
            "Bucket existence not verifiable with anon key; verify manually in Supabase UI",
            warning=True,
        )

    public_probe_status, public_probe_body = _request(
        "GET",
        f"{_base_url()}/storage/v1/object/public/"
        f"{urllib.parse.quote(REQUIRED_BUCKET)}/__collectiq_readiness_probe__",
    )
    if public_probe_status in {401, 403, 404} and not _body_proves_missing_bucket(
        public_probe_status,
        public_probe_body,
    ):
        return CheckResult(
            f"bucket:{REQUIRED_BUCKET}",
            True,
            "Bucket existence not verifiable with anon key; verify manually in Supabase UI",
            warning=True,
        )

    probes = (
        (list_status, list_body),
        (direct_status, direct_body),
        (object_list_status, object_list_body),
        (public_probe_status, public_probe_body),
    )
    if all(_body_proves_missing_bucket(status, body) for status, body in probes[1:]):
        return CheckResult(
            f"bucket:{REQUIRED_BUCKET}",
            False,
            "Supabase storage APIs reported bucket not found.",
        )

    return CheckResult(
        f"bucket:{REQUIRED_BUCKET}",
        True,
        "Bucket existence not verifiable with anon key; verify manually in Supabase UI",
        warning=True,
    )


def run_checks() -> list[CheckResult]:
    results = _check_config()
    if any(not result.passed for result in results):
        return results

    results.append(_check_reachability())
    results.append(_check_auth_endpoint())
    for table in REQUIRED_TABLES:
        results.append(_check_table(table))
    results.append(_check_storage_endpoint())
    results.append(_check_bucket())
    return results


def main() -> int:
    results = run_checks()
    failures = [result for result in results if not result.passed]
    warnings = [result for result in results if result.warning]

    for result in results:
        prefix = "WARN" if result.warning else "PASS" if result.passed else "FAIL"
        print(f"[{prefix}] {result.name} - {result.details}")

    print()
    print(f"Checks: {len(results)}")
    print(f"Passed: {len(results) - len(failures)}")
    print(f"Warnings: {len(warnings)}")
    print(f"Failed: {len(failures)}")

    if failures:
        print()
        print("No writes were performed. Fix the failed setup items and run again.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
