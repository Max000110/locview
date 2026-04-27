🌍 LocView

«Advanced Geospatial Intelligence & Reconnaissance Toolkit
Terminal-first location intelligence platform for geospatial scanning, hotspot analysis, and interactive reconnaissance workflows.»

---

✨ Features

- 📍 Reverse Geocoding & Address Resolution
- 🌦 Real-Time Weather Intelligence
- 🛰 Satellite / Static Map Screenshot Capture
- 🏢 Nearby POI Enumeration
- 🔥 Polygon / Bounding Box Heatmap Scanning
- 📊 Hotspot Visualization & Risk Scoring
- 📄 HTML / PDF Report Export
- 🚨 Geofence Alerting
- 📈 Trend Analysis Engine
- 📡 Live Coordinate Tracking
- 🖥 Interactive TUI Dashboard
- 🔌 Plugin-Based Provider Architecture

---

💻 Supported Platforms

Platform| Supported| Notes
Android (Termux)| ✅ Full Support| Primary target platform
Linux| ✅ Full Support| Native support
macOS| ⚠ Partial| May require minor adjustments
Windows| ⚠ Experimental| Best via WSL
Docker| ✅ Supported| Dockerfile included

---

📦 Installation

Full Install (Recommended)

git clone https://github.com/Max000110/locview.git
cd locview

pkg update && pkg upgrade -y
pkg install python git termux-api -y
termux-setup-storage

pip install -r requirements.txt
pip install -e .

---

🚀 Usage

---

🖥 Launch Interactive TUI Dashboard

locview tui

Use TUI when you want visual interactive scanning/dashboard workflow.

---

🧠 CLI Command Guide

---

📍 Standard Coordinate Scan

Scans a single coordinate and returns:

- Address
- Weather
- Nearby POIs
- Risk Score
- Satellite Screenshot
- HTML/PDF Reports

locview scan \
  --lat 19.1606 \
  --lon 72.8479

---

🗺 Scan + Open Google Maps

Same as standard scan, but auto-opens Google Maps.

locview scan \
  --lat 19.1606 \
  --lon 72.8479 \
  --open

---

🔥 Polygon / Area Heatmap Scan

Scans a full bounding box area and generates hotspot heatmap.

locview polygon \
  --lat-min 19.15 \
  --lon-min 72.84 \
  --lat-max 19.17 \
  --lon-max 72.86

---

📊 Compare Multiple Locations

Compare multiple coordinates to identify best location.

locview compare \
  --coords \
  "19.1606,72.8479" \
  "19.1700,72.8500"

---

🚨 Add Geofence

Create saved geofence alert region.

locview geofence-add \
  --name "Home" \
  --lat 19.1606 \
  --lon 72.8479 \
  --radius 500

---

📡 Check Geofence Trigger

Check whether coordinate enters saved geofence.

locview geofence-check \
  --lat 19.1606 \
  --lon 72.8479

---

📈 Trend Analysis

Analyze historical POI/intel trends for coordinate.

locview trend \
  --lat 19.1606 \
  --lon 72.8479

---

🛰 Live Tracking

Track movement across multiple coordinates.

locview track \
  --points \
  "19.1606,72.8479" \
  "19.1700,72.8500"

---

📁 Export Paths

Generated Reports

/storage/emulated/0/Documents/LocViewReports/

---

Satellite Screenshots

/storage/emulated/0/Pictures/LocView/

---

🛠 Troubleshooting

---

POI API Rate Limits (429 / 504)

If Overpass API returns rate-limit errors:

- Wait 30–60 seconds
- Reduce polygon scan area
- Increase polygon scan step size

---

Reports Not Opening

Install Termux API:

pkg install termux-api

---

Storage Permission Issues

termux-setup-storage

---

🗂 Project Structure

locview/
├── providers/     # Data providers / APIs
├── core/          # Scan engines
├── export/        # Report generation
├── tui/           # Interactive dashboard
├── intel/         # Risk / scoring / trends
├── alerts/        # Geofence logic
├── live/          # Tracking engine

---

🤝 Contributing

Contributions, bug reports, and feature requests are welcome.

Please include:

- Error traceback
- Reproduction steps
- Device / OS info
- Screenshots / logs

---

📜 License

Licensed under the MIT License.

You may use, modify, distribute, and sublicense this software under the terms of the MIT License.

See the "LICENSE" (LICENSE) file for full legal text.

---

⭐ Author

Built by Max000110

---

⚠ Disclaimer

LocView is intended for educational, research, and legitimate geospatial analysis purposes only.
Users are responsible for complying with applicable laws and provider terms.
