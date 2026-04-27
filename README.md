🌍 LocView

Advanced Geospatial Intelligence Toolkit for Terminal & TUI

LocView is a powerful reconnaissance and geospatial analysis toolkit built for terminal-first users.
It provides:

- 📍 Reverse Geocoding
- 🌦 Weather Intelligence
- 🛰 Satellite Screenshot Fetching
- 🏢 Nearby POI Detection
- 📊 Polygon / Area Scanning
- 🔥 Heatmap Visualization
- 📄 HTML / PDF Reporting
- 📡 Live Tracking
- 🚨 Geofence Alerts
- 🧠 Risk / Threat Scoring
- 📈 Trend Analysis
- 🖥 Interactive TUI Dashboard

---

📦 Installation

Step 1 — Clone Repository

git clone https://github.com/Max000110/locview.git
cd locview

---

Step 2 — Install Dependencies

pip install -r requirements.txt
pip install -e .

---

Step 3 — Run LocView

locview --help

---

🚀 Quick Start

Launch Dashboard UI

locview tui

This opens the full interactive terminal dashboard.

---

🧩 Features Overview

---

1. Standard Location Scan

Scans one coordinate and shows:

- Address
- Weather
- Nearby POIs
- Risk Score
- Satellite Screenshot
- Export Reports

locview scan --lat 19.1606 --lon 72.8479

---

2. Open Google Maps After Scan

locview scan --lat 19.1606 --lon 72.8479 --open

---

3. Compare Multiple Locations

Compare multiple coordinates for best location.

locview compare \
--coords "19.1606,72.8479" "19.1700,72.8500"

---

4. Polygon / Area Scan

Scan an entire area and rank hotspots.

locview polygon \
--lat-min 19.1500 \
--lon-min 72.8300 \
--lat-max 19.1800 \
--lon-max 72.8600

---

5. Live Tracking

Track coordinate movement over time.

locview track \
--points "19.1606,72.8479" "19.1700,72.8500"

---

6. Geofence Add

Create alert zones.

locview geofence-add \
--name "Home" \
--lat 19.1606 \
--lon 72.8479 \
--radius 500

---

7. Geofence Check

Check if point enters saved zone.

locview geofence-check \
--lat 19.1606 \
--lon 72.8479

---

8. Trend Analysis

Analyze historical POI trends.

locview trend \
--lat 19.1606 \
--lon 72.8479

---

9. List Plugins

locview plugins

---

🖥 TUI Dashboard Guide

Run:

locview tui

Dashboard Buttons:

---

Run Scan

Performs full intelligence scan.

---

Polygon Heatmap

Scans surrounding area and generates hotspot heatmap.

---

Open HTML Report

Opens latest generated HTML scan report.

---

Open Polygon Report

Opens latest polygon area scan report.

---

📁 Export Locations

Generated files save here:

/storage/emulated/0/Documents/LocViewReports/

Satellite screenshots save here:

/storage/emulated/0/Pictures/LocView/

---

🛠 Troubleshooting

---

POI API Rate Limit / 429 Errors

If you see:

429 Too Many Requests

It means POI providers are rate-limiting requests.

Fix:

- Wait 30–60 seconds
- Reduce polygon scan size
- Increase polygon step size

---

HTML Report Not Opening

Ensure Termux API installed:

pkg install termux-api

---

Permission Issues

Grant storage permission:

termux-setup-storage

---

Broken Install / Dependency Errors

Reinstall:

pip install -r requirements.txt --upgrade
pip install -e . --force-reinstall

---

📌 Project Structure

locview/
├── providers/      # External data providers
├── export/         # Report generation
├── core/           # Scan engines
├── tui/            # Dashboard UI
├── intel/          # Scoring / Risk / Trend engines
├── alerts/         # Geofence logic
├── live/           # Tracking engine

---

🤝 Support / Feedback

If you encounter bugs:

1. Open GitHub Issues
2. Include:
   - Error Screenshot
   - Command Used
   - Logs / Traceback
   - Device / OS Info

GitHub Repo:

https://github.com/Max000110/locview

---

📜 License

MIT License

---

⭐ Credits

Built by Max000110

---

🔮 Roadmap

Planned Future Features:

- Multi-provider POI engine
- Advanced satellite imagery layers
- ML hotspot prediction
- Route analysis
- Web dashboard
- Plugin marketplace
