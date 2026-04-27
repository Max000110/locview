#!/usr/bin/env bash
set -e

########################################
# Install PDF Dependency
########################################
pip install reportlab

########################################
# PDF Export Module
########################################
mkdir -p locview/export

cat > locview/export/pdf_report.py <<'PYEOF'
import os
import time
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle
)
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet

EXPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"
os.makedirs(EXPORT_DIR, exist_ok=True)


def generate_pdf_report(title, rows):
    ts = int(time.time())
    path = os.path.join(EXPORT_DIR, f"locview_report_{ts}.pdf")

    doc = SimpleDocTemplate(path)
    styles = getSampleStyleSheet()
    story = []

    story.append(Paragraph(title, styles['Title']))
    story.append(Spacer(1, 12))

    table_data = [["Latitude", "Longitude", "POI Count"]]

    for row in rows:
        table_data.append([
            str(row.get("lat")),
            str(row.get("lon")),
            str(row.get("poi_count"))
        ])

    table = Table(table_data)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.black),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1),
         [colors.whitesmoke, colors.lightgrey]),
    ]))

    story.append(table)
    doc.build(story)

    return path
PYEOF

########################################
# Integrate into Polygon Workflow
########################################
python - <<'PYEOF'
from pathlib import Path

p = Path("locview/main.py")
text = p.read_text()

if "generate_pdf_report" not in text:
    text = text.replace(
        "from locview.export.heatmap_report import generate_heatmap_report",
        "from locview.export.heatmap_report import generate_heatmap_report\nfrom locview.export.pdf_report import generate_pdf_report"
    )

old = '''
    report = generate_polygon_report(data)
    heatmap = generate_heatmap_report(data)

    print("[green]Polygon Scan Report:[/green]", report)
    print("[green]Heatmap Visualization:[/green]", heatmap)

    open_browser(heatmap)
'''

new = '''
    report = generate_polygon_report(data)
    heatmap = generate_heatmap_report(data)
    pdf = generate_pdf_report("LocView Polygon Area Scan", data)

    print("[green]Polygon Scan Report:[/green]", report)
    print("[green]Heatmap Visualization:[/green]", heatmap)
    print("[green]PDF Report:[/green]", pdf)

    open_browser(heatmap)
'''

text = text.replace(old, new)
p.write_text(text)
PYEOF

########################################
# Reinstall Package
########################################
pip install -e .

echo "[+] PDF Export Engine Integrated Successfully"
