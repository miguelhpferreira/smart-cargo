from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_fix_update003.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

required_imports = [
    "import 'scanner_page.dart';",
    "import '../widgets/info_card.dart';",
]

lines = code.splitlines()

# Remove possíveis duplicações.
lines = [
    line for line in lines
    if line.strip() not in required_imports
]

last_import = -1
for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

for new_import in required_imports:
    last_import += 1
    lines.insert(last_import, new_import)

HOME.write_text("\n".join(lines) + "\n", encoding="utf-8")

print("Imports de ScannerPage e InfoCard adicionados com sucesso.")
