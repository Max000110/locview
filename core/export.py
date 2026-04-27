import json
from reportlab.pdfgen import canvas

def export_json(report):
    with open("exports/report.json","w") as f:
        json.dump(report,f,indent=2)

def export_html(report):
    html="<html><body><pre>"+json.dumps(report,indent=2)+"</pre></body></html>"
    open("exports/report.html","w").write(html)

def export_pdf(report):
    c=canvas.Canvas("exports/report.pdf")
    y=800
    for k,v in report.items():
        c.drawString(40,y,f"{k}: {str(v)[:100]}")
        y-=20
    c.save()
