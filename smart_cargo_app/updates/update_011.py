from pathlib import Path
import shutil

CONTROLLER = Path("lib/controllers/home_controller.dart")
BACKUP = Path("backups/home_controller_before_update011.txt")

if not CONTROLLER.exists():
    raise SystemExit(
        "Erro: lib/controllers/home_controller.dart não encontrado."
    )

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(CONTROLLER, BACKUP)

code = CONTROLLER.read_text(encoding="utf-8")

database_import = "import '../services/database_service.dart';"

# Remove possível import duplicado e adiciona no local correto.
lines = [
    line
    for line in code.splitlines()
    if line.strip() != database_import
]

last_import = -1

for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

if last_import == -1:
    raise SystemExit(
        "Erro: nenhum import encontrado no HomeController."
    )

lines.insert(last_import + 1, database_import)
code = "\n".join(lines) + "\n"

class_marker = "class HomeController extends ChangeNotifier {"

if class_marker not in code:
    raise SystemExit(
        "Erro: classe HomeController não encontrada."
    )

database_field = (
    "  final DatabaseService databaseService;\n\n"
    "  HomeController({DatabaseService? databaseService})\n"
    "      : databaseService = "
    "databaseService ?? DatabaseService.instance;"
)

if "final DatabaseService databaseService;" not in code:
    code = code.replace(
        class_marker,
        class_marker + "\n" + database_field,
        1,
    )

CONTROLLER.write_text(code, encoding="utf-8")

print("Update 011 aplicado com sucesso.")
print("- DatabaseService importado")
print("- HomeController recebeu o serviço por injeção")
print("- funcionamento atual preservado")
print("- backup criado")
