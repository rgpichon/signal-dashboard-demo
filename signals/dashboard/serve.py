#!/usr/bin/env python3
"""Serve the dashboard over HTTP. Run from repo root: python signals/dashboard/serve.py"""
import http.server
import os
import sys

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    http.server.HTTPServer(("", port), http.server.SimpleHTTPRequestHandler).serve_forever()
