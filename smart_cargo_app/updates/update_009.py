from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")

HOME_BACKUP = Path("backups/home_page_before_update009.txt")
CONTROLLER_BACKUP = Path("backups/home_controller_before_update009.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

if not CONTROLLER.exists():
    raise SystemExit("Erro: lib/controllers/home_controller.dart não encontrado.")

HOME_BACKUP.parent.mkdir(parents=True, exist_ok=True)

shutil.copy2(HOME, HOME_BACKUP)
shutil.copy2(CONTROLLER, CONTROLLER_BACKUP)

home_code = HOME.read_text(encoding="utf-8")
controller_code = CONTROLLER.read_text(encoding="utf-8")

controller_field = "final HomeController controller = HomeController();"

if controller_field not in home_code:
    raise SystemExit(
        "Erro: HomeController não está integrado à HomePage."
    )

# ------------------------------------------------------------
# ATUALIZA O CONTROLLER
# ------------------------------------------------------------

model_import = "import '../models/delivery_stop.dart';"

controller_lines = [
    line
    for line in controller_code.splitlines()
    if line.strip() != model_import
]

last_import = -1

for index, line in enumerate(controller_lines):
    if line.startswith("import "):
        last_import = index

controller_lines.insert(last_import + 1, model_import)
controller_code = "\n".join(controller_lines) + "\n"

class_marker = "class HomeController extends ChangeNotifier {"
stops_field = "  final List<DeliveryStop> stops = [];"

if class_marker not in controller_code:
    raise SystemExit(
        "Erro: classe HomeController não encontrada."
    )

if stops_field not in controller_code:
    controller_code = controller_code.replace(
        class_marker,
        class_marker + "\n" + stops_field,
        1,
    )

# ------------------------------------------------------------
# ATUALIZA A HOME PAGE
# ------------------------------------------------------------

possible_declarations = [
    "  final List<DeliveryStop> stops = [];\n",
    "  final List<DeliveryStop> stops = <DeliveryStop>[];\n",
]

removed = False

for declaration in possible_declarations:
    if declaration in home_code:
        home_code = home_code.replace(declaration, "", 1)
        removed = True
        break

if not removed and "controller.stops" not in home_code:
    raise SystemExit(
        "Erro: não encontrei a declaração local da lista stops."
    )

# Substitui somente referências não qualificadas.
home_code = re.sub(
    r"(?<![\w.])stops\b",
    "controller.stops",
    home_code,
)

if "controller.controller.stops" in home_code:
    raise SystemExit(
        "Erro: substituição duplicada detectada."
    )

if re.search(r"(?<![\w.])stops\b", home_code):
    raise SystemExit(
        "Erro: ainda existem referências antigas à lista stops."
    )

CONTROLLER.write_text(controller_code, encoding="utf-8")
HOME.write_text(home_code, encoding="utf-8")

print("Update 009 aplicado com sucesso.")
print("- lista stops movida para HomeController")
print("- HomePage agora usa controller.stops")
print("- backups criados")
