#!/usr/bin/env python3
"""Serve the Godot web export with correct MIME types."""

from __future__ import annotations

import argparse
import http.server
import os
import socketserver

ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "holygems-web")
)

MIME = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".json": "application/json",
}


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()

    def guess_type(self, path):
        ext = os.path.splitext(path)[1].lower()
        if ext in MIME:
            return MIME[ext]
        return super().guess_type(path)

    def log_message(self, fmt: str, *args) -> None:
        print("[%s] %s" % (self.log_date_time_string(), fmt % args), flush=True)


class ReuseServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8088)
    args = parser.parse_args()
    if not os.path.isfile(os.path.join(ROOT, "index.html")):
        raise SystemExit("Missing holygems-web/index.html. Export the Web preset first.")
    with ReuseServer((args.host, args.port), Handler) as httpd:
        print("Serving %s on http://%s:%s" % (ROOT, args.host, args.port), flush=True)
        httpd.serve_forever()


if __name__ == "__main__":
    main()
