from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")

HOME_BACKUP = Path("backups/home_page_before_update010.txt")
CONTROLLER_BACKUP = Path("backups/home_controller_before_update010.txt")

if not HOME.exists():
    raise SystemExit("Erro: home_page.dart não encontrado.")

if not CONTROLLER.exists():
    raise SystemExit("Erro: home_controller.dart não encontrado.")

HOME_BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, HOME_BACKUP)
shutil.copy2(CONTROLLER, CONTROLLER_BACKUP)

home_code = HOME.read_text(encoding="utf-8")
controller_code = CONTROLLER.read_text(encoding="utf-8")

getters = {
    "totalPackages": """  int get totalPackages {
    return stops.fold(
      0,
      (total, stop) => total + stop.packageCodes.length,
    );
  }
""",
    "condominiums": """  int get condominiums {
    return stops.where((stop) => stop.type == 'Condomínio').length;
  }
""",
    "residences": """  int get residences {
    return stops.where((stop) => stop.type == 'Residência').length;
  }
""",
    "commerces": """  int get commerces {
    return stops.where((stop) => stop.type == 'Comércio').length;
  }
""",
}

def remove_getter(code: str, getter_name: str) -> tuple[str, bool]:
    marker = f"int get {getter_name}"
    start = code.find(marker)

    if start == -1:
        return code, False

    # Inclui a indentação existente antes do getter.
    line_start = code.rfind("\n", 0, start) + 1
    brace_start = code.find("{", start)

    if brace_start == -1:
        raise SystemExit(
            f"Erro: abertura do getter {getter_name} não encontrada."
        )

    depth = 0
    end = None

    for index in range(brace_start, len(code)):
        if code[index] == "{":
            depth += 1
        elif code[index] == "}":
            depth -= 1

            if depth == 0:
                end = index + 1
                break

    if end is None:
        raise SystemExit(
            f"Erro: fechamento do getter {getter_name} não encontrado."
        )

    while end < len(code) and code[end] in "\r\n":
        end += 1

    return code[:line_start] + code[end:], True


# Remove os getters da HomePage.
for getter_name in getters:
    home_code, removed = remove_getter(home_code, getter_name)

    if not removed and f"controller.{getter_name}" not in home_code:
        raise SystemExit(
            f"Erro: getter {getter_name} não encontrado na HomePage."
        )

# Troca as referências da interface pelas propriedades do controller.
for getter_name in getters:
    home_code = re.sub(
        rf"(?<![\w.]){getter_name}\b",
        f"controller.{getter_name}",
        home_code,
    )

    if f"controller.controller.{getter_name}" in home_code:
        raise SystemExit(
            f"Erro: substituição duplicada em {getter_name}."
        )

# Adiciona os getters ao HomeController.
missing_getters = [
    code for name, code in getters.items()
    if f"int get {name}" not in controller_code
]

if missing_getters:
    class_end = controller_code.rfind("}")

    if class_end == -1:
        raise SystemExit(
            "Erro: fechamento do HomeController não encontrado."
        )

    block = "\n" + "\n".join(missing_getters)
    controller_code = (
        controller_code[:class_end].rstrip()
        + "\n\n"
        + block.strip()
        + "\n"
        + controller_code[class_end:]
    )

HOME.write_text(home_code, encoding="utf-8")
CONTROLLER.write_text(controller_code, encoding="utf-8")

print("Update 010 aplicado com sucesso.")
print("- Contadores movidos para HomeController")
print("- HomePage passou a usar controller.totalPackages")
print("- HomePage passou a usar os demais contadores do controller")
print("- Backups criados")
