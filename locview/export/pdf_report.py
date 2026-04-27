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
