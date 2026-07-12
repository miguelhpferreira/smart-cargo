from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")

HOME_BACKUP = Path("backups/home_page_before_update014.txt")
CONTROLLER_BACKUP = Path("backups/home_controller_before_update014.txt")

for file in (HOME, CONTROLLER):
    if not file.exists():
        raise SystemExit(f"Erro: {file} não encontrado.")

HOME_BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, HOME_BACKUP)
shutil.copy2(CONTROLLER, CONTROLLER_BACKUP)

home_code = HOME.read_text(encoding="utf-8")
controller_code = CONTROLLER.read_text(encoding="utf-8")

# ------------------------------------------------------------
# ADICIONA lastStop AO CONTROLLER
# ------------------------------------------------------------

class_marker = "class HomeController extends ChangeNotifier {"
last_stop_field = "  DeliveryStop? lastStop;"

if class_marker not in controller_code:
    raise SystemExit("Erro: classe HomeController não encontrada.")

if last_stop_field not in controller_code:
    controller_code = controller_code.replace(
        class_marker,
        class_marker + "\n" + last_stop_field,
        1,
    )

# ------------------------------------------------------------
# REMOVE lastStop LOCAL DA HOMEPAGE
# ------------------------------------------------------------

patterns = [
    r"^\s*DeliveryStop\?\s+lastStop\s*;\s*$\n?",
    r"^\s*DeliveryStop\?\s+lastStop\s*=\s*null\s*;\s*$\n?",
]

removed = False

for pattern in patterns:
    home_code, count = re.subn(
        pattern,
        "",
        home_code,
        count=1,
        flags=re.MULTILINE,
    )

    if count:
        removed = True
        break

if not removed and "controller.lastStop" not in home_code:
    raise SystemExit(
        "Erro: não encontrei a declaração local de lastStop. "
        "Nenhuma alteração foi aplicada."
    )

# Substitui somente referências não qualificadas.
home_code = re.sub(
    r"(?<![\w.])lastStop\b",
    "controller.lastStop",
    home_code,
)

if "controller.controller.lastStop" in home_code:
    raise SystemExit("Erro: substituição duplicada detectada.")

if re.search(r"(?<![\w.])lastStop\b", home_code):
    raise SystemExit("Erro: ainda existem referências antigas a lastStop.")

CONTROLLER.write_text(controller_code, encoding="utf-8")
HOME.write_text(home_code, encoding="utf-8")

print("Update 014 aplicado com sucesso.")
print("- lastStop movido para HomeController")
print("- HomePage agora usa controller.lastStop")
print("- backups criados")
