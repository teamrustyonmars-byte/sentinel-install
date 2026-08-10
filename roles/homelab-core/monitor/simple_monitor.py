#!/usr/bin/env python3
"""Minimal LAN probe HTTP service — no house secrets.

GET /health  → overall
GET /v1/nodes → probe results (icmp-less: TCP connect to port 22 or custom)
"""
from __future__ import annotations

import argparse
import json
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def probe_host(host: str, port: int = 22, timeout: float = 1.5) -> dict:
    t0 = time.time()
    ok = False
    err = None
    try:
        with socket.create_connection((host, port), timeout=timeout):
            ok = True
    except OSError as e:
        err = str(e)
    ms = int((time.time() - t0) * 1000)
    return {"host": host, "port": port, "ok": ok, "ms": ms, "error": err}


class Handler(BaseHTTPRequestHandler):
    targets: list = []

    def log_message(self, fmt, *args):
        pass

    def _json(self, code: int, obj: dict) -> None:
        b = json.dumps(obj, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):  # noqa: N802
        if self.path in ("/", "/health", "/v1/health"):
            results = [
                probe_host(t.get("host", ""), int(t.get("port") or 22))
                for t in self.targets
                if t.get("host")
            ]
            overall = all(r["ok"] for r in results) if results else True
            self._json(
                200,
                {
                    "ok": overall,
                    "service": "sentinel-simple-monitor",
                    "nodes": results,
                    "ts": int(time.time()),
                },
            )
            return
        if self.path in ("/v1/nodes", "/nodes"):
            results = [
                probe_host(t.get("host", ""), int(t.get("port") or 22))
                for t in self.targets
                if t.get("host")
            ]
            self._json(200, {"nodes": results})
            return
        self._json(404, {"ok": False, "error": "not_found"})


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8085)
    ap.add_argument("--targets", type=Path, required=True)
    args = ap.parse_args()
    raw = json.loads(args.targets.read_text(encoding="utf-8") or "[]")
    if isinstance(raw, dict):
        raw = raw.get("hosts") or raw.get("nodes") or []
    Handler.targets = raw if isinstance(raw, list) else []
    httpd = ThreadingHTTPServer((args.host, args.port), Handler)
    print(json.dumps({"service": "sentinel-simple-monitor", "port": args.port, "targets": len(Handler.targets)}), flush=True)
    httpd.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
