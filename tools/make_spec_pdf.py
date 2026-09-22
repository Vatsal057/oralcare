#!/usr/bin/env python3
"""Render SPECIFICATION.md to a paginated PDF.

WHY A BROWSER AND NOT LATEX: the specification quotes Kannada terms from the
Sree questionnaire (section 14.4). A LaTeX build needs explicit font-fallback
configuration to render them and drops the glyphs silently otherwise, which
would lose exactly the content that section exists to document. A Chromium
engine inherits the system font stack, so Kannada and emoji resolve with no
font setup at all.

Usage:  python3 tools/make_spec_pdf.py [source.md] [output.pdf]
Needs:  python3 -m pip install markdown
"""

from __future__ import annotations

import html
import re
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import date
from pathlib import Path

try:
    import markdown
except ImportError:
    sys.exit("Missing dependency. Install with: python3 -m pip install markdown")

REPO = Path(__file__).resolve().parent.parent

BROWSER_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
]

CSS = """
@page { size: A4 portrait; margin: 14mm 13mm 16mm 13mm; }

:root {
  --ink: #16191d;
  --muted: #5b6472;
  --rule: #d8dde4;
  --accent: #0f5c4a;
  --accent-soft: #eef5f2;
  --warn-bg: #fdf4e7;
}

* { box-sizing: border-box; }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }

body {
  font-family: "Charter", "Georgia", "Noto Serif", serif;
  font-size: 9.4pt;
  line-height: 1.5;
  color: var(--ink);
  margin: 0;
}

/* ---------- Cover ---------- */
.cover { page-break-after: always; padding-top: 52mm; }
.cover .eyebrow {
  font-family: "Helvetica Neue", Arial, sans-serif;
  font-size: 8.5pt; letter-spacing: 0.16em; text-transform: uppercase;
  color: var(--accent); font-weight: 600;
}
.cover h1 {
  font-size: 30pt; line-height: 1.12; margin: 8mm 0 3mm 0;
  border: 0; padding: 0; font-weight: 600; letter-spacing: -0.01em;
}
.cover .sub { font-size: 12.5pt; color: var(--muted); margin-bottom: 14mm; }
.cover .rule { height: 3px; width: 64mm; background: var(--accent); margin-bottom: 12mm; }
.cover dl {
  display: grid; grid-template-columns: 34mm 1fr;
  row-gap: 2.4mm; font-size: 9.2pt; margin: 0;
}
.cover dt {
  font-family: "Helvetica Neue", Arial, sans-serif;
  font-size: 7.8pt; letter-spacing: 0.08em; text-transform: uppercase;
  color: var(--muted); padding-top: 0.6mm;
}
.cover dd { margin: 0; }
.cover .foot {
  margin-top: 20mm; font-size: 8.4pt; color: var(--muted);
  border-top: 1px solid var(--rule); padding-top: 4mm; max-width: 140mm;
}

/* ---------- Contents ---------- */
.toc { page-break-after: always; }
.toc h2 { page-break-before: avoid; margin-top: 0; }
.toc ul { list-style: none; padding-left: 0; margin: 0; }
.toc ul ul { padding-left: 7mm; }
.toc li { margin: 0.9mm 0; }
.toc > ul > li > a { font-weight: 600; }
.toc a { text-decoration: none; color: var(--ink); }
.toc ul ul a { color: var(--muted); font-size: 8.8pt; }

/* ---------- Headings ---------- */
h1, h2, h3, h4 {
  font-family: "Helvetica Neue", Arial, sans-serif;
  font-weight: 600; color: var(--ink); line-height: 1.25;
}

/* Each numbered section starts a fresh page: this is a reference document that
   gets navigated to a clause, not read front to back. */
h2 {
  font-size: 15pt; margin: 0 0 5mm 0; padding-bottom: 2.5mm;
  border-bottom: 2px solid var(--accent);
  page-break-before: always; page-break-after: avoid;
}
h2:first-of-type { page-break-before: avoid; }
h3 { font-size: 11pt; margin: 7mm 0 2.5mm 0; page-break-after: avoid; }
h4 { font-size: 9.6pt; margin: 5mm 0 2mm 0; page-break-after: avoid; }

p { margin: 0 0 2.6mm 0; orphans: 3; widows: 3; }

/* ---------- Tables ---------- */
table {
  width: 100%; border-collapse: collapse; margin: 3mm 0 5mm 0;
  font-family: "Helvetica Neue", Arial, sans-serif;
  font-size: 7.9pt; line-height: 1.38;
}
/* Repeat the header row across page breaks, or a long traceability matrix
   becomes unreadable after the first break. */
thead { display: table-header-group; }
tr { page-break-inside: avoid; }
th, td {
  border: 1px solid var(--rule); padding: 1.5mm 2mm;
  text-align: left; vertical-align: top; overflow-wrap: break-word;
}
th {
  background: var(--accent-soft); font-weight: 600; color: var(--accent);
  font-size: 7.6pt; letter-spacing: 0.02em;
}
tbody tr:nth-child(even) td { background: #fafbfc; }

/* ---------- Code ---------- */
code {
  font-family: "SF Mono", "Menlo", "Consolas", monospace;
  font-size: 0.87em; background: #f2f4f6;
  padding: 0.3mm 1mm; border-radius: 2px; overflow-wrap: break-word;
}
pre {
  background: #f7f8fa; border: 1px solid var(--rule);
  border-left: 3px solid var(--accent); padding: 2.5mm 3mm;
  font-size: 8pt; line-height: 1.45; white-space: pre-wrap;
  page-break-inside: avoid; margin: 3mm 0;
}
pre code { background: none; padding: 0; font-size: 1em; }

/* ---------- Lists, quotes, rules ---------- */
ul, ol { margin: 0 0 3mm 0; padding-left: 5.5mm; }
li { margin: 0.7mm 0; }
blockquote {
  margin: 3mm 0; padding: 2mm 3mm; background: var(--warn-bg);
  border-left: 3px solid #d9a441; font-size: 8.8pt;
}
blockquote p:last-child { margin-bottom: 0; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 6mm 0; }
a { color: var(--accent); text-decoration: none; }
"""

HTML_SHELL = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<section class="cover">
  <div class="eyebrow">Application Specification</div>
  <h1>{title}</h1>
  <div class="sub">{subtitle}</div>
  <div class="rule"></div>
  <dl>
{meta}
  </dl>
  <div class="foot">{foot}</div>
</section>

<section class="toc">
<h2>Contents</h2>
{toc}
</section>

{body}
</body>
</html>
"""


def looks_complete(path: Path) -> bool:
    """A finished PDF starts with %PDF- and ends with %%EOF."""
    try:
        size = path.stat().st_size
        if size == 0:
            return False
        with open(path, "rb") as handle:
            if handle.read(5) != b"%PDF-":
                return False
            handle.seek(max(0, size - 2048))
            return b"%%EOF" in handle.read()
    except OSError:
        return False


def find_browser() -> str:
    for candidate in BROWSER_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    for name in ("google-chrome", "chromium", "microsoft-edge"):
        found = shutil.which(name)
        if found:
            return found
    sys.exit("No Chromium-based browser found. Install Google Chrome.")


def split_front_matter(text: str) -> tuple[str, str, list[tuple[str, str]], str]:
    """Move the H1 and the bold key/value preamble onto the cover page.

    Left in the body they would repeat the title and print the metadata as a
    run-on paragraph.
    """
    lines = text.splitlines()
    title, subtitle, cursor = "Specification", "", 0
    meta: list[tuple[str, str]] = []

    for index, line in enumerate(lines):
        if line.startswith("# "):
            title = line[2:].strip()
            cursor = index + 1
            break

    while cursor < len(lines):
        line = lines[cursor].strip()
        if not line:
            cursor += 1
            continue
        if line == "---":
            cursor += 1
            break
        match = re.match(r"^\*\*(.+?):\*\*\s*(.*)$", line)
        if not match:
            break
        meta.append((match.group(1), match.group(2)))
        cursor += 1

    if " — " in title:
        title, subtitle = title.split(" — ", 1)

    return title, subtitle, meta, "\n".join(lines[cursor:])


def linkify(value: str) -> str:
    out = html.escape(value)
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)
    out = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", out)
    out = re.sub(r"(https?://[^\s<)]+)", r'<a href="\1">\1</a>', out)
    return out


def build_html(source: Path) -> tuple[str, str]:
    raw = source.read_text(encoding="utf-8")
    title, subtitle, meta, body_md = split_front_matter(raw)

    converter = markdown.Markdown(
        extensions=["tables", "fenced_code", "toc", "sane_lists", "attr_list"],
        extension_configs={"toc": {"toc_depth": "2-3"}},
    )
    body_html = converter.convert(body_md)

    meta_html = "\n".join(
        f"    <dt>{html.escape(k)}</dt><dd>{linkify(v)}</dd>" for k, v in meta
    )

    foot = (
        f"Generated {date.today().isoformat()} from <code>{source.name}</code>. "
        "Describes the application as built, not as proposed. Section 14 carries "
        "the clause-by-clause traceability matrices against the source "
        "requirement documents."
    )

    return (
        HTML_SHELL.format(
            title=html.escape(title),
            subtitle=html.escape(subtitle or "Application Specification"),
            css=CSS,
            meta=meta_html,
            foot=foot,
            toc=converter.toc,
            body=body_html,
        ),
        title,
    )


def print_pdf(browser: str, page: Path, output: Path, profile: Path) -> None:
    """Print the page, then stop the browser ourselves.

    Deliberately not subprocess.run: some Chromium builds -- Microsoft Edge in
    particular -- finish writing the PDF and then hang indefinitely on an
    auto-updater child, so waiting for exit waits forever on output that is
    already complete. Poll for a complete file instead, then terminate.
    """
    if output.exists():
        output.unlink()

    process = subprocess.Popen(
        [
            browser,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--no-first-run",
            "--disable-component-update",
            "--disable-background-networking",
            "--disable-extensions",
            f"--user-data-dir={profile}",
            "--no-pdf-header-footer",
            f"--print-to-pdf={output}",
            page.as_uri(),
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    try:
        deadline = time.monotonic() + 180
        last_size, stable = -1, 0

        while time.monotonic() < deadline:
            time.sleep(1)
            size = output.stat().st_size if output.exists() else 0

            # Size alone is not enough; the file appears before it is finished.
            if size > 0 and size == last_size:
                stable += 1
                if stable >= 2 and looks_complete(output):
                    return
            else:
                stable = 0

            last_size = size
            if process.poll() is not None and looks_complete(output):
                return
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "SPECIFICATION.md"
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else REPO / "SPECIFICATION.pdf"

    if not source.exists():
        sys.exit(f"Source not found: {source}")

    document, title = build_html(source)
    browser = find_browser()

    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "spec.html"
        page.write_text(document, encoding="utf-8")
        print_pdf(browser, page, output, Path(tmp) / "profile")

    if not looks_complete(output):
        sys.exit(f"PDF at {output} is missing or truncated. Re-run.")

    print(f'Wrote "{title}" -> {output}  ({output.stat().st_size / 1024:.0f} KB)')


if __name__ == "__main__":
    main()
