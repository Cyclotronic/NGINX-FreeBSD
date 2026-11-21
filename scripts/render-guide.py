"""Render the recipient Markdown guide to a paginated PDF using PyMuPDF."""
from pathlib import Path
import html
import re
import sys
import pymupdf

PROJECT = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else PROJECT / "docs" / "UPGRADE-GUIDE.md"
output = Path(sys.argv[2]) if len(sys.argv) > 2 else PROJECT / "docs" / "NGINX-Upgrade-and-Recovery-DRAFT.pdf"

def inline(text):
    text = html.escape(text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    return re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)

parts = []
paragraph = []
code = None
table = None
def flush():
    if paragraph:
        parts.append("<p>" + inline(" ".join(paragraph)) + "</p>")
        paragraph.clear()

for line in source.read_text(encoding="utf-8").splitlines():
    if line.strip() == "<!-- pagebreak -->":
        flush()
        parts.append('<div style="page-break-before: always"></div>')
        continue
    if line.startswith("```"):
        flush()
        if code is None:
            code = []
        else:
            parts.append("<pre>" + html.escape("\n".join(code)) + "</pre>")
            code = None
        continue
    if code is not None:
        code.append(line)
        continue
    if line.startswith("|"):
        flush()
        if table is None: table = []
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not all(re.fullmatch(r"[-: ]+", c) for c in cells): table.append(cells)
        continue
    if table is not None:
        parts.append("<table>" + "".join("<tr>" + "".join(
            ("<th>" if i == 0 else "<td>") + inline(c) + ("</th>" if i == 0 else "</td>")
            for c in row) + "</tr>" for i, row in enumerate(table)) + "</table>")
        table = None
    heading = re.match(r"^(#{1,3}) (.*)", line)
    if heading:
        flush()
        level = len(heading[1])
        section = re.match(r"(\d+)\.", heading[2])
        start_page = level == 2 and section and int(section[1]) in {4, 6, 8, 10, 11}
        page_style = ' style="page-break-before: always"' if start_page else ''
        parts.append(f"<h{level}{page_style}>" + inline(heading[2]) + f"</h{level}>")
    elif not line.strip():
        flush()
    elif line.startswith("- "):
        flush()
        parts.append("<p class='bullet'>• " + inline(line[2:]) + "</p>")
    else:
        paragraph.append(line)
flush()

css = """
body {font-family: sans-serif; font-size: 10.5pt; line-height: 1.4; color: #202c3d;}
h1 {font-size: 27pt; color: #132b46; margin-top: 8pt; margin-bottom: 18pt;}
h2 {font-size: 15pt; color: #006b75; margin-top: 20pt; margin-bottom: 8pt; page-break-after: avoid;}
h3 {font-size: 12pt; color: #132b46; margin-top: 14pt; page-break-after: avoid;}
p {margin: 0 0 8pt;}
pre {font-family: monospace; font-size: 9pt; line-height: 1.3; background-color: #eef3f7; padding: 10pt; white-space: pre-wrap; page-break-inside: avoid;}
code {font-family: monospace; font-size: 9pt;}
table {border-collapse: collapse; width: 100%; margin: 8pt 0 12pt; font-size: 9.5pt;}
th {background-color: #132b46; color: white; text-align: left; padding: 7pt;}
td {padding: 7pt; border-bottom: 0.5pt solid #cbd5df; vertical-align: top;}
.bullet {margin-left: 12pt;}
"""
story = pymupdf.Story(html="<html><body>" + "\n".join(parts) + "</body></html>", user_css=css)
output.parent.mkdir(parents=True, exist_ok=True)
temporary = output.with_suffix(".unpaged.pdf")
writer = pymupdf.DocumentWriter(str(temporary))
page_rect = pymupdf.Rect(0, 0, 612, 792)
content_rect = pymupdf.Rect(45, 53, 567, 742)
more = True
page_count = 0
while more:
    device = writer.begin_page(page_rect)
    more, filled = story.place(content_rect)
    story.draw(device)
    writer.end_page()
    page_count += 1
    if page_count > 100: raise RuntimeError("Guide unexpectedly exceeded 100 pages")
writer.close()
del writer
doc = pymupdf.open(temporary)
for index, page in enumerate(doc):
    page.insert_text((45, 31), "NGINX / FREEBSD 14.2    UPGRADE & RECOVERY", fontsize=8, color=(0.22, 0.32, 0.42))
    page.draw_line((45, 755), (567, 755), color=(0.78, 0.83, 0.87), width=0.5)
    page.insert_text((45, 772), "Prepared for the recorded target • Review the build manifest before installation", fontsize=7.5, color=(0.3, 0.36, 0.42))
    page.insert_text((515, 772), f"{index+1} / {len(doc)}", fontsize=8, color=(0.3, 0.36, 0.42))
doc.set_metadata({"title": "NGINX upgrade and recovery guide — FreeBSD 14.2 amd64", "subject": "Preparation, installation, validation, rollback and emergency recovery"})
doc.save(output, garbage=4, deflate=True)
doc.close()
temporary.unlink()
print(f"Rendered {page_count} pages: {output}")
