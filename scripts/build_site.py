"""Bundle exported R results and final report artifacts for the static explorer."""
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
site = root / "site"
payload = json.loads((site / "data.json").read_text(encoding="utf-8-sig"))
text = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
template = (site / "index.template.html").read_text(encoding="utf-8")
(site / "index.html").write_text(template.replace("__PROJECT_DATA__", text), encoding="utf-8")
shutil.copytree(root / "reports" / "figures", site / "figures", dirs_exist_ok=True)
report = next((root / "reports").glob("*-insights.html"), None)
if report is None:
    report = root / "reports" / "urban-demand.html"
if report.exists():
    shutil.copy2(report, site / "report.html")
downloads = site / "downloads"
downloads.mkdir(exist_ok=True)
for path in (root / "reports" / "downloads").glob("*"):
    if path.is_file():
        shutil.copy2(path, downloads / path.name)
print(f"Built {root.name}: {len(text):,} bytes of embedded analytical data")
