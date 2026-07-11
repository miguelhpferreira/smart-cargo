from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update007.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

controller_import = "import '../controllers/home_controller.dart';"

# Adiciona o import sem duplicar.
lines = [
    line
    for line in code.splitlines()
    if line.strip() != controller_import
]

last_import = -1

for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

if last_import == -1:
    raise SystemExit("Erro: nenhum import encontrado em home_page.dart.")

lines.insert(last_import + 1, controller_import)
code = "\n".join(lines) + "\n"

class_marker = "class _HomePageState extends State<HomePage> {"
controller_field = "  final HomeController controller = HomeController();"

if class_marker not in code:
    raise SystemExit(
        "Erro: classe _HomePageState não encontrada. "
        "Nenhuma alteração foi aplicada."
    )

if controller_field not in code:
    code = code.replace(
        class_marker,
        class_marker + "\n" + controller_field,
        1,
    )

HOME.write_text(code, encoding="utf-8")

print("Update 007 aplicado com sucesso.")
print("- HomeController importado")
print("- Controller criado dentro da HomePage")
print("- Backup salvo em backups/home_page_before_update007.txt")
