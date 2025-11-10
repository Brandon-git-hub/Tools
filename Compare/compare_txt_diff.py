#!/usr/bin/env python3
r"""
compare_txt_diff.py
-------------------
Compare two text files and print a unified diff to the console, and/or generate
a side-by-side HTML diff report.

Usage:
cd tools
  python Compare\compare_txt_diff.py  C:\Users\brandon_wu\Documents\PDK_IDE\IC_RPC_250925\Writer_IC_RPC\tool\Runner\pa2413\pa2413.cpp  C:\Users\brandon_wu\Documents\PDK_IDE\IC_RPC_250909\Writer_IC_RPC\tool\Runner\pa2413\pa2413.cpp
  python Compare\compare_txt_diff.py  "C:\FAE\PA2413_PFC887\wrt_2413_cyc_QFN#2F\pdk_ecc.txt"  "C:\FAE\PA2413_PFC887\wrt_2413_cyc_QFN#2F\r128_vdd_4500.txt"
  python Compare\compare_txt_diff.py  temp_g8.txt  temp_open.txt
  python Compare\compare_txt_diff.py  file1.txt file2.txt --html diff_report.html
  python Compare\compare_txt_diff.py  file1.txt file2.txt --ignore-space --context 5
"""

import argparse
import difflib
import io
import os
import sys

def read_text_lines(path: str, encoding: str, strip_eol: bool = True, normalize_ws: bool = False):
    """Read a text file and return list of lines."""
    try:
        with io.open(path, 'r', encoding=encoding, errors='replace') as f:
            lines = f.readlines()
    except FileNotFoundError:
        sys.exit(f"Error: file not found: {path}")
    except PermissionError:
        sys.exit(f"Error: permission denied: {path}")

    if strip_eol:
        lines = [ln.rstrip('\r\n') for ln in lines]

    if normalize_ws:
        # Collapse whitespace inside each line
        lines = [' '.join(ln.split()) for ln in lines]

    return lines

def print_unified_diff(a_lines, b_lines, a_name, b_name, context: int):
    diff = difflib.unified_diff(
        a_lines, b_lines,
        fromfile=a_name, tofile=b_name,
        lineterm="",
        n=context
    )
    printed_any = False
    for line in diff:
        printed_any = True
        print(line)
    if not printed_any:
        print("No differences found.")

def write_html_diff(a_lines, b_lines, a_name, b_name, out_path):
    d = difflib.HtmlDiff(wrapcolumn=120)
    html = d.make_file(a_lines, b_lines, a_name, b_name)
    try:
        with io.open(out_path, 'w', encoding='utf-8') as f:
            f.write(html)
        return out_path
    except Exception as e:
        sys.exit(f"Error writing HTML file: {e}")

def main():
    parser = argparse.ArgumentParser(description="Compare two text files and output a unified diff and/or HTML report.")
    parser.add_argument("file1", help="First text file")
    parser.add_argument("file2", help="Second text file")
    parser.add_argument("--encoding", default="utf-8", help="Text encoding (default: utf-8)")
    parser.add_argument("--no-strip-eol", action="store_true", help="Do not strip end-of-line characters before diffing")
    parser.add_argument("--ignore-space", action="store_true", help="Normalize whitespace (collapse runs of whitespace)")
    parser.add_argument("--context", type=int, default=3, help="Number of context lines in unified diff (default: 3)")
    parser.add_argument("--html", metavar="OUT.html", help="Also write a side-by-side HTML diff report")
    parser.add_argument("--quiet", action="store_true", help="Suppress console unified diff (use with --html)")

    args = parser.parse_args()

    if os.path.abspath(args.file1) == os.path.abspath(args.file2):
        sys.exit("Error: file1 and file2 are the same path.")

    strip_eol = not args.no_strip_eol

    a_lines = read_text_lines(args.file1, args.encoding, strip_eol=strip_eol, normalize_ws=args.ignore_space)
    b_lines = read_text_lines(args.file2, args.encoding, strip_eol=strip_eol, normalize_ws=args.ignore_space)

    if not args.quiet:
        print_unified_diff(a_lines, b_lines, args.file1, args.file2, context=args.context)

    if args.html:
        out_path = write_html_diff(a_lines, b_lines, args.file1, args.file2, args.html)
        print(f"\nHTML diff written to: {out_path}")

if __name__ == "__main__":
    main()
