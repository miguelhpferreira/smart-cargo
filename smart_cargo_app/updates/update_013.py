from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")

HOME_BACKUP = Path("backups/home_page_before_update013.txt")
CONTROLLER_BACKUP = Path("backups/home_controller_before_update013.txt")

for file in (HOME, CONTROLLER):
    if not file.exists():
        raise SystemExit(f"Erro: {file} não encontrado.")

HOME_BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, HOME_BACKUP)
shutil.copy2(CONTROLLER, CONTROLLER_BACKUP)

home_code = HOME.read_text(encoding="utf-8")
controller_code = CONTROLLER.read_text(encoding="utf-8")


def replace_method(code: str, signature_text: str, replacement: str) -> str:
    start = code.find(signature_text)

    if start == -1:
        raise SystemExit(
            f"Erro: método '{signature_text}' não encontrado."
        )

    brace_start = code.find("{", start)

    if brace_start == -1:
        raise SystemExit("Erro: abertura do método não encontrada.")

    depth = 0
    end = None

    for index in range(brace_start, len(code)):
        char = code[index]

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                end = index + 1
                break

    if end is None:
        raise SystemExit("Erro: fechamento do método não encontrado.")

    return code[:start] + replacement + code[end:]


# ------------------------------------------------------------
# CONTROLLER
# ------------------------------------------------------------

class_marker = "class HomeController extends ChangeNotifier {"

if class_marker not in controller_code:
    raise SystemExit("Erro: classe HomeController não encontrada.")

fields = """  int _knownLocationsCount = 0;

  int get knownLocationsCount => _knownLocationsCount;
"""

if "int get knownLocationsCount" not in controller_code:
    controller_code = controller_code.replace(
        class_marker,
        class_marker + "\n" + fields,
        1,
    )

controller_method = """
  Future<void> loadKnownLocationsCount() async {
    _knownLocationsCount =
        await databaseService.countKnownLocations();
    notifyListeners();
  }
"""

if "Future<void> loadKnownLocationsCount()" not in controller_code:
    final_brace = controller_code.rfind("}")

    if final_brace == -1:
        raise SystemExit("Erro: fim do HomeController não encontrado.")

    controller_code = (
        controller_code[:final_brace].rstrip()
        + "\n"
        + controller_method
        + "\n}\n"
    )


# ------------------------------------------------------------
# HOME PAGE
# ------------------------------------------------------------

# Remove o campo local antigo.
home_code, removed_count = re.subn(
    r"^\s*int\s+knownLocationsCount\s*=\s*0\s*;\s*$\n?",
    "",
    home_code,
    count=1,
    flags=re.MULTILINE,
)

if removed_count == 0 and "controller.knownLocationsCount" not in home_code:
    raise SystemExit(
        "Erro: campo local knownLocationsCount não encontrado."
    )

# Substitui o método antigo por um wrapper que atualiza a tela.
home_wrapper = """Future<void> loadKnownLocationsCount() async {
    await controller.loadKnownLocationsCount();

    if (mounted) {
      setState(() {});
    }
  }"""

home_code = replace_method(
    home_code,
    "Future<void> loadKnownLocationsCount() async",
    home_wrapper,
)

# Troca somente usos não qualificados da variável.
home_code = re.sub(
    r"(?<![\w.])knownLocationsCount\b",
    "controller.knownLocationsCount",
    home_code,
)

# Corrige possível alteração indevida no nome do método.
home_code = home_code.replace(
    "loadController.knownLocationsCount",
    "loadKnownLocationsCount",
)

if "controller.controller." in home_code:
    raise SystemExit("Erro: referência duplicada detectada.")

CONTROLLER.write_text(controller_code, encoding="utf-8")
HOME.write_text(home_code, encoding="utf-8")

print("Update 013 aplicado com sucesso.")
print("- contagem movida para o HomeController")
print("- consulta usa DatabaseService.countKnownLocations()")
print("- HomePage preserva a atualização visual")
print("- backups criados")
