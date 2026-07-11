from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")
BACKUP = Path("backups/home_page_before_update008.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

if not CONTROLLER.exists():
    raise SystemExit("Erro: lib/controllers/home_controller.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

controller_field = "final HomeController controller = HomeController();"

if controller_field not in code:
    raise SystemExit(
        "Erro: HomeController ainda não está integrado à HomePage."
    )

# Remove a variável antiga da tela.
old_declarations = [
    "  bool processing = false;\n",
    "  bool processing = false;\r\n",
]

removed = False

for declaration in old_declarations:
    if declaration in code:
        code = code.replace(declaration, "", 1)
        removed = True
        break

if not removed and "bool processing = false;" in code:
    code = code.replace("bool processing = false;", "", 1)
    removed = True

if not removed and "controller.processing" not in code:
    raise SystemExit(
        "Erro: não encontrei a variável antiga 'processing'. "
        "Nenhuma alteração foi aplicada."
    )

# Troca atribuições pelo método do controller.
code = re.sub(
    r"(?<![\w.])processing\s*=\s*true\s*;",
    "controller.setProcessing(true);",
    code,
)

code = re.sub(
    r"(?<![\w.])processing\s*=\s*false\s*;",
    "controller.setProcessing(false);",
    code,
)

# Troca todas as leituras restantes.
code = re.sub(
    r"(?<![\w.])processing\b",
    "controller.processing",
    code,
)

# Valida para evitar substituições duplicadas.
if "controller.controller.processing" in code:
    raise SystemExit(
        "Erro: substituição duplicada detectada. "
        "Restaure o backup antes de continuar."
    )

if re.search(r"(?<![\w.])processing\b", code):
    raise SystemExit(
        "Erro: ainda existem referências antigas a 'processing'."
    )

HOME.write_text(code, encoding="utf-8")

print("Update 008 aplicado com sucesso.")
print("- variável local processing removida")
print("- leituras usam controller.processing")
print("- alterações usam controller.setProcessing(...)")
print("- backup salvo em backups/home_page_before_update008.txt")
